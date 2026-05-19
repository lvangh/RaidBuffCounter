local ADDON_NAME = ...

RaidBuffCounter = RaidBuffCounter or {}
local RBC = RaidBuffCounter
MageBuffTracker = RaidBuffCounter

local ADDON_TITLE = "Raid Buff Counter"

local AFFILIATION_MINE = COMBATLOG_OBJECT_AFFILIATION_MINE or 0x00000001
local AFFILIATION_RAID = COMBATLOG_OBJECT_AFFILIATION_RAID or 0x00000008

local function IsSourceInMyRaid(sourceFlags)
  if not sourceFlags then
    return false
  end
  if bit.band(sourceFlags, AFFILIATION_MINE) > 0 then
    return true
  end
  if bit.band(sourceFlags, AFFILIATION_RAID) > 0 then
    return true
  end
  return false
end

local function StripRealm(fullName)
  if not fullName or fullName == "" then
    return "Unknown"
  end
  return (fullName:match("^([^%-]+)")) or fullName
end

local function ImportLegacyDB()
  if type(RaidBuffCounterDB) ~= "table" and type(MageBuffTrackerDB) == "table" then
    RaidBuffCounterDB = MageBuffTrackerDB
  end
end

local function EnsureDB()
  ImportLegacyDB()

  if type(RaidBuffCounterDB) ~= "table" then
    RaidBuffCounterDB = {}
  end

  local db = RaidBuffCounterDB
  if type(db.counts) ~= "table" then
    db.counts = {}
  end

  local firstKey = next(db.counts)
  if firstKey and type(db.counts[firstKey]) == "table" and db.counts[firstKey].ai ~= nil and db.counts.mage == nil then
    db.counts = { mage = db.counts }
  end

  for _, classKey in ipairs(RBC.CLASS_ORDER) do
    if type(db.counts[classKey]) ~= "table" then
      db.counts[classKey] = {}
    end
  end

  if db.sessionActive == nil then
    db.sessionActive = false
  end
  if db.persistAcrossLogouts == nil then
    db.persistAcrossLogouts = false
  end
  if db.resetOnLogout == nil then
    db.resetOnLogout = not db.persistAcrossLogouts
  end
  if db.resetOnLogin == nil then
    db.resetOnLogin = true
  end
  if db.frame == nil then
    db.frame = {}
  end
  if db.frame.hidden == nil then
    db.frame.hidden = false
  end
  if db.frame.minimized == nil then
    db.frame.minimized = true
  end
  if db.frame.selectedClass == nil or not RBC.CLASSES[db.frame.selectedClass] then
    db.frame.selectedClass = "mage"
  end

  return db
end

local function ClearCounts()
  local db = EnsureDB()
  for _, classKey in ipairs(RBC.CLASS_ORDER) do
    wipe(db.counts[classKey])
  end
end

local function ShouldResetOnLogin(db)
  return db.resetOnLogin ~= false
end

local function ShouldResetOnLogout(db)
  return db.resetOnLogout ~= false
end

local function StartNewSession()
  local db = EnsureDB()
  if not db.sessionActive and ShouldResetOnLogin(db) then
    ClearCounts()
  end
  db.sessionActive = true
end

local function EndSession()
  local db = EnsureDB()
  db.sessionActive = false
  if ShouldResetOnLogout(db) then
    ClearCounts()
  end
end

function RBC.GetCounts(classKey)
  local db = EnsureDB()
  classKey = classKey or RBC.GetSelectedClass()
  return db.counts[classKey]
end

function RBC.ResetCounts()
  ClearCounts()
  if RBC.RefreshUI then
    RBC:RefreshUI()
  end
  print("|cff3fc7eb" .. ADDON_TITLE .. ":|r counts reset.")
end

function RBC.GetResetOnLogout()
  return ShouldResetOnLogout(EnsureDB())
end

function RBC.GetResetOnLogin()
  return ShouldResetOnLogin(EnsureDB())
end

function RBC.SetResetOnLogout(enabled)
  local db = EnsureDB()
  db.resetOnLogout = enabled and true or false
  db.persistAcrossLogouts = not db.resetOnLogout
  if RBC.SyncOptionsUI then
    RBC:SyncOptionsUI()
  end
end

function RBC.SetResetOnLogin(enabled)
  local db = EnsureDB()
  db.resetOnLogin = enabled and true or false
  if RBC.SyncOptionsUI then
    RBC:SyncOptionsUI()
  end
end

