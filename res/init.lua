local lg, la = love.graphics, love.audio

local FONT_MONOGRAM_TTF = "res/monogram.ttf"
local SOUND_WATER_DROP_FLAC = "res/water_drop.flac"
local ICON_HOME_PNG = "res/home.png"
local ICON_UNDO_PNG = "res/undo.png"

return {
  font = {
    lg = lg.newFont(FONT_MONOGRAM_TTF, 52),
    md = lg.newFont(FONT_MONOGRAM_TTF, 32),
  },
  sound = {
    split = la.newSource(SOUND_WATER_DROP_FLAC, "static"),
  },
  icon = {
    home = lg.newImage(ICON_HOME_PNG),
    undo = lg.newImage(ICON_UNDO_PNG),
  }
}
