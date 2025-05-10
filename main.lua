local toast = require("3rd.toasts.lovelyToasts")

local Color = require("color")
local GameScene = require("game")
local MenuScene = require("menu")
local input = require("input")
local res = require("res")

local scene

function love.load()
  toast.style.font = res.font.md
  toast.style.backgroundColor = Color.ChineseBlack
  toast.options.animationDuration = 0.1

  scene = MenuScene(function()
    scene = GameScene()
  end)
end

function love.update(dt)
  input:update()
  toast.update(dt)
  if scene.update then scene.update(dt) end
end

function love.draw()
  love.graphics.setBackgroundColor(Color.ChineseBlack)
  if scene.draw then scene:draw() end
  toast.draw()
end
