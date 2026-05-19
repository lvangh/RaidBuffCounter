local RBC = RaidBuffCounter

local MAX_COLUMNS = 5
local ROW_HEIGHT = 16
local HEADER_HEIGHT = 18
local TITLE_HEIGHT = 20
local DROPDOWN_HEIGHT = 26
local LIST_TOP_GAP = 6
local LIST_BOTTOM_GAP = 10
local FOOTER_HEIGHT = 22
local FOOTER_BOTTOM_INSET = 8
local FRAME_SIDE_PADDING = 10
local MIN_HEIGHT = 100
local MINIMIZED_HEIGHT = 30
local MINIMIZE_BTN_SIZE = 18
local MAX_VISIBLE_ROWS = 12
local BUTTON_WIDTH = 48
local BUTTON_HEIGHT = 18
local OPTIONS_BUTTON_WIDTH = 58

local NAME_COL_WIDTH = 78
local NUM_COL_WIDTH = 36
local COL_GAP = 4

local function EnsureDB()
  return RaidBuffCounterDB
end

local function FrameWidthForClass(classDef)
  local width = FRAME_SIDE_PADDING * 2 + NAME_COL_WIDTH
  for _ in ipairs(classDef.columns) do
    width = width + NUM_COL_WIDTH + COL_GAP
  end
  return math.max(width, 150)
end

local function SortedNames(counts)
  local names = {}
  for name in pairs(counts) do
    names[#names + 1] = name
  end
  table.sort(names)
  return names
end

function RBC:IsMinimized()
  local db = EnsureDB()
  return db and db.frame and db.frame.minimized
end

local function SetMinimizeButtonTextures(button, minimized)
  if minimized then
    button:SetNormalTexture("Interface\\Buttons\\UI-Panel-ExpandButton-Up")
    button:SetPushedTexture("Interface\\Buttons\\UI-Panel-ExpandButton-Down")
    button:SetHighlightTexture("Interface\\Buttons\\UI-Panel-ExpandButton-Highlight")
  else
    button:SetNormalTexture("Interface\\Buttons\\UI-Panel-CollapseButton-Up")
    button:SetPushedTexture("Interface\\Buttons\\UI-Panel-CollapseButton-Down")
    button:SetHighlightTexture("Interface\\Buttons\\UI-Panel-CollapseButton-Highlight")
  end
end

function RBC:SetMinimized(minimized)
  if not self.frame or not self.header then
    return
  end

  local db = EnsureDB()
  db.frame.minimized = minimized and true or false

  local showBody = not db.frame.minimized
  self.classBar:SetShown(showBody)
  self.header:SetShown(showBody)
  self.list:SetShown(showBody)
  self.footer:SetShown(showBody)

  if self.optionsPanel and db.frame.minimized then
    self.optionsPanel:Hide()
  end

  SetMinimizeButtonTextures(self.minimizeBtn, db.frame.minimized)

  if db.frame.minimized then
    self.frame:SetSize(172, MINIMIZED_HEIGHT)
    self.title:SetText(RBC.WINDOW_TITLE)
  else
    self:RefreshUI()
  end
end

function RBC:ToggleMinimized()
  self:SetMinimized(not self:IsMinimized())
end

function RBC:UpdateClassDropdown()
  if not self.classDropdown then
    return
  end
  local classDef = RBC.GetClassDef()
  UIDropDownMenu_SetText(self.classDropdown, classDef.label)
  UIDropDownMenu_Initialize(self.classDropdown, RBC.ClassDropdownInit)
end

function RBC.ClassDropdownInit()
  local info = UIDropDownMenu_CreateInfo()
  for _, classKey in ipairs(RBC.CLASS_ORDER) do
    local classDef = RBC.CLASSES[classKey]
    info.text = classDef.label
    info.value = classKey
    info.func = function()
      RBC.SetSelectedClass(classKey)
    end
    info.checked = RBC.GetSelectedClass() == classKey
    UIDropDownMenu_AddButton(info)
  end
end

function RBC:ApplyClassLayout()
  local classDef = RBC.GetClassDef()
  local colCount = #classDef.columns

  self.title:SetText(RBC.WINDOW_TITLE)
  self.headerName:SetText("Caster")

  for c = 1, MAX_COLUMNS do
    local colDef = classDef.columns[c]
    if colDef then
      self.headerCols[c]:SetText(colDef.label)
      self.headerCols[c]:Show()
    else
      self.headerCols[c]:Hide()
    end
  end

  for i = 1, MAX_VISIBLE_ROWS do
    local row = self.rows[i]
    for c = 1, MAX_COLUMNS do
      if c <= colCount then
        row.cols[c]:Show()
      else
        row.cols[c]:Hide()
      end
    end
  end

  self.frame:SetWidth(FrameWidthForClass(classDef))
end

function RBC:RefreshUI()
  if not self.frame or not self.rows or not self.list then
    return
  end

  if self:IsMinimized() then
    return
  end

  self:ApplyClassLayout()

  local classKey = RBC.GetSelectedClass()
  local classDef = RBC.GetClassDef(classKey)
  local counts = RBC.GetCounts(classKey)
  local names = SortedNames(counts)
  local visibleCount = math.min(#names, MAX_VISIBLE_ROWS)

  for i = 1, MAX_VISIBLE_ROWS do
    local row = self.rows[i]
    local name = names[i]
    if name then
      local entry = counts[name]
      row.name:SetText(name)
      for c, colDef in ipairs(classDef.columns) do
        row.cols[c]:SetText(tostring(entry[colDef.key] or 0))
      end
      row:Show()
    else
      row:Hide()
    end
  end

  local listContentHeight = math.max(visibleCount, 1) * ROW_HEIGHT
  self.list:SetHeight(listContentHeight)

  local totalHeight = TITLE_HEIGHT
    + DROPDOWN_HEIGHT
    + HEADER_HEIGHT
    + LIST_TOP_GAP
    + listContentHeight
    + LIST_BOTTOM_GAP
    + FOOTER_HEIGHT
    + FOOTER_BOTTOM_INSET

  self.frame:SetHeight(math.max(totalHeight, MIN_HEIGHT))
end

local function CreateRow(parent, index)
  local row = CreateFrame("Frame", nil, parent)
  row:SetHeight(ROW_HEIGHT)
  row:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -((index - 1) * ROW_HEIGHT))
  row:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, -((index - 1) * ROW_HEIGHT))

  row.name = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  row.name:SetPoint("LEFT", row, "LEFT", 0, 0)
  row.name:SetWidth(NAME_COL_WIDTH)
  row.name:SetJustifyH("LEFT")

  row.cols = {}
  local anchor = row.name
  for c = 1, MAX_COLUMNS do
    local col = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    col:SetPoint("LEFT", anchor, "RIGHT", COL_GAP, 0)
    col:SetWidth(NUM_COL_WIDTH)
    col:SetJustifyH("CENTER")
    row.cols[c] = col
    anchor = col
  end

  return row
