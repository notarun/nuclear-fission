local flux = require("3rd.flux.flux")
local lume = require("3rd.lume.lume")

local Color = require("color")
local core = require("core")
local fn = require("fn")
local input = require("input")
local res = require("res")

local lm, lg = love.mouse, love.graphics

--- @class ButtonOpts
--- @field w integer
--- @field h integer
--- @field mode "fill" | "line"
--- @field label string
--- @field color table
--- @field txtColor table
--- @field onclick function
--- @field z number
--- @field updatePos function

--- @param opt ButtonOpts
return function(opt)
  opt.mode = opt.mode or "fill"
  opt.txtColor = lume.clone(opt.txtColor or Color.White)
  opt.color = lume.clone(opt.color or Color.LavenderIndigo)
  opt.font = opt.font or res.font.md
  opt.w, opt.h = 152, 50
  opt.r = 4

  core.validate({
    ["opt.w"] = { value = opt.w, type = "number" },
    ["opt.h"] = { value = opt.h, type = "number" },
    ["opt.color"] = { value = opt.color, type = "table" },
    ["opt.label"] = { value = opt.label, type = "string" },
    ["opt.onclick"] = { value = opt.onclick, type = "function" },
    ["opt.updatePos"] = { value = opt.updatePos, type = "function" },
  })

  return core.Entity({
    z = opt.z,
    load = function(ctx)
      ctx.opacity = 1

      ctx.txt = lg.newText(opt.font, opt.label)

      ctx.x, ctx.y = 1, 1
      ctx.animation = { dty = 0, duration = 0.1 }
    end,
    update = function(_, ctx)
      opt.updatePos(ctx, opt)

      ctx.w, ctx.h = opt.w, opt.h
      local tw, th = ctx.txt:getDimensions()
      ctx.tx, ctx.ty = ctx.x + (ctx.w - tw) / 2, ctx.y + (ctx.h - th) / 2
      ctx.ty = ctx.ty + ctx.animation.dty

      local mx, my = lm.getPosition()
      local hovering = fn.checkCollision(mx, my, ctx.x, ctx.y, ctx.w, ctx.h)

      if hovering and input:pressed("click") then
        flux
          .to(ctx.animation, ctx.animation.duration, { dty = ctx.h / 24 })
          :oncomplete(opt.onclick)
          :after(ctx.animation, ctx.animation.duration, { dty = 0 })
      end
    end,
    draw = function(ctx)
      opt.color[4] = ctx.opacity
      lg.setColor(opt.color)
      lg.rectangle(opt.mode, ctx.x, ctx.y, ctx.w, ctx.h, 4)

      opt.txtColor[4] = ctx.opacity
      lg.setColor(opt.txtColor)
      lg.draw(ctx.txt, ctx.tx, ctx.ty)
    end,
  })
end
