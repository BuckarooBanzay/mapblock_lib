---------
-- singleblock mapgen helper

--- creates a new mapgen-function that generates a single mapblock,
--- the resulting function can be passed to `minetest.register_on_generated`
-- @see singleblock_mapgen.lua
-- @param cfg configuration table
-- @param cfg.filename the filename of the mapblock to use
-- @param cfg.filter an optional filter function of the type `fn(blockpos)`, returning true means the mapblock is placed
-- @param cfg.options optional table for `mapblock_lib.deserialize`
function mapblock_lib.mapgens.singleblock(cfg)
    cfg.filter = cfg.filter or function() return true end
    cfg.options = cfg.options or { use_cache = true }
    assert(cfg.filename, "missing schema filename")

    return function(minp, maxp)
        local min_block = mapblock_lib.get_mapblock(minp)
        local max_block = mapblock_lib.get_mapblock(maxp)

        for x=min_block.x, max_block.x do
            for y=min_block.y, max_block.y do
                for z=min_block.z, max_block.z do
                    local mapblock_pos = {x=x, y=y, z=z}
                    local do_place = cfg.filter(mapblock_pos)
                    if do_place then
                        mapblock_lib.deserialize_mapblock(mapblock_pos, cfg.filename, cfg.options)
                    end
                end
            end
        end
    end
end