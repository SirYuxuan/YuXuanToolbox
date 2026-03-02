local addonName, ns = ...
local L = ns.L
local Core = ns.Core

local quickAddFrame
local mainCategory
local managerCategory
local importExportCategory
local managerPanel

local function ensureColorFill(swatch)
    if not swatch.fill then
        swatch.fill = swatch:CreateTexture(nil, "ARTWORK")
        swatch.fill:SetPoint("TOPLEFT", 2, -2)
        swatch.fill:SetPoint("BOTTOMRIGHT", -2, 2)
    end
end

local function openColorPicker(color, onChanged)
    local function setColor()
        local r, g, b = ColorPickerFrame:GetColorRGB()
        color.r, color.g, color.b = r, g, b
        if onChanged then onChanged() end
    end

    ColorPickerFrame:SetupColorPickerAndShow({
        r = color.r,
        g = color.g,
        b = color.b,
        swatchFunc = setColor,
        opacityFunc = nil,
        cancelFunc = function(previous)
            if previous then
                color.r, color.g, color.b = previous.r, previous.g, previous.b
                if onChanged then onChanged() end
            end
        end,
        hasOpacity = false,
        previousValues = { r = color.r, g = color.g, b = color.b },
    })
end

local function showQuickAddPopup()
    Core:EnsureDB()

    if not quickAddFrame then
        quickAddFrame = CreateFrame("Frame", addonName .. "QuickAdd", UIParent, "BasicFrameTemplateWithInset")
        quickAddFrame:SetSize(360, 230)
        quickAddFrame:SetPoint("CENTER")
        quickAddFrame:SetFrameStrata("DIALOG")
        quickAddFrame:SetMovable(true)
        quickAddFrame:EnableMouse(true)
        quickAddFrame:RegisterForDrag("LeftButton")
        quickAddFrame:SetScript("OnDragStart", quickAddFrame.StartMoving)
        quickAddFrame:SetScript("OnDragStop", quickAddFrame.StopMovingOrSizing)

        quickAddFrame.TitleText:SetText(L.QUICK_ADD_TITLE)

        local titleLabel = quickAddFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        titleLabel:SetPoint("TOPLEFT", 14, -38)
        titleLabel:SetText(L.LABEL_TITLE)

        local titleEdit = CreateFrame("EditBox", nil, quickAddFrame, "InputBoxTemplate")
        titleEdit:SetAutoFocus(false)
        titleEdit:SetSize(320, 24)
        titleEdit:SetPoint("TOPLEFT", titleLabel, "BOTTOMLEFT", 0, -6)
        quickAddFrame.titleEdit = titleEdit

        local noteLabel = quickAddFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        noteLabel:SetPoint("TOPLEFT", titleEdit, "BOTTOMLEFT", 0, -12)
        noteLabel:SetText(L.LABEL_NOTE)

        local noteEdit = CreateFrame("EditBox", nil, quickAddFrame, "InputBoxTemplate")
        noteEdit:SetAutoFocus(false)
        noteEdit:SetSize(320, 24)
        noteEdit:SetPoint("TOPLEFT", noteLabel, "BOTTOMLEFT", 0, -6)
        quickAddFrame.noteEdit = noteEdit

        local colorLabel = quickAddFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        colorLabel:SetPoint("TOPLEFT", noteEdit, "BOTTOMLEFT", 0, -14)
        colorLabel:SetText(L.LABEL_COLOR)

        quickAddFrame.color = { r = 0.2, g = 1, b = 0.73 }

        local swatch = CreateFrame("Button", nil, quickAddFrame, "BackdropTemplate")
        swatch:SetSize(30, 18)
        swatch:SetPoint("LEFT", colorLabel, "RIGHT", 8, 0)
        swatch:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            edgeSize = 12,
            insets = { left = 2, right = 2, top = 2, bottom = 2 },
        })
        ensureColorFill(swatch)
        quickAddFrame.swatch = swatch

        local function updateSwatch()
            ensureColorFill(swatch)
            swatch:SetBackdropColor(0, 0, 0, 0.2)
            swatch.fill:SetColorTexture(quickAddFrame.color.r, quickAddFrame.color.g, quickAddFrame.color.b, 1)
        end

        swatch:SetScript("OnClick", function()
            openColorPicker(quickAddFrame.color, updateSwatch)
        end)

        local saveBtn = CreateFrame("Button", nil, quickAddFrame, "UIPanelButtonTemplate")
        saveBtn:SetSize(96, 24)
        saveBtn:SetPoint("BOTTOMRIGHT", -14, 12)
        saveBtn:SetText(L.BTN_SAVE)

        local cancelBtn = CreateFrame("Button", nil, quickAddFrame, "UIPanelButtonTemplate")
        cancelBtn:SetSize(96, 24)
        cancelBtn:SetPoint("RIGHT", saveBtn, "LEFT", -8, 0)
        cancelBtn:SetText(L.BTN_CANCEL)

        saveBtn:SetScript("OnClick", function()
            local title = strtrim(quickAddFrame.titleEdit:GetText() or "")
            if title == "" then
                title = L.CUSTOM_POINT
            end

            local note = quickAddFrame.noteEdit:GetText() or ""
            if Core:AddCurrentPositionMarker(title, note, quickAddFrame.color) then
                quickAddFrame:Hide()
            end
        end)

        cancelBtn:SetScript("OnClick", function()
            quickAddFrame:Hide()
        end)

        quickAddFrame:SetScript("OnShow", function(self)
            self.color = Core:GetLastColor()
            updateSwatch()
            self.titleEdit:SetText("")
            self.noteEdit:SetText("")
            self.titleEdit:SetFocus()
        end)

        quickAddFrame.updateSwatch = updateSwatch
    end

    if quickAddFrame.updateSwatch then
        quickAddFrame.color = Core:GetLastColor()
        quickAddFrame.updateSwatch()
    end

    quickAddFrame:Show()
