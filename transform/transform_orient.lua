local node_id_to_name_cache = {}

local wallmounted = {
	[90]  = {0, 1, 5, 4, 2, 3, 0, 0},
	[180] = {0, 1, 3, 2, 5, 4, 0, 0},
	[270] = {0, 1, 4, 5, 3, 2, 0, 0}
}
local facedir = {
	[90]  = { 1,  2,  3,  0, 13, 14, 15, 12, 17, 18, 19, 16,
	9, 10, 11,  8,  5,  6,  7,  4, 23, 20, 21, 22},
	[180] = { 2,  3,  0,  1, 10, 11,  8,  9,  6,  7,  4,  5,
	18, 19, 16, 17, 14, 15, 12, 13, 22, 23, 20, 21},
	[270] = { 3,  0,  1,  2, 19, 16, 17, 18, 15, 12, 13, 14,
	7,  4,  5,  6, 11,  8,  9, 10, 21, 22, 23, 20}
}

--- Applies a rotation around the y-axis to the given param2 value
-- @param node_name the node-name
-- @param param2 the existing param2
-- @param angle the angle, can be 0,90,180 or 270
-- @return the rotated param2 value
function mapblock_lib.rotate_param2(node_name, param2, angle)
	local def = minetest.registered_nodes[node_name]

	if def then
		local wallmounted_substitution = wallmounted[angle]
		local facedir_substitution = facedir[angle]

		local paramtype2 = def.paramtype2
		if paramtype2 == "wallmounted" or paramtype2 == "colorwallmounted" then
			local orient = param2 % 8
			return param2 - orient + wallmounted_substitution[orient + 1]

		elseif paramtype2 == "facedir" or paramtype2 == "colorfacedir" then
			local orient = param2 % 32
			return param2 - orient + facedir_substitution[orient + 1]

		end
	end

end

local min = { x=0, y=0, z=0 }

function mapblock_lib.orient(angle, max, mapblock, disable_orientation)
	-- https://github.com/Uberi/Minetest-WorldEdit/blob/master/worldedit/manipulations.lua#L555
	local area = VoxelArea:new({MinEdge=min, MaxEdge=max})

	local pos = {x=0, y=0, z=0}
	while pos.x <= max.x do
		pos.y = 0
		while pos.y <= max.y do
			pos.z = 0
			while pos.z <= max.z do
				local index = area:indexp(pos)

				local param2 = mapblock.param2[index]
				local node_id = mapblock.node_ids[index]
				local node_name = node_id_to_name_cache[node_id]
				if not node_name then
					-- cache association
					node_name = minetest.get_name_from_content_id(node_id)
					node_id_to_name_cache[node_id] = node_name
				end

				if not disable_orientation[node_name] then
					-- rotate only the non-disabled nodes
					param2 = mapblock_lib.rotate_param2(node_name, param2, angle)
					mapblock.param2[index] = param2
				end
				pos.z = pos.z + 1
			end
			pos.y = pos.y + 1
		end
		pos.x = pos.x + 1
	end
end
