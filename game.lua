local lume = require("3rd.lume.lume")
local toast = require("3rd.toasts.lovelyToasts")

local Color = require("color")
local core = require("core")
local drw = require("draw")
local input = require("input")
local state = require("state")

local lg, lm = love.graphics, love.mouse

local function Neutron(cellCtx, data)
  local cell = state.cell(data.self.i, data.self.j)
  local color, vibeMag, splitting = cell.ownedBy.color, 0, false

  local function vibrate(mag)
    vibeMag = mag
  end

  local function split(pld)
    require("dump")(pld)
  end

  local function update(_, ctx)
    ctx.x, ctx.y = cellCtx.x + cellCtx.w / 2, cellCtx.y + cellCtx.h / 2

    if not splitting then
      if cell.count == 2 then
        if data.idx == 1 then
          ctx.x = ctx.x - 10
        elseif data.idx == 2 then
          ctx.x = ctx.x + 10
        end
      elseif cell.count == 3 then
        if data.idx == 1 then
          ctx.x = ctx.x - 10
        elseif data.idx == 2 then
          ctx.y = ctx.y + 10
        elseif data.idx == 3 then
          ctx.x = ctx.x + 10
        end
        ctx.y = ctx.y - 4
      end
    end

    color = cell.ownedBy and cell.ownedBy.color or Color.White
  end

  local function draw(ctx)
    drw.neutron(ctx.x, ctx.y, color, vibeMag)
  end

  return core.Entity({
    update = update,
    draw = draw,
    events = { vibrate = vibrate, split = split },
  })
end

local function Cell(i, j)
  local rows, cols = state.matrixDimensions()
  local neutrons = {}

  local function fuseOrSplit(ctx)
    state.fuseOrSplit(i, j, state.playing().idx, function(ev, pld)
      if ev == "add" then
        lume.push(neutrons, Neutron(ctx, pld))
      elseif ev == "split" then
        lume.each(neutrons, "emit", "split", pld)
      end
    end)
  end

  local function update(dt, ctx)
    local winner = state.winner()
    if winner then core.goToScene("menu", { mode = "result" }) end

    local vw, vh = lg.getDimensions()
    ctx.w, ctx.h = vw / cols, vh / rows
    ctx.x, ctx.y = (j - 1) * ctx.w, (i - 1) * ctx.h

    local items = core.world:queryPoint(lm.getPosition())
    local hovering = lume.find(items, ctx.item) ~= nil

    if hovering and input:pressed("click") then
      local owner, playing = state.cell(i, j).owner, state.playing().idx

      if owner and owner ~= playing then
        toast.show("This cell is owned by other player")
      else
        fuseOrSplit(ctx)
        state.nextMove()
      end

      local threshold = #state.cellNeighbors(i, j) - 1
      local magnitude = state.cell(i, j).count < threshold and 0 or 0.1
      lume.each(neutrons, "emit", "vibrate", magnitude)
    end

    lume.each(neutrons, "update", dt)
  end

  local function draw(ctx)
    local c = state.cell(i, j)
    local str = string.format("o%s\nc%s", c.owner or "", c.count)
    lg.setColor(Color.CookiesAndCream)
    lg.print(str, ctx.x, ctx.y)

    lg.setColor(state.playing().player.color)
    lg.rectangle("line", ctx.x, ctx.y, ctx.w, ctx.h)
    lume.each(neutrons, "draw")
  end

  return core.Entity({ update = update, draw = draw })
end

return (function()
  local entities = {}

  return core.Scene({
    id = "game",
    entities = entities,
    enter = function()
      state.init(12, 6, 2)
      local rows, cols = state.matrixDimensions()
      for i = 1, rows do
        for j = 1, cols do
          lume.push(entities, Cell(i, j))
        end
      end
    end,
    leave = function()
      lume.clear(entities)
    end,
  })
end)()
