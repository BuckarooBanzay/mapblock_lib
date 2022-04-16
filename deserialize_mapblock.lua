---------
-- mapblock deserialization

local air_content_id = minetest.get_content_id("air")

-- local nodename->id cache
local local_nodename_to_id_mapping = {} -- name -> id

local function get_nodeid(node_name)
	local local_node_id = local_nodename_to_id_mapping[node_name]
	local is_known = true

	if not local_node_id then
		if minetest.registered_nodes[node_name] then
			-- node is locally available
			local_node_id = minetest.get_content_id(node_name)
		else
			-- node is not available here
			local_node_id = air_content_id
			is_known = false
		end
		local_nodename_to_id_mapping[node_name] = local_node_id
	end

	return local_node_id, is_known
end

-- map foreign node-ids to local node-ids
function mapblock_lib.localize_nodeids(node_mapping, node_ids)
	local foreign_nodeid_to_name_mapping = {} -- id -> name
	for k, v in pairs(node_mapping) do
		foreign_nodeid_to_name_mapping[v] = k
	end

	local all_nodes_known = true
	local unknown_nodes = {}

	for i, node_id in ipairs(node_ids) do
		local node_name = foreign_nodeid_to_name_mapping[node_id]
		local is_known
		node_ids[i], is_known = get_nodeid(node_name)
		if not is_known then
			all_nodes_known = false
			table.insert(unknown_nodes, node_name)
		end
	end

	return all_nodes_known, unknown_nodes
end

function mapblock_lib.deserialize_part(pos1, pos2, data, metadata, options)
	local manip = minetest.get_voxel_manip()
	local e1, e2 = manip:read_from_map(pos1, pos2)
	local area = VoxelArea:new({MinEdge=e1, MaxEdge=e2})

	local node_data = manip:get_data()
	local param1 = manip:get_light_data()
	local param2 = manip:get_param2_data()

	-- check if we have the same region (mapblock-aligned)
	local same_region = vector.equals(e1, pos1) and vector.equals(e2, pos2)

	-- overwrite flag
	local replace = options.mode ~= "add"
	if replace and same_region then
		-- replace node data 1:1
		node_data = data.node_ids
		param1 = data.param1
		param2 = data.param2
	else
		-- overwrite with air check one by one
		local j = 1
		for z=pos1.z,pos2.z do
			for y=pos1.y,pos2.y do
				for x=pos1.x,pos2.x do
					local i = area:index(x,y,z)
					if node_data[i] == air_content_id then
						node_data[i] = data.node_ids[j]
						param1[i] = data.param1[j]
						param2[i] = data.param2[j]
					end
					j = j + 1
				end
			end
		end
	end

	manip:set_data(node_data)
	manip:set_light_data(param1)
	manip:set_param2_data(param2)
	manip:write_to_map()

	-- deserialize metadata
	if metadata and metadata.meta then
		for pos_str, md in pairs(metadata.meta) do
			local relative_pos = minetest.string_to_pos(pos_str)
			local absolute_pos = vector.add(pos1, relative_pos)
			local meta = minetest.get_meta(absolute_pos)
			meta:from_table(md)
			if options.on_metadata then
				-- execute callback
				local i = area:indexp(absolute_pos)
				local content_id = node_data[i]
				options.on_metadata(absolute_pos, content_id, meta)
			end
		end
	end

	-- deserialize node timers
	if data.metadata and data.metadata.timers then
		for pos_str, timer_data in pairs(data.metadata.timers) do
			local relative_pos = minetest.string_to_pos(pos_str)
			local absolute_pos = vector.add(pos1, relative_pos)
			minetest.get_node_timer(absolute_pos):set(timer_data.timeout, timer_data.elapsed)
		end
	end

end

local mapblock_cache = {}
local manifest_cache = {}

------
-- Transformation options
-- @field replace
-- @field rotate
-- @field set_param2
-- @table transform_options

------
-- Deserialize options
-- @see deserialize_options.lua
-- @bool use_cache caches the on-disk file, useful for repetitive mapgen events
-- @field on_metadata metadata callback, can be used to intercept and modify node-metadata/inventory
--  `function(pos, content_id, meta)`
-- @field transform @{transform_options} transformation options
-- @string mode placement mode "replace": replace the whole mapblock, "add": replace only air nodes
-- @table deserialize_options


--- deserialize a mapblock from a file
-- @see deserialize_options.lua
-- @param mapblock_pos the mapblock position
-- @param filename the file to read from
-- @param options[opt] @{deserialize_options} the options to apply to the mapblock
function mapblock_lib.deserialize_mapblock(mapblock_pos, mapblock, manifest, options)
	local min, max = mapblock_lib.get_mapblock_bounds_from_mapblock(mapblock_pos)

	options = options or {}
	options.transform = options.transform or {}
	local cache_key = options.cache_key or ""

	if options.transform.rotate then
		-- add rotation info to cache key if specified
		cache_key = cache_key .. "/" .. options.transform.rotate.axis .. "/" .. options.transform.rotate.angle
	end

	if options.transform.replace then
		-- add nodeids to cache-key
		for k, v in pairs(options.transform.replace) do
			cache_key = cache_key .. "/" .. get_nodeid(k) .. "=" .. get_nodeid(v)
		end
	end

	if options.transform.set_param2 then
		-- add nodeids/param2 to cache-key
		for k, param2 in pairs(options.transform.set_param2) do
			cache_key = cache_key .. "/" .. get_nodeid(k) .. "=" .. param2
		end
	end

	-- true if the mapblock and metadata are read from cache
	-- they are already transformed
	local is_cached = false

	if options.use_cache and mapblock_cache[cache_key] then
		manifest = manifest_cache[cache_key]
		mapblock = mapblock_cache[cache_key]
		is_cached = true
	end

	if manifest.air_only then
		-- set air
		mapblock_lib.clear_mapblock(mapblock_pos)
		return true
	end

	if not mapblock then
		return false, "mapblock data not found"
	end

	if options.use_cache and not is_cached then
		-- populate cache
		mapblock_cache[cache_key] = mapblock
		manifest_cache[cache_key] = manifest
	end

	-- localize node-ids
	if not mapblock.node_ids_localized then
		mapblock_lib.localize_nodeids(manifest.node_mapping, mapblock.node_ids)
		mapblock.node_ids_localized = true
	end

	-- apply transformation only on uncached data
	if not is_cached then
		local size = {x=15, y=15, z=15}
		mapblock_lib.transform(options.transform, size, mapblock, manifest.metadata)
	end

	-- write to map
	mapblock_lib.deserialize_part(min, max, mapblock, manifest.metadata, options)

	return true
end

-- monitoring stuff
if minetest.get_modpath("monitoring") then
	local count = monitoring.counter("mapblock_lib_deserialize_count", "deserialization count")
	mapblock_lib.deserialize_mapblock = count.wrap(mapblock_lib.deserialize)

	local time = monitoring.counter("mapblock_lib_deserialize_time", "deserialization time")
	mapblock_lib.deserialize_mapblock = time.wraptime(mapblock_lib.deserialize)

	-- cache size, periodically updated
	local cache_size = monitoring.gauge("mapblock_lib_deserialize_cache_size", "deserialization cache size")
	local function update_cache_size()
		local entries = 0
		for _ in pairs(mapblock_cache) do
			entries = entries + 1
		end
		cache_size.set(entries)
		minetest.after(10, update_cache_size)
	end

	update_cache_size()
end