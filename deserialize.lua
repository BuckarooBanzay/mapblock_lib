local air_content_id = minetest.get_content_id("air")

-- local nodename->id cache
local local_nodename_to_id_mapping = {} -- name -> id

local function get_nodeid(node_name)
	local local_node_id = local_nodename_to_id_mapping[node_name]
	if not local_node_id then
		if minetest.registered_nodes[node_name] then
			-- node is locally available
			local_node_id = minetest.get_content_id(node_name)
		else
			-- node is not available here
			local_node_id = air_content_id
		end
		local_nodename_to_id_mapping[node_name] = local_node_id
	end

	return local_node_id
end

-- map foreign node-ids to local node-ids
local function localize_nodeids(node_mapping, node_ids)
	local foreign_nodeid_to_name_mapping = {} -- id -> name
	for k, v in pairs(node_mapping) do
		foreign_nodeid_to_name_mapping[v] = k
	end

	for i, node_id in ipairs(node_ids) do
		local node_name = foreign_nodeid_to_name_mapping[node_id]
		node_ids[i] = get_nodeid(node_name)
	end
end

local function deserialize_part(min, max, data, metadata, options)
	local manip = minetest.get_voxel_manip()
	local e1, e2 = manip:read_from_map(min, max)
	local area = VoxelArea:new({MinEdge=e1, MaxEdge=e2})

	local node_data = manip:get_data()
	local param1 = manip:get_light_data()
	local param2 = manip:get_param2_data()

	-- overwrite flag
	local replace = options.mode ~= "add"
	if replace then
		-- replace node data 1:1
		node_data = data.node_ids
		param1 = data.param1
		param2 = data.param2
	else
		-- overwrite with air check one by one
		local j = 1
		for z=min.z,max.z do
			for y=min.y,max.y do
				for x=min.x,max.x do
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
			local absolute_pos = vector.add(min, relative_pos)
			minetest.get_meta(absolute_pos):from_table(md)
		end
	end
end

local mapblock_cache = {}
local manifest_cache = {}

function mapblock_lib.deserialize(mapblock_pos, filename, options)
	local min, max = mapblock_lib.get_mapblock_bounds_from_mapblock(mapblock_pos)
	local cache_key = filename

	options = options or {}
	options.transform = options.transform or {}

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

	-- true if the mapblock and metadata are read from cache
	-- they are already transformed
	local is_cached = false
	local mapblock, manifest

	if options.use_cache and mapblock_cache[cache_key] then
		mapblock = mapblock_cache[cache_key]
		manifest = manifest_cache[cache_key]
		is_cached = true
	else
		mapblock = mapblock_lib.read_mapblock(filename .. ".bin")
		manifest = mapblock_lib.read_manifest(filename .. ".manifest.json")
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
		localize_nodeids(manifest.node_mapping, mapblock.node_ids)
		mapblock.node_ids_localized = true
	end

	-- apply transformation only on uncached data
	if not is_cached then
		mapblock_lib.transform(options.transform, mapblock, manifest.metadata)
	end

	-- write to map
	deserialize_part(min, max, mapblock, manifest.metadata, options)

	return true
end
