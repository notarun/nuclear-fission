local bump = require("3rd.bump.bump")
local lume = require("3rd.lume.lume")

local lg = love.graphics
local world = bump.newWorld()

local function validate(tb)
  assert(type(tb) == "table", "Invalid table `tb`")

  for k, v in pairs(tb) do
    local err = string.format("Invalid %s `%s`", v.type, k)
    assert(type(v.value) == v.type, err)
  end
end

local function Entity(args)
  args.x, args.y = args.x or 0, args.y or 0
  args.w, args.h = args.w or 1, args.h or 1

  validate({
    ["args.x"] = { value = args.x, type = "number" },
    ["args.y"] = { value = args.y, type = "number" },
    ["args.h"] = { value = args.h, type = "number" },
    ["args.w"] = { value = args.w, type = "number" },
    ["args.draw"] = { value = args.draw, type = "function" },
  })

  local item = { id = lume.uuid(), props = args, world = world }
  world:add(item, args.x, args.y, args.w, args.h)

  local function update(dt)
    if args.update then
      args.update(dt, item)
      world:update(
        item,
        item.props.x,
        item.props.y,
        item.props.w,
        item.props.h
      )
    end
  end

  local function draw()
    lg.push()
    args.draw(item)
    lg.pop()
  end

  return { update = update, draw = draw, item = item }
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

return { Scene = Scene, Entity = Entity, validate = validate }
