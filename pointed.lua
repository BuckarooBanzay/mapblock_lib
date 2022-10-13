
--- returns the pointed mapblock position
-- @param player the player object
-- @param distance[opt] the distance to point to in mapblocks (default: 2)
-- @return @{mapblock_pos} the pointed mapblock-position
function mapblock_lib.get_pointed_position(player, distance_mapblocks)
    local ppos = player:get_pos()
    local eye_height = player:get_properties().eye_height
    ppos = vector.add(ppos, {x=0, y=eye_height, z=0})
    local look_dir = player:get_look_dir()
    local distance = (distance_mapblocks or 2) * 16
    local target_pos = vector.add(ppos, vector.multiply(look_dir, distance))
    return mapblock_lib.get_mapblock(target_pos)
end
