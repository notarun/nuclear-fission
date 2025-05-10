local lume = require("3rd.lume.lume")

local Color = require("color")
local GameScene = require("game")
local core = require("core")
local dh = require("draw")
local input = require("input")
local res = require("res")

local lg, lm = love.graphics, love.mouse

local function MenuTitle()
  local txt = lg.newText(res.font.lg, "nuclear fission")
  local nc, nm = Color.ElectricPurple, 0.1

  local function update(_, ctx)
    local vw, vh = lg.getDimensions()
    ctx.w, ctx.h = txt:getDimensions()
    ctx.x, ctx.y = (vw - ctx.w) / 2, (vh - ctx.h) / 3
  end

  local function draw(ctx)
    dh.neutron(ctx.x + ctx.w - 10, ctx.y, nc, nm)
    dh.neutron(ctx.x + ctx.w, ctx.y + 10, nc, nm)
    dh.neutron(ctx.x + ctx.w + 10, ctx.y, nc, nm)

    lg.setColor(Color.CookiesAndCream)
    lg.draw(txt, ctx.x, ctx.y)
  end

  return core.Entity({ update = update, draw = draw })
end

local function PNPButton(fn)
  local txt = lg.newText(res.font.md, "pass &\nplay")
  local hovering = false
  local tx, ty = 0, 0

  local function update(_, ctx)
    local vw, vh = lg.getDimensions()
    local tw, th = txt:getDimensions()

    ctx.w, ctx.h = vw / 4, th * 3
    ctx.x, ctx.y = (vw - ctx.w) / 4, (vh - ctx.h) / 2
    tx, ty = ctx.x + (ctx.w - tw) / 2, ctx.y + (ctx.h - th) / 1.2

    local items = core.world:queryPoint(lm.getPosition())
    hovering = lume.find(items, ctx.item) ~= nil
    if hovering and input:pressed("click") then fn() end
  end

  local function draw(ctx)
    lg.setColor(hovering and Color.VividSkyBlue or Color.ElectricPurple)
    lg.rectangle("fill", ctx.x, ctx.y, ctx.w, ctx.h, 8)

    lg.setColor(hovering and Color.ChineseBlack or Color.BrightGray)
    lg.draw(txt, tx, ty)
  end

  return core.Entity({ update = update, draw = draw })
end

local function PWFButton()
  local txt = lg.newText(res.font.md, "play\nonline")
  local tx, ty = 0, 0

  local function update(_, ctx)
    local vw, vh = lg.getDimensions()
    local tw, th = txt:getDimensions()

    ctx.w, ctx.h = vw / 4, th * 3
    ctx.x, ctx.y = (vw - ctx.w) / 1.34, (vh - ctx.h) / 2
    tx, ty = ctx.x + (ctx.w - tw) / 2, ctx.y + (ctx.h - th) / 1.2
  end

  local function draw(ctx)
    lg.setColor(Color.BrightGray)
    lg.rectangle("fill", ctx.x, ctx.y, ctx.w, ctx.h, 8)

    lg.setColor(Color.ChineseBlack)
    lg.draw(txt, tx, ty)
  end

  return core.Entity({ update = update, draw = draw })
end

return core.Scene({
  entities = {
    MenuTitle(),
    PWFButton(),
    PNPButton(function()
      core.scene:enter(GameScene)
    end),
  },
  enter = function() end,
  leave = function() end,
})
