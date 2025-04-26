local Color = require 'color'
local input = require 'input'

local lg, lm = love.graphics, love.mouse

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
  assert(type(title) == "string", "Invalid string `title`")
  assert(type(fn) == "function", "Invalid function `fn`")

  local hovering = false

  local font = lg.newFont(24)
  local text = lg.newText(font, title)

  local screenW, screenH = lg.getWidth(), lg.getHeight()

  local txtW, txtH = text:getWidth(), text:getHeight()
  local btnW, btnH = lg.getWidth() / 2, txtH * 2

  local btnX, btnY = (screenW - btnW) / 2, (screenH - btnH) / 2
  local txtX, txtY = btnX + (btnW - txtW) / 2, btnY + (btnH - txtH) / 2

  local function update()
    local mX, mY = lm.getPosition()
    hovering = (btnX <= mX and btnX + btnW >= mX) and (btnY <= mY and btnY + btnH >= mY)

    if hovering and input:pressed('click') then fn() end
  end

  local function draw()
    lg.setColor(hovering and Color.ElectricPurple or Color.VividSkyBlue)
    lg.rectangle("fill", btnX, btnY, btnW, btnH)

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
