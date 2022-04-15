minetest.register_chatcommand("mapblock_show", {
	description = "shows the current mapblock bounds",
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
	description = "returns the current mapblock data",
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

minetest.register_chatcommand("mapblock_clear_data", {
	privs = { mapblock_lib = true },
	description = "removes the current mapblock data",
	func = function(name)
		local player = minetest.get_player_by_name(name)
		if not player then
			return false, "player not found"
		end

		local pos = player:get_pos()
		local mapblock_pos = mapblock_lib.get_mapblock(pos)
		local data = mapblock_lib.set_mapblock_data(mapblock_pos, nil)

		return true, dump(data)
	end
})

minetest.register_chatcommand("mapblock_rotate_y", {
	privs = { mapblock_lib = true },
	description = "rotates the current mapblock around the y axis",
	params = "<angle: [90,180,270]>",
	func = function(name, params)
		local player = minetest.get_player_by_name(name)
		if not player then
			return false, "player not found"
		end

		local pos = player:get_pos()

		local angle = tonumber(params)
		if not angle then
			return false, "specify the angle to rotate in degrees CW: 90,180,270"
		end

		local mapblock_pos = mapblock_lib.get_mapblock(pos)
		local min, max = mapblock_lib.get_mapblock_bounds_from_mapblock(mapblock_pos)

		local data = mapblock_lib.serialize_mapblock(mapblock_pos)

		local transform = {
			rotate = {
				axis = "y",
				angle = angle
			}
		}

		local size = {x=15, y=15, z=15}
		mapblock_lib.transform(transform, size, data, data.metadata)
		mapblock_lib.deserialize_part(min, max, data, data.metadata, {})

		return true, "mapblock rotated by " .. angle .. " degrees"
	end
})

if minetest.get_modpath("worldedit") then
	minetest.register_chatcommand("mapblock_mark", {
		privs = { mapblock_lib = true },
		description = "selects the current mapblock with the worldedit markers",
		func = function(name)
			local player = minetest.get_player_by_name(name)
			if not player then
				return false, "player not found"
			end

			local pos = player:get_pos()

			local mapblock_pos = mapblock_lib.get_mapblock(pos)
			local min, max = mapblock_lib.get_mapblock_bounds_from_mapblock(mapblock_pos)

			worldedit.pos1[name] = min
			worldedit.mark_pos1(name)
			worldedit.pos2[name] = max
			worldedit.mark_pos2(name)

			return true, "selected mapblock " .. minetest.pos_to_string(mapblock_pos)
		end
	})
end
