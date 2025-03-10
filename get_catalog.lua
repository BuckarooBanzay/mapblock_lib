---------
-- Catalog functions

local has_placeholder_mod = minetest.get_modpath("placeholder")

------
-- Catalog object
-- @type Catalog
local Catalog = {}
local Catalog_mt = { __index = Catalog }

--- Get the overall size of the catalog
-- @return @{util.mapblock_pos} the size in mapblocks
function Catalog:get_size()
	return vector.add(self.manifest.range, 1)
end

local function get_meta_filename(mapblock_pos)
	local pos_str = minetest.pos_to_string(mapblock_pos)
	return "mapblock_" .. pos_str .. ".meta.json"
end

local function get_mapblock_bin_filename(mapblock_pos)
	local pos_str = minetest.pos_to_string(mapblock_pos)
	return "mapblock_" .. pos_str .. ".bin"
end

local function read_manifest_mapblock(filename, catalog_mapblock_pos)
	local f = io.open(filename, "rb")
	local z, err = mtzip.unzip(f)
	if err then
		f:close()
		return nil, nil, err
	end

	local meta_name = get_meta_filename(catalog_mapblock_pos)
	local bin_name = get_mapblock_bin_filename(catalog_mapblock_pos)
	local mapblock_data = z:get(bin_name)
	local manifest_data = z:get(meta_name)
	local mapblock = mapblock_lib.read_mapblock(mapblock_data)
	if not manifest_data then
		return nil, nil, "no manifest found in '" .. meta_name .. "'"
	end
	local manifest = minetest.parse_json(manifest_data)
	f:close()

	return manifest, mapblock
end

--- Check for the existence of a mapblock in the catalog
-- @param catalog_mapblock_pos @{util.mapblock_pos} the mapblock position in the catalog
-- @return the zip-manifest entry of the meta-file or nil if not found
function Catalog:has_mapblock(catalog_mapblock_pos)
	local meta_name = get_meta_filename(catalog_mapblock_pos)
	return self.zip:get_entry(meta_name)
end

--- Deserialize a single mapblock from the catalog
-- @see deserialize_options.lua
-- @param catalog_mapblock_pos @{util.mapblock_pos} the mapblock position in the catalog
-- @param world_mapblock_pos @{util.mapblock_pos} the mapblock position in the world
-- @param options @{deserialize_mapblock.deserialize_options} mapblock deserialization options
-- @return success true on success
-- @return error in case of an error
function Catalog:deserialize(catalog_mapblock_pos, world_mapblock_pos, options)
	local manifest, mapblock, err = read_manifest_mapblock(self.filename, catalog_mapblock_pos)
	if err then
		return nil, err
	end
	options = options or {}
	return mapblock_lib.deserialize_mapblock(world_mapblock_pos, mapblock, manifest, options)
end

--- Prepare a mapblock with options for faster access
-- @param catalog_mapblock_pos @{util.mapblock_pos} the mapblock position in the catalog
-- @param options @{deserialize_mapblock.deserialize_options} mapblock deserialization options
-- @return deserFn a function that accepts a mapblock position @{util.mapblock_pos} to write the mapblock to the map
-- @return error in case of an error
function Catalog:prepare(catalog_mapblock_pos, options)
	options = options or {}
	local manifest, mapblock, err = read_manifest_mapblock(self.filename, catalog_mapblock_pos)
	if err then
		return nil, err
	end

	if options.transform and options.transform.replace then
		-- replace node-ids before localizing them
		mapblock_lib.replace(options.transform.replace, manifest.node_mapping, mapblock)
	end

	-- localize node ids and ignore unknown nodes
	local all_nodes_known, unknown_nodes = mapblock_lib.localize_nodeids(manifest.node_mapping, mapblock.node_ids)
	if has_placeholder_mod and not all_nodes_known then
		-- set placeholders
		mapblock_lib.place_placeholders(mapblock, manifest, unknown_nodes)
	end

	-- transform, if needed
	if options.transform then
		local size = {x=15, y=15, z=15}
		mapblock_lib.transform(options.transform, size, mapblock, manifest.metadata)
	end

	return function(mapblock_pos)
		-- write to map
		local min, max = mapblock_lib.get_mapblock_bounds_from_mapblock(mapblock_pos)
		mapblock_lib.deserialize_part(min, max, mapblock, manifest.metadata, options)
	end
end

-- mapblock area for index -> pos calculations
local mapblock_area = VoxelArea:new({MinEdge={x=0,y=0,z=0}, MaxEdge={x=15,y=15,z=15}})

