-- quote-board.lua
-- Author: DekMiscCC
-- CC:T version: 1.119.x | MC: 1.21.1 | Loader: NeoForge
-- Description: Rotating display of semi-motivational, semi-incorrect HOI4-style quotes on an
--              Advanced Monitor, with elevator-music accompaniment and automatic chat capture.
--
-- Usage: quote-board
-- Recommended peripherals:
--   Advanced Monitor  — required for display
--   Speaker           — optional, provides elevator music
--   Chat Box          — optional, from Advanced Peripherals mod; captures player chat as quotes

-- ============================================================
-- Configuration — edit these values before running
-- ============================================================
local QUOTE_INTERVAL  = 15     -- seconds each quote is shown before rotating
local MONITOR_SCALE   = 0.5    -- text scale sent to the monitor (try 0.5 or 1)
local CHAT_FILE       = "quote-board-chat.dat"  -- where chat quotes are persisted
local MAX_CHAT_QUOTES = 50     -- oldest entry is dropped when this limit is exceeded
local MIN_MSG_LEN     = 10     -- chat messages shorter than this are ignored
-- ============================================================

-- Instrument aliases (keep note tables readable)
local H  = "harp"
local F  = "flute"
local CH = "chime"
local BL = "bell"

-- ============================================================
-- Elevator-music library
-- Note format: { instrument, volume (0–3), pitch (0–24), sleep_after_s }
-- Pitch reference: C4=6 D4=8 E4=10 F4=11 G4=13 A4=15 B4=17 C5=18 D5=20 E5=22
-- ============================================================
local SONGS = {
  {
    name  = "Bossa Waiting",
    notes = {
      {H,  1.2,  6, 0.30}, {H,  1.2, 10, 0.30}, {H,  1.2, 13, 0.30},
      {H,  1.2, 15, 0.30}, {H,  1.2, 13, 0.30}, {H,  1.2, 10, 0.30},
      {H,  1.2,  6, 0.60},
      {H,  1.2,  8, 0.30}, {H,  1.2, 10, 0.30}, {H,  1.2, 13, 0.30},
      {H,  1.2, 10, 0.30}, {H,  1.2,  8, 0.60},
      {H,  1.2,  6, 0.30}, {H,  1.2, 13, 0.30}, {H,  1.2, 15, 0.30},
      {H,  1.2, 17, 0.60},
      {H,  1.2, 15, 0.30}, {H,  1.2, 13, 0.30}, {H,  1.2,  6, 1.00},
    },
  },
  {
    name  = "Corporate Zen",
    notes = {
      {F,  1.0, 12, 0.40}, {F,  1.0, 13, 0.40}, {F,  1.0, 15, 0.40},
      {F,  1.0, 17, 0.40}, {F,  1.0, 18, 0.60},
      {F,  1.0, 17, 0.40}, {F,  1.0, 15, 0.40}, {F,  1.0, 13, 0.60},
      {F,  1.0, 12, 0.40}, {F,  1.0, 10, 0.40}, {F,  1.0, 12, 0.80},
      {F,  1.0, 13, 0.40}, {F,  1.0, 15, 0.40}, {F,  1.0, 13, 0.40},
      {F,  1.0, 12, 1.00},
    },
  },
  {
    name  = "Executive Chime",
    notes = {
      {CH, 0.9,  6, 0.50}, {CH, 0.7, 13, 0.50}, {CH, 0.7, 10, 0.50},
      {CH, 0.9,  8, 0.50}, {CH, 0.7, 13, 0.50}, {CH, 0.7, 10, 0.50},
      {CH, 0.9,  6, 0.50}, {CH, 0.7, 15, 0.50}, {CH, 0.7, 13, 0.50},
      {CH, 0.9,  8, 0.50}, {CH, 0.7, 13, 0.50}, {CH, 0.7, 15, 1.00},
    },
  },
  {
    name  = "Lobby Bell",
    notes = {
      {BL, 0.8, 18, 0.60}, {BL, 0.6, 17, 0.30}, {BL, 0.6, 15, 0.30},
      {BL, 0.8, 13, 0.60}, {BL, 0.6, 10, 0.30}, {BL, 0.6, 13, 0.30},
      {BL, 0.8, 15, 0.60}, {BL, 0.6, 13, 0.30}, {BL, 0.6, 10, 0.30},
      {BL, 0.8,  8, 0.60}, {BL, 0.6,  6, 0.30}, {BL, 0.6,  8, 0.30},
      {BL, 0.8, 10, 1.00},
    },
  },
  {
    name  = "Penthouse Suite",
    notes = {
      {H,  0.9,  6, 0.40}, {BL, 0.5, 18, 0.40}, {H,  0.9, 10, 0.40},
      {BL, 0.5, 17, 0.40}, {H,  0.9, 13, 0.40}, {BL, 0.5, 15, 0.40},
      {H,  0.9, 15, 0.60},
      {H,  0.9, 13, 0.40}, {BL, 0.5, 18, 0.40}, {H,  0.9, 10, 0.40},
      {BL, 0.5, 17, 0.40}, {H,  0.9,  8, 0.40}, {BL, 0.5, 15, 0.40},
      {H,  0.9,  6, 1.00},
    },
  },
}

