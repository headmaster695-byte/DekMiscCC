-- quote-board.lua
-- Author: DekMiscCC
-- CC:T version: 1.119.x | MC: 1.21.1 | Loader: NeoForge
-- Description: HOI4-style rotating quotes on an Advanced Monitor, with
--              multi-speaker music and automatic chat capture.
--
-- Usage: quote-board
-- Requires (same directory): songs.lua, quotes.lua, apps.lua
--
-- Controls:
--   R next quote     P previous      Space pause/resume quotes
--   N skip song      M mute/unmute   -/= volume down/up
--   C category filter  L playlist     H help overlay
--   A apps launcher  X back/home     Q quit
--   Monitor touch = next quote (or app UI)
-- Chat commands (prefix '#'):
--   #next #prev #pause #skip #mute #vol <0-100> #cat #playlist
--   #help #stats #apps #app <name> #home

-- ============================================================
-- Configuration
-- ============================================================
local BOARD_TITLE         = "MOTIVATIONAL CORNER"
local QUOTE_INTERVAL      = 15
local MONITOR_SCALE       = 0.5
local CHAT_FILE           = "quote-board-chat.dat"
local CUSTOM_FILE         = "quote-board-custom.dat"
local SETTINGS_FILE       = "quote-board-settings.dat"
local MAX_CHAT_QUOTES     = 50
local MIN_MSG_LEN         = 10
local CHAT_BOX_NAME       = ""
local CHAT_CMD_PREFIX     = "#"
local DIFF_CAT_WEIGHT     = 4
local SAME_CAT_WEIGHT     = 1
local PLAYER_CAT_WEIGHT   = 6
local TITLE_SONG_IDX      = 1
local MUSIC_START_ON      = true
local FRESH_CHAT_FOCUS    = true
local TOUCH_ADVANCES      = true
local MIRROR_ALL_MONITORS = true
local SHOW_CLOCK          = true
local SHOW_PROGRESS_BAR   = true
local AUTO_SCROLL         = true
local SCROLL_SECONDS      = 2.5
local UI_TICK             = 0.25
local DEFAULT_VOLUME      = 1.0          -- 0.0 – 1.0 multiplier
local QUOTE_TICK_SOUND    = true         -- soft click on quote change
local HELP_SECONDS        = 8

-- Players whose chat is never captured (case-sensitive names)
local IGNORE_PLAYERS = {
  -- ["SomeBot"] = true,
}

-- ============================================================
-- Data modules
-- ============================================================
local SONGS, BUILTIN_QUOTES, Apps

do
  local here = fs.getDir(shell.getRunningProgram())
  if here == "" then here = "." end
  package.path = package.path
    .. ";" .. here .. "/?"
    .. ";" .. here .. "/?.lua"

  local okSongs, songs = pcall(require, "songs")
  local okQuotes, quotes = pcall(require, "quotes")
  local okApps, appsMod = pcall(require, "apps")
  if not okSongs then
    error("Missing songs.lua — place it next to quote-board.lua\n" .. tostring(songs))
  end
  if not okQuotes then
    error("Missing quotes.lua — place it next to quote-board.lua\n" .. tostring(quotes))
  end
  if not okApps then
    error("Missing apps.lua — place it next to quote-board.lua\n" .. tostring(appsMod))
  end
  SONGS = songs
  BUILTIN_QUOTES = quotes
  Apps = appsMod
end

-- ============================================================
-- Categories / playlists
-- ============================================================
local CATEGORY_ORDER = {
  "ALL", "TIP", "DID YOU KNOW", "WISDOM", "LOADING", "QUOTE", "PLAYER",
}

local PLAYLIST_ORDER = { "all", "elevator", "zelda", "runescape", "undertale", "original", "title" }
local PLAYLIST_LABEL = {
  all       = "All tracks",
  elevator  = "Elevator",
  zelda     = "Zelda-inspired",
  runescape = "RuneScape-inspired",
  undertale = "Undertale-inspired",
  original  = "Originals",
  title     = "Title only",
}

local function songPlaylist(idx, song)
  if idx == TITLE_SONG_IDX then return "title" end
  if type(song.playlist) == "string" and PLAYLIST_LABEL[song.playlist] then
    return song.playlist
  end
  local n = (song.name or ""):lower()
  if n:find("temple", 1, true) or n:find("kokiri", 1, true) or n:find("moonlight", 1, true)
    or n:find("ember", 1, true) or n:find("dock", 1, true) or n:find("clockwork", 1, true)
    or n:find("deepstone", 1, true) or n:find("frost", 1, true) or n:find("hollow", 1, true)
    or n:find("library", 1, true) or n:find("harbor", 1, true) or n:find("garden", 1, true) then
    return "original"
  end
  if n:find("forest", 1, true) or n:find("zora", 1, true) or n:find("gerudo", 1, true)
    or n:find("lon lon", 1, true) or n:find("tempest", 1, true) or n:find("great sea", 1, true)
    or n:find("highland", 1, true) or n:find("meadow", 1, true) or n:find("lantern", 1, true)
    or n:find("bazaar", 1, true) or n:find("archipelago", 1, true) or n:find("river market", 1, true)
    or n:find("sheikah", 1, true) or n:find("fairy", 1, true) then
    return "zelda"
  end
  return "elevator"
end

-- ============================================================
-- Shared state
-- ============================================================
local allQuotes    = {}
local chatQuotes   = {}
local customQuotes = {}  -- { text, source, category, enabled } ; enabled defaults false
local speakers     = {}
local monitors     = {}

local state = {
  running       = true,
  songName      = "—",
  quoteIdx      = 1,
  chatCount     = 0,
  speakerCount  = 0,
  musicOn       = MUSIC_START_ON,
  volume        = DEFAULT_VOLUME,
  skipSong      = false,
  requestSongIdx= nil,          -- jukebox queue
  dirty         = true,
  nextQuoteAt   = 0,
  flashUntil    = 0,
  flashText     = "",
  hasChatBox    = false,
  paused        = false,
  helpUntil     = 0,
  categoryFilter= "ALL",
  playlist      = "all",
  history       = {},           -- previous quote snapshots
  scrollOffset  = 0,
  scrollAt      = 0,
  bodyLines     = 0,
  bodyHeight    = 0,
  quotesShown   = 0,
  chatCaptured  = 0,
  startedAt     = 0,
  app           = nil,          -- active mini-app instance
  appId         = nil,
  polyVoices    = 0,            -- voices in the current song
  polySpeakers  = 0,            -- speakers used for current song
}

-- Forward declarations filled in after helpers exist
local openApp, closeApp, goAppHome, queueSong, showQuoteIndex
local appContext

local CHAT_EVENT_NAMES = { chat = true, chat_message = true }

-- Shuffle bag of song indices for current playlist
local songBag = {}

