---------
-- mapblock data management

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

local cache_hit_callback = function() end
local cache_miss_callback = function() end

--- get the mapblock data
-- @param mapblock_pos the mapblock position
-- @return the mapblock data as a table or nil if none available
function mapblock_lib.get_mapblock_data(mapblock_pos)
	local key = getkey(mapblock_pos)
	local data = cache[key]
	if data ~= nil then
		-- use cached data (false if no data available)
		cache_hit_callback()
		return data
	else
		-- cache for future use
		data = load_from_world(mapblock_pos)
		cache[key] = data or false
		cache_miss_callback()
		return data
	end
end

--- set the mapblock data
-- @param mapblock_pos the mapblock position
-- @param data the table to set for that mapblock
function mapblock_lib.set_mapblock_data(mapblock_pos, data)
	local key = getkey(mapblock_pos)
	cache[key] = data
	save_to_world(mapblock_pos, data)
end

--- merge data with existing mapblock data
-- @param mapblock_pos the mapblock position
-- @param data the table to set for that mapblock (keys are merged to existing data)
function mapblock_lib.merge_mapblock_data(mapblock_pos, data)
	local info = mapblock_lib.get_mapblock_data(mapblock_pos) or {}
	for key, value in pairs(data) do
		info[key] = value
	end
	mapblock_lib.set_mapblock_data(mapblock_pos, info)
end


-- monitoring stuff
if minetest.get_modpath("monitoring") then
	monitoring.wrap_global({"mapblock_lib", "set_mapblock_data"}, "mapblock_lib_set_mapblock_data")
	monitoring.wrap_global({"mapblock_lib", "get_mapblock_data"}, "mapblock_lib_get_mapblock_data")

	-- cache size, periodically updated
	local cache_size = monitoring.gauge("mapblock_lib_data_cache_size", "data cache size")
	local function update_cache_size()
		local entries = 0
		for _ in pairs(cache) do
			entries = entries + 1
		end
		cache_size.set(entries)
		minetest.after(10, update_cache_size)
	end
	update_cache_size()

	-- cache hit stats
	local cache_hits = monitoring.counter("mapblock_lib_data_cache_hits", "number of cache hits")
	cache_hit_callback = cache_hits.inc

	local cache_miss = monitoring.counter("mapblock_lib_data_cache_miss", "number of cache misses")
	cache_miss_callback = cache_miss.inc

end