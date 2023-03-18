
mtt.register("chatcommand parse-path", function(callback)
    local path, err = mapblock_lib.resolve_schema_path("xy")
    assert(not err)
    assert(path == mapblock_lib.schema_path .. "/xy.zip")

    path, err = mapblock_lib.resolve_schema_path("default:stuff")
    assert(not err)
    assert(path == minetest.get_modpath("default") .. "/stuff.zip")

    local _
    _, err = mapblock_lib.resolve_schema_path("garbage:stuff")
    assert(err)

    callback()
end)