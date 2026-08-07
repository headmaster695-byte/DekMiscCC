-- quote-board.lua
-- Author: DekMiscCC
-- CC:T version: 1.119.x | MC: 1.21.1 | Loader: NeoForge
-- Description: HOI4-style rotating quotes on an Advanced Monitor, with
--              multi-speaker music and automatic chat capture.
--
-- Usage: quote-board
-- Requires (same directory): songs.lua, quotes.lua
-- Peripherals:
--   Advanced Monitor  — required
--   Speaker(s)        — optional (adjacent or wired modem)
--   Chat Box          — optional (Advanced Peripherals)
--
-- Controls (computer keyboard):
--   R  next quote     N  skip song     M  mute/unmute     Q  quit
-- Monitor touch also advances the quote.

-- ============================================================
-- Configuration
-- ============================================================
local QUOTE_INTERVAL      = 15     -- seconds between automatic quote changes
local MONITOR_SCALE       = 0.5
local CHAT_FILE           = "quote-board-chat.dat"
local MAX_CHAT_QUOTES     = 50
local MIN_MSG_LEN         = 10
local CHAT_BOX_NAME       = ""     -- e.g. "left"; blank = auto-detect
local DIFF_CAT_WEIGHT     = 4      -- weight for quotes in a different category
local SAME_CAT_WEIGHT     = 1      -- weight for quotes in the same category
local PLAYER_CAT_WEIGHT   = 6      -- weight for PLAYER quotes (cross-category)
local TITLE_SONG_IDX      = 1      -- SONGS index that always plays first
local MUSIC_START_ON      = true   -- start with music unmuted
local FRESH_CHAT_FOCUS    = true   -- jump to newly captured chat quotes
local TOUCH_ADVANCES      = true   -- monitor touch -> next quote
local UI_TICK             = 0.25   -- display refresh granularity (seconds)

-- ============================================================
-- Data modules (songs.lua + quotes.lua next to this script)
-- ============================================================
local SONGS, BUILTIN_QUOTES

do
  local here = fs.getDir(shell.getRunningProgram())
  if here == "" then here = "." end
  package.path = package.path
    .. ";" .. here .. "/?"
    .. ";" .. here .. "/?.lua"

  local okSongs, songs = pcall(require, "songs")
  local okQuotes, quotes = pcall(require, "quotes")
  if not okSongs then
    error("Missing songs.lua — place it next to quote-board.lua\n" .. tostring(songs))
  end
  if not okQuotes then
    error("Missing quotes.lua — place it next to quote-board.lua\n" .. tostring(quotes))
  end
  SONGS = songs
  BUILTIN_QUOTES = quotes
end

-- ============================================================
-- Shared state
-- ============================================================
local allQuotes  = {}
local chatQuotes = {}
local speakers   = {}

local state = {
  running      = true,
  songName     = "—",
  quoteIdx     = 1,
  chatCount    = 0,
  speakerCount = 0,
  musicOn      = MUSIC_START_ON,
  skipSong     = false,
  dirty        = true,
  nextQuoteAt  = 0,
  flashUntil   = 0,
  flashText    = "",
  hasChatBox   = false,
}

local CHAT_EVENT_NAMES = { chat = true, chat_message = true }

-- ============================================================
-- Speakers
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

-- ============================================================
-- Chat persistence
-- ============================================================
local function loadChatQuotes()
  if not fs.exists(CHAT_FILE) then return end
  local f = fs.open(CHAT_FILE, "r")
  if not f then return end
  local raw = f.readAll()
  f.close()
  local ok, data = pcall(textutils.unserialise, raw)
  if ok and type(data) == "table" then
    chatQuotes = data
  end
end

local function saveChatQuotes()
  local f = fs.open(CHAT_FILE, "w")
  if not f then return end
  f.write(textutils.serialise(chatQuotes))
  f.close()
end

