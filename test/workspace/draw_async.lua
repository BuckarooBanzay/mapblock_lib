local fn1 = function(c) c:translate(0,0,0):set_node() end
local fn2 = function(c) c:translate(1,0,0):set_node() end
local fn3 = function(c) c:translate(2,0,0):set_node() end

return function(ctx)
    ctx
    :with("default:mese")
    :execute(fn1)
    :execute(fn2)
    :execute(fn3)
end