end

local function refreshManagerList(content)
    for _, child in ipairs({ content:GetChildren() }) do
        child:Hide()
        child:SetParent(nil)
    end

    for _, region in ipairs({ content:GetRegions() }) do
        if region and region.GetObjectType and region:GetObjectType() == "FontString" then
            region:SetText("")
            region:Hide()
        end
    end

    Core:EnsureDB()
    local db = Core:GetDB()
    local mapIDs = {}

    for mapID, list in pairs(db.markersByMap or {}) do
        mapID = tonumber(mapID)
        if mapID and type(list) == "table" and #list > 0 then
            table.insert(mapIDs, mapID)
        end
    end

    table.sort(mapIDs)
    local top = -8

    if #mapIDs == 0 then
        local emptyText = content:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        emptyText:SetPoint("TOPLEFT", 8, top)
        emptyText:SetText(L.MANAGER_EMPTY)
        return
    end

    for _, mapID in ipairs(mapIDs) do
        local list = db.markersByMap[mapID]

        local mapHeader = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        mapHeader:SetPoint("TOPLEFT", 8, top)
        mapHeader:SetText(string.format(L.MANAGER_MAP_HEADER, Core:GetMapName(mapID), mapID))
        mapHeader:SetTextColor(1, 0.82, 0)
        top = top - 24

        for i, marker in ipairs(list) do
            local row = CreateFrame("Frame", nil, content)
            row:SetSize(560, 24)
            row:SetPoint("TOPLEFT", 8, top)
            top = top - 26

            local x = math.floor((marker.coord or 0) / 10000) / 100
            local y = ((marker.coord or 0) % 10000) / 100

            local txt = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
            txt:SetPoint("LEFT", 0, 0)
            txt:SetJustifyH("LEFT")
            txt:SetWidth(460)
            txt:SetText(string.format("[%d] %s (%.2f, %.2f)", i, marker.title or L.CUSTOM_POINT, x, y))

            local del = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
            del:SetSize(80, 20)
            del:SetPoint("RIGHT", 0, 0)
            del:SetText(L.BTN_DELETE)

            local markerMapID = mapID
            local markerIndex = i
            del:SetScript("OnClick", function()
                Core:RemoveMarker(markerMapID, markerIndex)
                refreshManagerList(content)
            end)
        end

        top = top - 8
    end

    local contentHeight = math.max(360, -top + 20)
    content:SetHeight(contentHeight)
end

local function createManagerPanel()
    local panel = CreateFrame("Frame")
    managerPanel = panel

    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText(L.MANAGER_TITLE)
    title:SetTextColor(1, 0.82, 0)

    local scroll = CreateFrame("ScrollFrame", nil, panel, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 10, -44)
    scroll:SetPoint("BOTTOMRIGHT", -30, 12)

    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(560, 360)
    scroll:SetScrollChild(content)
    panel.content = content

    panel:SetScript("OnShow", function(self)
        refreshManagerList(self.content)
    end)

    return panel
