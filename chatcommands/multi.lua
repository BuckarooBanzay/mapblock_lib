
local pos1_map = {}
local pos2_map = {}

minetest.register_chatcommand("mapblocks_pos1", {
	privs = { mapblock_lib = true },
	description = "selects the current mapblock as pos1 for multi mapblock export/import",
	func = function(name)
		local player = minetest.get_player_by_name(name)
		if not player then
			return false, "player not found"
		end

		local pos = player:get_pos()

		local mapblock_pos = mapblock_lib.get_mapblock(pos)
		local min = mapblock_lib.get_mapblock_bounds_from_mapblock(mapblock_pos)

		pos1_map[name] = mapblock_pos
		if minetest.get_modpath("worldedit") then
			worldedit.pos1[name] = min
			worldedit.mark_pos1(name)
		end

		return true, "selected mapblock " .. minetest.pos_to_string(mapblock_pos) .. " as pos1"
	end
})

minetest.register_chatcommand("mapblocks_pos2", {
	privs = { mapblock_lib = true },
	description = "selects the current mapblock as pos2 for multi mapblock export/import",
	func = function(name)
		local player = minetest.get_player_by_name(name)
		if not player then
			return false, "player not found"
		end

		local pos = player:get_pos()

		local mapblock_pos = mapblock_lib.get_mapblock(pos)
		local _, max = mapblock_lib.get_mapblock_bounds_from_mapblock(mapblock_pos)

		pos2_map[name] = mapblock_pos
		if minetest.get_modpath("worldedit") then
			worldedit.pos2[name] = max
			worldedit.mark_pos2(name)
		end

		return true, "selected mapblock " .. minetest.pos_to_string(mapblock_pos) .. " as pos2"
	end
})

minetest.register_chatcommand("mapblocks_save", {
	privs = { mapblock_lib = true },
	description = "saves the current mapblocks region",
	params = "<filename>",
	func = function(name, params)

		local pos1 = pos1_map[name]
		local pos2 = pos2_map[name]

		if not pos1 or not pos2 then
			return false, "select a region with /mapblocks_pos[1|2] first"
		end

		if not params or params == "" then
			return false, "specify a name for the schema"
		end

		pos1, pos2 = mapblock_lib.sort_pos(pos1, pos2)
		local prefix = mapblock_lib.schema_path .. "/" .. params

		local success, result = mapblock_lib.serialize_multi(pos1, pos2, prefix)
		if not success then
			return false, result
		end

		local iterator = result
		local msg

		local function worker()
			result, msg = iterator()
			if result == true then
				-- not done yet
				minetest.after(0, worker)
			elseif result == nil then
				-- done
				minetest.chat_send_player(name, msg .. " mapblocks saved as " .. prefix)
			else
				-- error
				minetest.chat_send_player(name, "error while saving mapblocks: " .. msg or "<unknown>")
			end
		end

		minetest.after(0, worker)
		return true, "Started saving"
	end
})

minetest.register_chatcommand("mapblocks_load", {
	privs = { mapblock_lib = true },
	description = "loads a save mapblock region",
	params = "<filename>",
	func = function(name, params)
		local pos1 = pos1_map[name]

		if not pos1 then
			return false, "select /mapblocks_pos1 first"
		end

		if not params or params == "" then
			return false, "specify a name for the schema"
		end

		local prefix = mapblock_lib.schema_path .. "/" .. params

		local success, result = mapblock_lib.deserialize_multi(pos1, prefix)
		if not success then
			return false, result
		end

		local iterator = result
		local msg
		repeat
			result, msg = iterator()
		until result ~= true

		if result == nil then
			return true, msg .. " mapblocks loaded from " .. prefix
		else
			return false, msg
		end
	end
})
