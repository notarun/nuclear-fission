local bump = require("3rd.bump.bump")
local lume = require("3rd.lume.lume")

local lg, unpack = love.graphics, unpack or table.unpack
local world, _scenes = bump.newWorld(), {}

local function validate(tb)
  local err
  assert(type(tb) == "table", "Invalid table `tb`")

  for k, v in pairs(tb) do
    local keys = lume.keys(v)

    err = string.format("Required key `value` not found in `table.%s`", k)
    assert(lume.find(keys, "value"), err)

    err = string.format("Required key `type` not found in `table.%s`", k)
    assert(lume.find(keys, "type"), err)

    err = string.format("Invalid %s `%s`, val = %s", v.type, k, v.value)
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
  args.tags = args.tags or {}
  args.data.x, args.data.y = args.data.x or 0, args.data.y or 0
  args.data.w, args.data.h = args.data.w or 1, args.data.h or 1
  args.events = args.events or {}

  validate({
    ["args.data.x"] = { value = args.data.x, type = "number" },
    ["args.data.y"] = { value = args.data.y, type = "number" },
    ["args.data.h"] = { value = args.data.h, type = "number" },
    ["args.data.w"] = { value = args.data.w, type = "number" },
    ["args.events"] = { value = args.events, type = "table" },
    ["args.draw"] = { value = args.draw, type = "function" },
    ["args.tags"] = { value = args.events, type = "table" },
  })

  local itm = { id = lume.uuid() }
  local ctx =
    lume.merge(args.data, { item = itm, tags = args.tags, dead = false })

  if args.load then args.load(ctx) end
  world:add(itm, ctx.x, ctx.y, ctx.w, ctx.h)

  local function emit(...)
    -- compatibility with lume's each method, since it passes self as first arg
    local params = { ... }
    if type(params[1]) == "table" then params = lume.slice(params, 2) end
    local ev = params[1]

    validate({ ev = { value = ev, type = "string" } })
    local err = string.format("Invalid event key, val = %s", ev)
    assert(args.events[ev], err)
    args.events[ev](ctx, unpack(lume.slice(params, 2)))
  end

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

  return { update = update, draw = draw, ctx = ctx, emit = emit }
end

local function Scene(args)
  validate({
    ["args.id"] = { value = args.id, type = "string" },
    ["args.enter"] = { value = args.enter, type = "function" },
    ["args.leave"] = { value = args.leave, type = "function" },
    ["args.entities"] = { value = args.entities, type = "table" },
  })

  local function update(dt)
    for i, e in lume.ripairs(args.entities) do
      if e.update then e.update(dt) end
      if e.ctx.dead then table.remove(args.entities, i) end
    end
  end

  local function draw()
    for _, b in ipairs(args.entities) do
      if b.draw then b.draw() end
    end
  end

  local scene = {
    draw = draw,
    update = update,
    enter = args.enter,
    leave = args.leave,
  }

  _scenes[args.id] = scene
  return _scenes[args.id]
end

local function goToScene(id, args)
  args = args or {}

  validate({
    id = { value = id, type = "string" },
    args = { value = args, type = "table" },
  })

  local err = string.format("Invalid scene id, val = %s", id)
  assert(_scenes[id], err)

  if _scenes.current then _scenes.current.leave(args) end
  _scenes.current = _scenes[id]
  _scenes.current.enter(args)
end

local function scene()
  return _scenes.current
end

return {
  scene = scene,
  world = world,
  Scene = Scene,
  Entity = Entity,
  validate = validate,
  goToScene = goToScene,
}
