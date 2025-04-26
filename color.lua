local Color = {}

setmetatable(Color, {
  __call = function(_, hexcode, opacity)
    return {
      tonumber(string.sub(hexcode, 2, 3), 16) / 256,
      tonumber(string.sub(hexcode, 4, 5), 16) / 256,
      tonumber(string.sub(hexcode, 6, 7), 16) / 256,
      opacity,
    }
  end
})

Color.White = Color("#FFFFFF")
Color.BrightGray = Color("#EFEFEF")
Color.VividSkyBlue = Color("#00C7F7")
Color.ChineseBlack = Color("#111111")
Color.ElectricPurple = Color("#BF00FF")
Color.CookiesAndCream = Color("#EBDBB2")

return Color
