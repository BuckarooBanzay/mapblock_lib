-- deserialization options example

-- all fields are optional
local options = {
	-- caches the on-disk file, useful for repetitive mapgen events
	use_cache = false,

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

-- place at mapblock 0,0,0
local mapblock_pos = { x=0, y=0, z=0 }

-- local from a mod folder
local filename = minetest.get_modpath("my_mod") .. "/schematics/my_mapblock"

-- deserialize
local success, msg = mapblock_lib.deserialize(mapblock_pos, filename, options)

if not success then
    -- not successful, abort with error
    error(msg)
end
