local lg = love.graphics

local FONT_MONOGRAM_TTF = "res/monogram.ttf"

return {
  font = {
    lg = lg.newFont(FONT_MONOGRAM_TTF, 52),
    md = lg.newFont(FONT_MONOGRAM_TTF, 32),
  },
}
