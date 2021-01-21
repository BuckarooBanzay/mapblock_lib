minetest.register_chatcommand("mapblock_show", {
	func = function(name)
		local player = minetest.get_player_by_name(name)
		if not player then
			return false, "player not found"
		end

		local pos = player:get_pos()

		local mapblock_pos = mapblock_lib.get_mapblock(pos)
		mapblock_lib.display_mapblock(mapblock_pos, minetest.pos_to_string(mapblock_pos), 5)

		return true
	end
})

minetest.register_chatcommand("mapblock_get_data", {
	privs = { mapblock_lib = true },
	func = function(name)
		local player = minetest.get_player_by_name(name)
		if not player then
			return false, "player not found"
		end

		local pos = player:get_pos()
		local mapblock_pos = mapblock_lib.get_mapblock(pos)
		local data = mapblock_lib.get_mapblock_data(mapblock_pos)

		return true, dump(data)
	end
})

minetest.register_chatcommand("mapblock_save", {
	privs = { mapblock_lib = true },
	func = function(name, params)
		local player = minetest.get_player_by_name(name)
		if not player then
			return false, "player not found"
		end

		local pos = player:get_pos()

		if not params or params == "" then
			return false, "specify a name for the schema"
		end

		local block_pos = mapblock_lib.get_mapblock(pos)
		local filename = mapblock_lib.schema_path .. "/" .. params
		mapblock_lib.serialize(block_pos, filename)
		return true, "mapblock saved as " .. filename
	end
})

minetest.register_chatcommand("mapblock_load", {
	privs = { mapblock_lib = true },
	func = function(name, params)
		local player = minetest.get_player_by_name(name)
		if not player then
			return false, "player not found"
		end

		local pos = player:get_pos()

		if not params or params == "" then
			return false, "specify a name for the schema"
		end

		local mapblock_pos = mapblock_lib.get_mapblock(pos)
		local filename = mapblock_lib.schema_path .. "/" .. params
		local ok, err = mapblock_lib.deserialize(mapblock_pos, filename, {})
		return ok, err or ("mapblock loaded from " .. filename)
	end
})
