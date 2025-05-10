local Color = {}

setmetatable(Color, {
  __call = function(_, hexcode, opacity)
    return {
      tonumber(string.sub(hexcode, 2, 3), 16) / 256,
      tonumber(string.sub(hexcode, 4, 5), 16) / 256,
      tonumber(string.sub(hexcode, 6, 7), 16) / 256,
      opacity,
    }
  end,
})

Color.Kiwi = Color("#9BE550")
Color.FireOpal = Color("#E55050")
Color.Turquoise = Color("#50E5E5")
Color.LavenderIndigo = Color("#9B50E5")

Color.White = Color("#FFFFFF")
Color.ChineseBlack = Color("#111111")
Color.CookiesAndCream = Color("#EBDBB2")

return Color
