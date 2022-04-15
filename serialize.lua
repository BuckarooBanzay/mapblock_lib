---------
-- mapblock serialization

local air_content_id = minetest.get_content_id("air")
local ignore_content_id = minetest.get_content_id("ignore")

-- collect node ids with on_timer attributes
local node_ids_with_timer = {}
minetest.register_on_mods_loaded(function()
	for _,node in pairs(minetest.registered_nodes) do
		if node.on_timer then
			local nodeid = minetest.get_content_id(node.name)
			node_ids_with_timer[nodeid] = true
		end
	end
end)

-- checks if a table is empty
local function is_empty(tbl)
	return not tbl or not next(tbl)
end

-- serialize the mapblock at the given mapblock-position
function mapblock_lib.serialize_mapblock(mapblock_pos)
	local manip = minetest.get_voxel_manip()
	local pos1, pos2 = mapblock_lib.get_mapblock_bounds_from_mapblock(mapblock_pos)
	local e1, e2 = manip:read_from_map(pos1, pos2)
	local area = VoxelArea:new({MinEdge=e1, MaxEdge=e2})

	local node_data = manip:get_data()
	local param1 = manip:get_light_data()
	local param2 = manip:get_param2_data()

	local node_id_map = {}

	-- prepare data structure
	local data = {
		air_only = true,
		node_ids = {},
		node_mapping = {},
		param1 = {},
		param2 = {},
		metadata = nil
	}

	local timers = {}

	-- loop over all blocks and fill cid,param1 and param2
	for z=pos1.z,pos2.z do
		for y=pos1.y,pos2.y do
			for x=pos1.x,pos2.x do
				local i = area:index(x,y,z)

				local node_id = node_data[i]
				if node_id == ignore_content_id then
					-- replace ignore blocks with air
					node_id = air_content_id
				end

				if data.air_only and node_id ~= air_content_id then
					-- mapblock contains not jut air
					data.air_only = false
				end

				if node_ids_with_timer[node_id] then
					-- node has a node-timer
					local pos = {x=x, y=y, z=z}
					local timer = minetest.get_node_timer(pos)
					local relative_pos = vector.subtract(pos, pos1)
					if timer:is_started() then
						timers[minetest.pos_to_string(relative_pos)] = {
							timeout = timer:get_timeout(),
							elapsed = math.floor(timer:get_elapsed()) -- truncate decimals
						}
					end
				end

				table.insert(data.node_ids, node_id)
				table.insert(data.param1, param1[i])
				table.insert(data.param2, param2[i])

				node_id_map[node_id] = true
			end
		end
	end

	-- gather node id mapping
	for node_id in pairs(node_id_map) do
		local node_name = minetest.get_name_from_content_id(node_id)
		data.node_mapping[node_name] = node_id
	end

	if not data.air_only then
		-- serialize metadata
		local pos_with_meta = minetest.find_nodes_with_meta(pos1, pos2)
		for _, mpos in ipairs(pos_with_meta) do
			local relative_pos = vector.subtract(mpos, pos1)
			local meta = minetest.get_meta(mpos):to_table()

			-- Convert metadata item stacks to item strings
			for _, invlist in pairs(meta.inventory) do
				for index = 1, #invlist do
					local itemstack = invlist[index]
					if itemstack.to_string then
						invlist[index] = itemstack:to_string()
					end
				end
			end

			-- re-check if metadata actually exists (may happen with minetest.find_nodes_with_meta)
			if not is_empty(meta.fields) or not is_empty(meta.inventory) then
				data.metadata = data.metadata or {}
				data.metadata.meta = data.metadata.meta or {}
				data.metadata.meta[minetest.pos_to_string(relative_pos)] = meta
			end

			if not is_empty(timers) then
				data.metadata = data.metadata or {}
				data.metadata.timers = timers
			end
		end
	end

	return data
end