local function rebuildAllQuotes()
  allQuotes = {}
  for _, q in ipairs(BUILTIN_QUOTES) do
    allQuotes[#allQuotes + 1] = q
  end
  for _, q in ipairs(chatQuotes) do
    allQuotes[#allQuotes + 1] = q
  end
  state.chatCount = #chatQuotes
  if state.quoteIdx > #allQuotes then
    state.quoteIdx = math.max(1, #allQuotes)
  end
end

local function isDuplicateChat(msg)
  for i = #chatQuotes, math.max(1, #chatQuotes - 19), -1 do
    if chatQuotes[i][1] == msg then
      return true
    end
  end
  return false
end

local function scheduleNextQuote(seconds)
  state.nextQuoteAt = os.epoch("utc") + math.floor((seconds or QUOTE_INTERVAL) * 1000)
  state.dirty = true
end

local function addChatQuote(user, msg)
  if isDuplicateChat(msg) then return false end

  if #chatQuotes >= MAX_CHAT_QUOTES then
    table.remove(chatQuotes, 1)
  end
  chatQuotes[#chatQuotes + 1] = { msg, user, "PLAYER" }
  saveChatQuotes()
  rebuildAllQuotes()

  if FRESH_CHAT_FOCUS and #allQuotes > 0 then
    state.quoteIdx = #allQuotes
    scheduleNextQuote(QUOTE_INTERVAL)
  end

  state.flashText = "LIVE: " .. user
  state.flashUntil = os.epoch("utc") + 4000
  state.dirty = true
  return true
end

local function tryCaptureChat(user, msg)
  if not state.hasChatBox then return end
  if type(user) ~= "string" or type(msg) ~= "string" then return end
  if #msg < MIN_MSG_LEN then return end
  local first = msg:sub(1, 1)
  if first == "/" or first == "!" then return end
  addChatQuote(user, msg)
end

-- ============================================================
-- Display
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
  local ms = state.nextQuoteAt - os.epoch("utc")
  if ms <= 0 then return 0 end
  return math.ceil(ms / 1000)
end

local function drawScreen(mon, quote)
  local w, h = mon.getSize()
  local text, source, category = quote[1], quote[2], quote[3]
  local flashing = os.epoch("utc") < state.flashUntil

  mon.setBackgroundColour(colours.black)
  mon.setTextColour(colours.white)
  mon.clear()

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
    mon.setCursorPos(1, 1)
    mon.write(centre("* MOTIVATIONAL CORNER *", w))
  end
  mon.setBackgroundColour(colours.black)

  mon.setTextColour(colours.grey)
  mon.setCursorPos(1, 2)
  mon.write(string.rep("-", w))

  mon.setTextColour(CATEGORY_COLOUR[category] or colours.white)
  mon.setCursorPos(2, 3)
  local catLabel = "[ " .. category .. " ]"
  if flashing and category == "PLAYER" then
    catLabel = "[ PLAYER · NEW ]"
  end
  mon.write(catLabel)

  local countStr = string.format("next %ds", secondsLeft())
  mon.setTextColour(colours.grey)
  mon.setCursorPos(math.max(1, w - #countStr), 3)
  mon.write(countStr)

  mon.setTextColour(colours.white)
  local margin = 3
  local bodyW = math.max(8, w - margin * 2)
  local wrapped = wordWrap(text, bodyW)
  if #wrapped >= 1 then
    wrapped[1] = "\xE2\x80\x9C" .. wrapped[1]
    wrapped[#wrapped] = wrapped[#wrapped] .. "\xE2\x80\x9D"
  end

  local bodyStart, bodyEnd = 5, h - 3
  for i, line in ipairs(wrapped) do
    local row = bodyStart + i - 1
    if row > bodyEnd then break end
    mon.setCursorPos(margin, row)
    mon.write(line:sub(1, bodyW))
  end

  mon.setTextColour(colours.lightGrey)
  local attr = "— " .. source
  local attrRow = math.min(bodyStart + #wrapped + 1, h - 2)
  attrRow = math.max(attrRow, bodyStart + 1)
  if attrRow < h - 1 then
    mon.setCursorPos(math.max(1, w - #attr - 1), attrRow)
    mon.write(attr:sub(1, w - 2))
  end

  mon.setTextColour(colours.grey)
  mon.setCursorPos(1, h - 1)
  mon.write(string.rep("-", w))

  mon.setCursorPos(1, h)
  mon.setBackgroundColour(colours.grey)
  mon.clearLine()
  mon.setTextColour(state.musicOn and colours.green or colours.red)

  local chatLabel = state.chatCount > 0 and (" | chat:" .. state.chatCount) or ""
  local spkLabel = state.speakerCount > 1 and (" | " .. state.speakerCount .. "spk") or ""
  local musicLabel
  if state.speakerCount == 0 then
    musicLabel = "  * no speakers"
  elseif state.musicOn then
    musicLabel = "  * " .. state.songName .. spkLabel .. chatLabel
  else
    musicLabel = "  * MUTED" .. spkLabel .. chatLabel
  end
  mon.setCursorPos(1, h)
  mon.write(musicLabel:sub(1, w))

  mon.setBackgroundColour(colours.black)
  mon.setTextColour(colours.white)
end

-- ============================================================
-- Quote selection
-- ============================================================
local function weightFor(i, currentIdx, currentCat)
  if i == currentIdx then return 0 end
  local cat = allQuotes[i][3]
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

local function advanceQuote()
  state.quoteIdx = pickNextQuote(state.quoteIdx)
  scheduleNextQuote(QUOTE_INTERVAL)
end

-- ============================================================
-- Shared event handling
-- (music playback must not swallow chat/keys via filtered sleep)
-- ============================================================
local function toggleMusic()
  state.musicOn = not state.musicOn
  if not state.musicOn then
    state.skipSong = true
    stopSpeakers()
    state.songName = "muted"
  end
  state.dirty = true
end

local function requestSkipSong()
  if state.musicOn and state.speakerCount > 0 then
    state.skipSong = true
    stopSpeakers()
  end
end

-- Returns: "quit", "redraw", "abort_music", or nil
local function handleGlobalEvent(ev)
  local kind = ev[1]

  if kind == "terminate" then
    state.running = false
    return "quit"
  end

  if kind == "key" then
    local key = ev[2]
    if key == keys.q then
      state.running = false
      return "quit"
    elseif key == keys.r then
      advanceQuote()
      return "redraw"
    elseif key == keys.n then
      requestSkipSong()
      return "abort_music"
    elseif key == keys.m then
      toggleMusic()
      return state.musicOn and "redraw" or "abort_music"
    end
  elseif kind == "monitor_touch" and TOUCH_ADVANCES then
    advanceQuote()
    return "redraw"
  elseif CHAT_EVENT_NAMES[kind] then
    tryCaptureChat(ev[2], ev[3])
    return "redraw"
  end

  return nil
end

local function shouldAbortPlayback()
  return (not state.running) or (not state.musicOn) or state.skipSong
end

-- Sleep that re-queues non-timer events for the UI loop.
-- Only the music timeline uses this; UI owns chat/keys/touch handling.
local function coopSleep(seconds)
  if seconds <= 0 then return end
  local tEnd = os.clock() + seconds
  while state.running and os.clock() < tEnd do
    if shouldAbortPlayback() then return end
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
      -- Let uiLoop handle controls/chat.
      os.queueEvent(table.unpack(ev))
    end
  end
end

-- ============================================================
-- UI loop
-- ============================================================
local function uiLoop(mon)
  scheduleNextQuote(QUOTE_INTERVAL)

  while state.running do
    if os.epoch("utc") >= state.nextQuoteAt then
      advanceQuote()
    end

    local q = allQuotes[state.quoteIdx]
    if q then drawScreen(mon, q) end
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
-- Music (single timeline so events are not eaten by nested sleeps)
-- ============================================================
local function getSongVoices(song)
  if song.voices then return song.voices end
  if song.notes then return { { notes = song.notes } } end
  return {}
end

local function playSong(song, spkList)
  local voices = getSongVoices(song)
  if #voices == 0 or #spkList == 0 then return end

  -- Flatten voices into a sorted absolute-time timeline.
  local timeline = {}
  for vi, voice in ipairs(voices) do
    local t = 0
    for _, note in ipairs(voice.notes or {}) do
      timeline[#timeline + 1] = {
        t = t,
        vi = vi,
        inst = note[1],
        vol = note[2],
        pitch = note[3],
      }
      t = t + (note[4] or 0.05)
    end
  end

  if #timeline == 0 then return end
  table.sort(timeline, function(a, b)
    if a.t == b.t then return a.vi < b.vi end
    return a.t < b.t
  end)

  local t0 = os.clock()
  for _, ev in ipairs(timeline) do
    if shouldAbortPlayback() then return end

    local target = t0 + ev.t
    local wait = target - os.clock()
    if wait > 0 then
      coopSleep(wait)
      if shouldAbortPlayback() then return end
    end

    if type(ev.inst) == "string" then
      local spk = spkList[(ev.vi - 1) % #spkList + 1]
      local ok = spk.playNote(ev.inst, ev.vol, ev.pitch)
      if not ok then
        coopSleep(0.05)
        if shouldAbortPlayback() then return end
        spk.playNote(ev.inst, ev.vol, ev.pitch)
      end
    end
  end
end

local function musicLoop(spkList)
  if #spkList == 0 then
    while state.running do coopSleep(0.5) end
    return
  end

  local isFirst, lastIdx = true, 0

  while state.running do
    if not state.musicOn then
      state.songName = "muted"
      stopSpeakers(spkList)
      while state.running and not state.musicOn do
        coopSleep(0.2)
      end
      if not state.running then break end
    end

    state.skipSong = false

    local idx
    if isFirst then
      idx = TITLE_SONG_IDX
      if idx < 1 or idx > #SONGS then idx = 1 end
      isFirst = false
    elseif #SONGS == 1 then
      idx = 1
    else
      repeat
        idx = math.random(#SONGS)
      until idx ~= lastIdx
    end
    lastIdx = idx

    local song = SONGS[idx]
    state.songName = song.name or ("song " .. idx)
    state.dirty = true

    local ok = pcall(playSong, song, spkList)
    if not ok then
      state.songName = "err"
      state.dirty = true
      coopSleep(0.5)
    end

    if state.skipSong or not state.musicOn then
      state.skipSong = false
      stopSpeakers(spkList)
      coopSleep(0.05)
    end
  end

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
-- Entry point
-- ============================================================
local function main()
  loadChatQuotes()
  rebuildAllQuotes()
  assert(#allQuotes > 0, "No quotes available.")
  assert(#SONGS > 0, "No songs available.")
  math.randomseed(os.epoch("utc"))
  state.quoteIdx = math.random(#allQuotes)

  local attached = peripheral.getNames()
  print("quote-board: peripherals (" .. #attached .. ")")
  for _, name in ipairs(attached) do
    print("  " .. name .. " -> " .. tostring(peripheral.getType(name)))
  end
  print("")

  local mon = peripheral.find("monitor")
  assert(mon, "No monitor found. Attach an Advanced Monitor and reboot.")
  assert(mon.isColour(), "Monitor must be an Advanced (colour) Monitor.")
  mon.setTextScale(MONITOR_SCALE)

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
    print("       Tried: chatBox, chat_box, chatbox")
    if CHAT_BOX_NAME ~= "" then
      print("       Also tried CHAT_BOX_NAME = '" .. CHAT_BOX_NAME .. "'")
    end
  else
    print("[OK]  Chat Box detected.")
  end

  print("Songs: " .. #SONGS .. "  |  Quotes: " .. #allQuotes)
  print("Keys:  R next quote | N skip song | M mute | Q quit")
  print("Touch the monitor to advance quotes.")
  if #speakers == 0 or not box then
    os.sleep(3)
  else
    os.sleep(1)
  end

  -- Two parallel loops; both use coop/raw event handling so chat & keys
  -- are never discarded by filtered sleeps during note playback.
  parallel.waitForAll(
    function() uiLoop(mon) end,
    function() musicLoop(speakers) end
  )
end

local ok, err = pcall(main)

state.running = false
stopAllSpeakers()

term.setBackgroundColour(colours.black)
term.setTextColour(colours.white)
term.clear()
term.setCursorPos(1, 1)

if not ok and err ~= "Terminated" then
  printError("quote-board error: " .. tostring(err))
else
  print("Quote Board stopped.")
end
