return {
  noop = function() end,

  createMatrix = function(rows, cols, default)
    local matrix = {}

    for i = 1, rows do
      matrix[i] = {}
      for j = 1, cols do
        matrix[i][j] = default
      end
    end

    return matrix
  end,

  vonNeumannNeighborIndices = function(matrix, i, j)
    local neighbors = {}
    local num_rows = #matrix

    if num_rows == 0 then return neighbors end

    local num_cols = #(matrix[1] or {})
    if num_cols == 0 then return neighbors end

    local offsets = { { -1, 0 }, { 1, 0 }, { 0, -1 }, { 0, 1 } }

    for _, offset in ipairs(offsets) do
      local neighbor_r = i + offset[1]
      local neighbor_c = j + offset[2]

      if
        neighbor_r >= 1
        and neighbor_r <= num_rows
        and neighbor_c >= 1
        and neighbor_c <= num_cols
      then
        table.insert(neighbors, { i = neighbor_r, j = neighbor_c })
      end
    end

    return neighbors
  end,
}
