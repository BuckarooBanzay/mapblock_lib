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


function mapblock_lib.transform(transform, max, mapblock, metadata)
	if transform.replace then
		mapblock_lib.replace(transform.replace, mapblock)
	end

	if transform.set_param2 then
		mapblock_lib.set_param2(transform.set_param2, mapblock)
	end

	if transform.rotate then
		local axis = transform.rotate.axis
		local angle = transform.rotate.angle
		local disable_orientation = transform.rotate.disable_orientation or {}

		local other1, other2 = get_axis_others(axis)

		if angle == 90 then
			mapblock_lib.flip(other1, max, mapblock, metadata)
			mapblock_lib.transpose(other1, other2, max, mapblock, metadata)
			if axis == "y" then
				mapblock_lib.orient(90, max, mapblock, disable_orientation)
			end
		elseif angle == 180 then
			mapblock_lib.flip(other1, max, mapblock, metadata)
			mapblock_lib.flip(other2, max, mapblock, metadata)
			if axis == "y" then
				mapblock_lib.orient(180, max, mapblock, disable_orientation)
			end
		elseif angle == 270 then
			mapblock_lib.flip(other2, max, mapblock, metadata)
			mapblock_lib.transpose(other1, other2, max, mapblock, metadata)
			if axis == "y" then
				mapblock_lib.orient(270, max, mapblock, disable_orientation)
			end
		end
	end

end
