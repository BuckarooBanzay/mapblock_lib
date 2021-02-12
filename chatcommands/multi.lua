
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
		local count = 0
		local prefix = mapblock_lib.schema_path .. "/" .. params

		for x=pos1.x,pos2.x do
			for y=pos1.y,pos2.y do
				for z=pos1.z,pos2.z do
					local mapblock_pos = {x=x,y=y,z=z}
					local rel_pos = vector.subtract(mapblock_pos, pos1)
					local filename = prefix .. "_" .. minetest.pos_to_string(rel_pos)
					mapblock_lib.serialize(mapblock_pos, filename)
					count = count + 1
				end
			end
		end

		local manifest = {
			range = vector.subtract(pos2, pos1)
		}
		mapblock_lib.write_manifest(manifest, prefix .. ".manifest")

		return true, count .. " mapblocks saved as " .. prefix
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

		local count = 0
		local prefix = mapblock_lib.schema_path .. "/" .. params

		local manifest = mapblock_lib.read_manifest(prefix .. ".manifest")
		if not manifest then
			return false, "no manifest found!"
		end

		local pos2 = vector.add(pos1, manifest.range)

		for x=pos1.x,pos2.x do
			for y=pos1.y,pos2.y do
				for z=pos1.z,pos2.z do
					local mapblock_pos = {x=x,y=y,z=z}
					local rel_pos = vector.subtract(mapblock_pos, pos1)
					local filename = prefix .. "_" .. minetest.pos_to_string(rel_pos)

					local _, err = mapblock_lib.deserialize(mapblock_pos, filename, {})
					if err then
						return false, "couldn't load mapblock from " .. filename
					end
					count = count + 1
				end
			end
		end

		return true, count .. " mapblocks loaded from " .. prefix
	end
})
