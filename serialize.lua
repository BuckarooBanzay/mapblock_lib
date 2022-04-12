---------
-- mapblock serialization

local air_content_id = minetest.get_content_id("air")
local ignore_content_id = minetest.get_content_id("ignore")

-- collect node ids with on_timer attributes
local node_ids_with_timer = {}
minetest.register_on_mods_loaded(function()
	for _,node in pairs(minetest.registered_nodes) do
		if node.on_timer then
			local nodeid = minetest.get_content_id(node.name)
			node_ids_with_timer[nodeid] = true
		end
	end
end)

-- checks if a table is empty
local function is_empty(tbl)
	return not tbl or not next(tbl)
end

-- serialize the mapblock at the given node-position
function mapblock_lib.serialize_part(pos1, pos2, node_mapping)
	node_mapping = node_mapping or {}
	local manip = minetest.get_voxel_manip()
	local e1, e2 = manip:read_from_map(pos1, pos2)
	local area = VoxelArea:new({MinEdge=e1, MaxEdge=e2})

	local node_data = manip:get_data()
	local param1 = manip:get_light_data()
	local param2 = manip:get_param2_data()

	local node_id_map = {}
	local air_only = true

	-- prepare data structure
	local data = {
		node_ids = {},
		param1 = {},
		param2 = {},
		metadata = nil
	}

	local timers = {}

	-- loop over all blocks and fill cid,param1 and param2
	for z=pos1.z,pos2.z do
		for y=pos1.y,pos2.y do
			for x=pos1.x,pos2.x do
				local i = area:index(x,y,z)

				local node_id = node_data[i]
				if node_id == ignore_content_id then
					-- replace ignore blocks with air
					node_id = air_content_id
				end

				if air_only and node_id ~= air_content_id then
					-- mapblock contains not jut air
					air_only = false
				end

				if node_ids_with_timer[node_id] then
					-- node has a node-timer
					local pos = {x=x, y=y, z=z}
					local timer = minetest.get_node_timer(pos)
					local relative_pos = vector.subtract(pos, pos1)
					if timer:is_started() then
						timers[minetest.pos_to_string(relative_pos)] = {
							timeout = timer:get_timeout(),
							elapsed = math.floor(timer:get_elapsed()) -- truncate decimals
						}
					end
				end

				table.insert(data.node_ids, node_id)
				table.insert(data.param1, param1[i])
				table.insert(data.param2, param2[i])

				node_id_map[node_id] = true
			end
		end
	end

	-- gather node id mapping
	for node_id in pairs(node_id_map) do
		local node_name = minetest.get_name_from_content_id(node_id)
		node_mapping[node_name] = node_id
	end

	-- serialize metadata
	local pos_with_meta = minetest.find_nodes_with_meta(pos1, pos2)
	for _, mpos in ipairs(pos_with_meta) do
		local relative_pos = vector.subtract(mpos, pos1)
		local meta = minetest.get_meta(mpos):to_table()

		-- Convert metadata item stacks to item strings
		for _, invlist in pairs(meta.inventory) do
			for index = 1, #invlist do
				local itemstack = invlist[index]
				if itemstack.to_string then
					invlist[index] = itemstack:to_string()
				end
			end
		end

		-- re-check if metadata actually exists (may happen with minetest.find_nodes_with_meta)
		if not is_empty(meta.fields) or not is_empty(meta.inventory) then
			data.metadata = data.metadata or {}
			data.metadata.meta = data.metadata.meta or {}
			data.metadata.meta[minetest.pos_to_string(relative_pos)] = meta
		end

		if not is_empty(timers) then
			data.metadata = data.metadata or {}
			data.metadata.timers = timers
		end
	end

	return data, air_only
end

--- serialize a mapblock to a file
-- @param mapblock_pos @{util.mapblock_pos} the mapblock position
-- @string filename the file to save to
function mapblock_lib.serialize(mapblock_pos, filename)
	local f = io.open(filename, "w")
	local z = mapblock_lib.mtzip.zip(f)
	local node_mapping = {}
	local pos1, pos2 = mapblock_lib.get_mapblock_bounds_from_mapblock(mapblock_pos)
	local mapblock, air_only = mapblock_lib.serialize_part(pos1, pos2, node_mapping)

	if not air_only then
		z:add("mapblock.bin", mapblock_lib.write_mapblock(mapblock))
	end

	local manifest = {
		node_mapping = node_mapping,
		air_only = air_only,
		metadata = mapblock.metadata,
		version = 2
	}

	z:add("manifest.json", minetest.write_json(manifest))
	z:close()
	f:close()
end

------
-- Serialize multi options
-- @number delay for async mode: delay between serialization-calls
-- @field callback function to call when the blocks are serialized
-- @field progress_callback function to call when the progress is update
-- @table serialize_multi_options

--- serialize multiple mapblocks to a file
-- @param pos1 @{util.node_pos} the first (lower) mapblock position
-- @param pos2 @{util.node_pos} the second (upper) mapblock position
-- @string filename the filename to save to
-- @param options[opt] @{serialize_multi_options} multi-serialization options
function mapblock_lib.serialize_multi(pos1, pos2, filename, options)
	local f = io.open(filename, "w")
	local z = mapblock_lib.mtzip.zip(f)

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
			local nodepos1, nodepos2 = mapblock_lib.get_mapblock_bounds_from_mapblock(mapblock_pos)
			local node_mapping = {}
			local mapblock, air_only = mapblock_lib.serialize_part(nodepos1, nodepos2, node_mapping)

			if not air_only then
				z:add("mapblock_" .. minetest.pos_to_string(rel_pos) .. ".bin", mapblock_lib.write_mapblock(mapblock))
			end

			local manifest = {
				node_mapping = node_mapping,
				air_only = air_only,
				metadata = mapblock.metadata,
				version = 2
			}
			z:add("mapblock_" .. minetest.pos_to_string(rel_pos) .. ".meta.json", minetest.write_json(manifest))

			count = count + 1
			options.progress_callback(count / total_count)
			minetest.after(options.delay, worker)
		else
			-- done, write manifest
			local manifest = {
				range = vector.subtract(pos2, pos1),
				version = 2
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