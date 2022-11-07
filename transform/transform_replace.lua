function mapblock_lib.replace(replacement_map, node_mapping)
	for src, dst in pairs(replacement_map) do
		if node_mapping[src] then
			-- swap node-id
			node_mapping[dst] = node_mapping[src]
			node_mapping[src] = nil
		end
	end
end
