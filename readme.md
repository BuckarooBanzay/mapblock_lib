
# mapblock_lib

Mapblock-granular world operations and utilities

<img src="./screenshot.png"/>

## Chatcommands

* **/mapblock_show** marks the current mapblock with a grid
* **/mapblock_save [name]** saves the current mapblock in `<world_path>/mapblocks/<name>`
* **/mapblock_load [name]** loads a previously saved mapblock

## Api

```lua
-- main api
mapblock_lib.serialize(mapblock_pos, filename)
mapblock_lib.deserialize(mapblock_pos, filename, options)

options = {
	-- caches the on-disk file, useful for repetitive mapgen events
	use_cache = false,
	-- various transformation to apply to the loaded mapblock
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
		}
	}
	-- placement mode "replace": replace the whole mapblock, "add": replace only air nodes
	mode = "replace"
}

-- mapblock data storage
mapblock_lib.get_mapblock_data(mapblock_pos)
mapblock_lib.set_mapblock_data(mapblock_pos, data)
mapblock_lib.merge_mapblock_data(mapblock_pos, data)

-- utils
mapblock_lib.get_mapblock(pos)
mapblock_lib.get_mapblock_bounds_from_mapblock(block_pos)
mapblock_lib.get_mapblock_bounds(pos)
mapblock_lib.get_mapblock_center(pos)
mapblock_lib.sort_pos(pos1, pos2)

-- display
mapblock_lib.display_mapblock_at_pos(pos, text, timeout)
mapblock_lib.display_mapblock(mapblock, text, timeout)
```
