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
    it.props.w, it.props.h = txt:getDimensions()
    it.props.x, it.props.y = (vw - it.props.w) / 2, (vh - it.props.h) / 3
  end

  local function draw(it)
    drawNeutron(it.props.x + it.props.w - 10, it.props.y)
    drawNeutron(it.props.x + it.props.w, it.props.y + 10)
    drawNeutron(it.props.x + it.props.w + 10, it.props.y)

    lg.setColor(Color.CookiesAndCream)
    lg.draw(txt, it.props.x, it.props.y)
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

    it.props.w, it.props.h = vw / 4, th * 3
    it.props.x, it.props.y = (vw - it.props.w) / 4, (vh - it.props.h) / 2
    tx, ty =
      it.props.x + (it.props.w - tw) / 2, it.props.y + (it.props.h - th) / 1.2

    local items = it.world:queryPoint(lm.getPosition())
    hovering = lume.find(items, it) ~= nil
    if hovering and input:pressed("click") then fn() end
  end

  local function draw(it)
    lg.setColor(hovering and Color.VividSkyBlue or Color.ElectricPurple)
    lg.rectangle("fill", it.props.x, it.props.y, it.props.w, it.props.h, 8)

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

    it.props.w, it.props.h = vw / 4, th * 3
    it.props.x, it.props.y = (vw - it.props.w) / 1.34, (vh - it.props.h) / 2
    tx, ty =
      it.props.x + (it.props.w - tw) / 2, it.props.y + (it.props.h - th) / 1.2
  end

  local function draw(it)
    lg.setColor(Color.BrightGray)
    lg.rectangle("fill", it.props.x, it.props.y, it.props.w, it.props.h, 8)

    lg.setColor(Color.ChineseBlack)
    lg.draw(txt, tx, ty)
  end

  return core.Entity({ update = update, draw = draw })
end

return function(goToGame)
  return core.Scene({
    MenuTitle(),
    PNPButton(goToGame),
    PWFButton(),
  })
end
