local bump = require("3rd.bump.bump")
local lume = require("3rd.lume.lume")

local core = require("core")
local input = require("input")
local useStore = require("store")

local lg, lm, wrld = love.graphics, love.mouse, bump.newWorld()

local function Nuclei(x, y, opts)
  assert(opts.i, "Invalid param `opts.i`")
  assert(opts.j, "Invalid param `opts.j`")
  assert(type(opts.gridSz) == "number", "Invalid param `opts.gridSz`")

  local state = useStore()

  local size = 12
  local this = {
    x = x + opts.gridSz / 2,
    y = y + opts.gridSz / 2,
    h = size,
    w = size,
  }

  local function draw()
    local cell = state.matrix[opts.i][opts.j]

    if cell.owner then lg.setColor(state.players[cell.owner].color) end

    if cell.value == 1 then
      lg.circle("line", this.x, this.y, size)
    elseif cell.value == 2 then
      lg.circle("line", this.x - 10, this.y, size)
      lg.circle("line", this.x + 10, this.y, size)
    elseif cell.value == 3 then
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

  local state, actions = useStore()
  local this = { x = x, y = y, h = opts.size, w = opts.size }
  local nuclei = Nuclei(this.x, this.y, {
    i = opts.i,
    j = opts.j,
    gridSz = opts.size,
  })

  wrld:add(this, this.x, this.y, this.w, this.h)

  local function update()
    local mX, mY = lm.getPosition()
    local items = wrld:queryPoint(mX, mY)
    local hovering = lume.find(items, this) ~= nil

    if hovering and input:pressed("click") then
      local owner = state.matrix[opts.i][opts.j].owner
      if owner and owner ~= state.playing then
        print("THIS CELL IS OWNED BY OTHER PLAYER")
      else
        actions.fuse(opts.i, opts.j, state.playing)
        actions.nextPlayer()
      end
    end
  end

  local function draw()
    lg.setColor(state.players[state.playing].color)
    lg.rectangle("line", this.x, this.y, this.w, this.h)
    -- local cell = state.matrix[opts.i][opts.j]
    -- lg.print(lume.format("{1}:{2}", {cell.value, cell.owner or ""}), this.x, this.y)
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
    for j, _ in ipairs(cols) do
      local cellX = x + pl + (j - 1) * opts.cellSize
      local cellY = y + ph + (i - 1) * opts.cellSize
      table.insert(
        cells,
        GridCell(cellX, cellY, { size = opts.cellSize, i = i, j = j })
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
  return core.Scene({ Grid(0, 0) })
end
