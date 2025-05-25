local flux = require("3rd.flux.flux")
local lume = require("3rd.lume.lume")

local Color = require("color")
local core = require("core")
local drw = require("draw")
local fn = require("fn")
local input = require("input")
local res = require("res")
local state = require("state")

local entities = {}
local lg, lm, le = love.graphics, love.mouse, love.event

local function Heading(title, nColor)
  core.validate({
    title = { value = title, type = "string" },
    nColor = { value = nColor, type = "table" },
  })

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

local function LeftButton(label, cb)
  core.validate({
    label = { value = label, type = "string" },
    cb = { value = cb, type = "function" },
  })

  local txt = lg.newText(res.font.md, label)
  local tx, ty, hovering = 0, 0, false
  local zoom = { dw = 0, dh = 0 }

  local function update(_, ctx)
    local vw, vh = lg.getDimensions()
    local tw, th = txt:getDimensions()

    ctx.w, ctx.h = (vw / 4) + zoom.dw, (th * 3) + zoom.dh
    ctx.x, ctx.y = (vw - ctx.w) / 4, (vh - ctx.h) / 2
    tx, ty = ctx.x + (ctx.w - tw) / 2, ctx.y + (ctx.h - th) / 1.2

    local items = core.world:queryPoint(lm.getPosition())
    hovering = lume.find(items, ctx.item) ~= nil

    if hovering then
      flux.to(zoom, 0.1, { dw = 6, dh = 6 }):ease("backout")
      if input:pressed("click") then cb() end
    else
      flux.to(zoom, 0.1, { dw = 0, dh = 0 }):ease("backout")
    end
  end

  local function draw(ctx)
    lg.setColor(Color.LavenderIndigo)
    lg.rectangle("fill", ctx.x, ctx.y, ctx.w, ctx.h, 8)

    lg.setColor(Color.White)
    lg.draw(txt, tx, ty)
  end

  return core.Entity({ update = update, draw = draw })
end

local function RightButton(label, cb)
  core.validate({
    label = { value = label, type = "string" },
    cb = { value = cb, type = "function" },
  })

  local txt = lg.newText(res.font.md, label)
  local tx, ty, hovering = 0, 0, false
  local zoom = { dw = 0, dh = 0 }

  local function update(_, ctx)
    local vw, vh = lg.getDimensions()
    local tw, th = txt:getDimensions()

    ctx.w, ctx.h = (vw / 4) + zoom.dw, (th * 3) + zoom.dh
    ctx.x, ctx.y = (vw - ctx.w) / 1.34, (vh - ctx.h) / 2
    tx, ty = ctx.x + (ctx.w - tw) / 2, ctx.y + (ctx.h - th) / 1.2

    local items = core.world:queryPoint(lm.getPosition())
    hovering = lume.find(items, ctx.item) ~= nil

    if hovering then
      flux.to(zoom, 0.1, { dw = 6, dh = 6 }):ease("backout")
      if input:pressed("click") then cb() end
    else
      flux.to(zoom, 0.1, { dw = 0, dh = 0 }):ease("backout")
    end
  end

  local function draw(ctx)
    lg.setColor(Color.FireOpal)
    lg.rectangle("fill", ctx.x, ctx.y, ctx.w, ctx.h, 8)

    lg.setColor(Color.White)
    lg.draw(txt, tx, ty)
  end

  return core.Entity({ update = update, draw = draw })
end

local function PlayerCountSelector()
  local function update() end

  local function draw() end

  return core.Entity({
    tags = { "PlayerCountSelector" },
    update = update,
    draw = draw,
  })
end

local function Escape()
  local function update(_, _)
    if input:pressed("back") then le.quit(0) end
  end
  return core.Entity({ update = update })
end

return (function()
  local s = {
    heading = {
      title = "nuclear fission",
      nColor = Color.LavenderIndigo,
    },
    leftBtn = {
      label = "pass &\nplay",
      cb = function()
        local entityExists = #fn.entitiesWhereTag(
          entities,
          { "PlayerCountSelector" }
        ) == 1
        if not entityExists then lume.push(entities, PlayerCountSelector()) end
      end,
    },
    rightBtn = {
      label = "exit  \ngame",
      cb = function()
        le.quit(0)
      end,
    },
  }

  return core.Scene({
    id = "menu",
    entities = entities,
    enter = function(args)
      if args.mode == "result" then
        local winner = state.winner().player
        s.heading.title = string.format("%s won!", winner.label)
        s.heading.nColor = winner.color
        s.leftBtn.label = "play \nagain"
      else
        s.heading.title = "nuclear fission"
        s.heading.nColor = Color.LavenderIndigo
        s.leftBtn.label = "pass &\nplay"
      end

      lume.push(
        entities,
        Escape(),
        Heading(s.heading.title, s.heading.nColor),
        LeftButton(s.leftBtn.label, s.leftBtn.cb),
        RightButton(s.rightBtn.label, s.rightBtn.cb)
      )
    end,
    leave = function()
      lume.each(entities, function(e)
        e.ctx.dead = true
      end)
    end,
  })
end)()
