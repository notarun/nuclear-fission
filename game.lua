local Color = require 'color'
local useStore = require 'store'

local lg = love.graphics

local function GridCell(x, y, opts)
  assert(type(opts.value) == "number", "Invalid string `opts.value`")
  opts.size = opts.size or 80

  local function draw()
    lg.setColor(Color.White)
    lg.rectangle("line", x, y, opts.size, opts.size)
    lg.print(opts.value, x, y)
  end

  return { draw = draw }
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
      }))
    end
  end

  local function draw()
    for _, c in ipairs(cells) do c.draw() end
  end

  return { draw = draw }
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
