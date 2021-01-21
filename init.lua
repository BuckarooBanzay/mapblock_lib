mapblock_lib = {
	schema_path = minetest.get_worldpath() .. "/mapblocks"
}

-- create global schema_path
minetest.mkdir(mapblock_lib.schema_path)

local MP = minetest.get_modpath("mapblock_lib")

dofile(MP .. "/privs.lua")
dofile(MP .. "/util.lua")
dofile(MP .. "/data.lua")

dofile(MP .. "/manifest.lua")
dofile(MP .. "/mapblock.lua")

dofile(MP .. "/transform.lua")
dofile(MP .. "/transform_replace.lua")
dofile(MP .. "/transform_flip.lua")
dofile(MP .. "/transform_orient.lua")
dofile(MP .. "/transform_transpose.lua")

dofile(MP .. "/serialize.lua")
dofile(MP .. "/deserialize.lua")

dofile(MP .. "/display.lua")
dofile(MP .. "/chatcommands.lua")
