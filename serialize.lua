local air_content_id = minetest.get_content_id("air")
local ignore_content_id = minetest.get_content_id("ignore")

-- serialize the mapblock at the given node-position
local function serialize_part(block_pos, node_mapping)
	local pos1, pos2 = mapblock_lib.get_mapblock_bounds_from_mapblock(block_pos)

	local manip = minetest.get_voxel_manip()
	local e1, e2 = manip:read_from_map(pos1, pos2)
	local area = VoxelArea:new({MinEdge=e1, MaxEdge=e2})

	local node_data = manip:get_data()
	local param1 = manip:get_light_data()
	local param2 = manip:get_param2_data()

	local node_id_map = {}

	-- prepare data structure
	local data = {
		node_ids = {},
		param1 = {},
		param2 = {},
		metadata = nil
	}

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
		node_mapping[node_name] = node_id
	end

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

		data.metadata = data.metadata or {}
		data.metadata.meta = data.metadata.meta or {}
		data.metadata.meta[minetest.pos_to_string(relative_pos)] = meta
	end

	return data
end


function mapblock_lib.serialize(block_pos, filename)
	local node_mapping = {}
	local data = serialize_part(block_pos, node_mapping)

	mapblock_lib.write_mapblock(data, filename .. ".bin")

	local manifest = {
		node_mapping = node_mapping,
		metadata = data.metadata,
		version = 2
	}

	mapblock_lib.write_manifest(manifest, filename .. ".manifest.json")
end
