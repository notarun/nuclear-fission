local flux = require("3rd.flux.flux")
local lume = require("3rd.lume.lume")
local toast = require("3rd.toasts.lovelyToasts")

local Color = require("color")
local core = require("core")
local drw = require("draw")
local input = require("input")
local res = require("res")
local state = require("state")

local debugMode = os.getenv("DEBUG") == "true"
local lg, lm = love.graphics, love.mouse
local sf = string.format

local entities = {}
local animating, animationTime = false, 0.2

local function entitiesWhereTag(tags)
  return lume.filter(entities, function(e)
    return lume.all(tags, function(tag)
      return lume.find(e.ctx.item.tags, tag)
    end)
  end)
end

local function splitAll(nextMove, onWin)
  core.validate({
    nextMove = { value = nextMove, type = "function" },
    onWin = { value = onWin, type = "function" },
  })

  animating = true

  if state.winner() then
    animating = false
    onWin()
    return
  end

  local splittables = state.splittables()
  if #splittables == 0 then
    animating = false
    nextMove()
    return
  end

  for _, s in ipairs(splittables) do
    local e = entitiesWhereTag({ "neutrons", sf("cell:%s-%s", s.i, s.j) })[1]
    e.emit("split", s.neighbors)
  end

  flux.to({}, animationTime + (animationTime / 2), {}):oncomplete(function()
    splitAll(nextMove, onWin)
  end)
end

local function cellPosAndSz(i, j)
  local rows, cols = state.matrixDimensions()
  local vw, vh = lg.getDimensions()
  local w, h = vw / cols, vh / rows
  local x, y = (j - 1) * w, (i - 1) * h

  return x, y, w, h
end

local function Neutrons(i, j)
  local vibration, color = false, nil
  local count, neutrons = 0, {}
  local offsets = {
    { { 0, 0 } },
    { { -10, 0 }, { 10, 0 } },
    { { -10, -4 }, { 0, 6 }, { 10, -4 } },
    { { -10, 0 }, { 0, -10 }, { 0, 10 }, { 10, 0 } },

    -- handles edge case where count can be greater than 4
    { { -10, 0 }, { 0, -10 }, { 0, 10 }, { 10, 0 }, { 0, 0 } },
  }

  local function load(ctx)
    local cx, cy, cw, ch = cellPosAndSz(i, j)
    ctx.x, ctx.y = cx + cw / 2, cy + ch / 2
    ctx.w, ctx.h = 18, 18
  end

  local function arrangeNeutrons(ctx)
    local cell = state.cell(i, j)

    if count ~= cell.count then
      count = cell.count
      lume.clear(neutrons)
      for idx = 1, count do
        local offset = offsets[count][idx]
        neutrons[idx] = { x = ctx.x + offset[1], y = ctx.y + offset[2] }
      end
    end
  end

  local function split(ctx, neighbors)
    arrangeNeutrons(ctx)
    res.sound.split:play()

    for idx, n in ipairs(neighbors) do
      local cx, cy, cw, ch = cellPosAndSz(n.i, n.j)
      local tx, ty = cx + cw / 2, cy + ch / 2
      flux
        .to(neutrons[idx], animationTime, { x = tx, y = ty })
        :oncomplete(function()
          state.fuse(n.i, n.j, state.playing().idx)
          state.defuse(i, j)
        end)
    end
  end

  local function update(_, ctx)
    arrangeNeutrons(ctx)
    local cell = state.cell(i, j)
    if cell.ownedBy then color = cell.ownedBy.color end
    local threshold = #state.cellNeighbors(i, j) - 1
    vibration = count < threshold and 0 or 0.1
  end

  local function draw(_)
    for idx, n in ipairs(neutrons) do
      drw.neutron(n.x, n.y, color, vibration)
      if debugMode then
        local txt = sf("%s/%s\n%s:%s", idx, #neutrons, i, j)
        lg.setColor(Color.White)
        lg.print(txt, n.x - 18 / 2, n.y - 18 / 2)
      end
    end
  end

  return core.Entity({
    load = load,
    draw = draw,
    update = update,
    events = { split = split },
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
        splitAll(state.nextMove, function()
          core.goToScene("menu", { mode = "result" })
        end)
      end
    end
  end

  local function draw(ctx)
    lg.setColor(state.playing().player.color)
    lg.rectangle("line", ctx.x, ctx.y, ctx.w, ctx.h)
    if debugMode then
      local cell = state.cell(i, j)
      local text = sf("c%sp%s\n%s:%s", cell.count, cell.owner or "", i, j)
      lg.setColor(Color.White)
      lg.print(text, ctx.x, ctx.y)
    end
  end

  return core.Entity({ update = update, draw = draw })
end

local function Escape()
  local function update(_, _)
    if input:pressed("back") then
      core.goToScene("menu", { mode = "home" })
    end
  end
  return core.Entity({ update = update })
end

return core.Scene({
  id = "game",
  entities = entities,
  enter = function()
    lume.push(entities, Escape())
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
