local lume = require '3rd.lume.lume'
local bump = require '3rd.bump.bump'

local input = require 'input'
local Color = require 'color'
local useStore = require 'store'

local lg, lm, wrld = love.graphics, love.mouse, bump.newWorld()

local function GridCell(x, y, opts)
  assert(type(opts.index) == "string", "Invalid string `opts.value`")
  opts.size = opts.size or 80

  local hovering = false
  local _, actions = useStore()
  local this = { x = x, y = y, h = opts.size, w = opts.size }

  wrld:add(this, this.x, this.y, this.w, this.h)

  local function update()
    local mX, mY = lm.getPosition()
    local items = wrld:queryPoint(mX, mY)
    hovering = lume.find(items, this) ~= nil
    if hovering and input:pressed('click') then
      actions.updateCell(opts.index, actions.getCell(opts.index) + 1)
    end
  end

  local function draw()
    lg.setColor(hovering and Color.ElectricPurple or Color.White)
    lg.rectangle("line", this.x, this.y, this.w, this.h)
    lg.print(actions.getCell(opts.index), x, y)
  end

  return { update = update, draw = draw }
end

local function Grid(x, y, opts)
  x, y, opts = x or 0, y or 0, opts or {}
  opts.rows = opts.rows or 12
  opts.cols = opts.cols or 6
  opts.cellSize = opts.cellSize or 80

  local state, actions = useStore()
  actions.createMatrix(opts.rows, opts.cols)

  local cells = {}
  for i, cols in ipairs(state.matrix) do
    for j, value in ipairs(cols) do
      local cellX = x + (j - 1) * opts.cellSize
      local cellY = y + (i - 1) * opts.cellSize
      table.insert(cells, GridCell(cellX, cellY, {
        value = value,
        size = opts.cellSize,
        index = lume.format("{i}:{j}", {i = i, j = j}),
      }))
    end
  end

  local function update(dt)
    for _, c in ipairs(cells) do c.update(dt) end
  end

  local function draw()
    for _, c in ipairs(cells) do c.draw() end
  end

  return { update = update, draw = draw }
end

local function GameScene()
  local entities = {
    Grid(0, 0)
  }

  local function update(dt)
    for _, b in ipairs(entities) do
      if b.update then b.update(dt) end
    end
  end

  local function draw()
    for _, b in ipairs(entities) do
      if b.draw then b.draw() end
    end
  end

  return { update = update, draw = draw }
end

return GameScene
