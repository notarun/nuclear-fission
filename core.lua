local bump = require("3rd.bump.bump")
local lume = require("3rd.lume.lume")

local lg = love.graphics
local world = bump.newWorld()

local function validate(tb)
  assert(type(tb) == "table", "Invalid table `tb`")

  local err

  for k, v in pairs(tb) do
    err = string.format("Invalid %s `%s`", v.type, k)
    assert(type(v.value) == v.type, err)

    if v.min then
      err = string.format("%s must be >= %s, val = %s", k, v.min, v.value)
      assert(v.value >= v.min, err)
    end

    if v.max then
      err = string.format("%s must be <= %s, val = %s", k, v.max, v.value)
      assert(v.value <= v.max, err)
    end
  end
end

local function Entity(args)
  args.data = args.data or {}
  args.data.x, args.data.y = args.data.x or 0, args.data.y or 0
  args.data.w, args.data.h = args.data.w or 1, args.data.h or 1

  validate({
    ["args.data.x"] = { value = args.data.x, type = "number" },
    ["args.data.y"] = { value = args.data.y, type = "number" },
    ["args.data.h"] = { value = args.data.h, type = "number" },
    ["args.data.w"] = { value = args.data.w, type = "number" },
    ["args.draw"] = { value = args.draw, type = "function" },
  })

  local itm = { id = lume.uuid() }
  local ctx = lume.merge(args.data, { item = itm })

  world:add(itm, ctx.x, ctx.y, ctx.w, ctx.h)

  local function update(dt)
    if args.update then
      args.update(dt, ctx)
      if world:hasItem(itm) then
        world:update(itm, ctx.x, ctx.y, ctx.w, ctx.h)
      end
    end
  end

  local function draw()
    lg.push()
    args.draw(ctx)
    lg.pop()
  end

  return { update = update, draw = draw }
end

local function Scene(entities)
  validate({ entities = { value = entities, type = "table" } })

  local function update(dt)
    for _, b in ipairs(entities) do
      if b.update then b.update(dt) end
    end
  end

  local function draw()
    for _, b in ipairs(entities) do
      if b.draw then b.draw() end
    end
  end

  return { update = update, draw = draw }
end

return {
  Scene = Scene,
  Entity = Entity,
  validate = validate,
  world = world,
}