function Catalog:get_node(pos)
	local mb_pos = mapblock_lib.get_mapblock(pos)
	if not self:has_mapblock(mb_pos) then
		-- return fast
		return
	end

	local cache_key = minetest.pos_to_string(mb_pos)
	local cache_entry = self.cache[cache_key]
	if not cache_entry then
		-- load and parse
		local manifest, mapblock, err = read_manifest_mapblock(self.filename, mb_pos)
		if err then
			return nil, err
		end

		local nodeid_name_mapping = {}
		for name, id in pairs(manifest.node_mapping) do
			nodeid_name_mapping[id] = name
		end

		cache_entry = {
			nodeid_name_mapping = nodeid_name_mapping,
			manifest = manifest,
			mapblock = mapblock
		}
		self.cache[cache_key] = cache_entry
	end

	-- fetch relative node data
	local mb_min_pos = mapblock_lib.get_mapblock_bounds_from_mapblock(mb_pos)
	local rel_pos = vector.subtract(pos, mb_min_pos)
	local index = mapblock_area:indexp(rel_pos)

	local nodeid = cache_entry.mapblock.node_ids[index]

	return {
		param1 = cache_entry.mapblock.param1[index],
		param2 = cache_entry.mapblock.param2[index],
		name = cache_entry.nodeid_name_mapping[nodeid]
	}
end

------
-- Deserialize options
-- @number delay for async mode: delay between deserialization-calls
-- @number rotate_y the y rotation, can be 0,90,180 or 270 degrees
-- @field progress_callback function to call when the progress is update
-- @field mapblock_options function that returns the deserialization options when called with a mapblock_pos as param
-- @table deserialize_all_options

--- Deserialize all mapblocks in the catalog to the world
-- @see deserialize_options.lua
-- @param target_mapblock_pos @{util.mapblock_pos} the first mapblock position
-- @param options[opt] @{deserialize_all_options} deserialization options
-- @return a promise that resolves with the total mapblock count
function Catalog:deserialize_all(target_mapblock_pos, options)
	local f = io.open(self.filename, "rb")
	local z, err = mtzip.unzip(f)
	if err then
		return false, err
	end

	local pos1 = target_mapblock_pos
	local pos2 = vector.add(pos1, self.manifest.range)
	local total_count = mapblock_lib.count_mapblocks(pos1, pos2)
	local count = 0

	options = options or {}
	options.delay = options.delay or 0.1
	options.rotate_y = options.rotate_y or 0
	options.progress_callback = options.progress_callback or function() end
	options.mapblock_options = options.mapblock_options or function() end

	return Promise.async(function(await)
		for mapblock_pos in mapblock_lib.pos_iterator(pos1, pos2) do
			local rel_pos = vector.subtract(mapblock_pos, pos1)
			rel_pos = mapblock_lib.rotate_pos(rel_pos, self.manifest.range, options.rotate_y)
			local mapblock_entry_name = "mapblock_" .. minetest.pos_to_string(rel_pos) .. ".bin"
			local manifest_entry_name = "mapblock_" .. minetest.pos_to_string(rel_pos) .. ".meta.json"

			local mb_manifest = z:get(manifest_entry_name)
			if mb_manifest then
				local manifest = minetest.parse_json(mb_manifest)
				local mapblock = mapblock_lib.read_mapblock(z:get(mapblock_entry_name))
				local mapblock_options = options.mapblock_options(mapblock_pos)
				if options.rotate_y then
					-- apply mapblock rotation to mapblock-nodes
					mapblock_options = mapblock_options or {}
					mapblock_options.transform = mapblock_options.transform or {}
					mapblock_options.transform.rotate = mapblock_options.transform.rotate or {}
					mapblock_options.transform.rotate.axis = "y"
					mapblock_options.transform.rotate.angle = options.rotate_y
				end
				local _, deser_err = mapblock_lib.deserialize_mapblock(mapblock_pos, mapblock, manifest, mapblock_options)
				if deser_err then
					error(deser_err, 0)
					return
				end
			end

			count = count + 1
			options.progress_callback(count / total_count)
			await(Promise.after(options.delay))
		end

		f:close()
		return count
	end)
end

--- create a new catalog wrapper for the given filename
-- @param filename the file to read from
-- @return @{Catalog} the catalog object
function mapblock_lib.get_catalog(filename)
	local f = io.open(filename, "rb")
	if not f then
		return nil, "file is nil: '" .. filename .. "'"
	end
	local z, err = mtzip.unzip(f)
	if err then
		f:close()
		return nil, err
	end

	local manifest = minetest.parse_json(z:get("manifest.json"))
	f:close()
	if not manifest then
		return false, "no manifest found!"
	end

	local self = {
		filename = filename,
		manifest = manifest,
		-- for lookups only
		zip = z,
		-- cached mapblocks for get_node()
		cache = {}
	}
	return setmetatable(self, Catalog_mt)
end
