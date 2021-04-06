
function mapblock_lib.get_mapblock_center(pos)
	local mapblock = vector.floor( vector.divide(pos, 16))
	return vector.add(vector.multiply(mapblock, 16), 7.5)
end

function mapblock_lib.get_mapblock(pos)
	return vector.floor( vector.divide(pos, 16))
end

function mapblock_lib.get_mapblock_bounds_from_mapblock(block_pos)
	local min = vector.multiply(block_pos, 16)
	local max = vector.add(min, 15)
	return min, max
end

function mapblock_lib.get_mapblock_bounds(pos)
	local mapblock = vector.floor( vector.divide(pos, 16))
	return mapblock_lib.get_mapblock_bounds_from_mapblock(mapblock)
end

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

-- returns an iterator function for the mapblock coordinate range
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

function mapblock_lib.format_multi_mapblock(prefix, pos)
	return prefix .. "_" .. minetest.pos_to_string(pos)
end