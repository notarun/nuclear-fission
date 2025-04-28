local lume = require '3rd.lume.lume'

local util = require 'util'

local function State()
  return {
    matrix = util.createMatrix(12, 6, 0),
  }
end

local function Actions(s)
  local function dumpState() require('dump')(s) end

  local function createMatrix(row, col)
    s.matrix = util.createMatrix(row, col, 0)
  end

  local function updateCell(index, val)
    local t = lume.split(index, ":")
    s.matrix[tonumber(t[1])][tonumber(t[2])] = val
  end

  local function getCell(index)
    local t = lume.split(index, ":")
    return s.matrix[tonumber(t[1])][tonumber(t[2])]
  end

  return {
    dumpState = dumpState,
    getCell = getCell,
    createMatrix = createMatrix,
    updateCell = updateCell,
  }
end

local state = State()
local actions = Actions(state)

return function()
  return state, actions
end
