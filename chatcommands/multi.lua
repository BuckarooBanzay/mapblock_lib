
local pos1_map = {}
local pos2_map = {}

local function update_position_marks(name)
	if not minetest.get_modpath("worldedit") then
		return
	end

	if pos1_map[name] and pos2_map[name] then
		-- mark all affected mapblocks
		local mb_min, mb_max = mapblock_lib.sort_pos(pos1_map[name], pos2_map[name])

		local min = mapblock_lib.get_mapblock_bounds_from_mapblock(mb_min)
		local _, max = mapblock_lib.get_mapblock_bounds_from_mapblock(mb_max)
		worldedit.pos1[name] = min
		worldedit.pos2[name] = max

	elseif pos1_map[name] then
		-- mark single mapblock
		local min, max = mapblock_lib.get_mapblock_bounds_from_mapblock(pos1_map[name])
		worldedit.pos1[name] = min
		worldedit.pos2[name] = max

	elseif pos2_map[name] then
		-- mark single mapblock
		local min, max = mapblock_lib.get_mapblock_bounds_from_mapblock(pos2_map[name])
		worldedit.pos1[name] = min
		worldedit.pos2[name] = max

	end

	worldedit.mark_pos1(name)
	worldedit.mark_pos2(name)
end

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
		pos1_map[name] = mapblock_pos
		update_position_marks(name)

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
		pos2_map[name] = mapblock_pos
		update_position_marks(name)

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
		local prefix = mapblock_lib.schema_path .. "/" .. params .. ".zip"

		mapblock_lib.serialize_multi(pos1, pos2, prefix, {
			callback = function(total_count, micros)
				minetest.chat_send_player(name, "[mapblock_lib] saved " .. total_count ..
					" mapblocks to '" .. prefix .. "' in " .. micros/1000 .. " ms")
			end,
			progress_callback = function(p)
				minetest.chat_send_player(name, "[mapblock_lib] save-progress: " .. math.floor(p*100) .. " %")
			end
		})

		return true, "Started saving to '" .. prefix .. "'"
	end
})

minetest.register_chatcommand("mapblocks_load", {
	privs = { mapblock_lib = true },
	description = "loads a saved mapblock region",
	params = "<filename>",
	func = function(name, params)
		local pos1 = pos1_map[name]

		if not pos1 then
			return false, "select /mapblocks_pos1 first"
		end

		if not params or params == "" then
			return false, "specify a name for the schema"
		end

		local prefix = mapblock_lib.schema_path .. "/" .. params .. ".zip"

		mapblock_lib.deserialize_multi(pos1, prefix, {
			callback = function(total_count, micros)
				minetest.chat_send_player(name, "[mapblock_lib] loaded " .. total_count ..
					" mapblocks to '" .. prefix .. "' in " .. micros/1000 .. " ms")
			end,
			progress_callback = function(p)
				minetest.chat_send_player(name, "[mapblock_lib] load-progress: " .. math.floor(p*100) .. " %")
			end
		})

		return true, "Started loading from '" .. prefix .. "'"
	end
})

minetest.register_chatcommand("mapblocks_allocate", {
	privs = { mapblock_lib = true },
	description = "allocates a saved mapblock region",
	params = "<filename>",
	func = function(name, params)
		local pos1 = pos1_map[name]

		if not pos1 then
			return false, "select /mapblocks_pos1 first"
		end

		if not params or params == "" then
			return false, "specify a name for the schema"
		end

		local prefix = mapblock_lib.schema_path .. "/" .. params .. ".zip"

		local success, result = mapblock_lib.get_multi_size(prefix)
		if success then
			pos2_map[name] = vector.subtract(vector.add(pos1, result), 1)
			update_position_marks(name)
		else
			return false, "Error: " .. result
		end

		return true, "Allocated: '" .. prefix .. "' with size: " .. minetest.pos_to_string(result)
	end
})
