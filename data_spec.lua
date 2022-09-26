
local pos1 = { x=-32, y=-32, z=-32 }
local pos2 = { x=64, y=32, z=64 }

local storage = minetest.get_mod_storage()

mtt.register("data storage", function(callback)
	local store = mapblock_lib.create_data_storage(storage)
	assert(store)

	-- create
	store:set(pos1, {x=1})

	-- read
	local data = store:get(pos1)
	assert(data)
	assert(data.x == 1)

	-- read non-existing
	data = store:get(pos2)
	assert(data == nil)

	-- merge
	store:merge(pos1, {y=2})
	data = store:get(pos1)
	assert(data)
	assert(data.x == 1)
	assert(data.y == 2)

	-- merge into non-existing
	store:merge(pos2, {z=3})
	data = store:get(pos2)
	assert(data)
	assert(data.x == nil)
	assert(data.y == nil)
	assert(data.z == 3)

	-- remove
	store:set(pos1, nil)
	assert(store:get(pos1) == nil)

	callback()
end)