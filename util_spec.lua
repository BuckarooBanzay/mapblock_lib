
mtt.register("util::is_mapblock_aligned", function(callback)
	local p1 = {x=0,y=0,z=0}
	local p2 = {x=15,y=15,z=15}
	local p3 = {x=1,y=1,z=1}

	assert(mapblock_lib.is_mapblock_aligned(p1, p2))
	assert(not mapblock_lib.is_mapblock_aligned(p1, p3))
	callback()
end)

