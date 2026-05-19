RaidBuffCounter = RaidBuffCounter or {}
local RBC = RaidBuffCounter

-- Back-compat for any old references
MageBuffTracker = RaidBuffCounter

RBC.WINDOW_TITLE = "Raid Buff Counter"

RBC.CLASS_ORDER = { "mage", "warlock", "druid", "priest", "warrior" }

RBC.CLASSES = {
  mage = {
    label = "Mage",
    columns = {
      { key = "ai", label = "AI", prefix = "Arcane Intellect" },
      { key = "ab", label = "AB", prefix = "Arcane Brilliance" },
    },
  },
  warlock = {
    label = "Warlock",
    columns = {
      {
        key = "hs",
        label = "HS",
        match = function(spellName)
          return spellName:find("^Create .-Healthstone", 1) == 1
        end,
      },
      {
        key = "ss",
        label = "SS",
        match = function(spellName)
          return spellName:find("^Create .-Soulstone", 1) == 1
        end,
      },
    },
  },
  druid = {
    label = "Druid",
    columns = {
      { key = "motw", label = "MotW", prefix = "Mark of the Wild" },
      { key = "gotw", label = "GotW", prefix = "Gift of the Wild" },
    },
  },
  priest = {
    label = "Priest",
    columns = {
      { key = "pof", label = "PoF", prefix = "Prayer of Fortitude" },
      { key = "pwf", label = "PW:F", prefix = "Power Word: Fortitude" },
    },
  },
  warrior = {
    label = "Warrior",
    columns = {
      { key = "sa", label = "SA", prefix = "Sunder Armor" },
    },
  },
}

function RBC.GetClassDef(classKey)
  return RBC.CLASSES[classKey or RBC.GetSelectedClass()]
end

function RBC.GetSelectedClass()
  local db = RaidBuffCounterDB
  if db and db.frame and db.frame.selectedClass and RBC.CLASSES[db.frame.selectedClass] then
    return db.frame.selectedClass
  end
  return "mage"
end

function RBC.SetSelectedClass(classKey)
  if not RBC.CLASSES[classKey] then
    return
  end
  local db = RaidBuffCounterDB
  if db then
    if not db.frame then
      db.frame = {}
    end
    db.frame.selectedClass = classKey
  end
  if RBC.UpdateClassDropdown then
    RBC:UpdateClassDropdown()
  end
  if RBC.RefreshUI then
    RBC:RefreshUI()
  end
end

function RBC.BuildSpellLookup()
  local lookup = {}
  for classKey, classDef in pairs(RBC.CLASSES) do
    for _, col in ipairs(classDef.columns) do
      lookup[#lookup + 1] = {
        classKey = classKey,
        key = col.key,
        prefix = col.prefix,
        match = col.match,
      }
    end
  end
  return lookup
end

RBC.spellLookup = RBC.BuildSpellLookup()

function RBC.MatchSpell(spellName)
  if not spellName then
    return nil, nil
  end
  for _, entry in ipairs(RBC.spellLookup) do
    if entry.match then
      if entry.match(spellName) then
        return entry.classKey, entry.key
      end
    elseif entry.prefix and spellName:find(entry.prefix, 1, true) == 1 then
      return entry.classKey, entry.key
    end
  end
  return nil, nil
end

function RBC.CreateEmptyEntry(classKey)
  local entry = {}
  for _, col in ipairs(RBC.CLASSES[classKey].columns) do
    entry[col.key] = 0
  end
  return entry
end
