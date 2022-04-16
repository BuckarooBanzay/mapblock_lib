---------
-- singleblock mapgen helper

--- creates a new mapgen-function that generates a single mapblock,
--- the resulting function can be passed to `minetest.register_on_generated`
-- @see singleblock_mapgen.lua
-- @param cfg configuration table
-- @param cfg.filename the filename of the mapblock to use
-- @param cfg.filter an optional filter function of the type `fn(blockpos)`, returning true means the mapblock is placed
-- @param cfg.options optional table for `mapblock_lib.deserialize`
-- @return the on_generated function or nil on error
-- @return the error or nil
function mapblock_lib.mapgens.singleblock(cfg)
	cfg.filter = cfg.filter or function() return true end
	cfg.options = cfg.options or {}
	assert(cfg.filename, "missing schema filename")

	local catalog, err = mapblock_lib.get_catalog(cfg.filename)
	if err then
		return nil, err
	end

	local deserFn
	deserFn, err = catalog:prepare({x=0,y=0,z=0})
	if err then
		return nil, err
	end

	return function(minp, maxp)
		local min_block = mapblock_lib.get_mapblock(minp)
		local max_block = mapblock_lib.get_mapblock(maxp)

		for x=min_block.x, max_block.x do
			for y=min_block.y, max_block.y do
				for z=min_block.z, max_block.z do
					local mapblock_pos = {x=x, y=y, z=z}
					local do_place = cfg.filter(mapblock_pos)
					if do_place then
						deserFn(mapblock_pos)
					end
				end
			end
		end
	end
end