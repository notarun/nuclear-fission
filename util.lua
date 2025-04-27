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
  end
}
