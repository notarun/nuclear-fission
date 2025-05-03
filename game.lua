local bump = require("3rd.bump.bump")
local lume = require("3rd.lume.lume")

local Color = require("color")
local Scene = require("scene")
local input = require("input")
local useStore = require("store")
local util = require("util")

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

  local function set(options)
    for k in pairs(options) do
      opts[k] = options[k]
    end
  end

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

  return { draw = draw, set = set }
end

local function GridCell(x, y, opts)
  assert(type(opts.i) == "number", "Invalid number `opts.i`")
  assert(type(opts.j) == "number", "Invalid number `opts.j`")

  local owner
  local state, actions = useStore()
  local this = { x = x, y = y, h = opts.size, w = opts.size }
  local nuclei = Nuclei(this.x, this.y, {
    count = state.matrix[opts.i][opts.j],
    color = Color.White,
    gridSz = opts.size,
  })

  local threshold = #util.vonNeumannNeighborIndices(
    state.matrix,
    opts.i,
    opts.j
  ) - 1

  wrld:add(this, this.x, this.y, this.w, this.h)

  local function update()
    local mX, mY = lm.getPosition()
    local items = wrld:queryPoint(mX, mY)
    local hovering = lume.find(items, this) ~= nil

    if hovering and input:pressed("click") then
      local nucleiCount = state.matrix[opts.i][opts.j]

      if nucleiCount == 0 and not owner then owner = state.playing end
      if owner ~= state.playing then return end

      if nucleiCount < threshold then
        local count = nucleiCount + 1
        local color = state.players[state.playing].color

        actions.updateCell(opts.i, opts.j, count)
        nuclei.set({ color = color, count = count })
        actions.nextPlayer()
      else
        actions.updateCell(opts.i, opts.j, 0)
        nuclei.set({ count = 0 })

        local neighbors = util.vonNeumannNeighborIndices(state.matrix, opts.i, opts.j)
        for _, n in ipairs(neighbors) do
          local cellVal = state.matrix[n.i][n.j]
          actions.updateCell(n.i, n.j, cellVal + 1)
        end

        actions.nextPlayer()

        --- XXX: Look into posibility of using physics world instead
      end
    end
  end

  local function draw()
    lg.setColor(state.players[state.playing].color)
    lg.rectangle("line", this.x, this.y, this.w, this.h)
    nuclei.draw()
  end

  return { update = update, draw = draw }
end

local function Grid(x, y, opts)
  x, y, opts = x or 0, y or 0, opts or {}
  opts.rows = opts.rows or 12
  opts.cols = opts.cols or 6
  opts.cellSize = opts.cellSize or 60

  local w, h = opts.cellSize * opts.cols, opts.cellSize * opts.rows
  local pl, ph = (lg.getWidth() - w) / 2, (lg.getHeight() - h) / 2

  local state, actions = useStore()
  actions.createMatrix(opts.rows, opts.cols)

  local cells = {}
  for i, cols in ipairs(state.matrix) do
    for j, value in ipairs(cols) do
      local cellX = x + pl + (j - 1) * opts.cellSize
      local cellY = y + ph + (i - 1) * opts.cellSize
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

return function()
  return Scene({ Grid(0, 0) })
end
