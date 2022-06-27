

minetest.register_chatcommand("mapblock_pos1", {
	privs = { mapblock_lib = true },
	description = "selects the current mapblock as pos1 for multi mapblock export/import",
	func = function(name)
		local player = minetest.get_player_by_name(name)
		if not player then
			return false, "player not found"
		end

		local pos = player:get_pos()
		local mapblock_pos = mapblock_lib.get_mapblock(pos)
		mapblock_lib.set_pos(1, name, mapblock_pos)

		return true, "selected mapblock " .. minetest.pos_to_string(mapblock_pos) .. " as pos1"
	end
})

minetest.register_chatcommand("mapblock_pos2", {
	privs = { mapblock_lib = true },
	description = "selects the current mapblock as pos2 for multi mapblock export/import",
	func = function(name)
		local player = minetest.get_player_by_name(name)
		if not player then
			return false, "player not found"
		end

		local pos = player:get_pos()
		local mapblock_pos = mapblock_lib.get_mapblock(pos)
		mapblock_lib.set_pos(2, name, mapblock_pos)

		return true, "selected mapblock " .. minetest.pos_to_string(mapblock_pos) .. " as pos2"
	end
})

minetest.register_chatcommand("mapblock_save", {
	privs = { mapblock_lib = true },
	description = "saves the current mapblocks region",
	params = "<filename>",
	func = function(name, params)

		local pos1 = mapblock_lib.get_pos(1, name)
		local pos2 = mapblock_lib.get_pos(2, name)

		if not pos1 or not pos2 then
			return false, "select a region with /mapblock_pos[1|2] first"
		end

		if not params or params == "" then
			return false, "specify a name for the schema"
		end

		pos1, pos2 = mapblock_lib.sort_pos(pos1, pos2)
		local filename = mapblock_lib.schema_path .. "/" .. params .. ".zip"

		mapblock_lib.create_catalog(filename, pos1, pos2, {
			callback = function(total_count, micros)
				minetest.chat_send_player(name, "[mapblock_lib] saved " .. total_count ..
					" mapblocks to '" .. filename .. "' in " .. micros/1000 .. " ms")
			end,
			progress_callback = function(p)
				minetest.chat_send_player(name, "[mapblock_lib] save-progress: " .. math.floor(p*1000)/10 .. " %")
			end
		})

		return true, "Started saving to '" .. filename .. "'"
	end
})

minetest.register_chatcommand("mapblock_load", {
	privs = { mapblock_lib = true },
	description = "loads a saved mapblock region",
	params = "<filename>",
	func = function(name, params)
		local pos1 = mapblock_lib.get_pos(1, name)

		if not pos1 then
			return false, "select /mapblocks_pos1 first"
		end

		if not params or params == "" then
			return false, "specify a name for the schema"
		end

		local filename = mapblock_lib.schema_path .. "/" .. params .. ".zip"

		local catalog, err = mapblock_lib.get_catalog(filename)
		if err then
			return false, err
		end
		catalog:deserialize_all(pos1, {
			callback = function(total_count, micros)
				minetest.chat_send_player(name, "[mapblock_lib] loaded " .. total_count ..
					" mapblocks to '" .. filename .. "' in " .. micros/1000 .. " ms")
			end,
			progress_callback = function(p)
				minetest.chat_send_player(name, "[mapblock_lib] load-progress: " .. math.floor(p*1000)/10 .. " %")
			end
		})

		return true, "Started loading from '" .. filename .. "'"
	end
})

minetest.register_chatcommand("mapblock_allocate", {
	privs = { mapblock_lib = true },
	description = "allocates a saved mapblock region",
	params = "<filename>",
	func = function(name, params)
		local pos1 = mapblock_lib.get_pos(1, name)

		if not pos1 then
			return false, "select /mapblocks_pos1 first"
		end

		if not params or params == "" then
			return false, "specify a name for the schema"
		end

		local filename = mapblock_lib.schema_path .. "/" .. params .. ".zip"
		local catalog, err = mapblock_lib.get_catalog(filename)
		if err then
			return false, "Error: " .. err
		end

		local size = catalog:get_size()
		mapblock_lib.set_pos(2, name, vector.subtract(vector.add(pos1, size), 1))

		return true, "Allocated: '" .. filename .. "' with size: " .. minetest.pos_to_string(size)
	end
})

minetest.register_chatcommand("mapblock_load_plain", {
	privs = { mapblock_lib = true },
	description = "loads a saved (single-file) mapblock region",
	params = "<filename>",
	func = function(name, params)
		local pos1 = mapblock_lib.get_pos(1, name)

		if not pos1 then
			return false, "select /mapblocks_pos1 first"
		end

		if not params or params == "" then
			return false, "specify a name for the schema"
		end

		local prefix = mapblock_lib.schema_path .. "/" .. params

		local success, err = mapblock_lib.deserialize(pos1, prefix)

		return success, err or "Loaded mapblock from '" .. prefix .. "'"
	end
})