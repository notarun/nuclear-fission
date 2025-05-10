local Color = require("color")
local core = require("core")

local _state = {
  matrix = {},
  players = {},
  playing = nil,
  winner = nil,
}

local colors = {
  Color.VividSkyBlue,
  Color.DiscordGreen,
  Color.ElectricPurple,
  Color.CookiesAndCream,
}

local function init(rows, cols, pCount)
  core.validate({
    rows = { value = rows, type = "number" },
    cols = { value = cols, type = "number" },
    pCount = { value = pCount, type = "number", min = 2, max = 4 },
  })

  for i = 1, rows do
    _state.matrix[i] = {}
    for j = 1, cols do
      _state.matrix[i][j] = { count = 0, owner = nil }
    end
  end

  for i = 1, pCount do
    _state.players[i] = {
      label = string.format("Player %s", i),
      color = colors[i],
    }
  end

  _state.playing = 1
  _state.winner = nil
end

local function matrixDimensions()
  local r = #_state.matrix
  if r == 0 then return r, 0 end
  local c = #(_state.matrix[1] or {})
  return r, c
end

local function nextMove()
  local nxt = _state.playing + 1
  if nxt > #_state.players then
    _state.playing = 1
  else
    _state.playing = nxt
  end

  -- handle winner
end

local function cellNeighbors(i, j)
  local neighbors = {}

  local totalRows = #_state.matrix
  if totalRows == 0 then return neighbors end

  local totalCols = #(_state.matrix[1] or {})
  if totalCols == 0 then return neighbors end

  local offsets = { { -1, 0 }, { 1, 0 }, { 0, -1 }, { 0, 1 } }

  for _, offset in ipairs(offsets) do
    local r = i + offset[1]
    local c = j + offset[2]

    if r >= 1 and r <= totalRows and c >= 1 and c <= totalCols then
      table.insert(neighbors, { i = r, j = c })
    end
  end

  return neighbors
end

local function validateCell(i, j)
  local rMax, cMax = matrixDimensions()

  core.validate({
    i = { value = i, type = "number", min = 1, max = rMax },
    j = { value = j, type = "number", min = 1, max = cMax },
  })
end

local function cell(i, j)
  validateCell(i, j)
  local ret = _state.matrix[i][j]
  ret.ownedBy = _state.players[ret.owner]
  return ret
end

local function playing()
  local idx = _state.playing
  return { idx = idx, player = _state.players[idx] }
end

local function fuseOrSplit(i, j, owner)
  validateCell(i, j)
  core.validate({
    owner = { value = owner, type = "number", min = 1, max = #_state.players },
  })

  local neighbors = cellNeighbors(i, j)
  local threshold = #neighbors - 1
  local cl = cell(i, j)

  if cl.count < threshold then
    cl.count = cl.count + 1
    cl.owner = owner
  else
    cl.count = 0
    cl.owner = nil
    for _, n in ipairs(neighbors) do
      fuseOrSplit(n.i, n.j, owner)
    end
  end
end

return {
  init = init,
  cell = cell,
  playing = playing,
  nextMove = nextMove,
  fuseOrSplit = fuseOrSplit,
  cellNeighbors = cellNeighbors,
  matrixDimensions = matrixDimensions,
}
