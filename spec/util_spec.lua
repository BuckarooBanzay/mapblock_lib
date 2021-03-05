require("mineunit")

mineunit("core")
mineunit("player")
mineunit("default/functions")

sourcefile("init")

describe("mapblock_lib.get_mapblock", function()
	it("returns proper coordinates", function()
		local mapblock_pos = mapblock_lib.get_mapblock({ x=1, y=1, z=1 })
		assert.not_nil(mapblock_pos)
		assert.equals(0, mapblock_pos.x)
		assert.equals(0, mapblock_pos.y)
		assert.equals(0, mapblock_pos.z)

		mapblock_pos = mapblock_lib.get_mapblock({ x=17, y=1, z=1 })
		assert.not_nil(mapblock_pos)
		assert.equals(1, mapblock_pos.x)
		assert.equals(0, mapblock_pos.y)
		assert.equals(0, mapblock_pos.z)

		mapblock_pos = mapblock_lib.get_mapblock({ x=1, y=1, z=-15 })
		assert.not_nil(mapblock_pos)
		assert.equals(0, mapblock_pos.x)
		assert.equals(0, mapblock_pos.y)
		assert.equals(-1, mapblock_pos.z)
	end)
end)
