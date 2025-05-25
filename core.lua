local bump = require("3rd.bump.bump")
local lume = require("3rd.lume.lume")

local fn = require("fn")

local lg, sf = love.graphics, string.format
local world, _scenes = bump.newWorld(), {}

local function validate(tb)
  local err
  assert(type(tb) == "table", "Invalid table `tb`")

  for k, v in pairs(tb) do
    local keys = lume.keys(v)

    err = sf("Required key `value` not found in `table.%s`", k)
    assert(lume.find(keys, "value"), err)

    err = sf("Required key `type` not found in `table.%s`", k)
    assert(lume.find(keys, "type"), err)

    err = sf("Invalid %s `%s`, val = %s", v.type, k, tostring(v.value))
    assert(type(v.value) == v.type, err)

    if v.min then
      err = sf("%s must be >= %s, val = %s", k, v.min, v.value)
      assert(v.value >= v.min, err)
    end

    if v.max then
      err = sf("%s must be <= %s, val = %s", k, v.max, v.value)
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
  args.draw = args.draw or fn.noop

  validate({
    ["args.data.x"] = { value = args.data.x, type = "number" },
    ["args.data.y"] = { value = args.data.y, type = "number" },
    ["args.data.h"] = { value = args.data.h, type = "number" },
    ["args.data.w"] = { value = args.data.w, type = "number" },
    ["args.events"] = { value = args.events, type = "table" },
    ["args.draw"] = { value = args.draw, type = "function" },
    ["args.tags"] = { value = args.events, type = "table" },
  })

  local itm = { id = args.tags.id, tags = args.tags }
  local ctx = lume.merge(args.data, { item = itm, dead = false })

  if args.load then args.load(ctx) end
  world:add(itm, ctx.x, ctx.y, ctx.w, ctx.h)

  local function emit(ev, ...)
    validate({ ev = { value = ev, type = "string" } })

    local err = sf("Invalid event key, val = %s", ev)
    assert(args.events[ev], err)

    return args.events[ev](ctx, ...)
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
    if args.draw then args.draw(ctx) end
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
      if e.ctx.dead then
        table.remove(args.entities, i)
        world:remove(e.ctx.item)
      end
    end
  end

  local function draw()
    for _, b in ipairs(args.entities) do
      if b.draw then b.draw() end
    end
  end

  local scene = {
    id = args.id,
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

  local err = sf("Invalid scene id, val = %s", id)
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
