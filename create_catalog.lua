---------
-- Create catalog function
local global_env = ...

local has_isogen = minetest.get_modpath("isogen")

------
-- Serialize options
-- @number delay for async mode: delay between serialization-calls
-- @field callback function to call when the blocks are serialized
-- @field progress_callback function to call when the progress is update
-- @table serialize_options

--- create a new catalog and serialize the mapblocks from pos1 to pos2 in it
-- @see create_catalog.lua
-- @string filename the filename to save to
-- @param pos1 @{util.mapblock_pos} the first (lower) mapblock position
-- @param pos2 @{util.mapblock_pos} the second (upper) mapblock position
-- @param options[opt] @{serialize_options} serialization options
function mapblock_lib.create_catalog(filename, pos1, pos2, options)
	local f = global_env.io.open(filename, "wb")
	local z = mtzip.zip(f)

	local iterator, total_count = mapblock_lib.pos_iterator(pos1, pos2)
	local mapblock_pos
	local count = 0

	-- default to async serialization
	options = options or {}
	options.delay = options.delay or 0.1
	options.callback = options.callback or function() end
	options.progress_callback = options.progress_callback or function() end
	options.iso_cube_len = 8

	pos1, pos2 = mapblock_lib.sort_pos(pos1, pos2)
	local start = minetest.get_us_time()

	local worker
	worker = function()
		mapblock_pos = iterator()
		if mapblock_pos then
			local rel_pos = vector.subtract(mapblock_pos, pos1)
			local mapblock = mapblock_lib.serialize_mapblock(mapblock_pos)

			-- only serialize non-air blocks
			if not mapblock.air_only then
				z:add("mapblock_" .. minetest.pos_to_string(rel_pos) .. ".bin",mapblock_lib.write_mapblock(mapblock))
				z:add("mapblock_" .. minetest.pos_to_string(rel_pos) .. ".meta.json",mapblock_lib.write_mapblock_manifest(mapblock))
			end

			count = count + 1
			options.progress_callback(count / total_count)
			minetest.after(options.delay, worker)
		else
			-- done, generate preview and write global manifest

			if has_isogen then
				-- isogen in modpath, generate isometric preview and metadata
				local min = mapblock_lib.get_mapblock_bounds_from_mapblock(pos1)
				local _, max = mapblock_lib.get_mapblock_bounds_from_mapblock(pos2)

				local png = isogen.draw(min, max, { cube_len = options.iso_cube_len })
				z:add("preview.png", png)

				local size = vector.add(vector.subtract(max, min), 1)
				local width, height = isogen.calculate_image_size(size, options.iso_cube_len)
				local preview_metadata = {
					width = width,
					height = height
				}
				z:add("preview.json", minetest.write_json(preview_metadata))
			end

			local manifest = {
				range = vector.subtract(pos2, pos1),
				version = mapblock_lib.version
			}
			z:add("manifest.json", minetest.write_json(manifest))
			z:close()
			f:close()
			options.progress_callback(1)
			local micros = minetest.get_us_time() - start
			options.callback(count, micros)
		end
	end

	-- initial call
	worker()
end
