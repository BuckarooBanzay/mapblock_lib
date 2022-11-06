
mtt.register("mapblock_lib.localize_nodeids (all known)", function(callback)
    local node_mapping = {
        ["air"] = 0,
        ["default:stone"] = 1
    }
    local node_ids = {0,1}

    local all_nodes_known, unknown_nodes = mapblock_lib.localize_nodeids(node_mapping, node_ids)
    assert(all_nodes_known)
    assert(#unknown_nodes == 0)
    assert(node_ids[1] == minetest.get_content_id("air"))
    assert(node_ids[2] == minetest.get_content_id("default:stone"))

    callback()
end)


mtt.register("mapblock_lib.localize_nodeids (with unknown nodes)", function(callback)
    local node_mapping = {
        ["air"] = 0,
        ["default:node_not_found"] = 1
    }
    local node_ids = {0,1}

    local all_nodes_known, unknown_nodes = mapblock_lib.localize_nodeids(node_mapping, node_ids)
    assert(not all_nodes_known)
    assert(unknown_nodes[1] == "default:node_not_found")
    assert(node_ids[1] == minetest.get_content_id("air"))
    assert(node_ids[2] == minetest.get_content_id("air"))

    callback()
end)

minetest.register_alias("mapblock_lib:fancy_node", "default:gravel")

mtt.register("mapblock_lib.localize_nodeids (with alias)", function(callback)
    assert(minetest.registered_nodes["mapblock_lib:fancy_node"], "aliased node is in registered_nodes")

    local node_mapping = {
        ["air"] = 0,
        ["mapblock_lib:fancy_node"] = 1
    }
    local node_ids = {0,1}

    local all_nodes_known, unknown_nodes = mapblock_lib.localize_nodeids(node_mapping, node_ids)
    assert(all_nodes_known)
    assert(#unknown_nodes == 0)
    assert(node_ids[1] == minetest.get_content_id("air"))
    assert(node_ids[2] == minetest.get_content_id("default:gravel"))

    callback()
end)