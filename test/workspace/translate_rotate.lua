
local function simple_thing(ctx)
    ctx
    :with("default:mese")
    :set_node()

    -- "point" towards x with a white wool node
    ctx
    :translate(1,0,0)
    :with("wool:white")
    :set_node()
end

return function(ctx)
    ctx
    :rotate(0,90,0)
    :execute(simple_thing)
end

--[[

Original:
     .....
     .....
     ..MW.
     .....
    Z.....
     X->

Rotated by 90° around y-axis:
     .....
     .....
     ..M..
     ..W..
    Z.....
     X->

Expected result 90° around y-axis:
     .....
     .....
     .....
     ..M..
    Z..W..
     X->


--]]