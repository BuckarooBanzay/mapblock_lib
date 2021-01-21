local function get_axis_others(axis)
	if axis == "x" then
		return "y", "z"
	elseif axis == "y" then
		return "x", "z"
	elseif axis == "z" then
		return "x", "y"
	else
		error("Axis must be x, y, or z!")
	end
end


function mapblock_lib.transform(transform, mapblock, metadata)

	if transform.replace then
		mapblock_lib.replace(transform.replace, mapblock)
	end

	if transform.rotate then
		local axis = transform.rotate.axis
		local angle = transform.rotate.angle
		local disable_orientation = transform.rotate.disable_orientation

		local other1, other2 = get_axis_others(axis)

		if angle == 90 then
			mapblock_lib.flip(other1, mapblock, metadata)
			mapblock_lib.transpose(other1, other2, mapblock, metadata)
			if axis == "y" and not disable_orientation then
				mapblock_lib.orient(90, mapblock)
			end
		elseif angle == 180 then
			mapblock_lib.flip(other1, mapblock, metadata)
			mapblock_lib.flip(other2, mapblock, metadata)
			if axis == "y" and not disable_orientation then
				mapblock_lib.orient(180, mapblock)
			end
		elseif angle == 270 then
			mapblock_lib.flip(other2, mapblock, metadata)
			mapblock_lib.transpose(other1, other2, mapblock, metadata)
			if axis == "y" and not disable_orientation then
				mapblock_lib.orient(270, mapblock)
			end
		end
	end

end
