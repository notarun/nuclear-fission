local flux = require("3rd.flux.flux")

local Color = require("color")
local core = require("core")
local fn = require("fn")
local input = require("input")
local res = require("res")

local lm, lg = love.mouse, love.graphics

--- @class ButtonOpts
--- @field w integer
--- @field h integer
--- @field label string
--- @field color table
--- @field onclick function
--- @field updatePos function

--- @param opt ButtonOpts
return function(opt)
  opt.color = opt.color or Color.LavenderIndigo
  opt.font = opt.font or res.font.md
  opt.w, opt.h = 140, 50
  opt.r = 4

  core.validate({
    ["opt.w"] = { value = opt.w, type = "number" },
    ["opt.h"] = { value = opt.h, type = "number" },
    ["opt.label"] = { value = opt.label, type = "string" },
    ["opt.color"] = { value = opt.color, type = "table" },
    ["opt.onclick"] = { value = opt.onclick, type = "function" },
    ["opt.updatePos"] = { value = opt.updatePos, type = "function" },
  })

  return core.Entity({
    load = function(ctx)
      ctx.txt = lg.newText(opt.font, opt.label)
      ctx.r = { value = opt.r }
      ctx.x, ctx.y = 1, 1
      ctx.animationTime = 0.2
    end,
    update = function(_, ctx)
      opt.updatePos(ctx, opt)

      ctx.w, ctx.h = opt.w, opt.h
      local tw, th = ctx.txt:getDimensions()
      ctx.tx, ctx.ty = ctx.x + (ctx.w - tw) / 2, ctx.y + (ctx.h - th) / 2

      local mx, my = lm.getPosition()
      local hovering = fn.checkCollision(mx, my, ctx.x, ctx.y, ctx.w, ctx.h)

      if hovering and input:pressed("click") then
        flux
          .to(ctx.r, ctx.animationTime, { value = 5.4 })
          :oncomplete(opt.onclick)
          :after(ctx.r, ctx.animationTime, { value = opt.r })
      end
    end,
    draw = function(ctx)
      lg.setColor(opt.color)
      lg.rectangle("fill", ctx.x, ctx.y, ctx.w, ctx.h, ctx.r.value)

      lg.setColor(Color.White)
      lg.draw(ctx.txt, ctx.tx, ctx.ty)
    end,
  })
end
