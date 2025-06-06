local lume = require("3rd.lume.lume")

local function noop() end

local function checkCollision(x, y, rectX, rectY, rectWidth, rectHeight)
  return x >= rectX
    and x <= rectX + rectWidth
    and y >= rectY
    and y <= rectY + rectHeight
end

local function dump(val)
  print(lume.serialize(val))
end

local function entitiesWhereTag(entities, tags)
  return lume.filter(entities, function(e)
    return lume.all(tags, function(tag)
      return lume.find(e.ctx.item.tags, tag)
    end)
  end)
end

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

return {
  noop = noop,
  dump = dump,
  each = each,
  getiter = getiter,
  checkCollision = checkCollision,
  entitiesWhereTag = entitiesWhereTag,
}
