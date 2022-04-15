
local tests = {}
local pos1 = { x=-32, y=-32, z=-32 }
local pos2 = { x=32, y=32, z=32 }

local mb_pos1 = { x=0, y=0, z=0 }
local mb_pos2 = { x=1, y=1, z=1 }

local filename = minetest.get_worldpath() .. "/mapblocks/test.zip"

-- defer emerging until stuff is settled
table.insert(tests, function(callback)
  print("defer test-start")
  minetest.after(1, callback)
end)

-- emerge area
table.insert(tests, function(callback)
  print("emerging area")
  minetest.emerge_area(pos1, pos2, function(_, _, calls_remaining)
    if calls_remaining == 0 then
      callback()
    end
  end)
end)

-- catalog
table.insert(tests, function(callback)
  print("creating catalog")
  mapblock_lib.create_catalog(filename, mb_pos1, mb_pos2, {
    callback = callback,
    progress_callback = function(p)
      print("progress: " .. p)
    end
  })
end)

table.insert(tests, function(callback)
  print("reading catalog")
  local c = mapblock_lib.get_catalog(filename)
  local size = c:get_size()
  assert(size.x == 2, "x-size wrong")
  assert(size.y == 2, "y-size wrong")
  assert(size.z == 2, "z-size wrong")
  callback()
end)

table.insert(tests, function(callback)
  print("reading non-existent catalog")
  local c, err = mapblock_lib.get_catalog(filename .. "blah")
  assert(c == nil, "catalog is not nil")
  assert(err, "err is nil")
  callback()
end)

-- job queue
minetest.log("warning", "[TEST] integration-test enabled!")
minetest.register_on_mods_loaded(function()
  local i = 0
  local function worker()
    i = i + 1
    local fn = tests[i]
    if fn then
      fn(worker)
    else
      -- exit gracefully
      print("all tests done")
      minetest.request_shutdown("success")
    end
  end

  worker()
end)