-- ============================================================
-- Speakers / monitors
-- ============================================================
local function findAllSpeakers()
  local found = {}
  for _, name in ipairs(peripheral.getNames()) do
    if peripheral.getType(name) == "speaker" then
      found[#found + 1] = peripheral.wrap(name)
    end
  end
  if #found == 0 then
    local spk = peripheral.find("speaker")
    if spk then found[1] = spk end
  end
  return found
end

local function findMonitors()
  local found = {}
  for _, name in ipairs(peripheral.getNames()) do
    if peripheral.getType(name) == "monitor" then
      local mon = peripheral.wrap(name)
      if mon and mon.isColour and mon.isColour() then
        found[#found + 1] = mon
      end
    end
  end
  if #found == 0 then
    local mon = peripheral.find("monitor")
    if mon and mon.isColour and mon.isColour() then
      found[1] = mon
    end
  end
  return found
end

local function stopSpeakers(list)
  for _, spk in ipairs(list or speakers) do
    pcall(spk.stop)
  end
end

local function stopAllSpeakers()
  for _, name in ipairs(peripheral.getNames()) do
    if peripheral.getType(name) == "speaker" then
      local s = peripheral.wrap(name)
      if s then pcall(s.stop) end
    end
  end
end

local function playTick()
  -- Never steal note-budget from active polyphony (8 notes/tick/speaker).
  if not QUOTE_TICK_SOUND or #speakers == 0 or state.musicOn then return end
  local spk = speakers[1]
  local vol = math.max(0.05, 0.2 * state.volume)
  pcall(spk.playNote, "hat", vol, 18)
end

-- ============================================================
-- Settings persistence
-- ============================================================
local function loadSettings()
  if not fs.exists(SETTINGS_FILE) then return end
  local f = fs.open(SETTINGS_FILE, "r")
  if not f then return end
  local raw = f.readAll()
  f.close()
  local ok, data = pcall(textutils.unserialise, raw)
  if not ok or type(data) ~= "table" then return end
  if type(data.musicOn) == "boolean" then state.musicOn = data.musicOn end
  if type(data.volume) == "number" then
    state.volume = math.max(0, math.min(1, data.volume))
  end
  if type(data.playlist) == "string" and PLAYLIST_LABEL[data.playlist] then
    state.playlist = data.playlist
  end
  if type(data.categoryFilter) == "string" then
    for _, c in ipairs(CATEGORY_ORDER) do
      if c == data.categoryFilter then
        state.categoryFilter = c
        break
      end
    end
  end
end

local function saveSettings()
  local data = {
    musicOn = state.musicOn,
    volume = state.volume,
    playlist = state.playlist,
    categoryFilter = state.categoryFilter,
  }
  local f = fs.open(SETTINGS_FILE, "w")
  if not f then return end
  f.write(textutils.serialise(data))
  f.close()
end

-- ============================================================
-- Chat persistence
-- ============================================================
local function isValidQuote(q)
  return type(q) == "table"
    and type(q[1]) == "string" and q[1] ~= ""
    and type(q[2]) == "string"
    and type(q[3]) == "string" and q[3] ~= ""
end

local function loadChatQuotes()
  if not fs.exists(CHAT_FILE) then return end
  local f = fs.open(CHAT_FILE, "r")
  if not f then return end
  local raw = f.readAll()
  f.close()
  local ok, data = pcall(textutils.unserialise, raw)
  if not ok or type(data) ~= "table" then return end
  for i = #chatQuotes, 1, -1 do
    chatQuotes[i] = nil
  end
  for _, q in ipairs(data) do
    if isValidQuote(q) then
      chatQuotes[#chatQuotes + 1] = { q[1], q[2], q[3] }
    end
  end
end

local function saveChatQuotes()
  local f = fs.open(CHAT_FILE, "w")
  if not f then return end
  f.write(textutils.serialise(chatQuotes))
  f.close()
end

local CUSTOM_CATEGORIES = {
  TIP = true, ["DID YOU KNOW"] = true, WISDOM = true, LOADING = true, QUOTE = true,
}

local function normalizeCustomQuote(q)
  if not isValidQuote(q) then return nil end
  local cat = q[3]
  if not CUSTOM_CATEGORIES[cat] then cat = "TIP" end
  local enabled = q[4]
  if enabled ~= true then enabled = false end  -- default OFF
  return { q[1], q[2], cat, enabled }
end

local function loadCustomQuotes()
  if not fs.exists(CUSTOM_FILE) then return end
  local f = fs.open(CUSTOM_FILE, "r")
  if not f then return end
  local raw = f.readAll()
  f.close()
  local ok, data = pcall(textutils.unserialise, raw)
  if not ok or type(data) ~= "table" then return end
  for i = #customQuotes, 1, -1 do
    customQuotes[i] = nil
  end
  for _, q in ipairs(data) do
    local n = normalizeCustomQuote(q)
    if n then customQuotes[#customQuotes + 1] = n end
  end
end

local function saveCustomQuotes()
  local f = fs.open(CUSTOM_FILE, "w")
  if not f then return end
  f.write(textutils.serialise(customQuotes))
  f.close()
end

local function rebuildAllQuotes()
  -- Mutate in place so app contexts keep a live reference.
  -- Order: builtins → enabled customs → chat (chat must stay last for Chat Log pinning).
  for i = #allQuotes, 1, -1 do
    allQuotes[i] = nil
  end
  for _, q in ipairs(BUILTIN_QUOTES) do
    if isValidQuote(q) then
      allQuotes[#allQuotes + 1] = q
    end
  end
  for _, q in ipairs(customQuotes) do
    if q[4] == true and isValidQuote(q) then
      allQuotes[#allQuotes + 1] = { q[1], q[2], q[3] }
    end
  end
  for _, q in ipairs(chatQuotes) do
    allQuotes[#allQuotes + 1] = q
  end
  state.chatCount = #chatQuotes
  if #allQuotes == 0 then
    state.quoteIdx = 1
  elseif state.quoteIdx < 1 or state.quoteIdx > #allQuotes then
    state.quoteIdx = math.max(1, #allQuotes)
  end
end

local function isDuplicateChat(msg)
  if #chatQuotes == 0 then return false end
  for i = #chatQuotes, math.max(1, #chatQuotes - 19), -1 do
    if chatQuotes[i][1] == msg then return true end
  end
  return false
end

local function scheduleNextQuote(seconds)
  state.nextQuoteAt = os.epoch("utc") + math.floor((seconds or QUOTE_INTERVAL) * 1000)
  state.scrollOffset = 0
  state.scrollAt = os.epoch("utc") + math.floor(SCROLL_SECONDS * 1000)
  state.dirty = true
end

local function flash(msg, ms)
  state.flashText = tostring(msg or "")
  state.flashUntil = os.epoch("utc") + (ms or 3000)
  state.dirty = true
end

-- History stores quote snapshots so chat eviction cannot stale indices.
local function pushHistoryQuote(q)
  if not isValidQuote(q) then return end
  state.history[#state.history + 1] = { q[1], q[2], q[3] }
  if #state.history > 40 then table.remove(state.history, 1) end
end

local function addChatQuote(user, msg)
  if IGNORE_PLAYERS[user] then return false end
  if isDuplicateChat(msg) then return false end

  local evicted = false
  if #chatQuotes >= MAX_CHAT_QUOTES then
    table.remove(chatQuotes, 1)
    evicted = true
  end
  chatQuotes[#chatQuotes + 1] = { msg, user, "PLAYER" }
  saveChatQuotes()

  local prev = allQuotes[state.quoteIdx]
  rebuildAllQuotes()
  state.chatCaptured = state.chatCaptured + 1

  if FRESH_CHAT_FOCUS and #allQuotes > 0 then
    if prev then pushHistoryQuote(prev) end
    state.quoteIdx = #allQuotes
    state.quotesShown = state.quotesShown + 1
    scheduleNextQuote(QUOTE_INTERVAL)
    playTick()
  elseif evicted then
    -- Indices may have shifted; keep showing something valid.
    if state.quoteIdx > #allQuotes then
      state.quoteIdx = #allQuotes
    end
  end

  flash("LIVE: " .. user, 4000)
  return true
end

-- ============================================================
-- Display helpers
-- ============================================================
local CATEGORY_COLOUR = {
  TIP              = colours.yellow,
  ["DID YOU KNOW"] = colours.cyan,
  WISDOM           = colours.lime,
  LOADING          = colours.lightGrey,
  QUOTE            = colours.orange,
  PLAYER           = colours.pink,
}

local function wordWrap(text, width)
  local lines, line = {}, ""
  for word in text:gmatch("%S+") do
    if line == "" then
      line = word
    elseif #line + 1 + #word <= width then
      line = line .. " " .. word
    else
      lines[#lines + 1] = line
      line = word
    end
  end
  if line ~= "" then lines[#lines + 1] = line end
  return lines
end

local function centre(text, width)
  local pad = math.max(0, math.floor((width - #text) / 2))
  return string.rep(" ", pad) .. text
end

local function secondsLeft()
  if state.paused then return -1 end
  local ms = state.nextQuoteAt - os.epoch("utc")
  if ms <= 0 then return 0 end
  return math.ceil(ms / 1000)
end

local function uptimeString()
  local sec = math.floor((os.epoch("utc") - state.startedAt) / 1000)
  local m = math.floor(sec / 60)
  local s = sec % 60
  if m >= 60 then
    local h = math.floor(m / 60)
    m = m % 60
    return string.format("%dh%02dm", h, m)
  end
  return string.format("%dm%02ds", m, s)
end

local function clockString()
  -- CC:T provides os.date compatible formatting on most versions
  local ok, text = pcall(os.date, "%H:%M")
  if ok and type(text) == "string" then return text end
  return ""
end

local function progressFraction()
  if state.paused or QUOTE_INTERVAL <= 0 then return 0 end
  local left = state.nextQuoteAt - os.epoch("utc")
  local total = QUOTE_INTERVAL * 1000
  local done = 1 - (left / total)
  if done < 0 then return 0 end
  if done > 1 then return 1 end
  return done
end

local function drawHelp(mon, w, h)
  mon.setBackgroundColour(colours.black)
  mon.setTextColour(colours.white)
  mon.clear()
  mon.setCursorPos(1, 1)
  mon.setBackgroundColour(colours.grey)
  mon.setTextColour(colours.yellow)
  mon.clearLine()
  mon.write(centre("CONTROLS", w))
  mon.setBackgroundColour(colours.black)

  local lines = {
    "R next     P previous",
    "Space pause quotes",
    "N skip song   M mute",
    "- / =  volume",
    "C category filter",
    "L playlist filter",
    "A apps     X back",
    "H help     Q quit",
    "Touch monitor = next",
    "",
    "Chat: #apps #app jukebox",
    "      #next #skip #mute",
    "      #vol 50 #playlist",
    "",
    "Up " .. uptimeString()
      .. "  shown " .. state.quotesShown,
    "Chat +" .. state.chatCaptured
      .. "  vol " .. math.floor(state.volume * 100) .. "%",
  }

  for i, line in ipairs(lines) do
    local row = i + 2
    if row >= h then break end
    mon.setTextColour(colours.lightGrey)
    mon.setCursorPos(2, row)
    mon.write(line:sub(1, w - 2))
  end
end

local function drawScreenOn(mon, quote)
  local w, h = mon.getSize()

  if os.epoch("utc") < state.helpUntil then
    drawHelp(mon, w, h)
    return
  end

  local text, source, category = quote[1], quote[2], quote[3]
  local flashing = os.epoch("utc") < state.flashUntil

  mon.setBackgroundColour(colours.black)
  mon.setTextColour(colours.white)
  mon.clear()

  -- Header
  mon.setCursorPos(1, 1)
  mon.setBackgroundColour(colours.grey)
  if flashing then
    mon.setTextColour(colours.pink)
    mon.clearLine()
    mon.setCursorPos(1, 1)
    mon.write(centre(state.flashText, w))
  else
    mon.setTextColour(colours.yellow)
    mon.clearLine()
    local title = "* " .. BOARD_TITLE .. " *"
    if state.paused then title = "* PAUSED *" end
    if SHOW_CLOCK then
      local clk = clockString()
      if clk ~= "" then
        mon.setCursorPos(1, 1)
        mon.write(centre(title, w))
        mon.setTextColour(colours.white)
        mon.setCursorPos(w - #clk + 1, 1)
        mon.write(clk)
      else
        mon.setCursorPos(1, 1)
        mon.write(centre(title, w))
      end
    else
      mon.setCursorPos(1, 1)
      mon.write(centre(title, w))
    end
  end
  mon.setBackgroundColour(colours.black)

  mon.setTextColour(colours.grey)
  mon.setCursorPos(1, 2)
  mon.write(string.rep("-", w))

  -- Category + filter hint
  mon.setTextColour(CATEGORY_COLOUR[category] or colours.white)
  mon.setCursorPos(2, 3)
  local catLabel = "[ " .. category .. " ]"
  if flashing and category == "PLAYER" then
    catLabel = "[ PLAYER · NEW ]"
  end
  if state.categoryFilter ~= "ALL" then
    catLabel = catLabel .. " lock"
  end
  mon.write(catLabel:sub(1, math.max(1, w - 12)))

  local right
  if state.paused then
    right = "PAUSED"
  else
    right = string.format("next %ds", secondsLeft())
  end
  mon.setTextColour(colours.grey)
  mon.setCursorPos(math.max(1, w - #right), 3)
  mon.write(right)

  -- Body (with auto-scroll for tall quotes)
  mon.setTextColour(colours.white)
  local margin = 3
  local bodyW = math.max(8, w - margin * 2)
  local wrapped = wordWrap(text, bodyW)
  if #wrapped >= 1 then
    wrapped[1] = "\xE2\x80\x9C" .. wrapped[1]
    wrapped[#wrapped] = wrapped[#wrapped] .. "\xE2\x80\x9D"
  end

  local bodyStart, bodyEnd = 5, h - 4
  if bodyEnd < bodyStart then bodyEnd = bodyStart end
  local bodyHeight = bodyEnd - bodyStart + 1
  state.bodyLines = #wrapped
  state.bodyHeight = bodyHeight

  if AUTO_SCROLL and #wrapped > bodyHeight then
    local maxOff = #wrapped - bodyHeight
    if state.scrollOffset > maxOff then state.scrollOffset = maxOff end
  else
    state.scrollOffset = 0
  end

  for i = 1, bodyHeight do
    local line = wrapped[i + state.scrollOffset]
    if not line then break end
    mon.setCursorPos(margin, bodyStart + i - 1)
    mon.write(line:sub(1, bodyW))
  end

  if AUTO_SCROLL and #wrapped > bodyHeight then
    mon.setTextColour(colours.grey)
    mon.setCursorPos(w, bodyStart)
    mon.write("^")
    mon.setCursorPos(w, bodyEnd)
    mon.write("v")
  end

  -- Attribution
  mon.setTextColour(colours.lightGrey)
  local attr = "— " .. source
  local attrRow = h - 3
  if attrRow > bodyStart then
    mon.setCursorPos(math.max(1, w - #attr - 1), attrRow)
    mon.write(attr:sub(1, w - 2))
  end

  -- Progress bar / divider
  mon.setCursorPos(1, h - 1)
  if SHOW_PROGRESS_BAR and not state.paused then
    local frac = progressFraction()
    local filled = math.floor(w * frac + 0.5)
    mon.setTextColour(colours.grey)
    mon.write(string.rep("=", math.max(0, filled)))
    mon.setTextColour(colours.grey)
    mon.write(string.rep("-", math.max(0, w - filled)))
  else
    mon.setTextColour(colours.grey)
    mon.write(string.rep(state.paused and "=" or "-", w))
  end

  -- Footer
  mon.setCursorPos(1, h)
  mon.setBackgroundColour(colours.grey)
  mon.clearLine()
  mon.setTextColour(state.musicOn and colours.green or colours.red)

  local volPct = math.floor(state.volume * 100 + 0.5)
  local bits = {}
  if state.speakerCount == 0 then
    bits[#bits + 1] = "no speakers"
  elseif state.musicOn then
    bits[#bits + 1] = state.songName
  else
    bits[#bits + 1] = "MUTED"
  end
  if state.musicOn and state.polyVoices > 0 then
    bits[#bits + 1] = state.polyVoices .. "v"
  end
  if state.speakerCount > 1 then
    bits[#bits + 1] = state.speakerCount .. "spk"
  end
  if state.playlist ~= "all" then
    bits[#bits + 1] = PLAYLIST_LABEL[state.playlist] or state.playlist
  end
  bits[#bits + 1] = volPct .. "%"
  if state.chatCount > 0 then
    bits[#bits + 1] = "chat:" .. state.chatCount
  end

  local musicLabel = "  * " .. table.concat(bits, " | ")
  mon.setCursorPos(1, h)
  mon.write(musicLabel:sub(1, w))

  mon.setBackgroundColour(colours.black)
  mon.setTextColour(colours.white)
end

local function drawAppOn(mon)
  if not state.app then return end
  local ok, err = pcall(function()
    state.app:draw(mon)
  end)
  if not ok then
    local w, h = mon.getSize()
    mon.setBackgroundColour(colours.black)
    mon.setTextColour(colours.red)
    mon.clear()
    mon.setCursorPos(1, 1)
    mon.write("App error")
    mon.setCursorPos(1, 3)
    mon.write(tostring(err):sub(1, w))
    mon.setTextColour(colours.lightGrey)
    mon.setCursorPos(1, h)
    mon.write("X back  A board")
  end
end

local function drawAll(quote)
  local list = monitors
  if not MIRROR_ALL_MONITORS and #list > 0 then
    list = { list[1] }
  end
  for _, mon in ipairs(list) do
    if state.app then
      pcall(drawAppOn, mon)
    elseif isValidQuote(quote) then
      pcall(drawScreenOn, mon, quote)
    end
  end
end

-- ============================================================
-- Quote selection
-- ============================================================
local function quoteMatchesFilter(q)
  if state.categoryFilter == "ALL" then return true end
  return isValidQuote(q) and q[3] == state.categoryFilter
end

local function ensureQuoteMatchesFilter()
  local q = allQuotes[state.quoteIdx]
  if isValidQuote(q) and quoteMatchesFilter(q) then return end
  local matches = {}
  for i, qq in ipairs(allQuotes) do
    if quoteMatchesFilter(qq) then
      matches[#matches + 1] = i
    end
  end
  if #matches > 0 then
    state.quoteIdx = matches[math.random(#matches)]
  end
end

local function weightFor(i, currentIdx, currentCat)
  if i == currentIdx then return 0 end
  local q = allQuotes[i]
  if not isValidQuote(q) or not quoteMatchesFilter(q) then return 0 end
  local cat = q[3]
  if cat == "PLAYER" and cat ~= currentCat then
    return PLAYER_CAT_WEIGHT
  elseif cat == currentCat then
    return SAME_CAT_WEIGHT
  else
    return DIFF_CAT_WEIGHT
  end
end

local function pickNextQuote(currentIdx)
  local n = #allQuotes
  if n <= 1 then return 1 end

  local currentCat = allQuotes[currentIdx] and allQuotes[currentIdx][3]
  local cumWeights, total = {}, 0

  for i = 1, n do
    local w = weightFor(i, currentIdx, currentCat)
    total = total + w
    cumWeights[i] = total
  end

  if total == 0 then
    -- Filter may be empty (e.g. PLAYER with no chat yet) — fall back to all
    if state.categoryFilter ~= "ALL" then
      local saved = state.categoryFilter
      state.categoryFilter = "ALL"
      local idx = pickNextQuote(currentIdx)
      state.categoryFilter = saved
      flash("No " .. saved .. " quotes", 2500)
      return idx
    end
    local pick = math.random(n)
    return pick ~= currentIdx and pick or (pick % n) + 1
  end

  local roll = math.random(total)
  local lo, hi = 1, n
  while lo < hi do
    local mid = math.floor((lo + hi) / 2)
    if cumWeights[mid] < roll then
      lo = mid + 1
    else
      hi = mid
    end
  end
  return lo
end

local function findQuoteIndex(snapshot)
  if not isValidQuote(snapshot) then return nil end
  for i, q in ipairs(allQuotes) do
    if q[1] == snapshot[1] and q[2] == snapshot[2] and q[3] == snapshot[3] then
      return i
    end
  end
  return nil
end

local function advanceQuote()
  pushHistoryQuote(allQuotes[state.quoteIdx])
  state.quoteIdx = pickNextQuote(state.quoteIdx)
  state.quotesShown = state.quotesShown + 1
  state.scrollOffset = 0
  scheduleNextQuote(QUOTE_INTERVAL)
  playTick()
end

local function previousQuote()
  while #state.history > 0 do
    local snapshot = table.remove(state.history)
    local idx = findQuoteIndex(snapshot)
    if idx then
      state.quoteIdx = idx
      state.quotesShown = state.quotesShown + 1
      state.scrollOffset = 0
      scheduleNextQuote(QUOTE_INTERVAL)
      playTick()
      return
    end
  end
  flash("No history", 1500)
end

local function togglePause()
  state.paused = not state.paused
  if state.paused then
    flash("PAUSED", 1500)
  else
    scheduleNextQuote(QUOTE_INTERVAL)
    flash("RESUMED", 1500)
  end
end

local function cycleCategory()
  local idx = 1
  for i, c in ipairs(CATEGORY_ORDER) do
    if c == state.categoryFilter then idx = i break end
  end
  idx = (idx % #CATEGORY_ORDER) + 1
  state.categoryFilter = CATEGORY_ORDER[idx]
  saveSettings()
  flash("Filter: " .. state.categoryFilter, 2000)
  -- If current quote is wrong category, advance
  local q = allQuotes[state.quoteIdx]
  if q and not quoteMatchesFilter(q) then
    advanceQuote()
  end
end

local function refillSongBag()
  songBag = {}
  for i, song in ipairs(SONGS) do
    local bucket = songPlaylist(i, song)
    if state.playlist == "all" or bucket == state.playlist
      or (state.playlist == "title" and i == TITLE_SONG_IDX) then
      songBag[#songBag + 1] = i
    end
  end
  -- Shuffle
  for i = #songBag, 2, -1 do
    local j = math.random(i)
    songBag[i], songBag[j] = songBag[j], songBag[i]
  end
  if #songBag == 0 then
    -- Never empty
    songBag[1] = TITLE_SONG_IDX
  end
end

local function requestSkipSong()
  if state.musicOn and state.speakerCount > 0 then
    state.skipSong = true
    stopSpeakers()
  end
end

local function cyclePlaylist()
  local idx = 1
  for i, p in ipairs(PLAYLIST_ORDER) do
    if p == state.playlist then idx = i break end
  end
  idx = (idx % #PLAYLIST_ORDER) + 1
  state.playlist = PLAYLIST_ORDER[idx]
  refillSongBag()
  saveSettings()
  flash("Playlist: " .. (PLAYLIST_LABEL[state.playlist] or state.playlist), 2500)
  requestSkipSong()
end

local function adjustVolume(delta)
  -- Snap to tenths so repeated +/- does not accumulate float error.
  local tenths = math.floor(state.volume * 10 + 0.5) + math.floor(delta * 10 + 0.5)
  state.volume = math.max(0, math.min(1, tenths / 10))
  saveSettings()
  flash("Volume " .. math.floor(state.volume * 100 + 0.5) .. "%", 1500)
end

local function showHelp()
  state.helpUntil = os.epoch("utc") + HELP_SECONDS * 1000
  state.dirty = true
end

local function showStats()
  flash(string.format(
    "Up %s | %d shown | %d chat",
    uptimeString(), state.quotesShown, state.chatCaptured
  ), 3500)
end

local function toggleMusic()
  state.musicOn = not state.musicOn
  if not state.musicOn then
    state.skipSong = true
    stopSpeakers()
    state.songName = "muted"
  end
  saveSettings()
  state.dirty = true
  flash(state.musicOn and "Music on" or "Music muted", 1500)
end

-- ============================================================
-- Mini-apps
-- ============================================================
queueSong = function(idx)
  if type(idx) ~= "number" or idx < 1 or idx > #SONGS then return end
  state.requestSongIdx = idx
  state.skipSong = true
  stopSpeakers()
  if not state.musicOn then
    state.musicOn = true
    saveSettings()
  end
  flash("Queued: " .. (SONGS[idx].name or ("#" .. idx)), 2000)
  state.dirty = true
end

showQuoteIndex = function(idx)
  if type(idx) ~= "number" or idx < 1 or idx > #allQuotes then return end
  pushHistoryQuote(allQuotes[state.quoteIdx])
  state.quoteIdx = idx
  state.quotesShown = state.quotesShown + 1
  scheduleNextQuote(QUOTE_INTERVAL)
  playTick()
  flash("Pinned quote", 1500)
end

local CUSTOM_CAT_ORDER = { "TIP", "DID YOU KNOW", "WISDOM", "LOADING", "QUOTE" }

local function refreshQuotesFromCustoms()
  local prev = allQuotes[state.quoteIdx]
  rebuildAllQuotes()
  -- Keep the same quote text in view when possible after enable toggles.
  if prev and isValidQuote(prev) then
    for i, q in ipairs(allQuotes) do
      if q[1] == prev[1] and q[2] == prev[2] and q[3] == prev[3] then
        state.quoteIdx = i
        break
      end
    end
  end
  state.dirty = true
end

local function saveAndRebuildCustoms()
  saveCustomQuotes()
  refreshQuotesFromCustoms()
end

local function buildAppContext()
  return {
    SONGS = SONGS,
    BUILTIN_QUOTES = BUILTIN_QUOTES,
    allQuotes = allQuotes,
    chatQuotes = chatQuotes,
    customQuotes = customQuotes,
    customCategories = CUSTOM_CAT_ORDER,
    state = state,
    boardTitle = BOARD_TITLE,
    wordWrap = wordWrap,
    centre = centre,
    flash = flash,
    clockString = clockString,
    uptimeString = uptimeString,
    playlistLabel = function(id) return PLAYLIST_LABEL[id] end,
    requestSkipSong = requestSkipSong,
    toggleMusic = toggleMusic,
    queueSong = queueSong,
    showQuoteIndex = showQuoteIndex,
    openApp = function(id) openApp(id) end,
    saveCustomQuotes = saveAndRebuildCustoms,
    normalizeCustomQuote = normalizeCustomQuote,
  }
end

openApp = function(id)
  appContext = buildAppContext()
  state.helpUntil = 0
  state.appId = id or "launcher"
  state.app = Apps.open(state.appId, appContext)
  state.dirty = true
end

closeApp = function()
  state.app = nil
  state.appId = nil
  state.dirty = true
  scheduleNextQuote(QUOTE_INTERVAL)
end

goAppHome = function()
  openApp("launcher")
end

local function handleAppAction(result)
  if result == "close" then
    closeApp()
    return "redraw"
  elseif result == "home" then
    goAppHome()
    return "redraw"
  elseif result == "abort_music" then
    state.dirty = true
    return "abort_music"
  elseif result == "redraw" then
    state.dirty = true
    return "redraw"
  end
  return result
end

-- ============================================================
-- Chat commands
-- ============================================================
local function handleChatCommand(user, msg)
  local prefix = CHAT_CMD_PREFIX
  if msg:sub(1, #prefix) ~= prefix then return false end

  local body = msg:sub(#prefix + 1):gsub("^%s+", ""):gsub("%s+$", "")
  if body == "" then return true end

  local cmd, arg = body:match("^(%S+)%s*(.*)$")
  if not cmd then return true end
  cmd = cmd:lower()

  if cmd == "next" or cmd == "r" then
    advanceQuote()
  elseif cmd == "prev" or cmd == "p" or cmd == "back" then
    previousQuote()
  elseif cmd == "pause" or cmd == "resume" then
    togglePause()
  elseif cmd == "skip" or cmd == "n" then
    requestSkipSong()
    flash(user .. " skipped", 2000)
  elseif cmd == "mute" or cmd == "m" then
    toggleMusic()
  elseif cmd == "vol" or cmd == "volume" then
    local n = tonumber(arg)
    if n then
      state.volume = math.max(0, math.min(1, n > 1 and (n / 100) or n))
      saveSettings()
      flash("Volume " .. math.floor(state.volume * 100 + 0.5) .. "%", 2000)
    else
      flash("Usage: #vol 50", 2000)
    end
  elseif cmd == "cat" or cmd == "category" then
    cycleCategory()
  elseif cmd == "playlist" or cmd == "pl" or cmd == "music" then
    cyclePlaylist()
  elseif cmd == "help" or cmd == "h" then
    showHelp()
  elseif cmd == "stats" then
    if arg ~= "" then
      openApp("stats")
    else
      showStats()
    end
  elseif cmd == "apps" or cmd == "app" or cmd == "menu" then
    local name = (arg ~= "" and arg or "launcher"):lower()
    if name == "list" or name == "launcher" or name == "menu" then
      openApp("launcher")
    else
      local ok = false
      for _, id in ipairs(Apps.ids()) do
        if id == name then
          openApp(id)
          ok = true
          break
        end
      end
      if not ok then
        flash("Apps: jukebox library workshop chatlog clock stats dice about", 3500)
      end
    end
  elseif cmd == "home" or cmd == "board" then
    closeApp()
  else
    flash("Unknown #" .. cmd .. " (try #help)", 2500)
  end
  return true
end

local function tryCaptureChat(user, msg)
  if not state.hasChatBox then return end
  if type(user) ~= "string" or type(msg) ~= "string" then return end
  if IGNORE_PLAYERS[user] then return end

  if handleChatCommand(user, msg) then
    return
  end

  if #msg < MIN_MSG_LEN then return end
  local first = msg:sub(1, 1)
  if first == "/" or first == "!" then return end
  addChatQuote(user, msg)
end

-- ============================================================
-- Event handling
-- ============================================================
local function handleGlobalEvent(ev)
  local kind = ev[1]

  if kind == "terminate" then
    state.running = false
    return "quit"
  end

  if kind == "char" then
    if state.app and state.app.onChar then
      local result = handleAppAction(state.app:onChar(ev[2]))
      if result then return result end
    end
    return nil
  end

  if kind == "key" then
    local key = ev[2]

    -- Global keys always available
    if key == keys.q then
      state.running = false
      return "quit"
    elseif key == keys.a then
      if state.app then
        closeApp()
      else
        openApp("launcher")
      end
      return "redraw"
    end

    -- Route to active app (before X/backspace so editors can use Backspace)
    if state.app and state.app.onKey then
      local result = handleAppAction(state.app:onKey(key))
      if result then return result end
      if key == keys.x then
        if state.appId == "launcher" then
          closeApp()
        else
          goAppHome()
        end
        return "redraw"
      end
      -- Unhandled: still allow mute/skip/volume while in apps
      if key == keys.n then
        requestSkipSong()
        return "abort_music"
      elseif key == keys.m then
        toggleMusic()
        return state.musicOn and "redraw" or "abort_music"
      elseif key == keys.minus then
        adjustVolume(-0.1)
        return "redraw"
      elseif key == keys.equals then
        adjustVolume(0.1)
        return "redraw"
      elseif key == keys.h then
        showHelp()
        return "redraw"
      end
      return nil
    end

    if key == keys.r then
      advanceQuote()
      return "redraw"
    elseif key == keys.p then
      previousQuote()
      return "redraw"
    elseif key == keys.space then
      togglePause()
      return "redraw"
    elseif key == keys.n then
      requestSkipSong()
      return "abort_music"
    elseif key == keys.m then
      toggleMusic()
      return state.musicOn and "redraw" or "abort_music"
    elseif key == keys.minus then
      adjustVolume(-0.1)
      return "redraw"
    elseif key == keys.equals then
      adjustVolume(0.1)
      return "redraw"
    elseif key == keys.c then
      cycleCategory()
      return "redraw"
    elseif key == keys.l then
      cyclePlaylist()
      return "abort_music"
    elseif key == keys.h then
      showHelp()
      return "redraw"
    end
  elseif kind == "monitor_touch" then
    local _, x, y = ev[2], ev[3], ev[4]
    -- Advanced Peripherals / CC: monitor_touch name, x, y — ev[2] may be side
    if type(x) ~= "number" then
      x, y = ev[2], ev[3]
    end
    if state.app and state.app.onTouch then
      local mon = monitors[1]
      local w, h = 20, 10
      if mon then w, h = mon.getSize() end
      local result = handleAppAction(state.app:onTouch(x or 1, y or 1, w, h))
      if result then return result end
      return "redraw"
    end
    if TOUCH_ADVANCES then
      if os.epoch("utc") < state.helpUntil then
        state.helpUntil = 0
      else
        advanceQuote()
      end
      return "redraw"
    end
  elseif CHAT_EVENT_NAMES[kind] then
    tryCaptureChat(ev[2], ev[3])
    return "redraw"
  end

  return nil
end

local function shouldAbortPlayback()
  return (not state.running) or (not state.musicOn) or state.skipSong
end

-- Forward non-timer events to the UI loop without busy-spinning.
-- abortFn: optional; when it returns true, sleep ends early.
local function yieldSleep(seconds, abortFn)
  if seconds <= 0 then return end
  local tEnd = os.clock() + seconds
  while state.running and os.clock() < tEnd do
    if abortFn and abortFn() then return end
    local slice = math.min(0.05, tEnd - os.clock())
    if slice <= 0 then return end
    local timerId = os.startTimer(slice)
    local ev = { os.pullEventRaw() }
    if ev[1] == "timer" and ev[2] == timerId then
      -- slice finished
    elseif ev[1] == "terminate" then
      state.running = false
      return
    else
      -- Hand off to uiLoop; yield once more so it can drain the event.
      os.queueEvent(table.unpack(ev))
      local handoff = os.startTimer(0)
      while true do
        local ev2 = { os.pullEventRaw() }
        if ev2[1] == "timer" and ev2[2] == handoff then
          break
        elseif ev2[1] == "terminate" then
          state.running = false
          return
        else
          os.queueEvent(table.unpack(ev2))
        end
      end
    end
  end
end

-- Used during note playback — abort on mute/skip/quit.
local function coopSleep(seconds)
  yieldSleep(seconds, shouldAbortPlayback)
end

-- Used while muted / idle — must NOT treat mute as abort (that busy-loops).
local function idleSleep(seconds)
  yieldSleep(seconds, function()
    return not state.running
  end)
end

-- ============================================================
-- UI loop
-- ============================================================
local function updateScroll()
  if not AUTO_SCROLL then return end
  if state.bodyLines <= state.bodyHeight then return end
  local now = os.epoch("utc")
  if now < state.scrollAt then return end
  state.scrollAt = now + math.floor(SCROLL_SECONDS * 1000)
  local maxOff = state.bodyLines - state.bodyHeight
  state.scrollOffset = state.scrollOffset + 1
  if state.scrollOffset > maxOff then
    state.scrollOffset = 0
  end
  state.dirty = true
end

local function uiLoop()
  scheduleNextQuote(QUOTE_INTERVAL)
  state.startedAt = os.epoch("utc")

  while state.running do
    -- Quote rotation pauses while a mini-app is open.
    if (not state.app) and (not state.paused) and os.epoch("utc") >= state.nextQuoteAt then
      advanceQuote()
    end
    if not state.app then
      updateScroll()
    elseif state.app.tick then
      local tickResult = handleAppAction(state.app:tick())
      if tickResult == "quit" then return end
    end

    local q = allQuotes[state.quoteIdx]
    drawAll(q)
    state.dirty = false

    local timerId = os.startTimer(UI_TICK)
    while state.running do
      local ev = { os.pullEventRaw() }
      if ev[1] == "timer" and ev[2] == timerId then
        break
      end
      local result = handleGlobalEvent(ev)
      if result == "quit" then
        return
      elseif result == "redraw" or result == "abort_music" or state.dirty then
        break
      end
    end
  end
end

-- ============================================================
-- Music
-- ============================================================
local function getSongVoices(song)
  if song.voices then return song.voices end
  if song.notes then return { { notes = song.notes } } end
  return {}
end

local function pickSongIndex(lastIdx)
  if #songBag == 0 then refillSongBag() end

  -- Prefer not to repeat last song if bag has alternatives
  if #songBag == 1 then
    return table.remove(songBag, 1)
  end

  for i, idx in ipairs(songBag) do
    if idx ~= lastIdx then
      table.remove(songBag, i)
      return idx
    end
  end
  return table.remove(songBag, 1)
end

-- CC:T allows up to 8 playNote calls per speaker per tick. Complex songs fire
-- whole chords in one batch (no mid-chord yields) so voices stay aligned.
local NOTES_PER_TICK = 8
local NOTE_TICK = 0.05
local TIME_EPS = 0.0005

local function playSong(song, spkList)
  local voices = getSongVoices(song)
  if #voices == 0 or #spkList == 0 then return end

  state.polyVoices = #voices
  state.polySpeakers = #spkList
  state.dirty = true

  -- Flatten to absolute song-time, then group into simultaneous chords.
  local flat = {}
  for vi, voice in ipairs(voices) do
    local t = 0
    for _, note in ipairs(voice.notes or {}) do
      flat[#flat + 1] = {
        t = t,
        vi = vi,
        inst = note[1],
        vol = note[2],
        pitch = note[3],
      }
      t = t + (tonumber(note[4]) or 0.05)
    end
  end
  if #flat == 0 then return end

  table.sort(flat, function(a, b)
    if a.t == b.t then return a.vi < b.vi end
    return a.t < b.t
  end)

  local groups = {}
  for _, note in ipairs(flat) do
    local g = groups[#groups]
    if (not g) or math.abs(note.t - g.t) > TIME_EPS then
      g = { t = note.t, notes = {} }
      groups[#groups + 1] = g
    end
    g.notes[#g.notes + 1] = note
  end

  -- Prefer a dedicated speaker per voice when hardware allows — that is the
  -- intended multi-speaker polyphony layout (V1→spk1, V2→spk2, …).
  local function speakerFor(vi)
    if #spkList >= #voices then
      return spkList[vi], vi
    end
    local idx = ((vi - 1) % #spkList) + 1
    return spkList[idx], idx
  end

  local function leastLoaded(load)
    local bestIdx, bestCount = 1, load[1] or 0
    for i = 2, #spkList do
      local c = load[i] or 0
      if c < bestCount then
        bestIdx, bestCount = i, c
      end
    end
    return bestIdx, bestCount
  end

  -- Sleep the gap between successive chords — NOT wall-clock catch-up.
  -- CC timers are tick-quantised (~0.05s); absolute catch-up falls permanently
  -- behind on dense songs (A New Start) and then dumps the rest with no delays.
  local prevT = 0
  for _, group in ipairs(groups) do
    if shouldAbortPlayback() then
      state.polyVoices = 0
      return
    end

    local gap = group.t - prevT
    if gap > 0 then
      coopSleep(gap)
      if shouldAbortPlayback() then
        state.polyVoices = 0
        return
      end
    end
    prevT = group.t

    -- Fire the whole chord without yielding so notes share one tick budget.
    local load = {}
    local failed = {}
    for _, note in ipairs(group.notes) do
      if type(note.inst) == "string" then
        local vol = (tonumber(note.vol) or 1) * state.volume
        if vol < 0 then vol = 0 end
        if vol > 3 then vol = 3 end
        if vol > 0 then
          local spk, spkIdx = speakerFor(note.vi)
          local used = load[spkIdx] or 0
          if used >= NOTES_PER_TICK then
            local altIdx, altUsed = leastLoaded(load)
            if altUsed < NOTES_PER_TICK then
              spk, spkIdx, used = spkList[altIdx], altIdx, altUsed
            else
              failed[#failed + 1] = { note = note, spk = spk, vol = vol }
              spk = nil
            end
          end
          if spk then
            local ok = spk.playNote(note.inst, vol, note.pitch)
            if ok then
              load[spkIdx] = used + 1
            else
              failed[#failed + 1] = { note = note, spk = spk, vol = vol }
            end
          end
        end
      end
    end

    -- Single one-tick retry for overflows (keeps chord timing mostly intact).
    if #failed > 0 then
      coopSleep(NOTE_TICK)
      if shouldAbortPlayback() then
        state.polyVoices = 0
        return
      end
      for _, item in ipairs(failed) do
        local n = item.note
        pcall(function()
          item.spk.playNote(n.inst, item.vol, n.pitch)
        end)
      end
    end
  end

  state.polyVoices = 0
end

local function musicLoop(spkList)
  if #spkList == 0 then
    while state.running do idleSleep(0.5) end
    return
  end

  local isFirst, lastIdx = true, 0
  refillSongBag()

  while state.running do
    if not state.musicOn then
      state.songName = "muted"
      state.polyVoices = 0
      state.dirty = true
      stopSpeakers(spkList)
      while state.running and not state.musicOn do
        idleSleep(0.2)
      end
      if not state.running then break end
      state.skipSong = false
    end

    state.skipSong = false

    local idx
    if state.requestSongIdx then
      idx = state.requestSongIdx
      state.requestSongIdx = nil
      isFirst = false
      -- Keep bag coherent: drop the queued track if present
      for i, v in ipairs(songBag) do
        if v == idx then table.remove(songBag, i) break end
      end
    elseif isFirst then
      idx = TITLE_SONG_IDX
      if idx < 1 or idx > #SONGS then idx = 1 end
      -- Remove title from bag so shuffle doesn't instantly replay it
      for i, v in ipairs(songBag) do
        if v == idx then table.remove(songBag, i) break end
      end
      isFirst = false
    else
      idx = pickSongIndex(lastIdx)
    end
    lastIdx = idx

    local song = SONGS[idx]
    if not song then
      idleSleep(0.5)
    else
      state.songName = song.name or ("song " .. idx)
      state.dirty = true

      local ok = pcall(playSong, song, spkList)
      state.polyVoices = 0
      if not ok then
        state.songName = "err"
        state.dirty = true
        idleSleep(0.5)
      end
    end

    if state.skipSong or not state.musicOn then
      state.skipSong = false
      state.polyVoices = 0
      stopSpeakers(spkList)
      idleSleep(0.05)
    end
  end

  state.polyVoices = 0
  stopSpeakers(spkList)
end

-- ============================================================
-- Chat Box detection
-- ============================================================
local function findChatBox()
  if CHAT_BOX_NAME ~= "" then
    return peripheral.wrap(CHAT_BOX_NAME)
  end
  for _, typeName in ipairs({ "chatBox", "chat_box", "chatbox" }) do
    local p = peripheral.find(typeName)
    if p then return p end
  end
  for _, name in ipairs(peripheral.getNames()) do
    local t = peripheral.getType(name)
    if type(t) == "string" and t:lower():find("chat", 1, true) then
      return peripheral.wrap(name)
    end
  end
  return nil
end

-- ============================================================
-- Boot splash
-- ============================================================
local function drawSplash()
  for _, mon in ipairs(monitors) do
    pcall(function()
      local w, h = mon.getSize()
      mon.setBackgroundColour(colours.black)
      mon.setTextColour(colours.yellow)
      mon.clear()
      mon.setCursorPos(1, math.max(1, math.floor(h / 2) - 1))
      mon.write(centre("* " .. BOARD_TITLE .. " *", w))
      mon.setTextColour(colours.white)
      mon.setCursorPos(1, math.max(1, math.floor(h / 2) + 1))
      mon.write(centre(#SONGS .. " songs  ·  " .. #allQuotes .. " quotes", w))
      mon.setTextColour(colours.lightGrey)
      mon.setCursorPos(1, math.max(1, math.floor(h / 2) + 3))
      mon.write(centre("H help   A apps", w))
    end)
  end
end

-- ============================================================
-- Entry point
-- ============================================================
local function main()
  loadChatQuotes()
  loadCustomQuotes()
  loadSettings()
  rebuildAllQuotes()
  assert(#allQuotes > 0, "No quotes available.")
  assert(#SONGS > 0, "No songs available.")
  math.randomseed(os.epoch("utc"))
  state.quoteIdx = math.random(#allQuotes)
  ensureQuoteMatchesFilter()
  state.startedAt = os.epoch("utc")

  local attached = peripheral.getNames()
  print("quote-board: peripherals (" .. #attached .. ")")
  for _, name in ipairs(attached) do
    print("  " .. name .. " -> " .. tostring(peripheral.getType(name)))
  end
  print("")

  monitors = findMonitors()
  assert(#monitors > 0, "No colour monitor found. Attach an Advanced Monitor and reboot.")
  for _, mon in ipairs(monitors) do
    pcall(mon.setTextScale, MONITOR_SCALE)
  end
  print("[OK]  " .. #monitors .. " monitor(s)"
    .. (MIRROR_ALL_MONITORS and " (mirrored)" or ""))

  speakers = findAllSpeakers()
  state.speakerCount = #speakers
  if #speakers == 0 then
    print("[WARN] No speakers — music disabled.")
  elseif #speakers == 1 then
    print("[OK]  1 speaker (monophonic).")
  else
    print("[OK]  " .. #speakers .. " speakers — polyphonic.")
  end

  local box = findChatBox()
  state.hasChatBox = box ~= nil
  if not box then
    print("[WARN] No Chat Box — chat capture disabled.")
  else
    print("[OK]  Chat Box detected.")
  end

  print("Songs: " .. #SONGS .. "  |  Quotes: " .. #allQuotes
    .. "  |  Vol: " .. math.floor(state.volume * 100) .. "%")
  print("Keys: R/P quote  Space pause  N skip  M mute  -/= vol")
  print("      C category  L playlist  A apps  X back  H help  Q quit")
  print("Chat: " .. CHAT_CMD_PREFIX .. "apps  "
    .. CHAT_CMD_PREFIX .. "app jukebox  "
    .. CHAT_CMD_PREFIX .. "next  "
    .. CHAT_CMD_PREFIX .. "help")

  drawSplash()
  os.sleep((#speakers == 0 or not box) and 3 or 1.5)

  parallel.waitForAll(
    function() uiLoop() end,
    function() musicLoop(speakers) end
  )
end

local ok, err = pcall(main)

state.running = false
stopAllSpeakers()
saveSettings()

term.setBackgroundColour(colours.black)
term.setTextColour(colours.white)
term.clear()
term.setCursorPos(1, 1)

if not ok and err ~= "Terminated" then
  printError("quote-board error: " .. tostring(err))
else
  print("Quote Board stopped.")
  print("Session: " .. state.quotesShown .. " quotes shown, "
    .. state.chatCaptured .. " chat captured.")
end
