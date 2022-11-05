
mtt.register("mapblock_lib.is_mapblock_aligned", function(callback)
	local p1 = {x=0,y=0,z=0}
	local p2 = {x=15,y=15,z=15}
	local p3 = {x=1,y=1,z=1}

	assert(mapblock_lib.is_mapblock_aligned(p1, p2))
	assert(not mapblock_lib.is_mapblock_aligned(p1, p3))
	callback()
end)

mtt.register("mapblock_lib.rotate_pos", function(callback)

	-- rotate a square
	local rel_pos = {x=0,y=0,z=0}
	local max_pos = {x=3,y=3,z=3}

	-- no rotation
	local rotated_pos = mapblock_lib.rotate_pos(rel_pos, max_pos, 0)
	assert(vector.equals(rotated_pos, {x=0,y=0,z=0}))

	-- nil rotation
	rotated_pos = mapblock_lib.rotate_pos(rel_pos, max_pos)
	assert(vector.equals(rotated_pos, {x=0,y=0,z=0}))

	rotated_pos = mapblock_lib.rotate_pos(rel_pos, max_pos, 90)
	assert(vector.equals(rotated_pos, {x=0,y=0,z=3}))

	rotated_pos = mapblock_lib.rotate_pos(rel_pos, max_pos, 180)
	assert(vector.equals(rotated_pos, {x=3,y=0,z=3}))

	rotated_pos = mapblock_lib.rotate_pos(rel_pos, max_pos, 270)
	assert(vector.equals(rotated_pos, {x=3,y=0,z=0}))

	-- rotate a non-square rectangle
	--		xxxx
	-- /\	xxxx
	-- z	xxxx
	-- x ->
	max_pos = {x=3,y=3,z=2} -- size == 4,4,3

	-- 90 deg cw
	assert(vector.equals(mapblock_lib.rotate_pos({x=0,y=0,z=0}, max_pos, 90), {x=0,y=0,z=3}))
	assert(vector.equals(mapblock_lib.rotate_pos({x=3,y=0,z=0}, max_pos, 90), {x=0,y=0,z=0}))
	assert(vector.equals(mapblock_lib.rotate_pos({x=0,y=0,z=2}, max_pos, 90), {x=2,y=0,z=3}))

	callback()
end)

mtt.register("mapblock_lib.rotate_size", function(callback)

	local size = {x=10,y=2,z=2}

	-- no rotation
	local new_size = mapblock_lib.rotate_size(size, 0)
	assert(vector.equals(new_size, {x=10,y=2,z=2}))

	-- nil rotation
	new_size = mapblock_lib.rotate_size(size)
	assert(vector.equals(new_size, {x=10,y=2,z=2}))

	new_size = mapblock_lib.rotate_size(size, 90)
	assert(vector.equals(new_size, {x=2,y=2,z=10}))

	new_size = mapblock_lib.rotate_size(size, 180)
	assert(vector.equals(new_size, {x=10,y=2,z=2}))

	new_size = mapblock_lib.rotate_size(size, 270)
	assert(vector.equals(new_size, {x=2,y=2,z=10}))


	callback()
end)