-- ============================================================
-- Built-in quote pool
-- Format: { "quote text", "attribution", "CATEGORY" }
-- ============================================================
local BUILTIN_QUOTES = {

  -- TIP ──────────────────────────────────────────────────────
  {
    "Mining with a wooden pickaxe is technically possible. However, so is walking to work. Neither is recommended.",
    "The Game", "TIP"
  },
  {
    "Coal can be used to fuel a furnace, power a campfire, or sit in a chest doing absolutely nothing. We support all three lifestyles.",
    "The Game", "TIP"
  },
  {
    "If you find yourself surrounded by hostile mobs, consider the time-honoured strategy of hoping someone else deals with it.",
    "The Game", "TIP"
  },
  {
    "Beds can be used to skip the night entirely. Time management experts consider this cheating.",
    "The Game", "TIP"
  },
  {
    "The shield blocks 100% of frontal attacks and 0% of attacks you did not see coming. Results may vary.",
    "The Game", "TIP"
  },
  {
    "Torches can be placed on most surfaces, except in the places where you actually need them.",
    "The Game", "TIP"
  },
  {
    "Turtles can automate most tasks, including the task of figuring out why your turtle is not working.",
    "The Game", "TIP"
  },
  {
    "Building a house before nightfall is recommended. Building a house before your seventh death is optional but encouraged.",
    "The Game", "TIP"
  },
  {
    "Gravel has a 10% chance to drop flint. The other 90% of the time it is the universe teaching you patience.",
    "The Game", "TIP"
  },
  {
    "If you dig straight down, you will fall into lava. This is not a bug. This is character development.",
    "The Game", "TIP"
  },
  {
    "Respawning is free, unlimited, and comes with complimentary existential dread.",
    "The Game", "TIP"
  },
  {
    "Dirt is the most common block in the game. This fact will not help you.",
    "The Game", "TIP"
  },

  -- DID YOU KNOW ─────────────────────────────────────────────
  {
    "Creepers were originally designed to be pigs. The pigs were not informed of this change.",
    "Probably True", "DID YOU KNOW"
  },
  {
    "The word 'Minecraft' contains the word 'mine'. The legal team has confirmed this was intentional.",
    "Legal Department", "DID YOU KNOW"
  },
  {
    "Diamonds were originally called 'shiny rocks'. Marketing insisted on the rebrand.",
    "Internal Memo, 2011", "DID YOU KNOW"
  },
  {
    "The Nether was added after a developer left the oven on. It was decided to keep it.",
    "Patch Notes (Unverified)", "DID YOU KNOW"
  },
  {
    "Endermen have never attacked first. All prior incidents are under internal review.",
    "Enderman PR Department", "DID YOU KNOW"
  },
  {
    "Herobrine has never existed in Minecraft. He has, however, been removed from the changelog forty-seven times.",
    "Changelogs, Various", "DID YOU KNOW"
  },
  {
    "Lava flows faster in the Nether. The lava is aware that you are wearing your best armour. The lava does not care.",
    "Nether Safety Commission", "DID YOU KNOW"
  },
  {
    "Skeletons are composed entirely of calcium. They are also composed entirely of the desire to ruin your evening.",
    "Skeleton Union, Local 7", "DID YOU KNOW"
  },
  {
    "The Ender Dragon has a name. Nobody in the game mentions it because it would undermine the atmosphere.",
    "Behind the Scenes, Vol. 3", "DID YOU KNOW"
  },
  {
    "Phantoms were added because players were sleeping too much. The developers considered therapy. They went with phantoms.",
    "Design Document, 2018", "DID YOU KNOW"
  },

  -- WISDOM ───────────────────────────────────────────────────
  {
    "Every great adventure begins with a single step. Unless that step is into a ravine. Then it ends there too.",
    "Ancient Proverb (Abridged)", "WISDOM"
  },
  {
    "The early miner gets the iron. The late miner gets the iron the early miner somehow missed.",
    "Miners' Almanac", "WISDOM"
  },
  {
    "Success is 10% inspiration and 90% not dying to the Skeleton that spawned directly behind you.",
    "Self-Help Book, Chapter 1", "WISDOM"
  },
  {
    "You miss 100% of the shots you do not take. You also miss approximately 43% of the ones you do. Aim for the body.",
    "Archery Instructor", "WISDOM"
  },
  {
    "A problem is just an opportunity you have not solved yet. Most problems remain problems.",
    "Motivational Poster", "WISDOM"
  },
  {
    "Believe in yourself. Unless you are about to dig straight down. Then believe in your backup saves.",
    "Therapy Session Notes", "WISDOM"
  },
  {
    "Hard work and dedication will get you far. A pickaxe enchanted with Fortune III will get you further.",
    "Career Counsellor", "WISDOM"
  },
  {
    "When life gives you gravel, smelt it into glass and build a structure nobody asked for.",
    "Survival Handbook, p. 47", "WISDOM"
  },
  {
    "The obstacle is the path. Unless the obstacle is lava. Then the path is around the lava.",
    "Zen and the Art of Spelunking", "WISDOM"
  },

  -- LOADING ──────────────────────────────────────────────────
  {
    "Loading... Please contemplate the decisions that brought you to this screen.",
    "The Loading Screen", "LOADING"
  },
  {
    "The world is being generated. This takes time because quality takes time. Also because it is very large.",
    "The Loading Screen", "LOADING"
  },
  {
    "Your progress has been saved. Your decisions, however, are permanent.",
    "Autosave Complete", "LOADING"
  },
  {
    "The server is thinking. Please do not disturb the server while it thinks.",
    "Server Administration", "LOADING"
  },
  {
    "If this is taking too long, it is not a bug. It is an opportunity for self-reflection.",
    "Support FAQ", "LOADING"
  },
}

