
# mapblock_lib

[![ContentDB](https://content.minetest.net/packages/BuckarooBanzay/mapblock_lib/shields/downloads/)](https://content.minetest.net/packages/BuckarooBanzay/mapblock_lib/)
![](https://github.com/BuckarooBanzay/mapblock_lib/workflows/luacheck/badge.svg)
![](https://github.com/BuckarooBanzay/mapblock_lib/workflows/ldoc/badge.svg)

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

* `/mapblock_show` marks the current mapblock with a grid
* `/mapblock_save [name]` saves the current mapblock in `<world_path>/mapblocks/<name>`
* `/mapblock_load [name]` loads a previously saved mapblock
* `/mapblock_rotate_y [90,180,270]` rotates the current mapblock around the y axis
* `/mapblock_mark` (only available if the `worldedit` mod is present) marks the current mapblock with worledit

### Multi-mapblock operations

* `/mapblocks_pos1` marks the pos1 for a multi-mapblock ex-/import
* `/mapblocks_pos2` marks the pos2 for a multi-mapblock ex-/import
* `/mapblocks_save [name]` saves the mapblock region in `<world_path/mapblocks/<name>`
* `/mapblocks_load [name]` loads a saved mapblock region

## Api

See: https://buckaroobanzay.github.io/mapblock_lib/

# License

* Code: MIT
* Textures: CC-BY-SA 3.0
