local lg, la = love.graphics, love.audio

local FONT_MONOGRAM_TTF = "res/monogram.ttf"
local SOUND_PLASMA_FLAC = "res/plasma.flac"

return {
  font = {
    lg = lg.newFont(FONT_MONOGRAM_TTF, 52),
    md = lg.newFont(FONT_MONOGRAM_TTF, 32),
  },
  sound = {
    plasma = la.newSource(SOUND_PLASMA_FLAC, "static"),
  },
}