-- ============================================================
-- Shared state (safe: CC:T cooperative multitasking means only
-- one coroutine executes at a time — no data races)
-- ============================================================
local allQuotes  = {}
local chatQuotes = {}
local state = {
  songName = "—",
  quoteIdx = 1,
  chatCount = 0,
}

-- ============================================================
-- Persistent chat-quote storage
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
    table.insert(allQuotes, q)
  end
  for _, q in ipairs(chatQuotes) do
    table.insert(allQuotes, q)
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
  table.insert(chatQuotes, { msg, user, "PLAYER" })
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
      table.insert(lines, line)
      line = word
    end
  end
  if line ~= "" then table.insert(lines, line) end
  return lines
end

local function centre(text, width)
  local pad = math.max(0, math.floor((width - #text) / 2))
  return string.rep(" ", pad) .. text
end

-- ============================================================
-- Monitor rendering
-- ============================================================
local function drawScreen(mon, quote)
  local w, h = mon.getSize()

  local text     = quote[1]
  local source   = quote[2]
  local category = quote[3]

  -- Clear with black background
  mon.setBackgroundColour(colours.black)
  mon.setTextColour(colours.white)
  mon.clear()

  -- Row 1: header bar (dark-grey bg, yellow text)
  mon.setCursorPos(1, 1)
  mon.setBackgroundColour(colours.grey)
  mon.setTextColour(colours.yellow)
  mon.clearLine()
  mon.setCursorPos(1, 1)
  mon.write(centre("* MOTIVATIONAL CORNER *", w))

  mon.setBackgroundColour(colours.black)

  -- Row 2: divider
  mon.setTextColour(colours.grey)
  mon.setCursorPos(1, 2)
  mon.write(string.rep("-", w))

  -- Row 3: category badge
  local catCol = CATEGORY_COLOUR[category] or colours.white
  mon.setTextColour(catCol)
  mon.setCursorPos(2, 3)
  mon.write("[ " .. category .. " ]")

  -- Rows 5+: quote body (word-wrapped, 2-char margin each side)
  mon.setTextColour(colours.white)
  local margin   = 3
  local bodyW    = w - margin * 2
  local wrapped  = wordWrap(text, bodyW)

  -- Decorate with curly quotes
  if #wrapped >= 1 then
    wrapped[1]       = "\xE2\x80\x9C" .. wrapped[1]
    wrapped[#wrapped] = wrapped[#wrapped] .. "\xE2\x80\x9D"
  end

  local bodyStart = 5
  -- Reserve last 3 rows for attribution + divider + music bar
  local bodyEnd   = h - 3
  for i, line in ipairs(wrapped) do
    local row = bodyStart + i - 1
    if row > bodyEnd then break end
    mon.setCursorPos(margin, row)
    mon.write(line:sub(1, bodyW))
  end

  -- Attribution (right-aligned, two rows above music bar)
  mon.setTextColour(colours.lightGrey)
  local attr    = "— " .. source
  local attrRow = math.min(bodyStart + #wrapped + 1, h - 2)
  attrRow = math.max(attrRow, bodyStart + 1)
  if attrRow < h - 1 then
    mon.setCursorPos(math.max(1, w - #attr - 1), attrRow)
    mon.write(attr:sub(1, w - 2))
  end

  -- Divider above music bar
  mon.setTextColour(colours.grey)
  mon.setCursorPos(1, h - 1)
  mon.write(string.rep("-", w))

  -- Last row: music bar (dark-grey bg, green text)
  mon.setCursorPos(1, h)
  mon.setBackgroundColour(colours.grey)
  mon.setTextColour(colours.green)
  mon.clearLine()
  local chatLabel = state.chatCount > 0
    and (" | chat: " .. state.chatCount .. " quote" .. (state.chatCount == 1 and "" or "s"))
    or ""
  local musicLine = "  * " .. state.songName .. chatLabel
  mon.setCursorPos(1, h)
  mon.write(musicLine:sub(1, w))

  mon.setBackgroundColour(colours.black)
  mon.setTextColour(colours.white)
end

-- ============================================================
-- Display loop — rotates quotes every QUOTE_INTERVAL seconds
-- ============================================================
local function displayLoop(mon)
  while true do
    local q = allQuotes[state.quoteIdx]
    if q then
      drawScreen(mon, q)
    end
    os.sleep(QUOTE_INTERVAL)
    state.quoteIdx = (state.quoteIdx % #allQuotes) + 1
  end
end

-- ============================================================
-- Music loop — cycles through SONGS indefinitely
-- ============================================================
local function musicLoop(spk)
  if not spk then
    while true do os.sleep(60) end
  end

  local songIdx = 1
  while true do
    local song = SONGS[songIdx]
    state.songName = song.name

    for _, note in ipairs(song.notes) do
      local ok = spk.playNote(note[1], note[2], note[3])
      if not ok then
        -- Hit the 8-notes/tick limit; wait one tick and retry
        os.sleep(0.05)
        spk.playNote(note[1], note[2], note[3])
      end
      os.sleep(note[4])
    end

    songIdx = (songIdx % #SONGS) + 1
  end
end

-- ============================================================
-- Chat capture loop (requires Advanced Peripherals Chat Box)
-- Event signature: "chat", username, message, uuid, isHidden
-- ============================================================
local function chatLoop()
  local box = peripheral.find("chatBox")
  if not box then
    while true do os.sleep(60) end
  end

  while true do
    local _, user, msg = os.pullEvent("chat")
    if type(msg) == "string"
      and #msg >= MIN_MSG_LEN
      and msg:sub(1, 1) ~= "/"
      and msg:sub(1, 1) ~= "!" then
      addChatQuote(user, msg)
    end
  end
end

-- ============================================================
-- Entry point
-- ============================================================
local function main()
  loadChatQuotes()
  rebuildAllQuotes()
  math.randomseed(os.epoch("utc"))
  state.quoteIdx = math.random(#allQuotes)

  -- Monitor (required)
  local mon = peripheral.find("monitor")
  assert(mon, "No monitor found. Attach an Advanced Monitor and reboot.")
  assert(mon.isColour(), "Monitor must be an Advanced (colour) Monitor.")
  mon.setTextScale(MONITOR_SCALE)

  -- Speaker (optional)
  local spk = peripheral.find("speaker")
  if not spk then
    print("[WARN] No speaker — music disabled.")
  end

  -- Chat Box (optional, requires Advanced Peripherals)
  if not peripheral.find("chatBox") then
    print("[WARN] No chatBox — chat capture disabled.")
    print("       Install Advanced Peripherals for this feature.")
  end

  if not spk or not peripheral.find("chatBox") then
    os.sleep(2)  -- let warnings be read
  end

  parallel.waitForAll(
    function() displayLoop(mon) end,
    function() musicLoop(spk) end,
    function() chatLoop() end
  )
end

-- Ensure terminal is always restored on exit (including Ctrl+T)
local ok, err = pcall(main)

local spk = peripheral.find("speaker")
if spk then spk.stop() end

term.setBackgroundColour(colours.black)
term.setTextColour(colours.white)
term.clear()
term.setCursorPos(1, 1)

if not ok and err ~= "Terminated" then
  printError("quote-board error: " .. tostring(err))
else
  print("Quote Board stopped.")
end
