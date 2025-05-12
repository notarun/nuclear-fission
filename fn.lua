local lume = require("3rd.lume.lume")

local dump = {}
setmetatable(dump, {
  __call = function(_, val)
    print(lume.serialize(val))
  end,
})

local function getiter(x)
  if lume.isarray(x) then
    return ipairs
  elseif type(x) == "table" then
    return pairs
  end
  error("expected table", 3)
end

-- lume.each passes `self` as the first argument, which interferes with core.Entity's event calling.
-- This is a patched version to handle cases when using a function name string.
local function each(t, fn, ...)
  local iter = getiter(t)
  if type(fn) == "string" then
    for _, v in iter(t) do
      v[fn](...)
    end
  else
    error("expected `fn` string", 3)
  end
  return t
end

return { dump = dump, getiter = getiter, each = each }
