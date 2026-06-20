-- nuclear-siren.lua
-- Author: DekMiscCC
-- CC:T version: 1.119.x | MC: 1.21.1 | Loader: NeoForge
-- Description: Plays a wailing nuclear-siren alarm with a flashing warning display for five minutes.
--
-- Usage: nuclear-siren
-- Recommended: Speaker peripheral for audio, Advanced Computer or Advanced Monitor for colour display.

-- ============================================================
-- Configuration — edit these values before running
-- ============================================================
local DURATION       = 5 * 60  -- alarm length in seconds (default: 300 = 5 minutes)
local INSTRUMENT     = "bit"   -- note-block instrument used for the siren tone
local VOLUME         = 3.0     -- speaker volume: 0.0 (silent) to 3.0 (loudest / farthest)
local SWEEP_DELAY    = 0.05    -- seconds between each semitone step (minimum = 1 game tick)
local FLASH_INTERVAL = 0.5     -- seconds between display colour flashes
-- ============================================================

-- ── Helpers ────────────────────────────────────────────────

local function epochSec()
  return os.epoch("utc") / 1000
end

local function formatTime(secs)
  secs = math.max(0, math.floor(secs))
  return string.format("%d:%02d", math.floor(secs / 60), secs % 60)
end

-- ── Display ────────────────────────────────────────────────

local isColour = term.isColour()

local WARNING_LINES = {
  "!!!  NUCLEAR ALERT  !!!",
  "",
  "EVACUATE IMMEDIATELY",
  "",
  "All personnel must leave the area now.",
  "",
  "",       -- placeholder: filled in with countdown each frame
  "",
  "(Press Ctrl+T to silence alarm)",
}
local COUNTDOWN_LINE = 7  -- index in WARNING_LINES for the live countdown

local function drawWarning(remaining, flashOn)
  local w, h = term.getSize()

  if isColour then
    if flashOn then
      term.setBackgroundColour(colours.red)
      term.setTextColour(colours.white)
    else
      term.setBackgroundColour(colours.black)
      term.setTextColour(colours.red)
    end
  end
  term.clear()

  WARNING_LINES[COUNTDOWN_LINE] = "Time remaining:  " .. formatTime(remaining)

  local startRow = math.max(1, math.floor((h - #WARNING_LINES) / 2) + 1)
  for i, line in ipairs(WARNING_LINES) do
    local col = math.max(1, math.floor((w - #line) / 2) + 1)
    term.setCursorPos(col, startRow + i - 1)
    term.write(line)
  end

  -- Keep cursor off the text area
  term.setCursorPos(1, h)
end

-- ── Siren sound ────────────────────────────────────────────

-- One cycle: sweep pitch 0 → 24 → 0, simulating the classic civil-defence wail.
-- Each semitone step lasts one game tick (SWEEP_DELAY ≥ 0.05 s).
-- At peak pitch (20-24) a second "bell" layer is added for a piercing top note.
local function sirenCycle(spk, endTime)
  for pitch = 0, 24 do
    if epochSec() >= endTime then return true end
    spk.playNote(INSTRUMENT, VOLUME, pitch)
    if pitch >= 20 then
      spk.playNote("bell", VOLUME * 0.6, pitch)
    end
    os.sleep(SWEEP_DELAY)
  end
  for pitch = 23, 0, -1 do
    if epochSec() >= endTime then return true end
    spk.playNote(INSTRUMENT, VOLUME, pitch)
    if pitch >= 20 then
      spk.playNote("bell", VOLUME * 0.6, pitch)
    end
    os.sleep(SWEEP_DELAY)
  end
  return false
end

local function soundLoop(endTime)
  local spk = peripheral.find("speaker")
  if not spk then return end
  while epochSec() < endTime do
    if sirenCycle(spk, endTime) then break end
  end
end

-- ── Display loop ───────────────────────────────────────────

local function displayLoop(endTime)
  local flashOn = true
  while epochSec() < endTime do
    drawWarning(endTime - epochSec(), flashOn)
    flashOn = not flashOn
    os.sleep(FLASH_INTERVAL)
  end
end

-- ── Main ───────────────────────────────────────────────────

local function cleanup()
  if isColour then
    term.setBackgroundColour(colours.black)
    term.setTextColour(colours.white)
  end
  term.clear()
  term.setCursorPos(1, 1)
end

local function main()
  -- Warn early if speaker is missing so the user isn't surprised.
  if not peripheral.find("speaker") then
    term.clear()
    term.setCursorPos(1, 1)
    print("[WARN] No speaker detected — running in visual-only mode.")
    print("       Attach a Speaker peripheral for audio.")
    os.sleep(2)
  end

  local endTime = epochSec() + DURATION

  parallel.waitForAll(
    function() soundLoop(endTime) end,
    function() displayLoop(endTime) end
  )
end

-- Wrap in pcall so terminal is always restored, even if Ctrl+T is pressed.
local ok, err = pcall(main)

cleanup()

if not ok and err ~= "Terminated" then
  printError("Alarm error: " .. tostring(err))
else
  print("Alarm ended. All clear.")
end
