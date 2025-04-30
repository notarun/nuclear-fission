local inspect = require("3rd.inspect.inspect")

local dump = {}

setmetatable(dump, {
  __call = function(_, val)
    print(inspect(val))
  end,
})

return dump
