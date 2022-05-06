---------
-- Legacy, file-based deserialization functions

local function read_file(filename)
    local f = io.open(filename, "rb")
    if not f then
        return nil, "file not found: '" .. filename .. "'"
    end
    local content = f:read("*all")
    f:close()
    return content
end

--- Deserialize a single mapblock from the catalog
-- @see deserialize_options.lua
-- @param mapblock_pos @{util.mapblock_pos} the mapblock position in the world
-- @param prefix the filename prefix for the mapblock files
-- @param options @{deserialize_mapblock.deserialize_options} mapblock deserialization options
-- @return success true on success
-- @return error in case of an error
function mapblock_lib.deserialize(mapblock_pos, prefix, options)
    local mapblock_filename = prefix .. ".bin"
    local manifest_filename = prefix .. ".manifest.json"

    local manifest_data, err = read_file(manifest_filename)
    if err then
        return false, err
    end

    local manifest, mapblock
    manifest, err = minetest.parse_json(manifest_data)
    if err then
        return false, err
    end
    mapblock, err = mapblock_lib.read_mapblock(minetest.decompress(read_file(mapblock_filename), "deflate"))
    if err then
        return false, err
    end

    return mapblock_lib.deserialize_mapblock(mapblock_pos, mapblock, manifest, options)
end