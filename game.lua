local flux = require("3rd.flux.flux")
local lume = require("3rd.lume.lume")
local toast = require("3rd.toasts.lovelyToasts")

local core = require("core")
local drw = require("draw")
local fn = require("fn")
local input = require("input")
local state = require("state")

local lg, lm = love.graphics, love.mouse
local sf = string.format

local entities, coro, splitTime = {}, nil, 0.3

local function neutronsInCell(i, j)
  return lume.filter(entities, function(e)
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

local function Neutron(i, j, idx)
  local cell = state.cell(i, j)
  local color, vibeMag, moving = cell.ownedBy.color, 0, false

  local dirs = {
    { { 0, 0 }, { 0, 0 } },
    { { -10, 0 }, { 10, 0 } },
    { { -10, -4 }, { 0, 6 }, { 10, -4 } },
    { { -10, 0 }, { 0, -10 }, { 0, 10 }, { 10, 0 } },
  }

  local function vibrate(_, mag)
    vibeMag = mag
  end

  local function capture(_, by)
    color = state.player(by).player.color
  end

  local function split(ctx, pld, oncomplete)
    local n = pld.neighbors[idx]
    local cx, cy, cw, ch = cellPosAndSz(n.i, n.j)
    flux
      .to(ctx, splitTime, { x = cx + cw / 2, y = cy + ch / 2 })
      :ease("linear")
      :oncomplete(function()
        ctx.dead = true
        if oncomplete then oncomplete() end
      end)
    moving = true
  end

  local function load(ctx)
    local cx, cy, cw, ch = cellPosAndSz(i, j)
    ctx.x, ctx.y = cx + cw / 2, cy + ch / 2
  end

  local function update(_, ctx)
    if moving then return end

    load(ctx)

    local dir = dirs[cell.count] and dirs[cell.count][idx]
    if dir then
      ctx.x, ctx.y = ctx.x + dir[1], ctx.y + dir[2]
      color = cell.ownedBy.color
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
    events = { vibrate = vibrate, split = split, capture = capture },
  })
end

local function fuseOrSplitCb(ev, pld)
  local i, j = pld.self.i, pld.self.j
  local neutrons = neutronsInCell(i, j)

  if ev == "add" then
    lume.push(entities, Neutron(i, j, pld.idx))
  elseif ev == "capture" then
    fn.each(neutrons, "emit", "capture", pld.by)
  elseif ev == "split" then
    local active = #pld.neighbors

    local oncomplete = function()
      active = active - 1
      if active == 0 and coro and coroutine.status(coro) == "suspended" then
        coroutine.resume(coro)
      end
    end

    fn.each(neutrons, "emit", "split", pld, oncomplete)
    coroutine.yield()
  end
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
        coro = coroutine.create(function()
          state.fuseOrSplit(i, j, state.playing().idx, fuseOrSplitCb)
          state.nextMove()
        end)
        coroutine.resume(coro)
      end
    end

    local threshold = #state.cellNeighbors(i, j) - 1
    local magnitude = state.cell(i, j).count < threshold and 0 or 0.1
    fn.each(neutronsInCell(i, j), "emit", "vibrate", magnitude)
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
