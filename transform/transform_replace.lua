function mapblock_lib.replace(replacement_map, node_mapping, mapblock)
	-- old-id -> new-id
	local nodeid_replacement_map = {}
	local next_id = -1

	for src, dst in pairs(replacement_map) do
		if node_mapping[src] then
			-- swap node-id
			local old_node_id = node_mapping[src]
			local new_id = node_mapping[dst]
			if not new_id then
				-- assign new id
				new_id = next_id
				next_id = next_id - 1
			end

			nodeid_replacement_map[old_node_id] = new_id

			node_mapping[dst] = new_id
			node_mapping[src] = nil
		end
	end
	for i, node_id in ipairs(mapblock.node_ids) do
		if nodeid_replacement_map[node_id] then
			mapblock.node_ids[i] = nodeid_replacement_map[node_id]
		end
	end
end
