---------
-- utilities and helpers

------
-- Mapblock position
-- @number x mapblock x-position
-- @number y mapblock y-position
-- @number z mapblock z-position
-- @table mapblock_pos

------
-- Node position
-- @number x node x-position
-- @number y node y-position
-- @number z node z-position
-- @table node_pos

--- returns the mapblock-center of the given coordinates
-- @param pos @{node_pos} the node-position
-- @return @{node_pos} the node-position of the current mapblock-center with fractions
function mapblock_lib.get_mapblock_center(pos)
	local mapblock = vector.floor( vector.divide(pos, 16))
	return vector.add(vector.multiply(mapblock, 16), 7.5)
end

--- returns the mapblock position for the node-position
-- @param pos @{node_pos} the node-position
-- @return @{mapblock_pos} the mapblock-position
function mapblock_lib.get_mapblock(pos)
	return vector.floor( vector.divide(pos, 16))
end

--- returns true if the two positions align to a single mapblock's edges
-- @param pos1 @{node_pos} the first node-position
-- @param pos2 @{node_pos} the second node-position
function mapblock_lib.is_mapblock_aligned(pos1, pos2)
	pos1, pos2 = mapblock_lib.sort_pos(pos1, pos2)
	local mapblock_pos1 = mapblock_lib.get_mapblock(pos1)
	local mapblock_pos2 = mapblock_lib.get_mapblock(pos2)
	if not vector.equals(mapblock_pos1, mapblock_pos2) then
		-- not even in the same mapblock
		return false
	end
	local min, max = mapblock_lib.get_mapblock_bounds_from_mapblock(mapblock_pos1)
	return vector.equals(min, pos1) and vector.equals(max, pos2)
end

--- returns the max/min bounds for the mapblock-position
-- @param block_pos @{mapblock_pos} the mapblock-position
-- @return @{node_pos} the min-node-position
-- @return @{node_pos} the max-node-position
function mapblock_lib.get_mapblock_bounds_from_mapblock(block_pos)
	local min = vector.multiply(block_pos, 16)
	local max = vector.add(min, 15)
	return min, max
end

--- returns the max/min bounds for the node-position
-- @param pos @{node_pos} the node-position
-- @return @{node_pos} the min-node-position
-- @return @{node_pos} the max-node-position
function mapblock_lib.get_mapblock_bounds(pos)
	local mapblock = vector.floor( vector.divide(pos, 16))
	return mapblock_lib.get_mapblock_bounds_from_mapblock(mapblock)
end

--- sorts the position by ascending order
-- @param pos1 @{node_pos} the first position
-- @param pos2 @{node_pos} the second position
-- @return @{node_pos} the lower position
-- @return @{node_pos} the upper position
function mapblock_lib.sort_pos(pos1, pos2)
	pos1 = {x=pos1.x, y=pos1.y, z=pos1.z}
	pos2 = {x=pos2.x, y=pos2.y, z=pos2.z}
	if pos1.x > pos2.x then
		pos2.x, pos1.x = pos1.x, pos2.x
	end
	if pos1.y > pos2.y then
		pos2.y, pos1.y = pos1.y, pos2.y
	end
	if pos1.z > pos2.z then
		pos2.z, pos1.z = pos1.z, pos2.z
	end
	return pos1, pos2
end

--- returns the total mapblock count in the given range
-- @param pos1 @{mapblock_pos} the lower position
-- @param pos2 @{mapblock_pos} the upper position
-- @return the mapblock count
function mapblock_lib.count_mapblocks(pos1, pos2)
	return ((pos2.x - pos1.x) + 1) * ((pos2.y - pos1.y) + 1) * ((pos2.z - pos1.z) + 1)
end

--- returns an iterator function for the mapblock coordinate range
-- @param pos1 @{mapblock_pos} the lower position
-- @param pos2 @{mapblock_pos} the upper position
-- @return a position iterator
-- @return the total node/mapblock count
function mapblock_lib.pos_iterator(pos1, pos2)
	local pos
	return function()
		if not pos then
			-- init, copy values
			pos = { x=pos1.x, y=pos1.y, z=pos1.z }
		else
			-- shift x
			pos.x = pos.x + 1
			if pos.x > pos2.x then
				-- shift z
				pos.x = pos1.x
				pos.z = pos.z + 1
				if pos.z > pos2.z then
					--shift y
					pos.z = pos1.z
					pos.y = pos.y + 1
					if pos.y > pos2.y then
						-- done
						pos = nil
					end
				end
			end
		end

		return pos
	end