end

local function StyleSmallButton(button, label, width)
  button:SetSize(width or BUTTON_WIDTH, BUTTON_HEIGHT)
  button:SetText(label)
  local labelFS = button:GetFontString()
  if labelFS then
    labelFS:SetFontObject(GameFontNormalSmall)
  end
end

local function CreateCheckbox(parent, label, yOffset, getValue, setValue)
  local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
  cb:SetSize(24, 24)
  cb:SetPoint("TOPLEFT", parent, "TOPLEFT", 12, yOffset)

  local text = cb:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  text:SetPoint("LEFT", cb, "RIGHT", 2, 0)
  text:SetText(label)

  cb:SetScript("OnClick", function(self)
    setValue(self:GetChecked())
  end)

  function cb:SyncFromDB()
    self:SetChecked(getValue())
  end

  return cb
end

function RBC:SyncOptionsUI()
  if not self.optionChecks then
    return
  end
  for _, cb in ipairs(self.optionChecks) do
    cb:SyncFromDB()
  end
end

function RBC:ToggleOptionsPanel()
  if not self.optionsPanel then
    return
  end
  if self.optionsPanel:IsShown() then
    self.optionsPanel:Hide()
  else
    self:SyncOptionsUI()
    self.optionsPanel:Show()
  end
end

