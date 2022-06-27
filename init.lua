local MP = minetest.get_modpath("mapblock_lib")

mapblock_lib = {
	schema_path = minetest.get_worldpath() .. "/mapblocks",
	mapgens = {},
	version = 2
}

-- create global schema_path
minetest.mkdir(mapblock_lib.schema_path)

dofile(MP .. "/privs.lua")
dofile(MP .. "/util.lua")
dofile(MP .. "/pos.lua")
dofile(MP .. "/data.lua")

dofile(MP .. "/mapblock.lua")

dofile(MP .. "/transform/transform.lua")
dofile(MP .. "/transform/transform_set_param2.lua")
dofile(MP .. "/transform/transform_replace.lua")
dofile(MP .. "/transform/transform_flip.lua")
dofile(MP .. "/transform/transform_orient.lua")
dofile(MP .. "/transform/transform_transpose.lua")

dofile(MP .. "/serialize_mapblock.lua")
dofile(MP .. "/deserialize_mapblock.lua")
dofile(MP .. "/deserialize.lua")

dofile(MP .. "/get_catalog.lua")
dofile(MP .. "/create_catalog.lua")

dofile(MP .. "/display.lua")
dofile(MP .. "/chatcommands/single.lua")
dofile(MP .. "/chatcommands/multi.lua")

dofile(MP .. "/mapgens/singleblock.lua")