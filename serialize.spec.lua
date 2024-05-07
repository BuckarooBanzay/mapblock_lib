local filename = minetest.get_worldpath() .. "/mapblocks/test.zip"

mtt.register("prepare and deserialize a mapblock", function(callback)
	local c, err = mapblock_lib.get_catalog(filename)
	assert(err == nil, "err is nil")

	local target_pos = {x=5,y=5,z=5}
	local catalog_pos = {x=0,y=0,z=0}
	local fn
	fn, err = c:prepare(catalog_pos)
	assert(fn, err)
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

mtt.benchmark("serialize mapblock", function(callback, iterations)
	local world_pos = {x=0,y=0,z=0}

	for _=1,iterations do
		local mb1 = mapblock_lib.serialize_mapblock(world_pos)
		assert(mb1)
	end

	callback()
end)

mtt.benchmark("deserialize mapblock", function(callback, iterations)
	local c, err = mapblock_lib.get_catalog(filename)
	assert(not err)

	local world_pos = {x=0,y=0,z=0}
	local catalog_pos = {x=0,y=0,z=0}

	for _=1,iterations do
		c:deserialize(catalog_pos, world_pos)
	end

	callback()
end)

mtt.benchmark("deserialize prepared mapblock", function(callback, iterations)
	local c, err = mapblock_lib.get_catalog(filename)
	assert(not err)

	local world_pos = {x=0,y=0,z=0}
	local catalog_pos = {x=0,y=0,z=0}

	local mb = c:prepare(catalog_pos)

	for _=1,iterations do
		mb(world_pos)
	end

	callback()
end)