local function CreateOptionsPanel(anchorFrame)
  local panel = CreateFrame("Frame", "RaidBuffCounterOptions", UIParent, "BackdropTemplate")
  panel:SetSize(240, 150)
  panel:SetFrameStrata("DIALOG")
  panel:SetClampedToScreen(true)
  panel:Hide()

  panel:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true,
    tileSize = 32,
    edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
  })
  panel:SetBackdropColor(0, 0, 0, 0.92)
  panel:SetPoint("TOPLEFT", anchorFrame, "TOPRIGHT", 6, 0)

  local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  title:SetPoint("TOP", panel, "TOP", 0, -10)
  title:SetText("Options")

  local checks = {}

  checks[1] = CreateCheckbox(
    panel,
    "Reset counts on logout",
    -36,
    function()
      return RBC.GetResetOnLogout()
    end,
    function(checked)
      RBC.SetResetOnLogout(checked)
    end
  )

  checks[2] = CreateCheckbox(
    panel,
    "Reset counts on login",
    -62,
    function()
      return RBC.GetResetOnLogin()
    end,
    function(checked)
      RBC.SetResetOnLogin(checked)
    end
  )

  local credit = panel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  credit:SetPoint("BOTTOM", panel, "BOTTOM", 0, 34)
  credit:SetWidth(220)
  credit:SetText("Made by Mobsonme/Cessiah/CursorAI Discord efnetdoom2")
  credit:SetJustifyH("CENTER")

  local close = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
  StyleSmallButton(close, "Close")
  close:SetPoint("BOTTOM", panel, "BOTTOM", 0, 10)
  close:SetScript("OnClick", function()
    panel:Hide()
  end)

  return panel, checks
end

local function SaveFramePosition(frame)
  local db = EnsureDB()
  if not db then
    return
  end
  local point, _, relativePoint, x, y = frame:GetPoint(1)
  db.frame.point = point
  db.frame.relativePoint = relativePoint
  db.frame.x = x
  db.frame.y = y
end

local function RestoreFramePosition(frame)
  local db = EnsureDB()
  if not db or not db.frame.point then
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 120)
    return
  end
  frame:ClearAllPoints()
  frame:SetPoint(db.frame.point, UIParent, db.frame.relativePoint or db.frame.point, db.frame.x or 0, db.frame.y or 0)
end

function RBC:ToggleFrame()
  if not self.frame then
    return
  end
  local db = EnsureDB()
  if self.frame:IsShown() then
    self.frame:Hide()
    db.frame.hidden = true
    if self.optionsPanel then
      self.optionsPanel:Hide()
    end
  else
    self.frame:Show()
    db.frame.hidden = false
    RBC.UpdateRaidWindowState()
  end
end

local function CreateClassDropdown(parent)
  local bar = CreateFrame("Frame", nil, parent)
  bar:SetHeight(DROPDOWN_HEIGHT)
  bar:SetPoint("TOPLEFT", parent, "TOPLEFT", FRAME_SIDE_PADDING, -(TITLE_HEIGHT + 2))
  bar:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -FRAME_SIDE_PADDING, -(TITLE_HEIGHT + 2))

  local dropdown = CreateFrame("Frame", "RaidBuffCounterClassDropdown", bar, "UIDropDownMenuTemplate")
  dropdown:SetPoint("LEFT", bar, "LEFT", -16, -2)
  UIDropDownMenu_SetWidth(dropdown, 110)
  UIDropDownMenu_Initialize(dropdown, RBC.ClassDropdownInit)

  return bar, dropdown
end

