function mapblock_lib.set_param2(node_param2_map, mapblock)

	local replacement_id_map = {}

	for key, value in pairs(node_param2_map) do
		local key_id = minetest.get_content_id(key)
		replacement_id_map[key_id] = value
	end

	for i, node_id in ipairs(mapblock.node_ids) do
		if replacement_id_map[node_id] ~= nil then
			mapblock.param2[i] = replacement_id_map[node_id]
		end
	end
end
