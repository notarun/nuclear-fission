local flux = require("3rd.flux.flux")
local lume = require("3rd.lume.lume")
local toast = require("3rd.toasts.lovelyToasts")

local core = require("core")
local drw = require("draw")
local fn = require("fn")
local input = require("input")
local res = require("res")
local state = require("state")

local lg, lm = love.graphics, love.mouse
local sf = string.format

local entities = {}
local animating, f = false, nil
local speed = 2

local function entitiesWhereTag(tags)
  return lume.filter(entities, function(e)
    return lume.all(tags, function(tag)
      return lume.find(e.ctx.item.tags, tag)
    end)
  end)
end

local function populateAnimationQueue(oncomplete)
  local splittables = state.splittables()
  for _, s in ipairs(splittables) do
    local e = entitiesWhereTag({ "neutrons", sf("cell:%s-%s", s.i, s.j) })[1]
    if not e then goto continue end

    if not f then
      fn.dump(e.ctx)
      -- f = flux.to(e.ctx, 0.2, { w = 32, h = 32 })
    end

    ::continue::
  end

  oncomplete()
end

local function cellPosAndSz(i, j)
  local rows, cols = state.matrixDimensions()
  local vw, vh = lg.getDimensions()
  local w, h = vw / cols, vh / rows
  local x, y = (j - 1) * w, (i - 1) * h

  return x, y, w, h
end

local function Neutrons(i, j)
  local splitting, vibration = false, false
  local count, neutrons = 0, {}
  local offsets = {
    { { 0, 0 } },
    { { -10, 0 }, { 10, 0 } },
    { { -10, -4 }, { 0, 6 }, { 10, -4 } },
    { { -10, 0 }, { 0, -10 }, { 0, 10 }, { 10, 0 } },
  }
  local directions = { { 0, 10 }, { 10, 0 }, { 0, -10 }, { -10, 0 } }

  local function load(ctx)
    local cx, cy, cw, ch = cellPosAndSz(i, j)
    ctx.x, ctx.y = cx + cw / 2, cy + ch / 2
    ctx.w, ctx.h = 18, 18
  end

  -- local function split(ctx, onfinish)
  -- end

  local function update(dt, ctx)
    local cell = state.cell(i, j)

    if cell.ownedBy then ctx.color = cell.ownedBy.color end

    if count ~= cell.count then
      count = cell.count

      for idx = 1, count do
        local offset = offsets[count][idx]
        neutrons[idx] = { x = ctx.x + offset[1], y = ctx.y + offset[2] }
      end
    end

    local threshold = #state.cellNeighbors(i, j) - 1
    vibration = count < threshold and 0 or 0.1

    if splitting then
      for idx = 1, count do
        neutrons[idx].x = neutrons[idx].x + directions[idx].x * speed * dt
        neutrons[idx].y = neutrons[idx].y + directions[idx].y * speed * dt
      end
    end
  end

  local function draw(ctx)
    for _, n in ipairs(neutrons) do
      drw.neutron(n.x, n.y, ctx.color, vibration)
    end
  end

  return core.Entity({
    load = load,
    draw = draw,
    update = update,
    -- events = { split = split },
    tags = { "neutrons", sf("cell:%s-%s", i, j) },
  })
end

local function Cell(i, j)
  local function update(_, ctx)
    ctx.x, ctx.y, ctx.w, ctx.h = cellPosAndSz(i, j)

    local items = core.world:queryPoint(lm.getPosition())
    local hovering = lume.find(items, ctx.item) ~= nil

    if not animating and hovering and input:pressed("click") then
      local owner, playing = state.cell(i, j).owner, state.playing().idx

      if owner and owner ~= playing then
        toast.show("This cell is owned by other player")
      else
        state.fuse(i, j, state.playing().idx)
        populateAnimationQueue(state.nextMove)
      end
    end
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
        lume.push(entities, Cell(i, j), Neutrons(i, j))
      end
    end
  end,
  leave = function()
    lume.each(entities, function(e)
      e.ctx.dead = true
    end)
  end,
})
