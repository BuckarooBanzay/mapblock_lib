local function transpose_data(data, max, indexFn, axis1, axis2)
	-- https://github.com/Uberi/Minetest-WorldEdit/blob/master/worldedit/manipulations.lua#L422
	local pos = {x=0, y=0, z=0}

	while pos.x <= max.x do
		pos.y = 0
		while pos.y <= max.y do
			pos.z = 0
			while pos.z <= max.z do
				local extent1, extent2 = pos[axis1], pos[axis2]
				if extent1 < extent2 then -- Transpose only if below the diagonal
					local data_1 = data[indexFn(pos)]
					local value1, value2 = pos[axis1], pos[axis2] -- Save position values

					pos[axis1], pos[axis2] = extent2, extent1 -- Swap axis extents
					local data_2 = data[indexFn(pos)]
					data[indexFn(pos)] = data_1

					pos[axis1], pos[axis2] = value1, value2 -- Restore position values
					data[indexFn(pos)] = data_2
				end
				pos.z = pos.z + 1
			end
			pos.y = pos.y + 1
		end
		pos.x = pos.x + 1
	end
end

function mapblock_lib.transpose(axis1, axis2, max, mapblock, metadata)
	local min = { x=0, y=0, z=0 }
	local area = VoxelArea:new({MinEdge=min, MaxEdge=max})

	local vmanipIndex = function(pos) return area:indexp(pos) end
	local metaIndex = function(pos) return minetest.pos_to_string(pos) end

	transpose_data(mapblock.node_ids, max, vmanipIndex, axis1, axis2)
	transpose_data(mapblock.param1, max, vmanipIndex, axis1, axis2)
	transpose_data(mapblock.param2, max, vmanipIndex, axis1, axis2)

	if metadata and metadata.meta then
		transpose_data(metadata.meta, max, metaIndex, axis1, axis2)
	end
end