end

-- pre-generate air-only mapblock
local air_content_id = minetest.get_content_id("air")
local air_mapblock_nodeids = {}
local air_mapblock_param1 = {}
local air_mapblock_param2 = {}
for i=1,4096 do
	air_mapblock_nodeids[i] = air_content_id
	air_mapblock_param1[i] = minetest.LIGHT_MAX
	air_mapblock_param2[i] = 0
end

--- clears a mapblock (fills it with air)
-- @param mapblock_pos the mapblock position
function mapblock_lib.clear_mapblock(mapblock_pos)
	local min, max = mapblock_lib.get_mapblock_bounds_from_mapblock(mapblock_pos)
	local manip = minetest.get_voxel_manip()
	manip:read_from_map(min, max)

	manip:set_data(air_mapblock_nodeids)
	manip:set_light_data(air_mapblock_param1)
	manip:set_param2_data(air_mapblock_param2)
	manip:write_to_map()

	if minetest.get_objects_in_area then
		-- remove entities
		local objects = minetest.get_objects_in_area(min, max)
		for _, obj in pairs(objects) do
			if not obj:is_player() then
				obj:remove()
			end
		end
	end
end

function mapblock_lib.flip_pos(rel_pos, max, axis)
	rel_pos[axis] = max[axis] - rel_pos[axis]
end

function mapblock_lib.transpose_pos(rel_pos, axis1, axis2)
	rel_pos[axis1], rel_pos[axis2] = rel_pos[axis2], rel_pos[axis1]
end

--- rotate a position around the y axis
-- @param rel_pos @{node_pos} the relative position to rotate
-- @param max @{node_pos} the maximum position to rotate in
-- @param rotation_y the clock-wise rotation, either 0,90,180 or 270
-- @return @{node_pos} the rotated position
function mapblock_lib.rotate_pos(rel_pos, max_pos, rotation_y)
	local new_pos = {x=rel_pos.x, y=rel_pos.y, z=rel_pos.z}
	if rotation_y == 90 then
		mapblock_lib.flip_pos(new_pos, max_pos, "x")
		mapblock_lib.transpose_pos(new_pos, "x", "z")
	elseif rotation_y == 180 then
		mapblock_lib.flip_pos(new_pos, max_pos, "x")
		mapblock_lib.flip_pos(new_pos, max_pos, "z")
	elseif rotation_y == 270 then
		mapblock_lib.flip_pos(new_pos, max_pos, "z")
		mapblock_lib.transpose_pos(new_pos, "x", "z")
	end
	return new_pos
end

--- rotate a size vector
-- @param size @{node_pos} a size vector
-- @param rotation_y the clock-wise rotation, either 0,90,180 or 270
-- @return @{node_pos} the rotated size
function mapblock_lib.rotate_size(size, rotation_y)
	local new_size = {x=size.x, y=size.y, z=size.z}
	if rotation_y == 90 or rotation_y == 270 then
		-- swap x and z axes
		mapblock_lib.transpose_pos(new_size, "x", "z")
	end
	return new_size
end

function mapblock_lib.compare_mapblock(mb1, mb2, strict)
	for i=1,4096 do
		if mb1.node_ids[i] ~= mb2.node_ids[i] then
			return false, "node-id mismatch at index " .. i ..
				" mb1=" .. mb1.node_ids[i] .. "(" .. minetest.get_name_from_content_id(mb1.node_ids[i]) .. ")" ..
				" mb2=" .. mb2.node_ids[i] .. "(" .. minetest.get_name_from_content_id(mb2.node_ids[i]) .. ")"
		elseif strict and mb1.param1[i] ~= mb2.param1[i] then
			return false, "param1 mismatch at index " .. i
		elseif mb1.param2[i] ~= mb2.param2[i] then
			return false, "param2 mismatch at index " .. i
		end
	end
	return true
end