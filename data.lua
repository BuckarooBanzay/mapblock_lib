local function getkey(mapblock)
	return mapblock.x .. "/" .. mapblock.y .. "/" .. mapblock.z
end

local meta_key = "__mapblock_data"
local cache = {}

local function save_to_world(mapblock, data)
	local min = mapblock_lib.get_mapblock_bounds_from_mapblock(mapblock)
	local meta = minetest.get_meta(min)
	if data ~= nil then
		-- save data
		meta:set_string(meta_key, minetest.serialize(data))
	else
		-- clear data
		meta:set_string(meta_key, "")
	end
end

local function load_from_world(mapblock)
	local min = mapblock_lib.get_mapblock_bounds_from_mapblock(mapblock)
	local meta = minetest.get_meta(min)
	local str = meta:get_string(meta_key)
	if str and str ~= "" then
		-- deserialize data
		return minetest.deserialize(str)
	else
		-- no data available
		return nil
	end
end

function mapblock_lib.get_mapblock_data(mapblock_pos)
	local key = getkey(mapblock_pos)
	local data = cache[key]
	if data ~= nil then
		-- use cached data (false if no data available)
		return data
	else
		-- cache for future use
		data = load_from_world(mapblock_pos)
		cache[key] = data or false
		return data
	end
end

function mapblock_lib.set_mapblock_data(mapblock_pos, data)
	local key = getkey(mapblock_pos)
	cache[key] = data
	save_to_world(mapblock_pos, data)
end

function mapblock_lib.merge_mapblock_data(mapblock_pos, data)
	local info = mapblock_lib.get_mapblock_data(mapblock_pos) or {}
	for key, value in pairs(data) do
		info[key] = value
	end
	mapblock_lib.set_mapblock_data(mapblock_pos, info)
end
