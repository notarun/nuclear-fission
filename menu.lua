local flux = require("3rd.flux.flux")
local lume = require("3rd.lume.lume")

local Color = require("color")
local core = require("core")
local drw = require("draw")
local fn = require("fn")
local input = require("input")
local res = require("res")

local entities = {}
local lg, lm, le = love.graphics, love.mouse, love.event

local function Heading()
  local title, nColor = "nuclear fission", Color.LavenderIndigo

  local txt = lg.newText(res.font.lg, title)
  local nc, nm = nColor, 0.1

  local function update(_, ctx)
    local vw, vh = lg.getDimensions()
    ctx.w, ctx.h = txt:getDimensions()
    ctx.x, ctx.y = (vw - ctx.w) / 2, (vh - ctx.h) / 3
  end

  local function draw(ctx)
    drw.neutron(ctx.x + ctx.w - 10, ctx.y, nc, nm)
    drw.neutron(ctx.x + ctx.w, ctx.y + 10, nc, nm)
    drw.neutron(ctx.x + ctx.w + 10, ctx.y, nc, nm)

    lg.setColor(Color.CookiesAndCream)
    lg.draw(txt, ctx.x, ctx.y)
  end

  return core.Entity({ update = update, draw = draw })
end

local function PlayButton()
  local label, color = "pass & play", Color.LavenderIndigo

  local txt = lg.newText(res.font.md, label)
  local tx, ty = 0, 0
  local zoom = { dw = 0, dh = 0 }

  local function update(_, ctx)
    local vw, vh = lg.getDimensions()
    local tw, th = txt:getDimensions()

    ctx.w, ctx.h = (vw / 1.6) + zoom.dw, (th * 2.4) + zoom.dh
    ctx.x, ctx.y = (vw - ctx.w) / 2, (vh + ctx.h * 2) / 2

    tx, ty = ctx.x + (ctx.w - tw) / 2, ctx.y + (ctx.h - th) / 2

    local items = core.world:queryPoint(lm.getPosition())
    local hovering = lume.find(items, ctx.item) ~= nil

    if hovering and input:pressed("click") then
      flux
        .to(zoom, 0.2, { dw = -0.8, dh = -0.8 })
        :ease("backout")
        :oncomplete(function()
          local e = fn.entitiesWhereTag(entities, { "PlayerCount" })[1]
          core.goToScene("game", { players = e.ctx.playerCount })
        end)
    end
  end

  local function draw(ctx)
    lg.setColor(color)
    lg.rectangle("fill", ctx.x, ctx.y, ctx.w, ctx.h, 2)

    lg.setColor(Color.White)
    lg.draw(txt, tx, ty)
  end

  return core.Entity({
    update = update,
    draw = draw,
  })
end

local function PlayerCount()
  local txt = lg.newText(res.font.md, "2")
  local tx, ty, color = 0, 0, Color.ChineseBlack

  local function load(ctx)
    ctx.playerCount = 2
  end

  local function increment(ctx)
    ctx.playerCount = ctx.playerCount + 1
    if ctx.playerCount > 4 then ctx.playerCount = 4 end
  end

  local function decrement(ctx)
    ctx.playerCount = ctx.playerCount - 1
    if ctx.playerCount < 2 then ctx.playerCount = 2 end
  end

  local function update(_, ctx)
    local vw, vh = lg.getDimensions()
    local tw, th = txt:getDimensions()

    ctx.w, ctx.h = (vw / 1.6), (th * 2.4)
    ctx.x, ctx.y = (vw - ctx.w) / 2, (vh - ctx.h) / 2
    tx, ty = ctx.x + (ctx.w - tw) / 2, ctx.y + (ctx.h - th) / 2

    txt:set(ctx.playerCount)
  end

  local function draw(ctx)
    lg.setColor(color)
    lg.rectangle("fill", ctx.x, ctx.y, ctx.w, ctx.h)

    lg.setColor(Color.White)
    lg.draw(txt, tx, ty)
  end

  return core.Entity({
    tags = { "PlayerCount" },
    update = update,
    draw = draw,
    load = load,
    events = {
      increment = increment,
      decrement = decrement,
    },
  })
end

local function PlayerDecrement()
  local txt = lg.newText(res.font.md, "-")
  local tx, ty, color = 0, 0, Color.FireOpal

  local function update(_, ctx)
    local vw, vh = lg.getDimensions()
    local tw, th = txt:getDimensions()

    ctx.w, ctx.h = (vw / 8), (th * 2.4)
    ctx.x, ctx.y = (vw - ctx.w) / 4.6, (vh - ctx.h) / 2
    tx, ty = ctx.x + (ctx.w - tw) / 2, ctx.y + (ctx.h - th) / 2

    local items = core.world:queryPoint(lm.getPosition())
    local hovering = lume.find(items, ctx.item) ~= nil

    if hovering and input:pressed("click") then
      local e = fn.entitiesWhereTag(entities, { "PlayerCount" })[1]
      e.emit("decrement")
    end
  end

  local function draw(ctx)
    lg.setColor(color)
    lg.rectangle("fill", ctx.x, ctx.y, ctx.w, ctx.h)

    lg.setColor(Color.White)
    lg.draw(txt, tx, ty)
  end

  return core.Entity({ update = update, draw = draw })
end

local function PlayerIncrement()
  local txt = lg.newText(res.font.md, "+")
  local tx, ty, color = 0, 0, Color.FireOpal

  local function update(_, ctx)
    local vw, vh = lg.getDimensions()
    local tw, th = txt:getDimensions()

    ctx.w, ctx.h = (vw / 8), (th * 2.4)
    ctx.x, ctx.y = ((vw - ctx.w) / 4.6) + (vw / 1.6) - ctx.w, (vh - ctx.h) / 2
    tx, ty = ctx.x + (ctx.w - tw) / 2, ctx.y + (ctx.h - th) / 2

    local items = core.world:queryPoint(lm.getPosition())
    local hovering = lume.find(items, ctx.item) ~= nil

    if hovering and input:pressed("click") then
      local e = fn.entitiesWhereTag(entities, { "PlayerCount" })[1]
      e.emit("increment")
    end
  end

  local function draw(ctx)
    lg.setColor(color)
    lg.rectangle("fill", ctx.x, ctx.y, ctx.w, ctx.h)

    lg.setColor(Color.White)
    lg.draw(txt, tx, ty)
  end

  return core.Entity({ update = update, draw = draw })
end

local function Escape()
  local function update(_, _)
    if input:pressed("back") then le.quit(0) end
  end
  return core.Entity({ update = update })
end

return core.Scene({
  id = "menu",
  entities = entities,
  enter = function()
    lume.push(
      entities,
      Escape(),
      Heading(),
      PlayButton(),
      PlayerCount(),
      PlayerDecrement(),
      PlayerIncrement()
    )
  end,
  leave = function()
    lume.each(entities, function(e)
      e.ctx.dead = true
    end)
  end,
})
