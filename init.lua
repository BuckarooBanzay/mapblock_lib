local MP = minetest.get_modpath("mapblock_lib")

mapblock_lib = {
	schema_path = minetest.get_worldpath() .. "/mapblocks",
	mapgens = {},
	version = 2
}

-- secure/insecure environment
local global_env = _G
local ie = minetest.request_insecure_environment and minetest.request_insecure_environment()
if ie then
	minetest.log("action", "[mapsync] using insecure environment")
	-- register insecure environment
	global_env = ie
end

-- create global schema_path
minetest.mkdir(mapblock_lib.schema_path)

dofile(MP .. "/privs.lua")
dofile(MP .. "/util.lua")
dofile(MP .. "/pointed.lua")
dofile(MP .. "/pos.lua")
dofile(MP .. "/data.lua")
dofile(MP .. "/metadata.lua")

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
loadfile(MP.."/create_catalog.lua")(global_env)

dofile(MP .. "/display.lua")
dofile(MP .. "/chatcommands/single.lua")
dofile(MP .. "/chatcommands/multi.lua")

dofile(MP .. "/mapgens/singleblock.lua")

if minetest.get_modpath("mtt") then
	dofile(MP .. "/chatcommands/multi.spec.lua")
	dofile(MP .. "/deserialize_mapblock.spec.lua")
	dofile(MP .. "/util.spec.lua")
	dofile(MP .. "/data.spec.lua")
	dofile(MP .. "/catalog.spec.lua")
	dofile(MP .. "/serialize.spec.lua")
end