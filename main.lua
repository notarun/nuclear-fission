local Color = require("color")
local GameScene = require("game")
local MenuScene = require("menu")
local input = require("input")

local scene

function love.load()
  scene = MenuScene(function()
    scene = GameScene()
  end)
end

function love.update(dt)
  input:update()
  if scene.update then scene.update(dt) end
end

function love.draw()
  love.graphics.setBackgroundColor(Color.ChineseBlack)
  if scene.draw then scene:draw() end
end
