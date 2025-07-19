_G.NF_DEBUG = false
_G.NF_VERSION = love.filesystem.read(".version")

local flux = require("3rd.flux.flux")
local toast = require("3rd.toasts.lovelyToasts")

local Color = require("color")
local core = require("core")
local input = require("input")
local res = require("res")

require("menu")
require("game")

function love.load()
  input:register()

  toast.style.font = res.font.md
  toast.style.backgroundColor = Color.ChineseBlack
  toast.options.animationDuration = 0.1

  core.goToScene("menu")
end

function love.update(dt)
  flux.update(dt)
  toast.update(dt)
  core.scene().update(dt)
  if input:pressed("d") then _G.NF_DEBUG = not _G.NF_DEBUG end
  input:update()
end

function love.draw()
  love.graphics.setBackgroundColor(Color.ChineseBlack)
  core.scene().draw()
  toast.draw()
end
