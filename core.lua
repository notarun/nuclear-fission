local flux = require("3rd.flux.flux")
local lume = require("3rd.lume.lume")

local fn = require("fn")

local lg, sf = love.graphics, string.format
local _scenes = {}
local transition = { scale = 1 }

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
  args.z = args.z or 1
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
    ["args.tags"] = { value = args.tags, type = "table" },
  })

  local itm = { id = args.tags.id, tags = args.tags, z = args.z }
  local ctx = lume.merge(args.data, { item = itm, dead = false })

  if args.load then args.load(ctx) end

  local function emit(ev, ...)
    validate({ ev = { value = ev, type = "string" } })

    local err = sf("Invalid event key, val = %s", ev)
    assert(args.events[ev], err)

    return args.events[ev](ctx, ...)
  end

  local function update(dt)
    if args.update then args.update(dt, ctx) end
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

  local vw, vh = lg.getDimensions()

  local function update(dt)
    vw, vh = lg.getDimensions()

    for i, e in lume.ripairs(args.entities) do
      if e.update then e.update(dt) end
      if e.ctx.dead then table.remove(args.entities, i) end
    end
  end

  local function draw()
    lg.translate(vw / 2, vh / 2)
    lg.scale(transition.scale)
    lg.translate(-vw / 2, -vh / 2)

    local sorted = lume.sort(args.entities, function(a, b)
      return a.ctx.item.z < b.ctx.item.z
    end)

    for _, b in ipairs(sorted) do
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

  transition.scale = 1.01
  flux.to(transition, 0.1, { scale = 1 })

  _scenes.current = _scenes[id]
  _scenes.current.enter(args)
end

local function scene()
  return _scenes.current
end

return {
  scene = scene,
  Scene = Scene,
  Entity = Entity,
  validate = validate,
  goToScene = goToScene,
}
