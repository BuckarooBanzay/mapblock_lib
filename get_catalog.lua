
local Catalog = {}
local Catalog_mt = { __index = Catalog }

function mapblock_lib.get_catalog(filename)
    local f = io.open(filename)
	local z, err = mtzip.unzip(f)
    if err then
        f:close()
        return nil, err
    end

    local manifest = minetest.parse_json(z:get("manifest.json"))
    f:close()
	if not manifest then
		return false, "no manifest found!"
	end

    local self = {
        filename = filename,
        manifest = manifest
    }
    return setmetatable(self, Catalog_mt)
end

function Catalog:get_size()
    return vector.add(self.manifest.range, 1)
end

function Catalog:deserialize(rel_mapblock_pos, target_mapblock_pos, options)
    local f = io.open(self.filename)
	local z, err = mtzip.unzip(f)
    if err then
        f:close()
        return nil, err
    end

    local mapblock_data = z:get("mapblock_" .. minetest.pos_to_string(rel_mapblock_pos) .. ".bin")
    local manifest_data = z:get("mapblock_" .. minetest.pos_to_string(rel_mapblock_pos) .. ".meta.json")
    local mapblock = mapblock_lib.read_mapblock(mapblock_data)
    local manifest = minetest.parse_json(manifest_data)



    f:close()
end

function Catalog:deserialize_all(target_mapblock_pos)
end