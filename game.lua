local flux = require("3rd.flux.flux")
local lume = require("3rd.lume.lume")
local toast = require("3rd.toasts.lovelyToasts")

local core = require("core")
local drw = require("draw")
local input = require("input")
local state = require("state")

local lg, lm = love.graphics, love.mouse
local sf = string.format

local entities = {}

local function neutronsInCell(i, j)
  return lume.chain(entities):filter(function(e)
    local isNeutron = lume.find(e.ctx.tags, "neutron")
    local inSameCell = lume.find(e.ctx.tags, sf("%s-%s", i, j))
    return isNeutron and inSameCell
  end)
end

local function cellPosAndSz(i, j)
  local rows, cols = state.matrixDimensions()
  local vw, vh = lg.getDimensions()
  local w, h = vw / cols, vh / rows
  local x, y = (j - 1) * w, (i - 1) * h

  return x, y, w, h
end

local function Neutron(data)
  local i, j = data.self.i, data.self.j
  local cell = state.cell(i, j)
  local color, vibeMag, goalPos = cell.ownedBy.color, 0, {}

  local dirs = {
    { { 0, 0 }, { 0, 0 } },
    { { -10, 0 }, { 10, 0 } },
    { { -10, -4 }, { 0, 6 }, { 10, -4 } },
    { { -10, 0 }, { 0, -10 }, { 0, 10 }, { 10, 0 } },
  }

  local function vibrate(mag)
    vibeMag = mag
  end

  local function split(pld)
    local n = pld.neighbors[data.idx]
    local cx, cy, cw, ch = cellPosAndSz(n.i, n.j)
    goalPos.x, goalPos.y = cx + cw / 2, cy + ch / 2
  end

  local function load(ctx)
    local cx, cy, cw, ch = cellPosAndSz(i, j)
    ctx.x, ctx.y = cx + cw / 2, cy + ch / 2
  end

  local function update(_, ctx)
    if goalPos.x and goalPos.y then
      flux.to(ctx, 0.1, goalPos):ease("linear"):oncomplete(function()
        ctx.dead = true
      end)
    else
      load(ctx)

      local dir = dirs[cell.count] and dirs[cell.count][data.idx]
      if dir then
        ctx.x, ctx.y = ctx.x + dir[1], ctx.y + dir[2]
        color = cell.ownedBy.color
      end
    end
  end

  local function draw(ctx)
    drw.neutron(ctx.x, ctx.y, color, vibeMag)
  end

  return core.Entity({
    load = load,
    draw = draw,
    update = update,
    tags = { "neutron", sf("%s-%s", i, j) },
    events = { vibrate = vibrate, split = split },
  })
end

local function fuseOrSplit(i, j)
  state.fuseOrSplit(i, j, state.playing().idx, function(ev, pld)
    if ev == "add" then
      lume.push(entities, Neutron(pld))
    elseif ev == "split" then
      neutronsInCell(i, j):each("emit", "split", pld)
    end
  end)
end

local function Cell(i, j)
  local function update(_, ctx)
    local winner = state.winner()
    if winner then core.goToScene("menu", { mode = "result" }) end

    ctx.x, ctx.y, ctx.w, ctx.h = cellPosAndSz(i, j)

    local items = core.world:queryPoint(lm.getPosition())
    local hovering = lume.find(items, ctx.item) ~= nil

    if hovering and input:pressed("click") then
      local owner, playing = state.cell(i, j).owner, state.playing().idx

      if owner and owner ~= playing then
        toast.show("This cell is owned by other player")
      else
        fuseOrSplit(i, j)
        state.nextMove()
      end
    end

    local threshold = #state.cellNeighbors(i, j) - 1
    local magnitude = state.cell(i, j).count < threshold and 0 or 0.1
    neutronsInCell(i, j):each("emit", "vibrate", magnitude)
  end

  local function draw(ctx)
    lg.setColor(state.playing().player.color)
    lg.rectangle("line", ctx.x, ctx.y, ctx.w, ctx.h)
  end

  return core.Entity({ update = update, draw = draw })
end

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
