
# mapblock_lib

[![ContentDB](https://content.minetest.net/packages/BuckarooBanzay/mapblock_lib/shields/downloads/)](https://content.minetest.net/packages/BuckarooBanzay/mapblock_lib/)
![](https://github.com/BuckarooBanzay/mapblock_lib/workflows/luacheck/badge.svg)
![](https://github.com/BuckarooBanzay/mapblock_lib/workflows/ldoc/badge.svg)
![](https://github.com/BuckarooBanzay/mapblock_lib/workflows/test/badge.svg)

Mapblock-granular world operations, transformations and utilities

![Screenshot](screenshot.png)

Features:

* Load/Save mapblocks from/to disk
* Serializes param1/param2/nodetimers and metadata
* Transforms mapblock data on the fly (rotation, orientation, replacements)
* Supports caching of the loaded mapblocks for fast in-world placement (mapgen)
* Adds position dependent data-storage (`mapblock_lib.create_data_storage(mod_storage)`) with caching

Use-cases:

* Custom mapgens with pre-built schematics
* Building-mods

Demo:

* [City mapgen](https://github.com/BuckarooBanzay/citygen)
* [Mapblock tileset](https://github.com/buckarooBanzay/mapblock_tileset)

## Chatcommands

### Single mapblock operations

* `/mapblock_show` marks the current mapblock with a grid
* `/mapblock_rotate_y [90,180,270]` rotates the current mapblock around the y axis
* `/mapblock_mark`,`/mb_mark` (only available if the `worldedit` mod is present) marks the current mapblock with worledit

### Multi-mapblock operations

* `/mapblock_pos1`,`/mb_pos1` marks the pos1 for a multi-mapblock ex-/import
* `/mapblock_pos2`,`/mb_pos2` marks the pos2 for a multi-mapblock ex-/import
* `/mapblock_save [path|modname:path]`,`/mb_save [path|modname:path]` saves the mapblock region
* `/mapblock_load [path|modname:path]`,`/mb_load [path|modname:path]` loads a saved mapblock region
* `/mapblock_allocate [name]`,`mb_alloc [name]` allocates and displays the affected region

The parameter `path|modname:path` can be either a file in `<world_path/mapblocks/<path>`
or, if a ":" delimiter is found and the `mapblock_lib` is a trusted mod: a file in the modpath `<modname-path>/<path>`

For example:
* `/mb_load xy` loads the schematic from `<world_path>/mapblocks/xy.zip`
* `/mb_load mymod:schematics/abc` loads the schematic `schematics/abc.zip` from the `mymod` mod-path (`mapblock_lib` has to be a trusted mod)

## Api

See: https://buckaroobanzay.github.io/mapblock_lib/

# License

* Code: MIT
* Textures: CC-BY-SA 3.0

![Always has been](mapblocks.jpg)
