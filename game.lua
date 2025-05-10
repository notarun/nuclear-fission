local lume = require("3rd.lume.lume")

local Color = require("color")
local core = require("core")
local input = require("input")
local state = require("state")

local lg, lm, lc = love.graphics, love.mouse, love.math

local function drawNeutron(x, y, color, vibeMag)
  core.validate({
    x = { value = x, type = "number" },
    y = { value = x, type = "number" },
    color = { value = color, type = "table" },
  })

  vibeMag = vibeMag or 0
  local dx, dy = lc.random(-vibeMag, vibeMag), lc.random(-vibeMag, vibeMag)

  lg.setColor(color)
  lg.circle("fill", x + dx, y + dy, 18)
  lg.setColor(Color.White)
  lg.setLineWidth(1)
  lg.circle("line", x + dx, y + dy, 18)
end

local function Cell(i, j)
  local rows, cols = state.matrixDimensions()

  local function update(_, ctx)
    local vw, vh = lg.getDimensions()
    ctx.w, ctx.h = vw / cols, vh / rows
    ctx.x, ctx.y = (j - 1) * ctx.w, (i - 1) * ctx.h

    local items = core.world:queryPoint(lm.getPosition())
    local hovering = lume.find(items, ctx.item) ~= nil

    if hovering and input:pressed("click") then
      local owner, playing = state.cell(i, j).owner, state.playing().idx
      if owner and owner ~= playing then
        print("THIS CELL IS OWNED BY OTHER PLAYER")
      else
        state.fuseOrSplit(i, j, playing)
        state.nextMove()
      end
    end
  end

  local function draw(ctx)
    lg.setColor(state.playing().player.color)
    lg.rectangle("line", ctx.x, ctx.y, ctx.w, ctx.h)

    local cell = state.cell(i, j)
    if cell.owner then
      local vibe = 0.1
      local nx, ny = ctx.x + ctx.w / 2, ctx.y + ctx.h / 2

      if cell.count == 1 then
        drawNeutron(nx, ny, cell.ownedBy.color, vibe)
      elseif cell.count == 2 then
        drawNeutron(nx - 10, ny, cell.ownedBy.color, vibe)
        drawNeutron(nx + 10, ny, cell.ownedBy.color, vibe)
      elseif cell.count == 3 then
        drawNeutron(nx - 10, ny, cell.ownedBy.color, vibe)
        drawNeutron(nx + 10, ny, cell.ownedBy.color, vibe)
        drawNeutron(nx, ny + 10, cell.ownedBy.color, vibe)
      end
    end
  end

  return core.Entity({ update = update, draw = draw })
end

return function()
  state.init(12, 6, 2)

  local entities = {}
  local rows, cols = state.matrixDimensions()

  for i = 1, rows do
    for j = 1, cols do
      lume.push(entities, Cell(i, j))
    end
  end

  return core.Scene(entities)
end
