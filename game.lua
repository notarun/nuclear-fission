local flux = require("3rd.flux.flux")
local lume = require("3rd.lume.lume")
local toast = require("3rd.toasts.lovelyToasts")

local Button = require("button")
local Color = require("color")
local core = require("core")
local drw = require("draw")
local fn = require("fn")
local input = require("input")
local res = require("res")
local state = require("state")

local lg, lm = love.graphics, love.mouse
local sf = string.format

local entities = {}
local px, py = 18, 82
local animating, animationDuration = false, 0.2

local function splitAll(nextMove, onWin)
  core.validate({
    nextMove = { value = nextMove, type = "function" },
    onWin = { value = onWin, type = "function" },
  })

  animating = true

  if state.winner() then
    onWin()
    return
  end

  local splittables = state.splittables()
  if #splittables == 0 then
    nextMove()
    animating = false
    return
  end

  for _, s in ipairs(splittables) do
    local e = fn.entitiesWhereTag(
      entities,
      { "neutrons", sf("cell:%s-%s", s.i, s.j) }
    )[1]
    e.emit("split", s.neighbors)
  end

  flux
    .to({}, animationDuration + (animationDuration / 2), {})
    :oncomplete(function()
      splitAll(nextMove, function()
        local e = fn.entitiesWhereTag(entities, { "modal" })[1]
        if e then e.emit("toggle") end
      end)
    end)
end

local function cellPosAndSz(i, j)
  local rows, cols = state.matrixDimensions()
  local vw, vh = lg.getDimensions()
  vw, vh = vw - px, vh - py

  local w, h = vw / cols, vh / rows
  local x, y = (j - 1) * w, (i - 1) * h
  x, y = x + (px / 2), y + (px / 2)

  return x, y, w, h
end

local function GameOverModal()
  local hidden = true
  local bw = 4
  local txt = {
    title = lg.newText(res.font.lg, " GAME OVER! "),
    subtitle = lg.newText(res.font.md, "player x won"),
  }
  local vw, vh = lg.getDimensions()
  local transition = { scale = 1 }
  local leftBtn, rightBtn

  local function load(this)
    rightBtn = Button({
      label = "replay",
      color = Color.LavenderIndigo,
      onclick = function()
        core.goToScene("game", { players = state.currentPlayerCount() })
        animating = false
      end,
      updatePos = function(ctx, opt)
        local pw = 6 * bw
        ctx.x, ctx.y =
          this.x + this.w - pw - ctx.w, this.y + this.h - ctx.h - pw
        opt.w = (this.w / 2) - (2 * pw)
      end,
    })

    leftBtn = Button({
      label = "main menu",
      color = Color.FireOpal,
      onclick = function()
        core.goToScene("menu")
        animating = false
      end,
      updatePos = function(ctx, opt)
        local pw = 6 * bw
        ctx.x, ctx.y = this.x + pw, this.y + this.h - ctx.h - pw
        opt.w = (this.w / 2) - (2 * pw)
      end,
    })
  end

  local function update(_, ctx)
    if hidden then return end

    vw, vh = lg.getDimensions()
    ctx.w, ctx.h = vw / 1.2, vh / 3
    ctx.x, ctx.y = (vw - ctx.w) / 2, (vh - ctx.h) / 2

    local winner = state.winner()
    if winner then txt.subtitle:set(sf("%s Won", winner.player.label)) end
  end

  local function draw(ctx)
    if hidden then return end

    lg.translate(vw / 2, vh / 2)
    lg.scale(transition.scale)
    lg.translate(-vw / 2, -vh / 2)

    lg.setColor(Color.CookiesAndCream)
    lg.rectangle(
      "fill",
      ctx.x - (bw / 2),
      ctx.y - (bw / 2),
      ctx.w + bw,
      ctx.h + bw,
      8
    )

    lg.setColor(Color.ChineseBlack)
    lg.rectangle("fill", ctx.x, ctx.y, ctx.w, ctx.h, 8)

    local ttw, tth = txt.title:getDimensions()
    lg.setColor(Color.CookiesAndCream)
    lg.draw(txt.title, (vw - ttw) / 2, ctx.y + tth)

    local stw, sth = txt.subtitle:getDimensions()
    lg.setColor(Color.CookiesAndCream)
    lg.draw(txt.subtitle, (vw - stw) / 2, ctx.y + (4 * sth))
  end

  local function toggle()
    hidden = not hidden

    if not hidden then
      transition.scale = 1.2
      flux.to(transition, 0.1, { scale = 1 }):oncomplete(function()
        leftBtn.dead, leftBtn.ctx.opacity = false, 0
        rightBtn.dead, rightBtn.ctx.opacity = false, 0
        lume.push(entities, leftBtn, rightBtn)

        flux.to(leftBtn.ctx, 0.5, { opacity = 1 })
        flux.to(rightBtn.ctx, 0.5, { opacity = 1 })
      end)
    else
      leftBtn.dead = true
      rightBtn.dead = true
    end
  end

  return core.Entity({
    events = { toggle = toggle },
    tags = { "modal" },
    update = update,
    draw = draw,
    load = load,
  })
end

