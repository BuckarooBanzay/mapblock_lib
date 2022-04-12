minetest.log("warning", "[TEST] integration-test enabled!")
minetest.register_on_mods_loaded(function()
  -- defer emerging until stuff is settled
  minetest.after(1, function()
    -- exit gracefully
    minetest.request_shutdown("success")
  end)
end)
