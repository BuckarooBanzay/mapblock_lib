
local pos1 = { x=-32, y=-32, z=-32 }
local pos2 = { x=64, y=32, z=64 }

local mb_pos1 = { x=0, y=0, z=0 }
local mb_pos2 = { x=1, y=1, z=1 }

local filename = minetest.get_worldpath() .. "/mapblocks/test.zip"


-- emerge area
mtt.emerge_area(pos1, pos2)

-- catalog
mtt.register("creating catalog", function(callback)
	mapblock_lib.create_catalog(filename, mb_pos1, mb_pos2, {
		callback = function() callback() end,
		progress_callback = function(p)
			print("progress: " .. p)
		end
	})
end)

mtt.register("reading catalog", function(callback)
	local c, err = mapblock_lib.get_catalog(filename)
	assert(err == nil, "err is nil")
	local size = c:get_size()
	assert(size.x == 2, "x-size match")
	assert(size.y == 2, "y-size match")
	assert(size.z == 2, "z-size match")
	callback()
end)

mtt.register("reading non-existent catalog", function(callback)
	local c, err = mapblock_lib.get_catalog(filename .. "blah")
	assert(c == nil, "catalog is nil")
	assert(err, "err is not nil")
	callback()
end)

mtt.register("deserializing one mapblock from the catalog", function(callback)
	local c, err = mapblock_lib.get_catalog(filename)
	assert(err == nil, "err is nil")

	c:deserialize({x=0,y=0,z=0}, {x=10,y=10,z=10})

	local mb1 = mapblock_lib.serialize_mapblock({x=0,y=0,z=0})
	local mb2 = mapblock_lib.serialize_mapblock({x=10,y=10,z=10})
	local equal
	equal, err = mapblock_lib.compare_mapblock(mb1, mb2)
	if err then
		error(err)
	end
	assert(equal, "deserialized mapblock is equal to the serialized")
	callback()
end)

mtt.register("deserializing all mapblocks from the catalog", function(callback)
	local c, err = mapblock_lib.get_catalog(filename)
	assert(err == nil, "err is nil")

	c:deserialize_all({x=0,y=1,z=2}, {
		callback = function() callback() end,
		progress_callback = function(p)
			print("progress: " .. p)
		end,
		error_callback = error
	})
end)

mtt.register("comparing all mapblocks from the catalog", function(callback)
	for x=mb_pos1.x,mb_pos2.x do
		for y=mb_pos1.y,mb_pos2.y do
			for z=mb_pos1.z,mb_pos2.z do
				local mapblock_pos = {x=x,y=y,z=z}
				local target_pos = {x=x,y=1+y,z=2+z}
				local mb1 = mapblock_lib.serialize_mapblock(mapblock_pos)
				local mb2 = mapblock_lib.serialize_mapblock(target_pos)
				local equal, err = mapblock_lib.compare_mapblock(mb1, mb2)
				if err then
					error(err .. ", mapblock " .. minetest.pos_to_string(mapblock_pos) ..
						" -> " .. minetest.pos_to_string(target_pos))
				end
				assert(equal, "deserialized mapblock is equal to the serialized")
			end
		end
	end
	callback()
end)