---------
-- off-world storage for position-dependent data (data in mapblocks, tilenames, etc)
-- indexed in 10^3 groups and saved in the mod-storage

------
-- World data storage object
-- @type DataStorage
local DataStorage = {}
local DataStorage_mt = { __index = DataStorage }

-- metrics
local cache_hit_callback = function() end
local cache_miss_callback = function() end

--- create a new world data storage object
-- @param storage the mod_storage object from "minetest.get_mod_storage()"
-- @return @{DataStorage} the storage object
function mapblock_lib.create_data_storage(storage, opts)
    opts = opts or {}

    local self = {
        -- mod_storage ref
        storage = storage,
        -- group_index -> data
        cache = {},
        -- group_index -> bool
        stale_data = {},

        serialize = opts.serialize or minetest.serialize,
        deserialize = opts.deserialize or minetest.deserialize
    }
    local ref = setmetatable(self, DataStorage_mt)

    -- start initial save_worker run
    self:save_worker()
    -- start periodic data purge worker
    self:purge_worker()
    -- save stale data on shutdown
    minetest.register_on_shutdown(function() self:save_stale_data() end)

    return ref
end

--- Creates a data link to the target position
-- @param target_pos the position to link to
-- @return the link object
function mapblock_lib.create_data_link(target_pos)
    return {
        _link = target_pos
    }
end

--- Checks if the data is a link
-- @param the data object
-- @return true if the data object is a link
function mapblock_lib.is_data_link(data)
    return data and data._link
end

--- Resolves a data link from the storage
-- @param storage the @{DataStorage} object
-- @param pos the first position to resolve
-- @param max_recursions[opt] maximum recursion count before aborting (defaults to 10)
-- @return the resolved data object or nil if none found
-- @return the target position of the link
function mapblock_lib.resolve_data_link(storage, pos, max_recursions)
    local recursions = 0
    local data = storage:get(pos)
    local target_pos = pos

    while true do
        if mapblock_lib.is_data_link(data) then
            target_pos = data._link
            data = storage:get(data._link)
        else
            break
        end

        recursions = recursions + 1
        if recursions > (max_recursions or 10) then
            return
        end
    end

    return data, target_pos
end

-- "group" is a bundle of mapblock-positions
local function get_group_pos(pos)
    -- 10^3 pos-datasets are in a group for better lookup, indexing and caching
    return vector.floor(vector.divide(pos, 10))
end

function DataStorage:get_group_data(pos)
    local index = minetest.pos_to_string(get_group_pos(pos))
    if not self.cache[index] then
        local serialized_data = self.storage:get_string(index)
        if serialized_data == "" then
            -- no data, add empty table
            self.cache[index] = {}
        else
            -- deserialize data
            self.cache[index] = self.deserialize(serialized_data) or {}
        end
        cache_miss_callback()
    else
        cache_hit_callback()
    end
    return self.cache[index]
end

-- store grouped data for async save
function DataStorage:set_group_data(pos, data)
    local index = minetest.pos_to_string(get_group_pos(pos))
    self.cache[index] = data
    self.stale_data[index] = true
end

-- saves all stale data
function DataStorage:save_stale_data()
    for index in pairs(self.stale_data) do
        local data = self.cache[index]
        local serialized_data = self.serialize(data)
        self.storage:set_string(index, serialized_data)
        self.stale_data[index] = nil
    end
end

-- async save worker
function DataStorage:save_worker()
    self:save_stale_data()
    minetest.after(2, function() self:save_worker() end)
end

function DataStorage:purge()
    self:save_stale_data()
    self.cache = {}
end

-- periodic data purge
function DataStorage:purge_worker()
    self:purge()
    minetest.after(600, function() self:purge_worker() end)
end

-- exposed functions below here

--- Returns the data at given position
-- @param pos @{util.node_pos} the position of the data
function DataStorage:get(pos)
    local index = minetest.pos_to_string(pos)
    local group_data = self:get_group_data(pos)
    return group_data[index]
end

--- Sets the data at given position
-- @param pos @{util.node_pos} the position of the data
-- @param data the data to save at the position or nil to clear
function DataStorage:set(pos, data)
    local index = minetest.pos_to_string(pos)
    local group_data = self:get_group_data(pos)
    group_data[index] = data
    self:set_group_data(pos, group_data)
end

--- Merges the data at given position with the existing data
-- @param pos @{util.node_pos} the position of the data
-- @param data the data to merge at the position, only top-level fields will be merged together
function DataStorage:merge(pos, merge_data)
    local data = self:get(pos) or {}
    for k,v in pairs(merge_data) do
        data[k] = v
    end
    self:set(pos, data)
end

--- Clears all data from the storage
function DataStorage:clear()
    -- remove disk data
    self.storage:from_table()
    -- remove cache
    self.cache = {}
    -- purge stale data
    self.stale_data = {}
end

-- monitoring stuff
if minetest.get_modpath("monitoring") then
    -- cache hit stats
    local cache_hits = monitoring.counter("mapblock_lib_data_cache_hits", "number of cache hits")
    cache_hit_callback = cache_hits.inc

    local cache_miss = monitoring.counter("mapblock_lib_data_cache_miss", "number of cache misses")
    cache_miss_callback = cache_miss.inc

end