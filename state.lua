local Color = require("color")
local core = require("core")

local sf = string.format

local _state = {
  matrix = {},
  players = {
    { label = sf("Player 1"), color = Color.LavenderIndigo, dead = false },
    { label = sf("Player 2"), color = Color.FireOpal, dead = false },
    { label = sf("Player 3"), color = Color.Turquoise, dead = false },
    { label = sf("Player 4"), color = Color.Kiwi, dead = false },
  },
  playing = nil,
  playerCount = 2,
}

local function init(rows, cols, pCount)
  core.validate({
    rows = { value = rows, type = "number" },
    cols = { value = cols, type = "number" },
    pCount = { value = pCount, type = "number" },
  })

  for i = 1, rows do
    _state.matrix[i] = {}
    for j = 1, cols do
      _state.matrix[i][j] = { count = 0, owner = nil }
    end
  end

  for i, _ in ipairs(_state.players) do
    _state.players[i].dead = pCount < i
  end

  _state.playerCount = pCount
  _state.playing = 1
end

local function matrixDimensions()
  local r = #_state.matrix
  if r == 0 then return r, 0 end
  local c = #(_state.matrix[1] or {})
  return r, c
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

local function nextMove()
  local nxt = _state.playing + 1
  if nxt > #_state.players then nxt = 1 end

  while _state.players[nxt].dead do
    nxt = nxt + 1
    if nxt > #_state.players then nxt = 1 end
  end

  _state.playing = nxt
end

local function winner()
  local row, col = matrixDimensions()
  local totalOwnedCells, playerOwnedCellCountMap = 0, {}

  for id, player in ipairs(_state.players) do
    if not player.dead then playerOwnedCellCountMap[id] = 0 end
  end

  for i = 1, row do
    for j = 1, col do
      local owner = cell(i, j).owner
      if owner then
        local count = playerOwnedCellCountMap[owner]
        if not count then count = 0 end
        playerOwnedCellCountMap[owner] = count + 1
        totalOwnedCells = totalOwnedCells + 1
      end
    end
  end

  if _state.playerCount > totalOwnedCells then return nil end

  local alivePlayersCount, alivePlayerIdx = 0, nil
  for id, player in ipairs(_state.players) do
    if not player.dead then player.dead = playerOwnedCellCountMap[id] == 0 end

    if not player.dead then
      alivePlayersCount = alivePlayersCount + 1
      alivePlayerIdx = id
    end
  end

  if alivePlayersCount ~= 1 then return nil end

  return { idx = alivePlayerIdx, player = _state.players[alivePlayerIdx] }
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

local function playing()
  local idx = _state.playing
  return { idx = idx, player = _state.players[idx] }
end

local function player(idx)
  core.validate({
    idx = { value = idx, type = "number", min = 1, max = #_state.players },
  })
  return { idx = idx, player = _state.players[idx] }
end

local function fuse(i, j, owner)
  validateCell(i, j)
  core.validate({
    owner = { value = owner, type = "number", min = 1, max = #_state.players },
  })
  local cl = cell(i, j)
  cl.count = cl.count + 1
  cl.owner = owner
end

local function defuse(i, j)
  validateCell(i, j)
  local cl = cell(i, j)
  cl.count = cl.count - 1
  if cl.count == 0 then cl.owner = nil end
end

local function splittables()
  local t = {}
  local row, col = matrixDimensions()

  for i = 1, row do
    for j = 1, col do
      local neighbors = cellNeighbors(i, j)
      if cell(i, j).count >= #neighbors then
        table.insert(t, { i = i, j = j, neighbors = neighbors })
      end
    end
  end

  return t
end

return {
  init = init,
  cell = cell,
  fuse = fuse,
  defuse = defuse,
  winner = winner,
  player = player,
  playing = playing,
  nextMove = nextMove,
  splittables = splittables,
  cellNeighbors = cellNeighbors,
  matrixDimensions = matrixDimensions,
}
