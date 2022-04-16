-- create catalog example

-- a region of 11x11x11 mapblocks
local pos1 = { x=0, y=0, z=0 }
local pos2 = { x=10, y=10, z=10 }
local filename = minetest.get_worldpath() .. "/mycatalog.zip"

-- create a catalog in the worldpath folder with the given area and default options
mapblock_lib.create_catalog(filename, pos1, pos2)

-- create a catalog with some additional options and callbacks
mapblock_lib.create_catalog(filename, pos1, pos2, {
    -- delay between mapblock exports in seconds (default is 0.2)
    delay = 1,
    callback = function(count, micros)
        -- called after the export is done
        print("Exported " .. count .. " mapblocks in " .. micros .. " us")
    end,
    progress_callback = function(f)
        -- progress is a fractional number from 0 to 1
        print("Progress: " .. (f*100) .. "%")
    end
})