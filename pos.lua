
local pos_map = {
    {},
    {}
}

local function update_position_marks(name)
	if not minetest.get_modpath("worldedit") then
		return
	end

	if pos_map[1][name] and pos_map[2][name] then
		-- mark all affected mapblocks
		local mb_min, mb_max = mapblock_lib.sort_pos(pos_map[1][name], pos_map[2][name])

		local min = mapblock_lib.get_mapblock_bounds_from_mapblock(mb_min)
		local _, max = mapblock_lib.get_mapblock_bounds_from_mapblock(mb_max)
		worldedit.pos1[name] = min
		worldedit.pos2[name] = max

	elseif pos_map[1][name] then
		-- mark single mapblock
		local min, max = mapblock_lib.get_mapblock_bounds_from_mapblock(pos_map[1][name])
		worldedit.pos1[name] = min
		worldedit.pos2[name] = max

	elseif pos_map[2][name] then
		-- mark single mapblock
		local min, max = mapblock_lib.get_mapblock_bounds_from_mapblock(pos_map[2][name])
		worldedit.pos1[name] = min
		worldedit.pos2[name] = max

	end

	worldedit.mark_pos1(name)
	worldedit.mark_pos2(name)
end

function mapblock_lib.get_pos(num, playername)
    return pos_map[num][playername]
end

function mapblock_lib.set_pos(num, playername, mapblock_pos)
    pos_map[num][playername] = mapblock_pos
    update_position_marks(playername)
end