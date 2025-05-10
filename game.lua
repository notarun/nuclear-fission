local lume = require("3rd.lume.lume")

local core = require("core")
local dh = require("draw")
local input = require("input")
local state = require("state")

local lg, lm = love.graphics, love.mouse

local function Cell(i, j)
  local rows, cols = state.matrixDimensions()
  local nx, ny, nm = 0, 0, 0

  local function update(_, ctx)
    local vw, vh = lg.getDimensions()
    ctx.w, ctx.h = vw / cols, vh / rows
    ctx.x, ctx.y = (j - 1) * ctx.w, (i - 1) * ctx.h
    nx, ny = ctx.x + ctx.w / 2, ctx.y + ctx.h / 2

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

    local threshold = #state.cellNeighbors(i, j) - 1
    nm = state.cell(i, j).count < threshold and 0 or 0.1
  end

  local function draw(ctx)
    lg.setColor(state.playing().player.color)
    lg.rectangle("line", ctx.x, ctx.y, ctx.w, ctx.h)

    local cell = state.cell(i, j)
    if cell.owner then
      if cell.count == 1 then
        dh.neutron(nx, ny, cell.ownedBy.color, nm)
      elseif cell.count == 2 then
        dh.neutron(nx - 10, ny, cell.ownedBy.color, nm)
        dh.neutron(nx + 10, ny, cell.ownedBy.color, nm)
      elseif cell.count == 3 then
        dh.neutron(nx - 10, ny, cell.ownedBy.color, nm)
        dh.neutron(nx, ny + 10, cell.ownedBy.color, nm)
        dh.neutron(nx + 10, ny, cell.ownedBy.color, nm)
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
