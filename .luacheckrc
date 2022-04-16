globals = {
	"mapblock_lib",
	-- optional deps
	"worldedit"
}

read_globals = {
	-- Stdlib
	string = {fields = {"split", "trim"}},
	table = {fields = {"copy", "getn"}},

	-- Minetest
	"minetest",
	"vector", "ItemStack",
	"dump", "dump2",
	"VoxelArea",

	-- mods
	"monitoring", "mtzip",

	-- testing
	"mineunit",
	"sourcefile",
	"describe",
	"it",
	"assert"
}
