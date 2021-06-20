---------
-- serialized mapblock validation utilities

--- validate a single mapblock file
-- @param filename the filename of the mapblock
-- @return success
-- @return error-message if success is false
function mapblock_lib.validate(filename)
    local mapblock = mapblock_lib.read_mapblock(filename .. ".bin")
    if not mapblock then
        return false, "mapblock data not found: " .. filename .. ".bin"
    end

    if #mapblock.node_ids ~= 4096 then
        return false, "node_id data has unexpected size: " .. #mapblock.node_ids
    end

    local manifest = mapblock_lib.read_manifest(filename .. ".manifest.json")
    if not manifest then
        return false, "manifest not found: " .. filename .. ".manifest.json"
    end

    if not manifest.node_mapping then
        return false, "node_mapping not found"
    end

    local all_nodes_known, unknown_nodes = mapblock_lib.localize_nodeids(manifest.node_mapping, mapblock.node_ids)
    if not all_nodes_known then
        return false, "nodes not registered: " .. dump(unknown_nodes)
    end

    return true
end

--- validate a multi-mapblock export
-- @param prefix the prefix of the files
-- @return success
-- @return error-message if success is false
function mapblock_lib.validate_multi(prefix)
    local manifest = mapblock_lib.read_manifest(prefix .. ".manifest")
	if not manifest then
		return false, "no multi-manifest found!"
	end

    local pos1 = {x=0, y=0, z=0}
    local pos2 = vector.add(pos1, manifest.range)
    local iterator = mapblock_lib.pos_iterator(pos1, pos2)

    local mapblock_pos = iterator()
    while mapblock_pos ~= nil do
        local rel_pos = vector.subtract(mapblock_pos, pos1)
        local filename = mapblock_lib.format_multi_mapblock(prefix, rel_pos)

        local success, msg = mapblock_lib.validate(filename)
        if not success then
            return false, minetest.pos_to_string(rel_pos) .. ": " .. msg
        end

        -- shift
        mapblock_pos = iterator()
    end

    return true
end