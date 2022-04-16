
local function int_to_bytes(i)
	local x =i + 32768
	local h = math.floor(x/256) % 256;
	local l = math.floor(x % 256);
	return(string.char(h, l));
end

-- converts a mapblock object to a string
function mapblock_lib.write_mapblock(mapblock)
	local data = ""
	for i=1,4096 do
		data = data .. int_to_bytes(mapblock.node_ids[i])
	end
	for i=1,4096 do
		data = data .. string.char(mapblock.param1[i])
	end
	for i=1,4096 do
		data = data .. string.char(mapblock.param2[i])
	end

	return data
end

function mapblock_lib.write_mapblock_manifest(mapblock)
	local manifest = {
		node_mapping = mapblock.node_mapping,
		metadata = mapblock.metadata
	}
	return minetest.write_json(manifest)
end

-- creates a mapblock object from a data string
function mapblock_lib.read_mapblock(data)
	if not data then
		return nil, "mapblock data is empty"
	elseif #data ~= 16384 then
		return nil, "unexpected mapblock size"
	end

	local mapblock = {
		node_ids = {},
		param1 = {},
		param2 = {}
	}

	for i=1,4096 do
		-- 1, 3, 5 ... 8191
		local node_id_offset = (i * 2) - 1
		local node_id = (string.byte(data, node_id_offset) * 256) +
		string.byte(data, node_id_offset+1) - 32768

		local param1 = string.byte(data, (4096 * 2) + i)
		local param2 = string.byte(data, (4096 * 3) + i)

		table.insert(mapblock.node_ids, node_id)
		table.insert(mapblock.param1, param1)
		table.insert(mapblock.param2, param2)
	end
	return mapblock
end
