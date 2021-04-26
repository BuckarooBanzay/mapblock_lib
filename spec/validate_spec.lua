require("mineunit")

mineunit("core")
mineunit("player")
mineunit("default/functions")

sourcefile("init")

describe("mapblock_lib.validate", function()
	it("no file is invalid", function()
		local valid, msg = mapblock_lib.validate("unknown_thing")
		assert.not_nil(msg)
		assert.equals(false, valid)
	end)
end)