local function Neutrons(i, j)
  local vibration, color = false, nil
  local count, neutrons = 0, {}
  local offsets = {
    { { 0, 0 } },
    { { -10, 0 }, { 10, 0 } },
    { { -10, -4 }, { 0, 6 }, { 10, -4 } },
    { { -10, 0 }, { 0, -10 }, { 0, 10 }, { 10, 0 } },

    -- handles edge case where count can be greater than 4
    { { -10, 0 }, { 0, -10 }, { 0, 10 }, { 10, 0 }, { 0, 0 } },
  }

  local function load(ctx)
    local cx, cy, cw, ch = cellPosAndSz(i, j)
    ctx.x, ctx.y = cx + cw / 2, cy + ch / 2
    ctx.w, ctx.h = 18, 18
  end

  local function arrangeNeutrons(ctx)
    local cell = state.cell(i, j)

    if count ~= cell.count then
      count = cell.count
      lume.clear(neutrons)
      for idx = 1, count do
        local offset = offsets[count][idx]
        neutrons[idx] = { x = ctx.x + offset[1], y = ctx.y + offset[2] }
      end
    end
  end

  local function split(ctx, neighbors)
    arrangeNeutrons(ctx)
    res.sound.split:play()

    for idx, n in ipairs(neighbors) do
      local cx, cy, cw, ch = cellPosAndSz(n.i, n.j)
      local tx, ty = cx + cw / 2, cy + ch / 2
      flux
        .to(neutrons[idx], animationDuration, { x = tx, y = ty })
        :oncomplete(function()
          state.fuse(n.i, n.j, state.playing().idx)
          state.defuse(i, j)
        end)
    end
  end

  local function update(_, ctx)
    arrangeNeutrons(ctx)
    local cell = state.cell(i, j)
    if cell.ownedBy then color = cell.ownedBy.color end
    local threshold = #state.cellNeighbors(i, j) - 1
    vibration = count < threshold and 0 or 0.1
  end

  local function draw(_)
    for idx, n in ipairs(neutrons) do
      drw.neutron(n.x, n.y, color, vibration)
      if _G.NF_DEBUG then
        local txt = sf("%s/%s\n%s:%s", idx, #neutrons, i, j)
        lg.setColor(Color.White)
        lg.print(txt, n.x - 18 / 2, n.y - 18 / 2)
      end
    end
  end

  return core.Entity({
    load = load,
    draw = draw,
    update = update,
    events = { split = split },
    tags = { "neutrons", sf("cell:%s-%s", i, j) },
  })
end

local function Cell(i, j)
  local function update(_, ctx)
    ctx.x, ctx.y, ctx.w, ctx.h = cellPosAndSz(i, j)

    local mx, my = lm.getPosition()
    local hovering = fn.checkCollision(mx, my, ctx.x, ctx.y, ctx.w, ctx.h)

    if not animating and hovering and input:pressed("click") then
      local owner, playing = state.cell(i, j).owner, state.playing().idx

      if owner and owner ~= playing then
        toast.show("This cell is owned by other player")
      else
        state.saveHistory()
        state.fuse(i, j, state.playing().idx)
        splitAll(state.nextMove, function()
          local e = fn.entitiesWhereTag(entities, { "modal" })[1]
          if e then e.emit("toggle") end
        end)
      end
    end
  end

  local function draw(ctx)
    lg.setColor(state.playing().player.color)
    lg.rectangle("line", ctx.x, ctx.y, ctx.w, ctx.h)
    if _G.NF_DEBUG then
      local cell = state.cell(i, j)
      local text = sf("c%sp%s\n%s:%s", cell.count, cell.owner or "", i, j)
      lg.setColor(Color.White)
      lg.print(text, ctx.x, ctx.y)
    end
  end

  return core.Entity({ update = update, draw = draw })
end

local function BottomPanel()
  local homeButton = Button({
    label = "home",
    mode = "line",
    color = Color.White,
    txtColor = Color.White,
    onclick = function()
      if animating then return end
      core.goToScene("menu")
    end,
    updatePos = function(ctx, opt)
      local vw, vh = lg.getDimensions()
      opt.w, opt.h = (vw - px) / 4, py - (1.5 * px)
      ctx.x, ctx.y = px / 2, vh - opt.h - (px / 2)
    end,
  })

  local undoBtn = Button({
    label = "undo",
    mode = "line",
    color = Color.FireOpal,
    txtColor = Color.FireOpal,
    onclick = function()
      if animating then return end
      state.undo()
    end,
    updatePos = function(ctx, opt)
      local vw, vh = lg.getDimensions()
      opt.w, opt.h = (vw - px) / 4, py - (1.5 * px)
      ctx.x, ctx.y = opt.w + px, vh - opt.h - (px / 2)
    end,
  })

  local playerIndicator = Button({
    label = "player x's turn",
    mode = "line",
    color = Color.ChineseBlack,
    onclick = function() end,
    updatePos = function(ctx, opt)
      local vw, vh = lg.getDimensions()
      opt.w, opt.h = (vw - px) / 2, py - (1.5 * px)
      ctx.x, ctx.y = (px / 2) + opt.w, vh - opt.h - (px / 2)

      local playing = state.playing().player
      opt.txtColor = playing.color
      ctx.txt:set(sf("%s's turn", playing.label))
    end,
  })

  local function load()
    lume.push(entities, playerIndicator, homeButton, undoBtn)
  end

  return core.Entity({
    load = load,
    update = function()
      if input:pressed("back") then core.goToScene("menu") end
    end,
  })
end

return core.Scene({
  id = "game",
  entities = entities,
  enter = function(args)
    state.init(12, 6, args.players)
    local rows, cols = state.matrixDimensions()
    for i = 1, rows do
      for j = 1, cols do
        lume.push(entities, Cell(i, j), Neutrons(i, j))
      end
    end
    lume.push(entities, BottomPanel(), GameOverModal())
    animating = false
  end,
  leave = function()
    lume.each(entities, function(e)
      e.ctx.dead = true
    end)
  end,
})
