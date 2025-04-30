local Color = require("color")
local util = require("util")

local function State()
  return {
    matrix = util.createMatrix(12, 6, 0),
    players = {
      { name = "Player 1", color = Color.ElectricPurple },
      { name = "Player 2", color = Color.VividSkyBlue },
    },
    playing = 1,
  }
end

local function Actions(s)
  local function dumpState()
    require("dump")(s)
  end

  local function createMatrix(row, col)
    s.matrix = util.createMatrix(row, col, 0)
  end

  local function updateCell(i, j, val)
    s.matrix[i][j] = val
  end

  local function nextPlayer()
    local nextIdx = s.playing + 1
    if nextIdx > #s.players then
      s.playing = 1
    else
      s.playing = nextIdx
    end

    print(s.playing, nextIdx)
  end

  return {
    dumpState = dumpState,
    createMatrix = createMatrix,
    updateCell = updateCell,
    nextPlayer = nextPlayer,
  }
end

local state = State()
local actions = Actions(state)

return function()
  return state, actions
end
