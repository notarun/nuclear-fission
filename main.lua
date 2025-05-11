local flux = require("3rd.flux.flux")
local toast = require("3rd.toasts.lovelyToasts")

local Color = require("color")
local core = require("core")
local input = require("input")
local res = require("res")

function love.load()
  toast.style.font = res.font.md
  toast.style.backgroundColor = Color.ChineseBlack
  toast.options.animationDuration = 0.1

  require("menu")
  require("game")

  core.goToScene("menu")
end

function love.update(dt)
  flux.update(dt)
  input:update()
  toast.update(dt)
  core.scene().update(dt)
end

function love.draw()
  love.graphics.setBackgroundColor(Color.ChineseBlack)
  core.scene().draw()
  toast.draw()
end