end

local function createImportExportPanel()
    local panel = CreateFrame("Frame")

    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText(L.IO_TITLE)
    title:SetTextColor(1, 0.82, 0)

    local statusText = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    statusText:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -12)
    statusText:SetText("")

    local exportBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    exportBtn:SetSize(100, 24)
    exportBtn:SetPoint("TOPLEFT", statusText, "BOTTOMLEFT", 0, -8)
    exportBtn:SetText(L.BTN_EXPORT)

    local importBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    importBtn:SetSize(100, 24)
    importBtn:SetPoint("LEFT", exportBtn, "RIGHT", 8, 0)
    importBtn:SetText(L.BTN_IMPORT)

    local ioScroll = CreateFrame("ScrollFrame", nil, panel, "InputScrollFrameTemplate")
    ioScroll:SetPoint("TOPLEFT", exportBtn, "BOTTOMLEFT", -6, -10)
    ioScroll:SetSize(620, 360)

    local ioEdit = ioScroll.EditBox
    ioEdit:SetAutoFocus(false)
    ioEdit:SetMultiLine(true)
    ioEdit:SetFontObject(GameFontHighlightSmall)
    ioEdit:SetWidth(600)

    exportBtn:SetScript("OnClick", function()
        ioEdit:SetText(Core:ExportMarkers())
        ioEdit:HighlightText()
        statusText:SetText(L.EXPORT_OK)
        statusText:SetTextColor(0.3, 1, 0.4)
    end)

    importBtn:SetScript("OnClick", function()
        local imported = Core:ImportMarkers(ioEdit:GetText())
        if imported > 0 then
            statusText:SetText(string.format(L.IMPORT_OK, imported))
            statusText:SetTextColor(0.3, 1, 0.4)
        else
            statusText:SetText(L.IMPORT_EMPTY)
            statusText:SetTextColor(1, 0.3, 0.3)
        end
    end)

    return panel
end

