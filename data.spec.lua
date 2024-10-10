
local pos1 = { x=-32, y=-32, z=-32 }
local pos2 = { x=64, y=32, z=64 }

local storage = minetest.get_mod_storage()

local function check_store(store)
	assert(store)

	-- clear
	store:clear()

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

	-- save and purge store
	store:save_stale_data()
	store:purge()

	-- validate persisted data
	data = store:get(pos2)
	assert(data)
	assert(data.z == 3)

	data = store:get(pos1)
	assert(data == nil)
end

mtt.register("data storage (default serialization)", function(callback)
	check_store(mapblock_lib.create_data_storage(storage))
	callback()
end)

mtt.register("data storage (granularity = 50)", function(callback)
	check_store(mapblock_lib.create_data_storage(storage, {
		granularity = 50
	}))
	callback()
end)

mtt.register("data storage (prefix = test_)", function(callback)
	check_store(mapblock_lib.create_data_storage(storage, {
		prefix = "test_"
	}))
	callback()
end)

mtt.register("data storage (json serialization)", function(callback)
	check_store(mapblock_lib.create_data_storage(storage, {
		serialize = minetest.write_json,
		deserialize = minetest.parse_json
	}))
	callback()
end)

local function check_storage_links(store)
	assert(store)
	store:clear()

	-- original data
	store:set({x=10,y=0,z=0}, {mydata=true})

	-- link to original
	store:set({x=20,y=0,z=0}, mapblock_lib.create_data_link({x=10,y=0,z=0}))

	-- link to link
	store:set({x=30,y=0,z=0}, mapblock_lib.create_data_link({x=20,y=0,z=0}))

	-- ensure that links exist
	assert(not mapblock_lib.is_data_link(store:get({x=10,y=0,z=0})))
	assert(mapblock_lib.is_data_link(store:get({x=20,y=0,z=0})))
	assert(mapblock_lib.is_data_link(store:get({x=30,y=0,z=0})))

	-- simple link
	local data, target_pos = mapblock_lib.resolve_data_link(store, {x=20,y=0,z=0})
	assert(data)
	assert(data.mydata)
	assert(target_pos)
	assert(target_pos.x == 10)
	assert(target_pos.y == 0)
	assert(target_pos.z == 0)

	-- nested link
	data, target_pos = mapblock_lib.resolve_data_link(store, {x=30,y=0,z=0})
	assert(data)
	assert(data.mydata)
	assert(target_pos)
	assert(target_pos.x == 10)
	assert(target_pos.y == 0)
	assert(target_pos.z == 0)

	-- not a link (data)
	data, target_pos = mapblock_lib.resolve_data_link(store, {x=10,y=0,z=0})
	assert(data)
	assert(data.mydata)
	assert(target_pos)
	assert(target_pos.x == 10)
	assert(target_pos.y == 0)
	assert(target_pos.z == 0)

	-- not a link (nil)
	data = mapblock_lib.resolve_data_link(store, {x=999,y=0,z=0})
	assert(not data)
	assert(target_pos)
	assert(target_pos.x == 10)
	assert(target_pos.y == 0)
	assert(target_pos.z == 0)
end

mtt.register("data storage links (default serialization)", function(callback)
	check_storage_links(mapblock_lib.create_data_storage(storage))
	callback()
end)

mtt.register("data storage links (json serialization)", function(callback)
	check_storage_links(mapblock_lib.create_data_storage(storage, {
		serialize = minetest.write_json,
		deserialize = minetest.parse_json
	}))
	callback()
end)

mtt.register("data storage links (granularity = 50)", function(callback)
	check_storage_links(mapblock_lib.create_data_storage(storage, {
		granularity = 50
	}))
	callback()
end)

mtt.register("data storage links (prefix = test)", function(callback)
	check_storage_links(mapblock_lib.create_data_storage(storage, {
		prefix = "test_"
	}))
	callback()
end)