
local function update_formspec(meta)
    local group = meta:get_string("group")
    -- TODO

    meta:set_string("formspec", [[
        size[10,8.3]
        real_coordinates[true]
        field[0.1,0.4;8.8,0.8;group;Group;]] .. group .. [[]
        button_exit[9,0.4;0.9,0.8;set;Set]
        list[context;main;0.1,1.4;8,1;]
        list[current_player;main;0.1,3;8,4;]
        listring[]
    ]])
end

minetest.register_node("mapblock_lib:metadata", {
	description = "Mapblock-lib metadata marker",
	tiles = {"mapblock_lib_metadata.png^[colorize:#23c1cc"},
    drawtype = "allfaces",
    use_texture_alpha = "blend",
    paramtype = "light",
    paramtype2 = "facedir",
    sunlight_propagates = true,
	groups = {
		oddly_breakable_by_hand = 3
	},

	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
        update_formspec(meta)
	end,

    on_receive_fields = function(pos, _, fields)
        if fields.set then
            local meta = minetest.get_meta(pos)
            meta:set_string("group", fields.group)
            update_formspec(meta)
        end
    end
})
