
# mapblock_lib

[![ContentDB](https://content.minetest.net/packages/BuckarooBanzay/mapblock_lib/shields/downloads/)](https://content.minetest.net/packages/BuckarooBanzay/mapblock_lib/)
![](https://github.com/BuckarooBanzay/mapblock_lib/workflows/luacheck/badge.svg)

Mapblock-granular world operations, transformations and utilities

<img src="./screenshot.png"/>

Features:

* Load/Save mapblocks from/to disk
* Serializes param1/param2/nodetimers and metadata
* Transforms mapblock data on the fly (rotation, orientation, replacements)
* Supports caching of the loaded mapblocks for fast in-world placement (mapgen)
* Adds a per-mapblock data-storage (`get_mapblock_data` / `set_mapblock_data`) with caching

Use-cases:

* Custom mapgens with pre-built schematics
* Building-mods

Demo:

* [City mapgen](https://github.com/BuckarooBanzay/citygen)

## Chatcommands

### Single mapblock operations
* **/mapblock_show** marks the current mapblock with a grid
* **/mapblock_save [name]** saves the current mapblock in `<world_path>/mapblocks/<name>`
* **/mapblock_load [name]** loads a previously saved mapblock
* **/mapblock_rotate_y [90,180,270]** rotates the current mapblock around the y axis
* **/mapblock_mark** (only available if the `worldedit` mod is present) marks the current mapblock with worledit

### Multi-mapblock operations
* **/mapblocks_pos1** marks the pos1 for a multi-mapblock ex-/import
* **/mapblocks_pos2** marks the pos2 for a multi-mapblock ex-/import
* **/mapblocks_save [name]** saves the mapblock region in `<world_path/mapblocks/<name>`
* **/mapblocks_load [name]** loads a saved mapblock region

## Api

```lua
-- main api
mapblock_lib.serialize(mapblock_pos, filename)
mapblock_lib.deserialize(mapblock_pos, filename, options)

options = {
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

# License

* Code: MIT
* Textures: CC-BY-SA 3.0
