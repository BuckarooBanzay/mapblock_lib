---------
-- Create catalog function

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
	local f = io.open(filename, "w")
	local z = mtzip.zip(f)

	local iterator, total_count = mapblock_lib.pos_iterator(pos1, pos2)
	local mapblock_pos
	local count = 0

	-- default to async serialization
	options = options or {}
	options.delay = options.delay or 0.2
	options.callback = options.callback or function() end
	options.progress_callback = options.progress_callback or function() end

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
			-- done, write global manifest
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