---------
-- mapblock deserialization

local air_content_id = minetest.get_content_id("air")
local placeholder_content_id = nil

local has_placeholder_mod = minetest.get_modpath("placeholder")
if has_placeholder_mod then
	placeholder_content_id = minetest.get_content_id("placeholder:placeholder")
end

-- local nodename->id cache
local local_nodename_to_id_mapping = {} -- name -> id

-- unknown id sequence
local next_unknown_id = -1

-- mapblock area for index -> pos calculations
local mapblock_area = VoxelArea:new({MinEdge={x=0,y=0,z=0}, MaxEdge={x=15,y=15,z=15}})

local function get_nodeid(node_name)
	local local_node_id = local_nodename_to_id_mapping[node_name]
	local is_known = true

	if not local_node_id then
		if minetest.registered_nodes[node_name] then
			-- node is locally available
			local_node_id = minetest.get_content_id(node_name)

		elseif has_placeholder_mod then
			-- assign negative id for placeholder
			local_node_id = next_unknown_id
			next_unknown_id = next_unknown_id - 1
			is_known = false

		else
			-- node is not available here
			local_node_id = air_content_id
			is_known = false
		end
		local_nodename_to_id_mapping[node_name] = local_node_id
	end

	if local_node_id < 0 then
		-- mark as not known
		is_known = false
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
			node_mapping[node_name] = node_ids[i]
			table.insert(unknown_nodes, node_name)
		end
	end

	return all_nodes_known, unknown_nodes
end

function mapblock_lib.place_placeholders(mapblock, manifest, unknown_nodes)
	-- lookup table
	-- id -> name
	local unknown_node_ids = {}
	for _, unknown_node_name in ipairs(unknown_nodes) do
		local unknown_node_id = manifest.node_mapping[unknown_node_name]
		unknown_node_ids[unknown_node_id] = unknown_node_name
	end

	for i, node_id in ipairs(mapblock.node_ids) do
		if unknown_node_ids[node_id] then
			-- set placeholder
			-- node-def
			local node = {
				name = unknown_node_ids[node_id],
				param1 = mapblock.param1[i],
				param2 = mapblock.param2[i]
			}

			-- get metadata if available
			local rel_pos = mapblock_area:position(i)
			local rel_pos_str = minetest.pos_to_string(rel_pos)
			local metadata = manifest.metadata and manifest.metadata.meta and manifest.metadata.meta[rel_pos_str] or {
				fields = {},
				inventory = {}
			}

			local _, placeholder_metadata = placeholder.create(node, metadata)

			-- replace in-memory
			mapblock.node_ids[i] = placeholder_content_id
			manifest.metadata.meta[rel_pos_str] = placeholder_metadata
		end
	end
end

function mapblock_lib.deserialize_part(pos1, pos2, data, metadata, options)
	-- check if we have the same region (mapblock-aligned)
	local same_region = mapblock_lib.is_mapblock_aligned(pos1, pos2)
	local manip = minetest.get_voxel_manip(pos1, pos2)
	local e1, e2, node_data

	-- overwrite flag
	local replace = options.mode ~= "add"
	if replace and same_region then
		-- replace node data 1:1
		manip:set_data(data.node_ids)
		manip:set_light_data(data.param1)
		manip:set_param2_data(data.param2)
		-- set edges
		e1 = pos1
		e2 = pos2
		-- set content-ids for later
		node_data = data.node_ids
	else
		-- overwrite with air check one by one
		e1, e2 = manip:read_from_map(pos1, pos2)
		local area = VoxelArea:new({MinEdge=e1, MaxEdge=e2})

		node_data = manip:get_data()
		local param1 = manip:get_light_data()
		local param2 = manip:get_param2_data()

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

		manip:set_data(node_data)
		manip:set_light_data(param1)
		manip:set_param2_data(param2)
	end

	manip:write_to_map()

	-- deserialize metadata
	if metadata and metadata.meta then
		local area = VoxelArea:new({MinEdge=e1, MaxEdge=e2})
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

------
-- Rotate options
-- @field @number angle the angle to rotate, can be 0,90,180 or 270
-- @field @string axis the axis to rotate, can be "x","y" or "z" **NOTE**: orientation only works with the y-rotation
-- @field disable_orientation map of nodename to bool/true of nodenames that shouldn't get oriented
-- @table rotate_options

------
-- Transformation options
-- @field replace map of nodename to replacement-nodename for node-replacements on place
-- @field rotate[opt] @{rotate_options} optional rotation options
-- @field set_param2[opt] map of nodename to param2-value to bulk-set param2 values
-- @table transform_options

------
-- Deserialize options
-- @see deserialize_options.lua
-- @field on_metadata[opt] metadata callback, can be used to intercept and modify node-metadata/inventory
--  `function(pos, content_id, meta)`
-- @field transform[opt] @{transform_options} transformation options
-- @string mode[opt] placement mode "replace": replace the whole mapblock, "add": replace only air nodes
-- @table deserialize_options


--- deserialize a mapblock from a file
-- @see deserialize_options.lua
-- @param mapblock_pos the mapblock position
-- @param filename the file to read from
-- @param options[opt] @{deserialize_options} the options to apply to the mapblock
-- @return success true on success
-- @return error in case of an error
function mapblock_lib.deserialize_mapblock(mapblock_pos, mapblock, manifest, options)
	local min, max = mapblock_lib.get_mapblock_bounds_from_mapblock(mapblock_pos)

	options = options or {}
	options.transform = options.transform or {}

	if manifest.air_only then
		-- set air
		mapblock_lib.clear_mapblock(mapblock_pos)
		return true
	end

	if not mapblock then
		return false, "mapblock data not found"
	end

	if options.transform.replace then
		-- replace node-ids before localizing them
		mapblock_lib.replace(options.transform.replace, manifest.node_mapping, mapblock)
	end

	-- localize node-ids and set placeholders if available
	if not mapblock.node_ids_localized then
		local all_nodes_known, unknown_nodes = mapblock_lib.localize_nodeids(manifest.node_mapping, mapblock.node_ids)

		if has_placeholder_mod and not all_nodes_known then
			-- set placeholders
			mapblock_lib.place_placeholders(mapblock, manifest, unknown_nodes)
		end

		mapblock.node_ids_localized = true
	end


	-- apply transformation
	local size = {x=15, y=15, z=15}
	mapblock_lib.transform(options.transform, size, mapblock, manifest.metadata)

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
end