local function createSettingsPanel()
    Core:EnsureDB()
    local db = Core:GetDB()

    local panel = CreateFrame("Frame")

    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText(L.ADDON_TITLE)
    title:SetTextColor(1, 0.82, 0)

    local enableCustom = CreateFrame("CheckButton", nil, panel, "InterfaceOptionsCheckButtonTemplate")
    enableCustom:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -16)
    enableCustom.Text:SetText(L.ENABLE_CUSTOM_MARKERS)
    enableCustom:SetChecked(db.settings.enableCustomMarkers)
    enableCustom:SetScript("OnClick", function(self)
        db.settings.enableCustomMarkers = self:GetChecked() and true or false
        Core:RefreshMapMarkers(true)
    end)

    local enableQuick = CreateFrame("CheckButton", nil, panel, "InterfaceOptionsCheckButtonTemplate")
    enableQuick:SetPoint("TOPLEFT", enableCustom, "BOTTOMLEFT", 0, -8)
    enableQuick.Text:SetText(L.ENABLE_QUICK_COORD)
    enableQuick:SetChecked(db.settings.enableQuickCoordInput)
    enableQuick:SetScript("OnClick", function(self)
        db.settings.enableQuickCoordInput = self:GetChecked() and true or false
        Core:UpdateQuickCoordInputVisibility()
    end)

    local sizeText = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    sizeText:SetPoint("TOPLEFT", enableQuick, "BOTTOMLEFT", 0, -16)
    sizeText:SetText(L.MARKER_SIZE)

    local slider = CreateFrame("Slider", addonName .. "MarkerSizeSlider", panel, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", sizeText, "BOTTOMLEFT", 0, -8)
    slider:SetMinMaxValues(10, 64)
    slider:SetValueStep(1)
    slider:SetObeyStepOnDrag(true)
    slider:SetWidth(220)
    slider:SetValue(db.settings.markerSize or 15)
    _G[slider:GetName() .. "Low"]:SetText("10")
    _G[slider:GetName() .. "High"]:SetText("64")
    _G[slider:GetName() .. "Text"]:SetText(tostring(db.settings.markerSize or 15))
    slider:SetScript("OnValueChanged", function(self, value)
        value = math.floor((value or 15) + 0.5)
        db.settings.markerSize = value
        _G[self:GetName() .. "Text"]:SetText(tostring(value))
        Core:RefreshMapMarkers(true)
    end)

    local quickAddHeader = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    quickAddHeader:SetPoint("TOPLEFT", slider, "BOTTOMLEFT", 0, -18)
    quickAddHeader:SetText(L.QUICK_ADD_TITLE)

    local titleInputLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    titleInputLabel:SetPoint("TOPLEFT", quickAddHeader, "BOTTOMLEFT", 0, -8)
    titleInputLabel:SetText(L.LABEL_TITLE)

    local titleEdit = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
    titleEdit:SetAutoFocus(false)
    titleEdit:SetSize(220, 24)
    titleEdit:SetPoint("TOPLEFT", titleInputLabel, "BOTTOMLEFT", 0, -6)

    local noteInputLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    noteInputLabel:SetPoint("TOPLEFT", titleEdit, "BOTTOMLEFT", 0, -8)
    noteInputLabel:SetText(L.LABEL_NOTE)

    local noteEdit = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
    noteEdit:SetAutoFocus(false)
    noteEdit:SetSize(220, 24)
    noteEdit:SetPoint("TOPLEFT", noteInputLabel, "BOTTOMLEFT", 0, -6)

    local quickColor = Core:GetLastColor()

    local colorLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    colorLabel:SetPoint("TOPLEFT", noteEdit, "BOTTOMLEFT", 0, -10)
    colorLabel:SetText(L.LABEL_COLOR)

    local colorSwatch = CreateFrame("Button", nil, panel, "BackdropTemplate")
    colorSwatch:SetSize(30, 18)
    colorSwatch:SetPoint("LEFT", colorLabel, "RIGHT", 8, 0)
    colorSwatch:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 12,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    ensureColorFill(colorSwatch)

    local function updateQuickSwatch()
        ensureColorFill(colorSwatch)
        colorSwatch:SetBackdropColor(0, 0, 0, 0.2)
        colorSwatch.fill:SetColorTexture(quickColor.r, quickColor.g, quickColor.b, 1)
    end

    updateQuickSwatch()

    colorSwatch:SetScript("OnClick", function()
        openColorPicker(quickColor, updateQuickSwatch)
    end)

    local addBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    addBtn:SetSize(160, 24)
    addBtn:SetPoint("TOPLEFT", colorLabel, "BOTTOMLEFT", 0, -10)
    addBtn:SetText(L.BTN_ADD_CURRENT)
    addBtn:SetScript("OnClick", function()
        local titleText = strtrim(titleEdit:GetText() or "")
        if titleText == "" then
            titleText = L.CUSTOM_POINT
        end
        local noteText = noteEdit:GetText() or ""
        if Core:AddCurrentPositionMarker(titleText, noteText, quickColor) then
            titleEdit:SetText("")
            noteEdit:SetText("")
            quickColor = Core:GetLastColor()
            updateQuickSwatch()
        end
    end)

    mainCategory = Settings.RegisterCanvasLayoutCategory(panel, L.ADDON_TITLE)
    managerCategory = Settings.RegisterCanvasLayoutSubcategory(mainCategory, createManagerPanel(), L.BTN_MANAGE)
    importExportCategory = Settings.RegisterCanvasLayoutSubcategory(mainCategory, createImportExportPanel(),
        L.BTN_EXPORT_IMPORT)
    Settings.RegisterAddOnCategory(mainCategory)
end

SLASH_YuXuanMapPin1 = "/yxpin"
SLASH_YuXuanMapPin2 = "/雨轩标点"
SlashCmdList["YuXuanMapPin"] = function()
    showQuickAddPopup()
end

SLASH_YuXuanMapPinConfig1 = "/yxmp"
SLASH_YuXuanMapPinConfig2 = "/yxpinconfig"
SlashCmdList["YuXuanMapPinConfig"] = function()
    if Settings and mainCategory then
        Settings.OpenToCategory(mainCategory:GetID())
    end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:SetScript("OnEvent", function(_, _, arg1)
    if arg1 ~= addonName then return end
    createSettingsPanel()
end)

ns.ShowQuickAddPopup = showQuickAddPopup

ns.NotifyDataChanged = function()
    if managerPanel and managerPanel:IsShown() and managerPanel.content then
        refreshManagerList(managerPanel.content)
    end
end
