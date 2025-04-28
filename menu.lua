local bump = require '3rd.bump.bump'
local lume = require '3rd.lume.lume'

local Color = require 'color'
local input = require 'input'

local lg, lm, wrld = love.graphics, love.mouse, bump.newWorld()

local function MenuTitle(title)
  assert(type(title) == "string", "Invalid string `title`")

  local fnt = lg.newFont(24)
  local txt = lg.newText(fnt, title)
  local screenW, screenH = lg.getWidth(), lg.getHeight()

  local x, y = (screenW - txt:getWidth()) / 2, (screenH - txt:getWidth()) / 2

  local function draw()
    lg.setColor(Color.CookiesAndCream)
    lg.draw(txt, x, y)
  end

  return { draw = draw }
end

local function MenuButton(title, fn)
  local this = {
    x = 0,
    y = 0,
    w = 0,
    h = 0,
  }

  assert(type(title) == "string", "Invalid string `title`")
  assert(type(fn) == "function", "Invalid function `fn`")

  local hovering = false
  local font = lg.newFont(24)
  local text = lg.newText(font, title)

  local screenW, screenH = lg.getWidth(), lg.getHeight()
  local txtW, txtH = text:getWidth(), text:getHeight()
  this.w, this.h = lg.getWidth() / 2, txtH * 2

  this.x, this.y = (screenW - this.w) / 2, (screenH - this.h) / 2
  local txtX, txtY = this.x + (this.w - txtW) / 2, this.y + (this.h - txtH) / 2

  wrld:add(this, this.x, this.y, this.w, this.h)

  local function update()
    local x, y = lm.getPosition()
    local items = wrld:queryPoint(x, y)
    hovering = lume.find(items, this) ~= nil
    if hovering and input:pressed('click') then fn() end
  end

  local function draw()
    lg.setColor(hovering and Color.ElectricPurple or Color.VividSkyBlue)
    lg.rectangle("fill", this.x, this.y, this.w, this.h)

    lg.setColor(hovering and Color.ChineseBlack or Color.BrightGray)
    lg.draw(text, txtX, txtY)
  end

  return { update = update, draw = draw }
end

local function MenuScene(goToGame)
  local entities = {
    MenuTitle("nuclear fission"),
    MenuButton("play", goToGame),
  }

  local function update(dt)
    for _, b in ipairs(entities) do
      if b.update then b.update(dt) end
    end
  end

  local function draw()
    for _, b in ipairs(entities) do
      if b.draw then b.draw() end
    end
  end

  return { update = update, draw = draw }
end

return MenuScene
