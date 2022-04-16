-- singleblock mapgen example, places a single mapblock _everywhere_

local MP = minetest.get_modpath("my_mod")

-- create a mapgen function for a single mapblock
local fn = mapblock_lib.mapgens.singleblock({
    filename = MP .. "/schemas/mymapblock.zip"
})

-- register it
minetest.register_on_generated(fn)