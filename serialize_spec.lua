local filename = minetest.get_worldpath() .. "/mapblocks/test.zip"

mtt.register("prepare and deserialize a mapblock", function(callback)
	local c, err = mapblock_lib.get_catalog(filename)
	assert(err == nil, "err is nil")

	local target_pos = {x=5,y=5,z=5}
	local catalog_pos = {x=0,y=0,z=0}
	local fn = c:prepare(catalog_pos)
	fn(target_pos)

	local mb1 = mapblock_lib.serialize_mapblock(catalog_pos)
	local mb2 = mapblock_lib.serialize_mapblock(target_pos)
	local equal
	equal, err = mapblock_lib.compare_mapblock(mb1, mb2)
	if err then
		error(err)
	end
	assert(equal, "deserialized mapblock is equal to the serialized")
	callback()
end)
