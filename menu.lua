local flux = require("3rd.flux.flux")
local lume = require("3rd.lume.lume")

local Color = require("color")
local core = require("core")
local drw = require("draw")
local input = require("input")
local res = require("res")

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

local function PlayButton(opt)
  core.validate({
    opt = { value = opt, type = "table" },
    ["opt.cb"] = { value = opt.cb, type = "function" },
    ["opt.color"] = { value = opt.color, type = "table" },
    ["opt.label"] = { value = opt.label, type = "string" },
  })

  local txt = lg.newText(res.font.md, opt.label)
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
      flux.to(zoom, 0.2, { dw = 6, dh = 6 }):ease("backout"):oncomplete(opt.cb)
    end
  end

  local function draw(ctx)
    lg.setColor(opt.color)
    lg.rectangle("fill", ctx.x, ctx.y, ctx.w, ctx.h, 2)

    lg.setColor(Color.White)
    lg.draw(txt, tx, ty)
  end

  return core.Entity({
    tags = { "button", opt.position },
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

return core.Scene({
  id = "menu",
  entities = entities,
  enter = function()
    lume.push(
      entities,
      Escape(),
      Heading("nuclear fission", Color.LavenderIndigo),
      PlayButton({
        label = "pass & play",
        cb = function()
          core.goToScene("game", { players = 2 })
        end,
        color = Color.LavenderIndigo,
      })
    )
  end,
  leave = function()
    lume.each(entities, function(e)
      e.ctx.dead = true
    end)
  end,
})
