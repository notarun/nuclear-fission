local baton = require("3rd.baton.baton")

return baton.new({
  controls = {
    click = { "mouse:1" },
    back = { "key:escape" },
    debug = { "key:d" },
  },
})
