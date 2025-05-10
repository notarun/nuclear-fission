local lume = require("3rd.lume.lume")

local Color = require("color")
local core = require("core")
local input = require("input")
local res = require("res")

local lg, lm, lc = love.graphics, love.mouse, love.math

local function MenuTitle()
  local txt = lg.newText(res.font.lg, "nuclear fission")

  local function drawNeutron(x, y)
    local mag = 0.1
    local dx, dy = lc.random(-mag, mag), lc.random(-mag, mag)

    lg.setColor(Color.ElectricPurple)
    lg.circle("fill", x + dx, y + dy, 18)
    lg.setColor(Color.White)
    lg.setLineWidth(1)
    lg.circle("line", x + dx, y + dy, 18)
  end

  local function update(_, it)
    local vw, vh = lg.getDimensions()
    it.w, it.h = txt:getDimensions()
    it.x, it.y = (vw - it.w) / 2, (vh - it.h) / 3
  end

  local function draw(it)
    drawNeutron(it.x + it.w - 10, it.y)
    drawNeutron(it.x + it.w, it.y + 10)
    drawNeutron(it.x + it.w + 10, it.y)

    lg.setColor(Color.CookiesAndCream)
    lg.draw(txt, it.x, it.y)
  end

  return core.Entity({ update = update, draw = draw })
end

local function PNPButton(fn)
  local txt = lg.newText(res.font.md, "pass &\nplay")
  local hovering = false
  local tx, ty = 0, 0

  local function update(_, it)
    local vw, vh = lg.getDimensions()
    local tw, th = txt:getDimensions()

    it.w, it.h = vw / 4, th * 3
    it.x, it.y = (vw - it.w) / 4, (vh - it.h) / 2
    tx, ty = it.x + (it.w - tw) / 2, it.y + (it.h - th) / 1.2

    local items = core.world:queryPoint(lm.getPosition())
    hovering = lume.find(items, it.itm) ~= nil
    if hovering and input:pressed("click") then fn() end
  end

  local function draw(it)
    lg.setColor(hovering and Color.VividSkyBlue or Color.ElectricPurple)
    lg.rectangle("fill", it.x, it.y, it.w, it.h, 8)

    lg.setColor(hovering and Color.ChineseBlack or Color.BrightGray)
    lg.draw(txt, tx, ty)
  end

  return core.Entity({ update = update, draw = draw })
end

local function PWFButton()
  local txt = lg.newText(res.font.md, "play\nonline")
  local tx, ty = 0, 0

  local function update(_, it)
    local vw, vh = lg.getDimensions()
    local tw, th = txt:getDimensions()

    it.w, it.h = vw / 4, th * 3
    it.x, it.y = (vw - it.w) / 1.34, (vh - it.h) / 2
    tx, ty = it.x + (it.w - tw) / 2, it.y + (it.h - th) / 1.2
  end

  local function draw(it)
    lg.setColor(Color.BrightGray)
    lg.rectangle("fill", it.x, it.y, it.w, it.h, 8)

    lg.setColor(Color.ChineseBlack)
    lg.draw(txt, tx, ty)
  end

  return core.Entity({ update = update, draw = draw })
end

return function(goToGame)
  local entities = {}
  lume.push(
    entities,
    MenuTitle(),
    PWFButton(),
    PNPButton(function()
      goToGame()
      lume.clear(entities)
      core.world:clear()
    end)
  )

  return core.Scene(entities)
end
