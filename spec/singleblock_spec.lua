require("mineunit")

mineunit("core")
mineunit("player")
mineunit("default/functions")

sourcefile("init")

describe("mapblock_lib.mapgens.singleblock", function()
	it("creates a proper function", function()
        -- mock deserialize function
        local mock_calls = {}
        mapblock_lib.deserialize = function(mapblock_pos, filename, options)
            table.insert(mock_calls, {
                mapblock_pos = mapblock_pos,
                filename = filename,
                options = options
            })
        end

        local fn = mapblock_lib.mapgens.singleblock({
            filename = "mypath/x"
        })

        assert.not_nil(fn)

        -- call resulting function
        -- 2x2x2 mapblocks
        local minp = {x=0, y=0, z=0}
        local maxp = {x=31, y=31, z=31}
        fn(minp, maxp)

		assert.equals(8, #mock_calls)
        assert.not_nil(mock_calls[1])
        assert.not_nil(mock_calls[1].options)
        assert.not_nil(mock_calls[1].mapblock_pos)
        assert.equals("mypath/x", mock_calls[1].filename)
        assert.equals(true, mock_calls[1].options.use_cache)
        assert.equals(0, mock_calls[1].mapblock_pos.x)
        assert.equals(0, mock_calls[1].mapblock_pos.y)
        assert.equals(0, mock_calls[1].mapblock_pos.z)
	end)
end)

