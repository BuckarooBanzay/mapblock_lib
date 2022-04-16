-- deserialization options example

-- all fields are optional
local options = {
	-- various transformations to apply to the loaded mapblock
	transform = {
		-- rotate the mapblock around the given axis with the angle (90, 180, 270)
		rotate = {
			angle = 90,
			axis = "y",
			-- disables param2 orientation for the given nodes
			disable_orientation = {
				["default:sandstonebrick"] = true
			}
		},

		-- replace certain nodes with others
		replace = {
			["default:dirt"] = "default:mese"
		},

		-- bulk set param2 for certain nodes, useful for mass-coloring
		set_param2 = {
			["unifiedbricks:brickblock"] = 15
		}
	},

	-- metadata callback, can be used to intercept and modify node-metadata/inventory
	on_metadata = function(pos, content_id, meta)
		-- resolve nodename (use a var here for better performance)
		local nodename = minetest.get_name_from_content_id(content_id)
		if nodename == "default:chest_locked" then
			print(minetest.pos_to_string(pos), nodename)
			-- set new owner
			meta:set_string("owner", "nobody")
		end
	end,

	-- placement mode "replace": replace the whole mapblock, "add": replace only air nodes
	mode = "replace"
}

-- local from a mod folder
local filename = minetest.get_modpath("my_mod") .. "/schematics/my_catalog.zip"

local catalog, err = mapblock_lib.get_catalog(filename)
if err then
	error(err)
end

-- deserialize the mapblock at 0,0,0 in the catalog to 1,1,1 in the world
local success, deser_err = catalog:deserialize({x=0,y=0,z=0}, {x=1,y=1,z=1})
if not success then
	error(deser_err)
end

-- deserialize the same mapblock but with additional options
success, deser_err = catalog:deserialize({x=0,y=0,z=0}, {x=1,y=1,z=1}, options)
if not success then
	error(deser_err)
end

-- deserialize all mapblocks to position 1,1,1 without any callback
catalog:deserialize_all({x=1,y=1,z=1})

-- deserialize all mapblocks to position 1,1,1 with options
catalog:deserialize_all({x=1,y=1,z=1}, {
	-- delay between mapblock exports in seconds (default is 0.2)
	delay = 1,
	callback = function(count, micros)
		-- called after the export is done
		print("Imported " .. count .. " mapblocks in " .. micros .. " us")
	end,
	progress_callback = function(f)
		-- progress is a fractional number from 0 to 1
		print("Progress: " .. (f*100) .. "%")
	end,
	error_callback = function(import_err)
		-- handle errors
		error(import_err)
	end
})

-- load and prepare a mapblock for faster access (mapgen)
local deserFn, prep_err = catalog:prepare({x=0,y=0,z=0}, options)
if prep_err then
	error(prep_err)
end
-- apply to the given position
deserFn({x=1,y=1,z=1})