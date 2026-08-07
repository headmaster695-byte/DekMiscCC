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
      { id = "jukebox",  title = "Jukebox",        blurb = "Browse and queue songs" },
      { id = "library",  title = "Quote Library",  blurb = "Browse the quote pool" },
      { id = "workshop", title = "Quote Workshop", blurb = "New / rewrite / enable customs" },
      { id = "scenes",   title = "Atmospheres",    blurb = "Scenes: playlist + quotes + title" },
      { id = "chatlog",  title = "Chat Log",       blurb = "Recent player quotes" },
      { id = "clock",    title = "Clock",          blurb = "Large clock display" },
      { id = "stats",    title = "Stats",          blurb = "Session and library info" },
      { id = "dice",     title = "Dice",           blurb = "Roll for the room" },
      { id = "about",    title = "About",          blurb = "What this board is" },
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
    drawFooter(mon, w, h, "Up/Down Enter  1-9 open  X back  A board")
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
-- Quote Workshop (custom quotes: new / rewrite / enable)
-- Customs default to OFF and only join the pool when enabled.
-- ============================================================
local function newWorkshop(ctx)
  local CAT_ORDER = ctx.customCategories
    or { "TIP", "DID YOU KNOW", "WISDOM", "LOADING", "QUOTE" }

  local self = {
    id = "workshop",
    mode = "list",       -- list | edit | pick
    cursor = 1,
    scroll = 0,
    pickCursor = 1,
    pickScroll = 0,
    editIdx = nil,       -- nil = creating new
    editField = 1,       -- 1 text, 2 source, 3 category
    draft = nil,         -- { text, source, category, enabled }
  }

  local function customs()
    return ctx.customQuotes
  end

  local function builtins()
    return ctx.BUILTIN_QUOTES or {}
  end

  local function enabledCount()
    local n = 0
    for _, q in ipairs(customs()) do
      if q[4] == true then n = n + 1 end
    end
    return n
  end

  local function persist()
    if ctx.saveCustomQuotes then ctx.saveCustomQuotes() end
  end

  local function beginEdit(idx, seed)
    self.mode = "edit"
    self.editIdx = idx
    self.editField = 1
    if seed then
      self.draft = {
        seed[1] or "",
        seed[2] or "Custom",
        seed[3] or "TIP",
        seed[4] == true,
      }
    else
      self.draft = { "", "Custom", "TIP", false }
    end
  end

  local function cycleCategory(dir)
    local cur = self.draft[3] or "TIP"
    local idx = 1
    for i, c in ipairs(CAT_ORDER) do
      if c == cur then idx = i break end
    end
    idx = idx + (dir or 1)
    if idx < 1 then idx = #CAT_ORDER end
    if idx > #CAT_ORDER then idx = 1 end
    self.draft[3] = CAT_ORDER[idx]
  end

  local function saveDraft()
    local text = (self.draft[1] or ""):gsub("^%s+", ""):gsub("%s+$", "")
    local source = (self.draft[2] or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if text == "" then
      ctx.flash("Text required", 2000)
      return false
    end
    if source == "" then source = "Custom" end
    local row = { text, source, self.draft[3] or "TIP", self.draft[4] == true }
    if ctx.normalizeCustomQuote then
      row = ctx.normalizeCustomQuote(row) or row
    end
    local list = customs()
    if self.editIdx and list[self.editIdx] then
      list[self.editIdx] = row
      ctx.flash(row[4] and "Saved (ON)" or "Saved (OFF)", 2000)
    else
      list[#list + 1] = row
      self.cursor = #list
      ctx.flash(row[4] and "Created (ON)" or "Created (OFF — enable with E)", 2500)
    end
    persist()
    self.mode = "list"
    self.draft = nil
    self.editIdx = nil
    return true
  end

  local function visibleCount(h)
    return math.max(1, h - 6)
  end

  local function drawList(mon, w, h)
    local list = customs()
    local right = enabledCount() .. "/" .. #list .. " on"
    drawHeader(mon, w, "QUOTE WORKSHOP", right)

    if #list == 0 then
      mon.setTextColour(colours.lightGrey)
      mon.setCursorPos(2, 4)
      mon.write("No custom quotes yet.")
      mon.setCursorPos(2, 5)
      mon.write("N new   B rewrite a builtin")
      mon.setCursorPos(2, 6)
      mon.write("New quotes stay OFF until enabled.")
      drawFooter(mon, w, h, "N new  B from builtin  X back")
      return
    end

    local vis = visibleCount(h)
    self.cursor = clamp(self.cursor, 1, #list)
    if self.cursor < self.scroll + 1 then self.scroll = self.cursor - 1 end
    if self.cursor > self.scroll + vis then self.scroll = self.cursor - vis end
    self.scroll = clamp(self.scroll, 0, math.max(0, #list - vis))

    for row = 1, vis do
      local idx = self.scroll + row
      local q = list[idx]
      if not q then break end
      local mark = q[4] and "ON " or "off"
      local preview = (q[1] or ""):gsub("%s+", " ")
      local line = string.format("%s %s [%s] %s", mark, idx, q[3] or "?", preview)
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
        mon.setTextColour(q[4] and colours.lime or colours.lightGrey)
        mon.setCursorPos(2, y)
        mon.write(line:sub(1, w - 2))
      end
    end

    local sel = list[self.cursor]
    if sel and h >= 5 then
      mon.setTextColour(colours.white)
      mon.setCursorPos(2, h - 3)
      mon.write(("— " .. (sel[2] or "")):sub(1, w - 2))
    end
    drawFooter(mon, w, h, "E on/off  R rewrite  N new  B builtin  D del")
  end

  local function drawEdit(mon, w, h)
    local title = self.editIdx and "REWRITE QUOTE" or "NEW QUOTE"
    local en = self.draft[4] and "ON" or "OFF"
    drawHeader(mon, w, title, en)

    local labels = { "Text", "Source", "Category" }
    local values = {
      self.draft[1] or "",
      self.draft[2] or "",
      self.draft[3] or "TIP",
    }

    for i = 1, 3 do
      local y = 2 + i * 2
      if y >= h - 2 then break end
      local selected = (self.editField == i)
      mon.setTextColour(selected and colours.yellow or colours.lightGrey)
      mon.setCursorPos(2, y)
      mon.write((labels[i] .. ":"))
      mon.setTextColour(colours.white)
      if selected then
        mon.setBackgroundColour(colours.grey)
        mon.setCursorPos(2, y + 1)
        mon.clearLine()
        mon.setCursorPos(2, y + 1)
        local shown = values[i]
        if i < 3 then shown = shown .. "_" end
        mon.write(shown:sub(math.max(1, #shown - (w - 3)), #shown))
        mon.setBackgroundColour(colours.black)
      else
        mon.setCursorPos(2, y + 1)
        mon.write(values[i]:sub(1, w - 2))
      end
    end

    mon.setTextColour(colours.lightGrey)
    mon.setCursorPos(2, h - 2)
    mon.write(("Tab fields  On Category: Left/Right / T on-off"):sub(1, w - 2))
    drawFooter(mon, w, h, "Type to edit  Backspace erase  Enter save  X cancel")
  end

  local function drawPick(mon, w, h)
    local list = builtins()
    drawHeader(mon, w, "REWRITE BUILTIN", self.pickCursor .. "/" .. #list)

    if #list == 0 then
      mon.setTextColour(colours.red)
      mon.setCursorPos(2, 4)
      mon.write("No builtins.")
      drawFooter(mon, w, h, "X back")
      return
    end

    local vis = visibleCount(h)
    self.pickCursor = clamp(self.pickCursor, 1, #list)
    if self.pickCursor < self.pickScroll + 1 then self.pickScroll = self.pickCursor - 1 end
    if self.pickCursor > self.pickScroll + vis then self.pickScroll = self.pickCursor - vis end
    self.pickScroll = clamp(self.pickScroll, 0, math.max(0, #list - vis))

    for row = 1, vis do
      local idx = self.pickScroll + row
      local q = list[idx]
      if not q then break end
      local preview = (q[1] or ""):gsub("%s+", " ")
      local line = string.format("%s [%s] %s", idx, q[3] or "?", preview)
      local y = row + 2
      if idx == self.pickCursor then
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
    drawFooter(mon, w, h, "Enter copy to workshop (starts OFF)  X back")
  end

  function self:draw(mon)
    local w, h = mon.getSize()
    mon.setBackgroundColour(colours.black)
    mon.clear()
    if self.mode == "edit" then
      drawEdit(mon, w, h)
    elseif self.mode == "pick" then
      drawPick(mon, w, h)
    else
      drawList(mon, w, h)
    end
  end

  function self:onChar(ch)
    if self.mode ~= "edit" or type(ch) ~= "string" or #ch == 0 then return nil end
    if self.editField == 3 then return "redraw" end  -- category via C / arrows
    local field = self.editField
    local cur = self.draft[field] or ""
    if #cur >= 200 then return "redraw" end
    self.draft[field] = cur .. ch
    return "redraw"
  end

  function self:onKey(key)
    if self.mode == "edit" then
      if key == keys.x then
        self.mode = "list"
        self.draft = nil
        self.editIdx = nil
        return "redraw"
      elseif key == keys.tab or key == keys.down then
        self.editField = self.editField >= 3 and 1 or (self.editField + 1)
        return "redraw"
      elseif key == keys.up then
        self.editField = self.editField <= 1 and 3 or (self.editField - 1)
        return "redraw"
      elseif key == keys.backspace then
        if self.editField < 3 then
          local cur = self.draft[self.editField] or ""
          self.draft[self.editField] = cur:sub(1, math.max(0, #cur - 1))
        end
        return "redraw"
      elseif key == keys.left or key == keys.right then
        if self.editField == 3 then
          cycleCategory(key == keys.left and -1 or 1)
        end
        return "redraw"
      elseif key == keys.c then
        -- Only when on Category (otherwise typing "c" would steal the key).
        if self.editField == 3 then
          cycleCategory(1)
        end
        return "redraw"
      elseif key == keys.t then
        if self.editField == 3 then
          self.draft[4] = not self.draft[4]
        end
        return "redraw"
      elseif key == keys.enter then
        saveDraft()
        return "redraw"
      end
      return "redraw"  -- swallow keys while editing (except globals Q/A)
    end

    if self.mode == "pick" then
      local list = builtins()
      if key == keys.x then
        self.mode = "list"
        return "redraw"
      elseif key == keys.up then
        self.pickCursor = clamp(self.pickCursor - 1, 1, math.max(1, #list))
        return "redraw"
      elseif key == keys.down then
        self.pickCursor = clamp(self.pickCursor + 1, 1, math.max(1, #list))
        return "redraw"
      elseif key == keys.enter then
        local q = list[self.pickCursor]
        if q then
          beginEdit(nil, { q[1], q[2], q[3], false })
          ctx.flash("Rewrite starts OFF — enable when ready", 2500)
        end
        return "redraw"
      end
      return nil
    end

    -- list mode
    local list = customs()
    if key == keys.up then
      if #list > 0 then self.cursor = clamp(self.cursor - 1, 1, #list) end
      return "redraw"
    elseif key == keys.down then
      if #list > 0 then self.cursor = clamp(self.cursor + 1, 1, #list) end
      return "redraw"
    elseif key == keys.n then
      beginEdit(nil, nil)
      return "redraw"
    elseif key == keys.b then
      self.mode = "pick"
      self.pickCursor = 1
      self.pickScroll = 0
      return "redraw"
    elseif key == keys.e then
      local q = list[self.cursor]
      if q then
        q[4] = not q[4]
        persist()
        ctx.flash(q[4] and "Enabled in pool" or "Disabled (hidden from pool)", 2000)
      end
      return "redraw"
    elseif key == keys.r or key == keys.enter then
      local q = list[self.cursor]
      if q then beginEdit(self.cursor, q) end
      return "redraw"
    elseif key == keys.d or key == keys.delete then
      if list[self.cursor] then
        table.remove(list, self.cursor)
        self.cursor = clamp(self.cursor, 1, math.max(1, #list))
        persist()
        ctx.flash("Deleted", 1500)
      end
      return "redraw"
    end
    return nil
  end

  function self:onTouch(x, y, w, h)
    if self.mode == "edit" then
      if y >= 4 and y <= 5 then self.editField = 1
      elseif y >= 6 and y <= 7 then self.editField = 2
      elseif y >= 8 and y <= 9 then self.editField = 3; cycleCategory(1)
      end
      return "redraw"
    end
    if self.mode == "pick" then
      local row = y - 2
      local vis = visibleCount(h)
      if row >= 1 and row <= vis then
        local idx = self.pickScroll + row
        if builtins()[idx] then
          self.pickCursor = idx
          return self:onKey(keys.enter)
        end
      end
      return nil
    end
    local row = y - 2
    local vis = visibleCount(h)
    if row >= 1 and row <= vis then
      local idx = self.scroll + row
      if customs()[idx] then
        self.cursor = idx
        return self:onKey(keys.e)
      end
    end
    return nil
  end

  return self
end

-- ============================================================
-- Atmospheres (scenes): playlist + category + title bundles
-- ============================================================
local function newScenes(ctx)
  local PLAYLISTS = ctx.playlistOrder
    or { "all", "elevator", "zelda", "runescape", "undertale", "original", "title" }
  local CATS = ctx.categoryOrder
    or { "ALL", "TIP", "DID YOU KNOW", "WISDOM", "LOADING", "QUOTE", "PLAYER" }

  local self = {
    id = "scenes",
    mode = "list", -- list | edit
    cursor = 1,
    scroll = 0,
    editIdx = nil,   -- index into customScenes, or nil for new
    editField = 1,
    draft = nil,
  }

  local FIELD_LABELS = {
    "Name", "Title", "Blurb", "Playlist", "Category", "From hour", "To hour",
  }

  local function scenes()
    return ctx.listScenes and ctx.listScenes() or {}
  end

  local function customs()
    return ctx.customScenes or {}
  end

  local function hourLabel(scene)
    if type(scene.fromHour) ~= "number" or type(scene.toHour) ~= "number" then
      return "manual"
    end
    return string.format("%02d-%02d", scene.fromHour, scene.toHour)
  end

  local function beginEdit(customIndex, seed)
    self.mode = "edit"
    self.editIdx = customIndex
    self.editField = 1
    seed = seed or {}
    self.draft = {
      name = seed.name or "New Scene",
      title = seed.title or "",
      blurb = seed.blurb or "",
      playlist = seed.playlist or "all",
      category = seed.category or "ALL",
      fromHour = seed.fromHour, -- may be nil
      toHour = seed.toHour,
      priority = seed.priority or 3,
      id = seed.id,
    }
  end

  local function fieldValue(i)
    local d = self.draft
    if i == 1 then return d.name or ""
    elseif i == 2 then return d.title or ""
    elseif i == 3 then return d.blurb or ""
    elseif i == 4 then return d.playlist or "all"
    elseif i == 5 then return d.category or "ALL"
    elseif i == 6 then
      return d.fromHour ~= nil and tostring(d.fromHour) or "off"
    elseif i == 7 then
      return d.toHour ~= nil and tostring(d.toHour) or "off"
    end
    return ""
  end

  local function cycleList(list, cur, dir)
    local idx = 1
    for i, v in ipairs(list) do
      if v == cur then idx = i break end
    end
    idx = idx + (dir or 1)
    if idx < 1 then idx = #list end
    if idx > #list then idx = 1 end
    return list[idx]
  end

  local function nudgeHour(field, dir)
    local key = field == 6 and "fromHour" or "toHour"
    local cur = self.draft[key]
    if cur == nil then
      self.draft.fromHour = self.draft.fromHour or 0
      self.draft.toHour = self.draft.toHour or 6
      return
    end
    cur = cur + (dir or 1)
    if cur < 0 then cur = 23 end
    if cur > 23 then cur = 0 end
    self.draft[key] = cur
  end

  local function saveDraft()
    local name = (self.draft.name or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if name == "" then
      ctx.flash("Name required", 2000)
      return false
    end
    local row = {
      id = self.draft.id,
      name = name,
      title = self.draft.title or "",
      blurb = self.draft.blurb or "",
      playlist = self.draft.playlist or "all",
      category = self.draft.category or "ALL",
      fromHour = self.draft.fromHour,
      toHour = self.draft.toHour,
      priority = self.draft.priority or 3,
      custom = true,
    }
    if not row.id or row.id == "" then
      row.id = (ctx.slugify and ctx.slugify(name)) or name:lower()
    end
    if ctx.normalizeScene then
      row = ctx.normalizeScene(row) or row
      row.custom = true
    end
    local list = customs()
    if self.editIdx and list[self.editIdx] then
      list[self.editIdx] = row
      ctx.flash("Scene saved", 2000)
    else
      -- ensure unique id
      local base, n = row.id, 2
      while true do
        local clash = false
        for _, s in ipairs(scenes()) do
          if s.id == row.id then clash = true break end
        end
        if not clash then break end
        row.id = base .. "-" .. n
        n = n + 1
      end
      list[#list + 1] = row
      ctx.flash("Scene created", 2000)
    end
    if ctx.saveCustomScenes then ctx.saveCustomScenes() end
    self.mode = "list"
    self.draft = nil
    self.editIdx = nil
    return true
  end

  local function visibleCount(h)
    return math.max(1, h - 6)
  end

  local function findCustomIndexById(id)
    for i, s in ipairs(customs()) do
      if s.id == id then return i end
    end
    return nil
  end

  local function drawList(mon, w, h)
    local list = scenes()
    local hour = ctx.minecraftHour and string.format("%.0f", ctx.minecraftHour()) or "?"
    local right = (ctx.state.sceneAuto and "AUTO" or "manual") .. " h" .. hour
    drawHeader(mon, w, "ATMOSPHERES", right)

    if #list == 0 then
      mon.setTextColour(colours.lightGrey)
      mon.setCursorPos(2, 4)
      mon.write("No scenes.")
      drawFooter(mon, w, h, "N new  X back")
      return
    end

    local vis = visibleCount(h)
    self.cursor = clamp(self.cursor, 1, #list)
    if self.cursor < self.scroll + 1 then self.scroll = self.cursor - 1 end
    if self.cursor > self.scroll + vis then self.scroll = self.cursor - vis end
    self.scroll = clamp(self.scroll, 0, math.max(0, #list - vis))

    for row = 1, vis do
      local idx = self.scroll + row
      local s = list[idx]
      if not s then break end
      local mark = (ctx.state.sceneId == s.id) and "*" or " "
      local kind = s.custom and "c" or "b"
      local line = string.format("%s%s %-14s %s [%s]", mark, kind, (s.name or "?"):sub(1, 14), hourLabel(s), s.playlist or "?")
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

    local sel = list[self.cursor]
    if sel and h >= 5 then
      mon.setTextColour(colours.lightGrey)
      mon.setCursorPos(2, h - 3)
      local blurb = sel.blurb or ""
      if blurb == "" then
        blurb = (sel.category or "ALL") .. " quotes"
      end
      mon.write(blurb:sub(1, w - 2))
    end
    drawFooter(mon, w, h, "Enter on  T auto  N new  R edit  B clone  D del")
  end

  local function drawEdit(mon, w, h)
    drawHeader(mon, w, self.editIdx and "EDIT SCENE" or "NEW SCENE", "custom")
    for i = 1, #FIELD_LABELS do
      local y = 2 + i
      if y >= h - 2 then break end
      local selected = (self.editField == i)
      local label = FIELD_LABELS[i]
      local value = fieldValue(i)
      if selected then
        mon.setBackgroundColour(colours.grey)
        mon.setTextColour(colours.yellow)
        mon.setCursorPos(1, y)
        mon.clearLine()
        mon.setCursorPos(2, y)
        local shown = label .. ": " .. value
        if i <= 3 then shown = shown .. "_" end
        mon.write(shown:sub(1, w - 2))
        mon.setBackgroundColour(colours.black)
      else
        mon.setTextColour(colours.white)
        mon.setCursorPos(2, y)
        mon.write((label .. ": " .. value):sub(1, w - 2))
      end
    end
    mon.setTextColour(colours.lightGrey)
    mon.setCursorPos(2, h - 2)
    mon.write(("Tab field  Left/Right cycle  Enter save"):sub(1, w - 2))
    drawFooter(mon, w, h, "Type name/title/blurb  O clear hours  X cancel")
  end

  function self:draw(mon)
    local w, h = mon.getSize()
    mon.setBackgroundColour(colours.black)
    mon.clear()
    if self.mode == "edit" then
      drawEdit(mon, w, h)
    else
      drawList(mon, w, h)
    end
  end

  function self:onChar(ch)
    if self.mode ~= "edit" or type(ch) ~= "string" or #ch == 0 then return nil end
    if self.editField > 3 then return "redraw" end
    local keys_ = { "name", "title", "blurb" }
    local k = keys_[self.editField]
    local cur = self.draft[k] or ""
    if #cur >= 60 then return "redraw" end
    self.draft[k] = cur .. ch
    return "redraw"
  end

  function self:onKey(key)
    if self.mode == "edit" then
      if key == keys.x then
        self.mode = "list"
        self.draft = nil
        self.editIdx = nil
        return "redraw"
      elseif key == keys.tab or key == keys.down then
        self.editField = self.editField >= #FIELD_LABELS and 1 or (self.editField + 1)
        return "redraw"
      elseif key == keys.up then
        self.editField = self.editField <= 1 and #FIELD_LABELS or (self.editField - 1)
        return "redraw"
      elseif key == keys.backspace then
        if self.editField <= 3 then
          local keys_ = { "name", "title", "blurb" }
          local k = keys_[self.editField]
          local cur = self.draft[k] or ""
          self.draft[k] = cur:sub(1, math.max(0, #cur - 1))
        end
        return "redraw"
      elseif key == keys.left or key == keys.right then
        local dir = key == keys.left and -1 or 1
        if self.editField == 4 then
          self.draft.playlist = cycleList(PLAYLISTS, self.draft.playlist, dir)
        elseif self.editField == 5 then
          self.draft.category = cycleList(CATS, self.draft.category, dir)
        elseif self.editField == 6 or self.editField == 7 then
          nudgeHour(self.editField, dir)
        end
        return "redraw"
      elseif key == keys.o then
        self.draft.fromHour, self.draft.toHour = nil, nil
        return "redraw"
      elseif key == keys.enter then
        saveDraft()
        return "redraw"
      end
      return "redraw"
    end

    local list = scenes()
    if key == keys.up then
      if #list > 0 then self.cursor = clamp(self.cursor - 1, 1, #list) end
      return "redraw"
    elseif key == keys.down then
      if #list > 0 then self.cursor = clamp(self.cursor + 1, 1, #list) end
      return "redraw"
    elseif key == keys.enter then
      local s = list[self.cursor]
      if s and ctx.applyScene then
        return ctx.applyScene(s) or "redraw"
      end
      return "redraw"
    elseif key == keys.t then
      if ctx.toggleSceneAuto then
        return ctx.toggleSceneAuto() or "redraw"
      end
      return "redraw"
    elseif key == keys.c then
      if ctx.clearScene then return ctx.clearScene() or "redraw" end
      return "redraw"
    elseif key == keys.n then
      beginEdit(nil, nil)
      return "redraw"
    elseif key == keys.b then
      local s = list[self.cursor]
      if s then
        local copy = {
          name = (s.name or "Scene") .. " Copy",
          title = s.title, blurb = s.blurb,
          playlist = s.playlist, category = s.category,
          fromHour = s.fromHour, toHour = s.toHour,
          priority = s.priority or 3,
        }
        beginEdit(nil, copy)
      end
      return "redraw"
    elseif key == keys.r then
      local s = list[self.cursor]
      if not s then return "redraw" end
      if s.custom then
        local idx = findCustomIndexById(s.id)
        if idx then beginEdit(idx, customs()[idx]) end
      else
        ctx.flash("Builtin — press B to clone", 2000)
      end
      return "redraw"
    elseif key == keys.d or key == keys.delete then
      local s = list[self.cursor]
      if s and s.custom then
        local idx = findCustomIndexById(s.id)
        if idx then
          table.remove(customs(), idx)
          if ctx.saveCustomScenes then ctx.saveCustomScenes() end
          if ctx.state.sceneId == s.id and ctx.clearScene then ctx.clearScene() end
          ctx.flash("Deleted", 1500)
          self.cursor = clamp(self.cursor, 1, math.max(1, #scenes()))
        end
      elseif s then
        ctx.flash("Can't delete builtins", 2000)
      end
      return "redraw"
    end
    return nil
  end

  function self:onTouch(x, y, w, h)
    if self.mode == "edit" then
      local idx = y - 2
      if idx >= 1 and idx <= #FIELD_LABELS then
        self.editField = idx
        if idx >= 4 then
          return self:onKey(keys.right)
        end
        return "redraw"
      end
      return nil
    end
    local row = y - 2
    local vis = visibleCount(h)
    if row >= 1 and row <= vis then
      local idx = self.scroll + row
      if scenes()[idx] then
        self.cursor = idx
        return self:onKey(keys.enter)
      end
    end
    return nil
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
      "Scene:         " .. tostring(ctx.state.sceneName or "(none)"),
      "Scene auto:    " .. (ctx.state.sceneAuto and "ON" or "off"),
      "Music:         " .. (ctx.state.musicOn and "on" or "muted"),
      "Now:           " .. tostring(ctx.state.songName),
    }

    local cats = catCounts()
    lines[#lines + 1] = ""
    local customTotal, customOn = 0, 0
    if ctx.customQuotes then
      customTotal = #ctx.customQuotes
      for _, q in ipairs(ctx.customQuotes) do
        if q[4] == true then customOn = customOn + 1 end
      end
    end
    lines[#lines + 1] = "Custom quotes: " .. customOn .. "/" .. customTotal .. " enabled"

    lines[#lines + 1] = "Categories:"
    for _, name in ipairs({ "TIP", "DID YOU KNOW", "WISDOM", "LOADING", "QUOTE", "PLAYER" }) do
      if cats[name] then
        lines[#lines + 1] = "  " .. name .. ": " .. cats[name]
      end
    end

    local pls = playlistCounts()
    lines[#lines + 1] = ""
    lines[#lines + 1] = "Playlists:"
    for _, name in ipairs({ "title", "elevator", "zelda", "runescape", "undertale", "original" }) do
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
      "Apps: jukebox, library, workshop,",
      "atmospheres, chat, clock, stats.",
      "",
      #ctx.SONGS .. " songs  ·  " .. #ctx.allQuotes .. " quotes",
      "",
      "A  app launcher",
      "S  cycle atmosphere",
      "Q  quit",
      "",
      "Chat: #scene dusk  #scene auto",
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
  workshop = newWorkshop,
  scenes   = newScenes,
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
  return { "jukebox", "library", "workshop", "scenes", "chatlog", "clock", "stats", "dice", "about" }
end

return Apps
