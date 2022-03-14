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

local function pos_equals(expected, actual)
	assert.equals(expected.x, actual.x, "x part error, expected " .. dump(expected) .. " actual: " .. dump(actual))
	assert.equals(expected.y, actual.y, "y part error, expected " .. dump(expected) .. " actual: " .. dump(actual))
	assert.equals(expected.z, actual.z, "z part error, expected " .. dump(expected) .. " actual: " .. dump(actual))
end

describe("mapblock_lib.pos_iterator", function()
	it("returns properly iterated coordinates", function()
		local pos1 = {x=0, y=0, z=0}
		local pos2 = {x=1, y=2, z=1}
		local iterator, total_count = mapblock_lib.pos_iterator(pos1, pos2)

		-- 2 x 2 x 3
		assert.equals(12, total_count)

		pos_equals({x=0,y=0,z=0}, iterator())
		pos_equals({x=1,y=0,z=0}, iterator())
		pos_equals({x=0,y=0,z=1}, iterator())
		pos_equals({x=1,y=0,z=1}, iterator())

		pos_equals({x=0,y=1,z=0}, iterator())
		pos_equals({x=1,y=1,z=0}, iterator())
		pos_equals({x=0,y=1,z=1}, iterator())
		pos_equals({x=1,y=1,z=1}, iterator())

		pos_equals({x=0,y=2,z=0}, iterator())
		pos_equals({x=1,y=2,z=0}, iterator())
		pos_equals({x=0,y=2,z=1}, iterator())
		pos_equals({x=1,y=2,z=1}, iterator())

		assert.is_nil(iterator())
	end)
end)


describe("mapblock_lib.transpose_pos", function()
	it("transposes the pos correctly", function()
		local pos = { x=2, y=0, z=5 }
		mapblock_lib.transpose_pos(pos, "x", "z")
		pos_equals({ x=5, y=0, z=2 }, pos)
	end)
end)

describe("mapblock_lib.flip_pos", function()
	it("flips the pos correctly", function()
		local pos = { x=2, y=0, z=1 }
		local max = { x=10, y=0, z=10 }
		mapblock_lib.flip_pos(pos, max, "x")
		pos_equals({ x=8, y=0, z=1 }, pos)
	end)
end)