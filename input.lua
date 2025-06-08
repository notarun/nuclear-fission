return {
  _down = {},
  _pressed = {},

  _keypressed = function(self, key, _, isrepeat)
    if not isrepeat then
      self._down[key], self._pressed[key] = true, true
    end
  end,
  _keyreleased = function(self, key, _, _)
    self._down[key] = false
  end,
  _mousepressed = function(self, _, _, button)
    local key = "mouse" .. tostring(button)
    self._down[key], self._pressed[key] = true, true
  end,
  _mousereleased = function(self, _, _, button)
    local key = "mouse" .. tostring(button)
    self._down[key] = false
  end,

  register = function(self)
    local hooks =
      { "keypressed", "keyreleased", "mousepressed", "mousereleased" }

    for _, hook in ipairs(hooks) do
      local og = love[hook]
      local hdlr = self["_" .. hook]

      love[hook] = function(...)
        if og then og(...) end
        hdlr(self, ...)
      end
    end
  end,
  update = function(self)
    self._pressed, self._down = {}, {}
  end,
  pressed = function(self, key)
    return self._pressed[key] or false
  end,
  down = function(self, key)
    return self._down[key] or false
  end,
}
