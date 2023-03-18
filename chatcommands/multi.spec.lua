
mtt.register("chatcommand parse-path", function(callback)
    assert(mapblock_lib.resolve_schema_path("xy") == mapblock_lib.schema_path .. "/xy.zip")

    callback()
end)