local lume = require("3rd.lume.lume")

local Button = require("button")
local Color = require("color")
local core = require("core")
local drw = require("draw")
local input = require("input")
local res = require("res")
local state = require("state")

local entities = {}
local lg, le = love.graphics, love.event

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
  return Button({
    label = "pass & play",
    color = Color.LavenderIndigo,
    onclick = function()
      core.goToScene("game", { players = state.currentPlayerCount() })
    end,
    updatePos = function(ctx, opt)
      local vw, vh = lg.getDimensions()
      local _, th = ctx.txt:getDimensions()

      opt.w, opt.h = vw / 1.6, th * 2.4
      ctx.x, ctx.y = (vw - opt.w) / 2, (vh + opt.h * 2) / 2
    end,
  })
end

local function PlayerCount()
  local txt = lg.newText(res.font.md, "2")
  local tx, ty = 0, 0

  local function load(this)
    local decBtn = Button({
      label = "-",
      color = Color.FireOpal,
      onclick = function()
        local count = state.currentPlayerCount() - 1
        if count < 2 then
          state.currentPlayerCount(2)
        else
          state.currentPlayerCount(count)
        end
      end,
      updatePos = function(ctx, opt)
        local vw, _ = lg.getDimensions()
        local _, th = txt:getDimensions()
        opt.w, opt.h = (vw / 8), (th * 2.4)
        ctx.x, ctx.y = this.x, this.y
      end,
    })

    local incBtn = Button({
      label = "+",
      color = Color.FireOpal,
      onclick = function()
        local count = state.currentPlayerCount() + 1
        if count > 4 then
          state.currentPlayerCount(4)
        else
          state.currentPlayerCount(count)
        end
      end,
      updatePos = function(ctx, opt)
        local vw, _ = lg.getDimensions()
        local _, th = txt:getDimensions()
        opt.w, opt.h = (vw / 8), (th * 2.4)
        ctx.x, ctx.y = this.x + this.w - ctx.w, this.y
      end,
    })

    lume.push(entities, incBtn, decBtn)
  end

  local function update(_, ctx)
    local vw, vh = lg.getDimensions()
    local tw, th = txt:getDimensions()

    ctx.w, ctx.h = (vw / 1.6), (th * 2.4)
    ctx.x, ctx.y = (vw - ctx.w) / 2, (vh - ctx.h) / 2
    tx, ty = ctx.x + (ctx.w - tw) / 2, ctx.y + (ctx.h - th) / 2

    txt:set(state.currentPlayerCount())
  end

  local function draw(_)
    lg.setColor(Color.White)
    lg.draw(txt, tx, ty)
  end

  return core.Entity({
    update = update,
    draw = draw,
    load = load,
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
    lume.push(entities, Escape(), Heading(), PlayButton(), PlayerCount())
  end,
  leave = function()
    lume.each(entities, function(e)
      e.ctx.dead = true
    end)
  end,
})
