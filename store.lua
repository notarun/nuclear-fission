local util = require("util")

local function State()
  return {
    matrix = util.createMatrix(12, 6, 0),
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

  return {
    dumpState = dumpState,
    createMatrix = createMatrix,
    updateCell = updateCell,
  }
end

local state = State()
local actions = Actions(state)

return function()
  return state, actions
end
