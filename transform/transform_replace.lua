function mapblock_lib.replace(replacement_map, mapblock)

	local replacement_id_map = {}

	for key, value in pairs(replacement_map) do
		-- TODO: check minetest.registered_items first
		local key_id = minetest.get_content_id(key)
		local value_id = minetest.get_content_id(value)

		replacement_id_map[key_id] = value_id
	end

	for i, node_id in ipairs(mapblock.node_ids) do
		if replacement_id_map[node_id] ~= nil then
			mapblock.node_ids[i] = replacement_id_map[node_id]
		end
	end
end
