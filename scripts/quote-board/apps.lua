-- quote-board mini-apps
-- Required by quote-board.lua
--
-- Each app is a small interactive screen opened from the launcher (key A).
-- Apps receive a context table from the host and return action strings:
--   "redraw" | "home" | "close" | "abort_music" | nil

local Apps = {}

local function clamp(n, lo, hi)
  if n < lo then return lo end
  if n > hi then return hi end
  return n
end

local function drawHeader(mon, w, title, right)
  mon.setCursorPos(1, 1)
  mon.setBackgroundColour(colours.grey)
  mon.setTextColour(colours.yellow)
  mon.clearLine()
  mon.setCursorPos(1, 1)
  mon.write((" " .. title):sub(1, w))
  if right and #right > 0 then
    mon.setTextColour(colours.white)
    mon.setCursorPos(math.max(1, w - #right + 1), 1)
    mon.write(right:sub(1, w))
  end
  mon.setBackgroundColour(colours.black)
  mon.setTextColour(colours.grey)
  mon.setCursorPos(1, 2)
  mon.write(string.rep("-", w))
end

local function drawFooter(mon, w, h, text)
  mon.setCursorPos(1, h)
  mon.setBackgroundColour(colours.grey)
  mon.setTextColour(colours.lightGrey)
  mon.clearLine()
  mon.setCursorPos(1, h)
  mon.write((" " .. (text or "A apps  X back")):sub(1, w))
  mon.setBackgroundColour(colours.black)
end

local function writeLines(mon, lines, startRow, endRow, w, selected)
  local row = startRow
  for i, line in ipairs(lines) do
    if row > endRow then break end
    if selected and i == selected then
      mon.setBackgroundColour(colours.grey)
      mon.setTextColour(colours.yellow)
      mon.setCursorPos(1, row)
      mon.clearLine()
      mon.setCursorPos(2, row)
      mon.write(("> " .. line):sub(1, w - 1))
      mon.setBackgroundColour(colours.black)
    else
      mon.setTextColour(colours.white)
      mon.setCursorPos(2, row)
      mon.write(line:sub(1, w - 2))
    end
    row = row + 1
  end
end

-- ============================================================
-- Launcher
-- ============================================================
local function newLauncher(ctx)
  local self = {
    id = "launcher",
    cursor = 1,
    catalog = {
      { id = "jukebox", title = "Jukebox",      blurb = "Browse and queue songs" },
      { id = "library", title = "Quote Library", blurb = "Browse the quote pool" },
      { id = "chatlog", title = "Chat Log",     blurb = "Recent player quotes" },
      { id = "clock",   title = "Clock",        blurb = "Large clock display" },
      { id = "stats",   title = "Stats",        blurb = "Session and library info" },
      { id = "dice",    title = "Dice",         blurb = "Roll for the room" },
      { id = "about",   title = "About",        blurb = "What this board is" },
    },
  }

  function self:draw(mon)
    local w, h = mon.getSize()
    mon.setBackgroundColour(colours.black)
    mon.setTextColour(colours.white)
    mon.clear()
    drawHeader(mon, w, "APPS", "A=board")

    local lines = {}
    for i, app in ipairs(self.catalog) do
      lines[i] = string.format("%d  %s", i, app.title)
    end
    writeLines(mon, lines, 3, h - 3, w, self.cursor)

    local sel = self.catalog[self.cursor]
    if sel and h >= 4 then
      mon.setTextColour(colours.lightGrey)
      mon.setCursorPos(2, h - 2)
      mon.write((sel.blurb or ""):sub(1, w - 2))
    end
    drawFooter(mon, w, h, "Up/Down Enter  1-7 open  X back  A board")
  end

  function self:onKey(key)
    if key == keys.up then
      self.cursor = self.cursor <= 1 and #self.catalog or (self.cursor - 1)
      return "redraw"
    elseif key == keys.down then
      self.cursor = self.cursor >= #self.catalog and 1 or (self.cursor + 1)
      return "redraw"
    elseif key == keys.enter then
      local app = self.catalog[self.cursor]
      if app then ctx.openApp(app.id) end
      return "redraw"
    else
      local numKeys = {
        keys.one, keys.two, keys.three, keys.four, keys.five,
        keys.six, keys.seven, keys.eight, keys.nine,
      }
      for i = 1, math.min(#numKeys, #self.catalog) do
        if key == numKeys[i] then
          ctx.openApp(self.catalog[i].id)
          return "redraw"
        end
      end
    end
    return nil
  end

  function self:onTouch(x, y, w, h)
    local idx = y - 2
    if idx >= 1 and idx <= #self.catalog then
      self.cursor = idx
      ctx.openApp(self.catalog[idx].id)
      return "redraw"
    end
    return nil
  end

  return self
end

-- ============================================================
-- Jukebox
-- ============================================================
local function newJukebox(ctx)
  local self = { id = "jukebox", cursor = 1, scroll = 0 }

  local function visibleCount(h)
    return math.max(1, h - 5)
  end

  function self:draw(mon)
    local w, h = mon.getSize()
    mon.setBackgroundColour(colours.black)
    mon.clear()
    local right = (ctx.state.musicOn and ctx.state.songName or "MUTED")
    drawHeader(mon, w, "JUKEBOX", right:sub(1, math.floor(w / 2)))

    local vis = visibleCount(h)
    self.cursor = clamp(self.cursor, 1, #ctx.SONGS)
    if self.cursor < self.scroll + 1 then self.scroll = self.cursor - 1 end
    if self.cursor > self.scroll + vis then self.scroll = self.cursor - vis end
    self.scroll = clamp(self.scroll, 0, math.max(0, #ctx.SONGS - vis))

    for row = 1, vis do
      local idx = self.scroll + row
      local song = ctx.SONGS[idx]
      if not song then break end
      local pl = song.playlist or "?"
      local mark = (ctx.state.songName == song.name) and "*" or " "
      local line = string.format("%s%2d %s [%s]", mark, idx, song.name or "?", pl)
      local y = row + 2
      if idx == self.cursor then
        mon.setBackgroundColour(colours.grey)
        mon.setTextColour(colours.yellow)
        mon.setCursorPos(1, y)
        mon.clearLine()
        mon.setCursorPos(1, y)
        mon.write((">" .. line):sub(1, w))
        mon.setBackgroundColour(colours.black)
      else
        mon.setTextColour(colours.white)
        mon.setCursorPos(2, y)
        mon.write(line:sub(1, w - 2))
      end
    end

    mon.setTextColour(colours.lightGrey)
    mon.setCursorPos(2, h - 2)
    mon.write(("Enter play  N skip  M mute  " .. #ctx.SONGS .. " tracks"):sub(1, w - 2))
    drawFooter(mon, w, h, "Up/Down  Enter play  X launcher")
  end

  function self:onKey(key)
    if key == keys.up then
      self.cursor = clamp(self.cursor - 1, 1, #ctx.SONGS)
      return "redraw"
    elseif key == keys.down then
      self.cursor = clamp(self.cursor + 1, 1, #ctx.SONGS)
      return "redraw"
    elseif key == keys.enter then
      ctx.queueSong(self.cursor)
      return "abort_music"
    elseif key == keys.n then
      ctx.requestSkipSong()
      return "abort_music"
    elseif key == keys.m then
      ctx.toggleMusic()
      return ctx.state.musicOn and "redraw" or "abort_music"
    end
    return nil
  end

  function self:onTouch(x, y, w, h)
    local vis = visibleCount(h)
    local row = y - 2
    if row >= 1 and row <= vis then
      local idx = self.scroll + row
      if ctx.SONGS[idx] then
        self.cursor = idx
        ctx.queueSong(idx)
        return "abort_music"
      end
    end
    return nil
  end

  return self
end

-- ============================================================
-- Quote Library
-- ============================================================
local function newLibrary(ctx)
  local self = { id = "library", cursor = 1, scroll = 0 }

  local function count()
    return #ctx.allQuotes
  end

  function self:draw(mon)
    local w, h = mon.getSize()
    mon.setBackgroundColour(colours.black)
    mon.clear()
    drawHeader(mon, w, "QUOTE LIBRARY", self.cursor .. "/" .. count())

    local q = ctx.allQuotes[self.cursor]
    if not q then
      mon.setTextColour(colours.red)
      mon.setCursorPos(2, 4)
      mon.write("No quotes.")
      drawFooter(mon, w, h)
      return
    end

    mon.setTextColour(colours.yellow)
    mon.setCursorPos(2, 3)
    mon.write(("[ " .. q[3] .. " ]"):sub(1, w - 2))

    local bodyW = math.max(8, w - 4)
    local wrapped = ctx.wordWrap(q[1], bodyW)
    local bodyEnd = h - 4
    for i, line in ipairs(wrapped) do
      local y = 5 + i - 1
      if y > bodyEnd then break end
      mon.setTextColour(colours.white)
      mon.setCursorPos(2, y)
      mon.write(line:sub(1, bodyW))
    end

    mon.setTextColour(colours.lightGrey)
    mon.setCursorPos(2, h - 2)
    mon.write(("— " .. q[2]):sub(1, w - 2))
    drawFooter(mon, w, h, "Left/Right browse  Enter show on board  X back")
  end

  function self:onKey(key)
    local n = count()
    if n < 1 then return nil end
    if key == keys.left or key == keys.up then
      self.cursor = self.cursor <= 1 and n or (self.cursor - 1)
      return "redraw"
    elseif key == keys.right or key == keys.down then
      self.cursor = self.cursor >= n and 1 or (self.cursor + 1)
      return "redraw"
    elseif key == keys.enter then
      ctx.showQuoteIndex(self.cursor)
      return "close"
    end
    return nil
  end

  function self:onTouch(x, y, w, h)
    if x < w / 2 then
      return self:onKey(keys.left)
    else
      return self:onKey(keys.right)
    end
  end

  return self
end

-- ============================================================
-- Chat Log
-- ============================================================
local function newChatLog(ctx)
  local self = { id = "chatlog", cursor = 1 }

  local function list()
    return ctx.chatQuotes
  end

  function self:draw(mon)
    local w, h = mon.getSize()
    mon.setBackgroundColour(colours.black)
    mon.clear()
    local items = list()
    drawHeader(mon, w, "CHAT LOG", #items .. " saved")

    if #items == 0 then
      mon.setTextColour(colours.lightGrey)
      mon.setCursorPos(2, 4)
      mon.write("No player quotes yet.")
      mon.setCursorPos(2, 5)
      mon.write("Chat when a Chat Box is attached.")
      drawFooter(mon, w, h)
      return
    end

    self.cursor = clamp(self.cursor, 1, #items)
    -- Show newest first
    local idx = #items - self.cursor + 1
    local q = items[idx]
    mon.setTextColour(colours.pink)
    mon.setCursorPos(2, 3)
    mon.write(("PLAYER  " .. (q[2] or "?")):sub(1, w - 2))

    local wrapped = ctx.wordWrap(q[1] or "", math.max(8, w - 4))
    for i, line in ipairs(wrapped) do
      local y = 5 + i - 1
      if y > h - 3 then break end
      mon.setTextColour(colours.white)
      mon.setCursorPos(2, y)
      mon.write(line:sub(1, w - 2))
    end
    drawFooter(mon, w, h, "Up/Down  Enter pin to board  X back")
  end

  function self:onKey(key)
    local items = list()
    if #items == 0 then return nil end
    if key == keys.up then
      self.cursor = clamp(self.cursor - 1, 1, #items)
      return "redraw"
    elseif key == keys.down then
      self.cursor = clamp(self.cursor + 1, 1, #items)
      return "redraw"
    elseif key == keys.enter then
      local idx = #items - self.cursor + 1
      -- Map chat quote to allQuotes index (builtins first)
      local allIdx = #ctx.allQuotes - #items + idx
      if ctx.allQuotes[allIdx] and ctx.allQuotes[allIdx][3] == "PLAYER" then
        ctx.showQuoteIndex(allIdx)
        return "close"
      end
    end
    return nil
  end

  function self:onTouch(x, y, w, h)
    return self:onKey(x < w / 2 and keys.up or keys.down)
  end

  return self
end

-- ============================================================
-- Clock
-- ============================================================
local function newClock(ctx)
  local self = { id = "clock" }

  local function nowParts()
    local ok, t = pcall(os.date, "*t")
    if ok and type(t) == "table" then return t end
    return nil
  end

  function self:draw(mon)
    local w, h = mon.getSize()
    mon.setBackgroundColour(colours.black)
    mon.clear()
    drawHeader(mon, w, "CLOCK", ctx.state.songName)

    local t = nowParts()
    local timeStr = t and string.format("%02d:%02d:%02d", t.hour, t.min, t.sec) or ctx.clockString()
    local dateStr = t and string.format("%04d-%02d-%02d", t.year, t.month, t.day) or ""

    mon.setTextColour(colours.yellow)
    mon.setCursorPos(1, math.max(3, math.floor(h / 2) - 1))
    mon.write(ctx.centre(timeStr, w))

    if dateStr ~= "" then
      mon.setTextColour(colours.white)
      mon.setCursorPos(1, math.max(4, math.floor(h / 2) + 1))
      mon.write(ctx.centre(dateStr, w))
    end

    mon.setTextColour(colours.lightGrey)
    mon.setCursorPos(1, math.min(h - 2, math.floor(h / 2) + 3))
    mon.write(ctx.centre("Up " .. ctx.uptimeString(), w))
    drawFooter(mon, w, h, "Live clock  X back  A board")
  end

  function self:onKey(key)
    return nil
  end

  function self:onTouch()
    return "home"
  end

  function self:tick()
    return "redraw"
  end

  return self
end

-- ============================================================
-- Stats
-- ============================================================
local function newStats(ctx)
  local self = { id = "stats" }

  local function catCounts()
    local c = {}
    for _, q in ipairs(ctx.allQuotes) do
      local cat = q[3] or "?"
      c[cat] = (c[cat] or 0) + 1
    end
    return c
  end

  local function playlistCounts()
    local c = {}
    for i, s in ipairs(ctx.SONGS) do
      local pl = s.playlist or "?"
      c[pl] = (c[pl] or 0) + 1
    end
    return c
  end

  function self:draw(mon)
    local w, h = mon.getSize()
    mon.setBackgroundColour(colours.black)
    mon.clear()
    drawHeader(mon, w, "STATS", ctx.uptimeString())

    local lines = {
      "Quotes shown:  " .. ctx.state.quotesShown,
      "Chat captured: " .. ctx.state.chatCaptured,
      "Quote pool:    " .. #ctx.allQuotes,
      "Chat saved:    " .. #ctx.chatQuotes,
      "Songs:         " .. #ctx.SONGS,
      "Speakers:      " .. ctx.state.speakerCount,
      "Volume:        " .. math.floor(ctx.state.volume * 100 + 0.5) .. "%",
      "Playlist:      " .. (ctx.playlistLabel(ctx.state.playlist) or ctx.state.playlist),
      "Filter:        " .. tostring(ctx.state.categoryFilter),
      "Music:         " .. (ctx.state.musicOn and "on" or "muted"),
      "Now:           " .. tostring(ctx.state.songName),
    }

    local cats = catCounts()
    lines[#lines + 1] = ""
    lines[#lines + 1] = "Categories:"
    for _, name in ipairs({ "TIP", "DID YOU KNOW", "WISDOM", "LOADING", "QUOTE", "PLAYER" }) do
      if cats[name] then
        lines[#lines + 1] = "  " .. name .. ": " .. cats[name]
      end
    end

    local pls = playlistCounts()
    lines[#lines + 1] = ""
    lines[#lines + 1] = "Playlists:"
    for _, name in ipairs({ "title", "elevator", "zelda", "runescape", "original" }) do
      if pls[name] then
        lines[#lines + 1] = "  " .. name .. ": " .. pls[name]
      end
    end

    for i, line in ipairs(lines) do
      local y = i + 2
      if y >= h then break end
      mon.setTextColour(colours.white)
      mon.setCursorPos(2, y)
      mon.write(line:sub(1, w - 2))
    end
    drawFooter(mon, w, h)
  end

  function self:onKey() return nil end
  function self:onTouch() return "home" end

  return self
end

-- ============================================================
-- Dice
-- ============================================================
local function newDice(ctx)
  local self = {
    id = "dice",
    sides = 20,
    last = nil,
    history = {},
  }

  local SIDE_OPTIONS = { 2, 4, 6, 8, 10, 12, 20, 100 }

  local function sideIndex()
    for i, s in ipairs(SIDE_OPTIONS) do
      if s == self.sides then return i end
    end
    return 7
  end

  local function roll()
    self.last = math.random(1, self.sides)
    self.history[#self.history + 1] = { sides = self.sides, value = self.last }
    if #self.history > 8 then table.remove(self.history, 1) end
    ctx.flash("d" .. self.sides .. " = " .. self.last, 2000)
  end

  function self:draw(mon)
    local w, h = mon.getSize()
    mon.setBackgroundColour(colours.black)
    mon.clear()
    drawHeader(mon, w, "DICE", "d" .. self.sides)

    mon.setTextColour(colours.yellow)
    mon.setCursorPos(1, math.max(3, math.floor(h / 2) - 2))
    local shown = self.last and tostring(self.last) or "--"
    mon.write(ctx.centre(shown, w))

    mon.setTextColour(colours.white)
    mon.setCursorPos(1, math.max(4, math.floor(h / 2)))
    mon.write(ctx.centre("d" .. self.sides, w))

    mon.setTextColour(colours.lightGrey)
    mon.setCursorPos(2, h - 3)
    local hist = {}
    for i, r in ipairs(self.history) do
      hist[i] = "d" .. r.sides .. "=" .. r.value
    end
    mon.write(table.concat(hist, "  "):sub(1, w - 2))

    drawFooter(mon, w, h, "Enter roll  Left/Right sides  X back")
  end

  function self:onKey(key)
    if key == keys.enter or key == keys.space then
      roll()
      return "redraw"
    elseif key == keys.left then
      local i = sideIndex()
      self.sides = SIDE_OPTIONS[i <= 1 and #SIDE_OPTIONS or (i - 1)]
      return "redraw"
    elseif key == keys.right then
      local i = sideIndex()
      self.sides = SIDE_OPTIONS[i >= #SIDE_OPTIONS and 1 or (i + 1)]
      return "redraw"
    end
    return nil
  end

  function self:onTouch(x, y, w, h)
    if y <= 3 then
      return self:onKey(x < w / 2 and keys.left or keys.right)
    end
    roll()
    return "redraw"
  end

  return self
end

-- ============================================================
-- About
-- ============================================================
local function newAbout(ctx)
  local self = { id = "about" }

  function self:draw(mon)
    local w, h = mon.getSize()
    mon.setBackgroundColour(colours.black)
    mon.clear()
    drawHeader(mon, w, "ABOUT", "DekMiscCC")

    local lines = {
      ctx.boardTitle or "Quote Board",
      "",
      "HOI4-style tips on a monitor,",
      "with music and live chat.",
      "",
      "Apps: jukebox, library, chat",
      "log, clock, stats, dice.",
      "",
      #ctx.SONGS .. " songs  ·  " .. #ctx.allQuotes .. " quotes",
      "",
      "A  app launcher",
      "H  controls help",
      "Q  quit",
      "",
      "Chat: #apps #app jukebox",
    }
    for i, line in ipairs(lines) do
      local y = i + 2
      if y >= h then break end
      mon.setTextColour(i == 1 and colours.yellow or colours.white)
      mon.setCursorPos(2, y)
      mon.write(line:sub(1, w - 2))
    end
    drawFooter(mon, w, h)
  end

  function self:onKey() return nil end
  function self:onTouch() return "home" end

  return self
end

-- ============================================================
-- Factory
-- ============================================================
local FACTORIES = {
  launcher = newLauncher,
  jukebox  = newJukebox,
  library  = newLibrary,
  chatlog  = newChatLog,
  clock    = newClock,
  stats    = newStats,
  dice     = newDice,
  about    = newAbout,
}

function Apps.open(id, ctx)
  local factory = FACTORIES[id or "launcher"] or FACTORIES.launcher
  return factory(ctx)
end

function Apps.ids()
  return { "jukebox", "library", "chatlog", "clock", "stats", "dice", "about" }
end

return Apps
