---------
-- Catalog functions

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

-- TODO: Catalog:prepare(catalog_mapblock_pos, options)

--- Deserialize a single mapblock from the catalog
-- @see deserialize_options.lua
-- @param catalog_mapblock_pos @{util.mapblock_pos} the mapblock position in the catalog
-- @param world_mapblock_pos @{util.mapblock_pos} the mapblock position in the world
-- @param options @{deserialize_mapblock.deserialize_options} mapblock deserialization options
function Catalog:deserialize(catalog_mapblock_pos, world_mapblock_pos, options)
    local f = io.open(self.filename)
	local z, err = mtzip.unzip(f)
    if err then
        f:close()
        return nil, err
    end

    local pos_str = minetest.pos_to_string(catalog_mapblock_pos)
    local mapblock_data = z:get("mapblock_" .. pos_str .. ".bin")
    local manifest_data = z:get("mapblock_" .. pos_str .. ".meta.json")
    local mapblock = mapblock_lib.read_mapblock(mapblock_data)
    local manifest = minetest.parse_json(manifest_data)
    f:close()

    options = options or {}
    options.cache_key = self.filename .. "/" .. pos_str
    return mapblock_lib.deserialize_mapblock(world_mapblock_pos, mapblock, manifest, options)
end

------
-- Deserialize options
-- @number delay for async mode: delay between deserialization-calls
-- @number rotate_y the y rotation, can be 0,90,180 or 270 degrees
-- @field callback function to call when the blocks are deserialized
-- @field progress_callback function to call when the progress is update
-- @field error_callback function to call on errors
-- @field mapblock_options function that returns the deserialization options when called with a mapblock_pos as param
-- @table deserialize_all_options

--- Deserialize all mapblocks in the catalog to the world
-- @see deserialize_options.lua
-- @param target_mapblock_pos @{util.mapblock_pos} the first mapblock position
-- @param options[opt] @{deserialize_all_options} deserialization options
function Catalog:deserialize_all(target_mapblock_pos, options)
    local f = io.open(self.filename)
	local z, err = mtzip.unzip(f)
	if err then
		return false, err
	end

    local pos1 = target_mapblock_pos
	local pos2 = vector.add(pos1, self.manifest.range)
	local iterator, total_count = mapblock_lib.pos_iterator(pos1, pos2)
	local mapblock_pos
	local count = 0

	options = options or {}
	options.delay = options.delay or 0.2
	options.callback = options.callback or function() end
	options.progress_callback = options.progress_callback or function() end
	options.error_callback = options.error_callback or function() end
	options.mapblock_options = options.mapblock_options or function() end

	local function rotate_pos(rel_pos)
		if options.rotate_y == 90 then
			mapblock_lib.flip_pos(rel_pos, self.manifest.range, "z")
			mapblock_lib.transpose_pos(rel_pos, "x", "z")
		elseif options.rotate_y == 180 then
			mapblock_lib.flip_pos(rel_pos, self.manifest.range, "x")
			mapblock_lib.flip_pos(rel_pos, self.manifest.range, "z")
		elseif options.rotate_y == 270 then
			mapblock_lib.flip_pos(rel_pos, self.manifest.range, "x")
			mapblock_lib.transpose_pos(rel_pos, "x", "z")
		end
	end

	local start = minetest.get_us_time()

	local worker
	worker = function()
		mapblock_pos = iterator()
		if mapblock_pos then
			local rel_pos = vector.subtract(mapblock_pos, pos1)
			rotate_pos(rel_pos)
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
					options.error_callback(deser_err)
					return
				end
			end

			count = count + 1
			options.progress_callback(count / total_count)
			minetest.after(options.delay, worker)
		else
			-- done
			f:close()
			local micros = minetest.get_us_time() - start
			options.callback(count, micros)
		end
	end

	-- initial call
	worker()
end

--- create a new catalog wrapper for the given filename
-- @param filename the file to read from
-- @return @{Catalog} the catalog object
function mapblock_lib.get_catalog(filename)
    local f = io.open(filename)
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
        manifest = manifest
    }
    return setmetatable(self, Catalog_mt)
end