local function CreateMainFrame()
  local classDef = RBC.GetClassDef()
  local frame = CreateFrame("Frame", "RaidBuffCounterFrame", UIParent, "BackdropTemplate")
  frame:SetSize(FrameWidthForClass(classDef), MIN_HEIGHT)
  frame:SetMovable(true)
  frame:EnableMouse(true)
  frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart", frame.StartMoving)
  frame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    SaveFramePosition(self)
  end)
  frame:SetClampedToScreen(true)
  frame:SetFrameStrata("MEDIUM")

  frame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true,
    tileSize = 32,
    edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
  })
  frame:SetBackdropColor(0, 0, 0, 0.85)

  local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  title:SetPoint("TOP", frame, "TOP", -6, -8)
  title:SetText(RBC.WINDOW_TITLE)

  local minimizeBtn = CreateFrame("Button", nil, frame)
  minimizeBtn:SetSize(MINIMIZE_BTN_SIZE, MINIMIZE_BTN_SIZE)
  minimizeBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -6, -5)
  SetMinimizeButtonTextures(minimizeBtn, false)
  minimizeBtn:SetScript("OnClick", function()
    RBC:ToggleMinimized()
  end)
  minimizeBtn:SetScript("OnEnter", function()
    GameTooltip:SetOwner(minimizeBtn, "ANCHOR_BOTTOMLEFT")
    if RBC:IsMinimized() then
      GameTooltip:SetText("Expand window", 1, 1, 1)
    else
      GameTooltip:SetText("Minimize window", 1, 1, 1)
    end
    GameTooltip:Show()
  end)
  minimizeBtn:SetScript("OnLeave", function()
    GameTooltip:Hide()
  end)

  local classBar, classDropdown = CreateClassDropdown(frame)

  local header = CreateFrame("Frame", nil, frame)
  header:SetPoint("TOPLEFT", frame, "TOPLEFT", FRAME_SIDE_PADDING, -(TITLE_HEIGHT + DROPDOWN_HEIGHT + 2))
  header:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -FRAME_SIDE_PADDING, -(TITLE_HEIGHT + DROPDOWN_HEIGHT + 2))
  header:SetHeight(HEADER_HEIGHT)

  local headerName = header:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  headerName:SetPoint("LEFT", header, "LEFT", 0, 0)
  headerName:SetWidth(NAME_COL_WIDTH)
  headerName:SetJustifyH("LEFT")
  headerName:SetText("Caster")

  local headerCols = {}
  local headerAnchor = headerName
  for c = 1, MAX_COLUMNS do
    local col = header:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    col:SetPoint("LEFT", headerAnchor, "RIGHT", COL_GAP, 0)
    col:SetWidth(NUM_COL_WIDTH)
    col:SetJustifyH("CENTER")
    headerCols[c] = col
    headerAnchor = col
  end

  local footer = CreateFrame("Frame", nil, frame)
  footer:SetHeight(FOOTER_HEIGHT)
  footer:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", FRAME_SIDE_PADDING, FOOTER_BOTTOM_INSET)
  footer:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -FRAME_SIDE_PADDING, FOOTER_BOTTOM_INSET)

  local list = CreateFrame("Frame", nil, frame)
  list:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -LIST_TOP_GAP)
  list:SetPoint("TOPRIGHT", header, "BOTTOMRIGHT", 0, -LIST_TOP_GAP)

  local rows = {}
  for i = 1, MAX_VISIBLE_ROWS do
    rows[i] = CreateRow(list, i)
    rows[i]:Hide()
  end

  local optionsBtn = CreateFrame("Button", nil, footer, "UIPanelButtonTemplate")
  StyleSmallButton(optionsBtn, "Options", OPTIONS_BUTTON_WIDTH)
  optionsBtn:SetPoint("LEFT", footer, "LEFT", 0, 0)
  optionsBtn:SetScript("OnClick", function()
    RBC:ToggleOptionsPanel()
  end)

  local resetBtn = CreateFrame("Button", nil, footer, "UIPanelButtonTemplate")
  StyleSmallButton(resetBtn, "Reset")
  resetBtn:SetPoint("RIGHT", footer, "RIGHT", 0, 0)
  resetBtn:SetScript("OnClick", function()
    RBC.ResetCounts()
  end)

  RestoreFramePosition(frame)

  local db = EnsureDB()
  if db.frame.hidden then
    frame:Hide()
  else
    frame:Show()
  end

  return frame, rows, list, header, footer, minimizeBtn, title, classBar, classDropdown, headerName, headerCols
end

local init = CreateFrame("Frame")
init:RegisterEvent("PLAYER_ENTERING_WORLD")
init:SetScript("OnEvent", function()
  if RBC.frame then
    return
  end
  RBC.frame,
    RBC.rows,
    RBC.list,
    RBC.header,
    RBC.footer,
    RBC.minimizeBtn,
    RBC.title,
    RBC.classBar,
    RBC.classDropdown,
    RBC.headerName,
    RBC.headerCols = CreateMainFrame()
  RBC.optionsPanel, RBC.optionChecks = CreateOptionsPanel(RBC.frame)
  RBC:UpdateClassDropdown()
  RBC:SyncOptionsUI()
  RBC:RefreshUI()
  RBC.UpdateRaidWindowState()
end)
