local Color = require("color")
local util = require("util")

local function DEFAULT_MATRIX_CELL()
  return { value = 0, owner = nil }
end

local function State()
  return {
    matrix = util.createMatrix(12, 6, DEFAULT_MATRIX_CELL),
    players = {
      { name = "Player 1", color = Color.ElectricPurple },
      { name = "Player 2", color = Color.CookiesAndCream },
    },
    playing = 1,
    winner = nil,
  }
end

local function Actions(s)
  local function dumpState()
    require("dump")(s)
  end

  local function createMatrix(row, col)
    s.matrix = util.createMatrix(row, col, DEFAULT_MATRIX_CELL)
  end

  local function fuse(i, j, owner)
    local neighbors = util.vonNeumannNeighborIndices(s.matrix, i, j)
    local threshold = #neighbors - 1

    if s.matrix[i][j].value < threshold then
      s.matrix[i][j].value = s.matrix[i][j].value + 1
      s.matrix[i][j].owner = owner
    else
      s.matrix[i][j].value = 0
      s.matrix[i][j].owner = nil

      for _, n in ipairs(neighbors) do
        fuse(n.i, n.j, owner)
      end
    end
  end

  local function nextPlayer()
    local nextIdx = s.playing + 1
    if nextIdx > #s.players then
      s.playing = 1
    else
      s.playing = nextIdx
    end
  end

  return {
    fuse = fuse,
    dumpState = dumpState,
    createMatrix = createMatrix,
    nextPlayer = nextPlayer,
  }
end

local state = State()
local actions = Actions(state)

return function()
  return state, actions
end
