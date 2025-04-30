local lume = require("3rd.lume.lume")
local bump = require("3rd.bump.bump")

local input = require("input")
local Color = require("color")
local useStore = require("store")

local lg, lm, wrld = love.graphics, love.mouse, bump.newWorld()

local function Nuclei(x, y, opts)
  assert(opts.color, "Invalid param `opts.color`")
  assert(type(opts.count) == "number", "Invalid param `opts.count`")
  assert(type(opts.gridSz) == "number", "Invalid param `opts.gridSz`")

  local size = 12
  local this = {
    x = x + opts.gridSz / 2,
    y = y + opts.gridSz / 2,
    h = size,
    w = size,
  }

  wrld:add(this, this.x, this.y, this.w, this.h)

  local function draw()
    lg.setColor(opts.color)

    if opts.count == 1 then
      lg.circle("line", this.x, this.y, size)
    elseif opts.count == 2 then
      lg.circle("line", this.x - 10, this.y, size)
      lg.circle("line", this.x + 10, this.y, size)
    elseif opts.count == 3 then
      lg.circle("line", this.x - 10, this.y, size)
      lg.circle("line", this.x + 10, this.y, size)
      lg.circle("line", this.x, this.y + 10, size)
    end
  end

  return { draw = draw }
end

local function GridCell(x, y, opts)
  assert(type(opts.i) == "number", "Invalid number `opts.i`")
  assert(type(opts.j) == "number", "Invalid number `opts.j`")

  opts.size = opts.size or 80

  local hovering = false
  local state, actions = useStore()
  local this = { x = x, y = y, h = opts.size, w = opts.size }

  wrld:add(this, this.x, this.y, this.w, this.h)

  local function update()
    local mX, mY = lm.getPosition()
    local items = wrld:queryPoint(mX, mY)
    hovering = lume.find(items, this) ~= nil

    if hovering and input:pressed("click") then
      local nucleiCount = state.matrix[opts.i][opts.j]

      -- FIXME: change according to the location of the cell
      local threshold = 3

      if nucleiCount < threshold then
        actions.updateCell(opts.i, opts.j, nucleiCount + 1)
      else
        print("FIXME: IMPLEMENT SPLITTING")
      end
    end
  end

  local function draw()
    lg.setColor(hovering and Color.ElectricPurple or Color.White)
    lg.rectangle("line", this.x, this.y, this.w, this.h)

    Nuclei(x, y, {
      count = state.matrix[opts.i][opts.j],
      color = Color.ElectricPurple,
      gridSz = opts.size,
    }).draw()
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
      table.insert(
        cells,
        GridCell(cellX, cellY, {
          value = value,
          size = opts.cellSize,
          i = i,
          j = j,
        })
      )
    end
  end

  local function update(dt)
    for _, c in ipairs(cells) do
      c.update(dt)
    end
  end

  local function draw()
    for _, c in ipairs(cells) do
      c.draw()
    end
  end

  return { update = update, draw = draw }
end

local function GameScene()
  local entities = {
    Grid(0, 0),
  }

  local function update(dt)
    for _, b in ipairs(entities) do
      if b.update then
        b.update(dt)
      end
    end
  end

  local function draw()
    for _, b in ipairs(entities) do
      if b.draw then
        b.draw()
      end
    end
  end

  return { update = update, draw = draw }
end

return GameScene
