local toast = require("3rd.toasts.lovelyToasts")

local Color = require("color")
local core = require("core")
local input = require("input")
local menu = require("menu")
local res = require("res")

function love.load()
  toast.style.font = res.font.md
  toast.style.backgroundColor = Color.ChineseBlack
  toast.options.animationDuration = 0.1

  core.scene:push(menu)
end

function love.update(dt)
  input:update()
  toast.update(dt)
  core.scene:emit("update", dt)
end

function love.draw()
  love.graphics.setBackgroundColor(Color.ChineseBlack)
  core.scene:emit("draw")
  toast.draw()
end
