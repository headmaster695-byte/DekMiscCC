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

-- ============================================================
-- Configuration
-- ============================================================
local QUOTE_INTERVAL  = 15
local MONITOR_SCALE   = 0.5
local CHAT_FILE       = "quote-board-chat.dat"
local MAX_CHAT_QUOTES = 50
local MIN_MSG_LEN     = 10
local CHAT_BOX_NAME   = ""   -- e.g. "left"; blank = auto-detect
local DIFF_CAT_WEIGHT = 4    -- weight for quotes in a different category
local SAME_CAT_WEIGHT = 1    -- weight for quotes in the same category
local TITLE_SONG_IDX  = 1    -- SONGS index that always plays first

-- ============================================================
-- Data modules (songs.lua + quotes.lua next to this script)
-- ============================================================
local SONGS, BUILTIN_QUOTES

do
  -- Allow require() to find siblings of this program
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
local state = {
  songName     = "—",
  quoteIdx     = 1,
  chatCount    = 0,
  speakerCount = 0,
}

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
    state.quoteIdx = 1
  end
end

local function addChatQuote(user, msg)
  if #chatQuotes >= MAX_CHAT_QUOTES then
    table.remove(chatQuotes, 1)
  end
  chatQuotes[#chatQuotes + 1] = { msg, user, "PLAYER" }
  saveChatQuotes()
  rebuildAllQuotes()
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

local function drawScreen(mon, quote)
  local w, h = mon.getSize()
  local text, source, category = quote[1], quote[2], quote[3]

  mon.setBackgroundColour(colours.black)
  mon.setTextColour(colours.white)
  mon.clear()

  -- Header
  mon.setCursorPos(1, 1)
  mon.setBackgroundColour(colours.grey)
  mon.setTextColour(colours.yellow)
  mon.clearLine()
  mon.setCursorPos(1, 1)
  mon.write(centre("* MOTIVATIONAL CORNER *", w))
  mon.setBackgroundColour(colours.black)

  -- Divider
  mon.setTextColour(colours.grey)
  mon.setCursorPos(1, 2)
  mon.write(string.rep("-", w))

  -- Category
  mon.setTextColour(CATEGORY_COLOUR[category] or colours.white)
  mon.setCursorPos(2, 3)
  mon.write("[ " .. category .. " ]")

  -- Body
  mon.setTextColour(colours.white)
  local margin = 3
  local bodyW = w - margin * 2
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

  -- Attribution
  mon.setTextColour(colours.lightGrey)
  local attr = "— " .. source
  local attrRow = math.min(bodyStart + #wrapped + 1, h - 2)
  attrRow = math.max(attrRow, bodyStart + 1)
  if attrRow < h - 1 then
    mon.setCursorPos(math.max(1, w - #attr - 1), attrRow)
    mon.write(attr:sub(1, w - 2))
  end

  -- Footer divider + music bar
  mon.setTextColour(colours.grey)
  mon.setCursorPos(1, h - 1)
  mon.write(string.rep("-", w))

  mon.setCursorPos(1, h)
  mon.setBackgroundColour(colours.grey)
  mon.setTextColour(colours.green)
  mon.clearLine()

  local chatLabel = state.chatCount > 0
    and (" | chat: " .. state.chatCount)
    or ""
  local spkLabel = state.speakerCount > 1
    and (" | " .. state.speakerCount .. " spk")
    or ""
  local musicLine = "  * " .. state.songName .. spkLabel .. chatLabel
  mon.setCursorPos(1, h)
  mon.write(musicLine:sub(1, w))

  mon.setBackgroundColour(colours.black)
  mon.setTextColour(colours.white)
end

-- ============================================================
-- Weighted quote selection
-- ============================================================
local function pickNextQuote(currentIdx)
  local n = #allQuotes
  if n <= 1 then return 1 end

  local currentCat = allQuotes[currentIdx] and allQuotes[currentIdx][3]
  local cumWeights, total = {}, 0

  for i = 1, n do
    local w
    if i == currentIdx then
      w = 0
    elseif allQuotes[i][3] == currentCat then
      w = SAME_CAT_WEIGHT
    else
      w = DIFF_CAT_WEIGHT
    end
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

local function displayLoop(mon)
  while true do
    local q = allQuotes[state.quoteIdx]
    if q then drawScreen(mon, q) end
    os.sleep(QUOTE_INTERVAL)
    state.quoteIdx = pickNextQuote(state.quoteIdx)
  end
end

-- ============================================================
-- Speakers + polyphonic playback
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

local function getSongVoices(song)
  if song.voices then return song.voices end
  if song.notes then return { { notes = song.notes } } end
  return {}
end

local function playSong(song, speakers)
  local voices = getSongVoices(song)
  if #voices == 0 or #speakers == 0 then return end

  local tasks = {}
  for i, voice in ipairs(voices) do
    local spk = speakers[(i - 1) % #speakers + 1]
    local notes = voice.notes or {}
    tasks[#tasks + 1] = function()
      for _, note in ipairs(notes) do
        local inst, vol, pitch, delay = note[1], note[2], note[3], note[4]
        if type(inst) == "string" then
          local ok = spk.playNote(inst, vol, pitch)
          if not ok then
            os.sleep(0.05)
            spk.playNote(inst, vol, pitch)
          end
        end
        os.sleep(delay or 0.05)
      end
    end
  end

  parallel.waitForAll(table.unpack(tasks))
end

local function musicLoop(speakers)
  if #speakers == 0 then
    while true do os.sleep(60) end
  end

  local isFirst, lastIdx = true, 0

  while true do
    local idx
    if isFirst then
      idx = TITLE_SONG_IDX
      isFirst = false
    else
      if #SONGS == 1 then
        idx = 1
      else
        repeat
          idx = math.random(#SONGS)
        until idx ~= lastIdx
      end
    end
    lastIdx = idx

    local song = SONGS[idx]
    state.songName = song.name or ("song " .. idx)

    local ok, err = pcall(playSong, song, speakers)
    if not ok then
      state.songName = "err"
      os.sleep(0.5)
    end
  end
end

-- ============================================================
-- Chat Box detection + capture
-- ============================================================
local CHAT_EVENT_NAMES = { chat = true, chat_message = true }

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

local function chatLoop()
  if not findChatBox() then
    while true do os.sleep(60) end
  end

  while true do
    local ev = { os.pullEvent() }
    if CHAT_EVENT_NAMES[ev[1]] then
      local user, msg = ev[2], ev[3]
      if type(user) == "string" and type(msg) == "string"
        and #msg >= MIN_MSG_LEN
        and msg:sub(1, 1) ~= "/"
        and msg:sub(1, 1) ~= "!" then
        addChatQuote(user, msg)
      end
    end
  end
end

-- ============================================================
-- Entry point
-- ============================================================
local function main()
  loadChatQuotes()
  rebuildAllQuotes()
  assert(#allQuotes > 0, "No quotes available.")
  math.randomseed(os.epoch("utc"))
  state.quoteIdx = math.random(#allQuotes)

  -- Diagnostics
  local attached = peripheral.getNames()
  print("quote-board: peripherals (" .. #attached .. ")")
  for _, name in ipairs(attached) do
    print("  " .. name .. " -> " .. tostring(peripheral.getType(name)))
  end
  print("")

  -- Monitor (required)
  local mon = peripheral.find("monitor")
  assert(mon, "No monitor found. Attach an Advanced Monitor and reboot.")
  assert(mon.isColour(), "Monitor must be an Advanced (colour) Monitor.")
  mon.setTextScale(MONITOR_SCALE)

  -- Speakers (optional)
  local speakers = findAllSpeakers()
  state.speakerCount = #speakers
  if #speakers == 0 then
    print("[WARN] No speakers — music disabled.")
  elseif #speakers == 1 then
    print("[OK]  1 speaker (monophonic).")
  else
    print("[OK]  " .. #speakers .. " speakers — polyphonic.")
  end

  -- Chat Box (optional)
  local box = findChatBox()
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
  if #speakers == 0 or not box then
    os.sleep(3)
  end

  parallel.waitForAll(
    function() displayLoop(mon) end,
    function() musicLoop(speakers) end,
    function() chatLoop() end
  )
end

local ok, err = pcall(main)

-- Cleanup every speaker
for _, pName in ipairs(peripheral.getNames()) do
  if peripheral.getType(pName) == "speaker" then
    local s = peripheral.wrap(pName)
    if s then pcall(s.stop) end
  end
end

term.setBackgroundColour(colours.black)
term.setTextColour(colours.white)
term.clear()
term.setCursorPos(1, 1)

if not ok and err ~= "Terminated" then
  printError("quote-board error: " .. tostring(err))
else
  print("Quote Board stopped.")
end