function RBC.SetPersistAcrossLogouts(enabled)
  RBC.SetResetOnLogout(not enabled)
  print(
    "|cff3fc7eb" .. ADDON_TITLE .. ":|r persist across logout is "
      .. (enabled and "|cff00ff00ON|r" or "|cffff0000OFF|r")
      .. "."
  )
end

function RBC.UpdateRaidWindowState()
  if not RBC.frame or not RBC.frame:IsShown() or not RBC.SetMinimized then
    return
  end
  RBC:SetMinimized(not IsInRaid())
end

local function GetOrCreateEntry(classKey, shortName)
  local counts = RBC.GetCounts(classKey)
  local entry = counts[shortName]
  if not entry then
    entry = RBC.CreateEmptyEntry(classKey)
    counts[shortName] = entry
  end
  return entry
end

local function IncrementCount(classKey, shortName, column)
  local entry = GetOrCreateEntry(classKey, shortName)
  entry[column] = (entry[column] or 0) + 1
  if RBC.RefreshUI then
    RBC:RefreshUI()
  end
end

local function OnCombatLog()
  local _, subEvent, _, _, srcName, sourceFlags, _, _, _, _, _, _, spellName =
    CombatLogGetCurrentEventInfo()
  if subEvent ~= "SPELL_CAST_SUCCESS" then
    return
  end

  if not srcName or not spellName or not IsInRaid() then
    return
  end

  if not IsSourceInMyRaid(sourceFlags) then
    return
  end

  local classKey, column = RBC.MatchSpell(spellName)
  if not classKey or not column then
    return
  end

  IncrementCount(classKey, StripRealm(srcName), column)
end

local function SlashHandler(msg)
  msg = strtrim(msg or ""):lower()

  if msg == "reset" then
    RBC.ResetCounts()
    return
  end

  if msg == "toggle" then
    if RBC.ToggleFrame then
      RBC:ToggleFrame()
    end
    return
  end

  if msg == "options" then
    if RBC.ToggleOptionsPanel then
      RBC:ToggleOptionsPanel()
    end
    return
  end

  if msg == "mini" or msg == "minimize" then
    if RBC.ToggleMinimized then
      RBC:ToggleMinimized()
    end
    return
  end

  if msg == "persist on" then
    RBC.SetPersistAcrossLogouts(true)
    return
  end

  if msg == "persist off" then
    RBC.SetPersistAcrossLogouts(false)
    return
  end

  for _, classKey in ipairs(RBC.CLASS_ORDER) do
    if msg == classKey then
      RBC.SetSelectedClass(classKey)
      print("|cff3fc7eb" .. ADDON_TITLE .. ":|r showing " .. RBC.CLASSES[classKey].label .. ".")
      return
    end
  end

  print("|cff3fc7eb" .. ADDON_TITLE .. " commands:|r")
  print("  /rbc - show this help")
  print("  /rbc reset - clear all counts")
  print("  /rbc toggle - show or hide the window")
  print("  /rbc options - show options panel")
  print("  /rbc mini - minimize or expand the window")
  print("  /rbc druid|mage|paladin|priest|warlock|warrior - switch class view")
  print("  /rbc persist on|off - keep counts after logout (default off)")
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_LOGOUT")
eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
eventFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

eventFrame:SetScript("OnEvent", function(_, event, arg1)
  if event == "ADDON_LOADED" and arg1 == ADDON_NAME then
    EnsureDB()
    StartNewSession()
    return
  end

  if event == "PLAYER_LOGIN" then
    StartNewSession()
    return
  end

  if event == "PLAYER_LOGOUT" then
    EndSession()
    return
  end

  if event == "GROUP_ROSTER_UPDATE" then
    RBC.UpdateRaidWindowState()
    return
  end

  if event == "COMBAT_LOG_EVENT_UNFILTERED" then
    OnCombatLog()
  end
end)

SLASH_RAIDBUFFCOUNTER1 = "/rbc"
SLASH_RAIDBUFFCOUNTER2 = "/raidbuffcounter"
SlashCmdList["RAIDBUFFCOUNTER"] = SlashHandler

SLASH_MAGEBUFFTRACKER1 = "/mbt"
SLASH_MAGEBUFFTRACKER2 = "/magebufftracker"
SlashCmdList["MAGEBUFFTRACKER"] = function(msg)
  print("|cff3fc7ebRaid Buff Counter:|r /mbt is deprecated; use /rbc instead.")
  SlashHandler(msg)
end

RBC.StripRealm = StripRealm
RBC.ADDON_TITLE = ADDON_TITLE
