local Color = require("color")
local core = require("core")

local lg, lm = love.graphics, love.math

return {
  neutron = function(x, y, color, vibeMag)
    vibeMag = vibeMag or 0

    core.validate({
      x = { value = x, type = "number" },
      y = { value = y, type = "number" },
      color = { value = color, type = "table" },
      vibeMag = { value = vibeMag, type = "number" },
    })

    local dx, dy = lm.random(-vibeMag, vibeMag), lm.random(-vibeMag, vibeMag)

    lg.setColor(color)
    lg.circle("fill", x + dx, y + dy, 18)
    lg.setColor(Color.White)
    lg.setLineWidth(1)
    lg.circle("line", x + dx, y + dy, 18)
  end,
}
