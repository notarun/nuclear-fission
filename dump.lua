local lume = require("3rd.lume.lume")

local dump = {}

setmetatable(dump, {
  __call = function(_, val)
    print(lume.serialize(val))
  end,
})

return dump
