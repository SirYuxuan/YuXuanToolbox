local addonName, ns = ...
local L = ns.L
local floor = math.floor

local DB_NAME = "YuXuanMapPointDB"
local EXPORT_HEADER = "YUXUAN_MAP_PIN_V1"
local DEFAULT_COLOR = { r = 0.2, g = 1, b = 0.73 }

local Core = {
    activeMarkers = {},
    quickCoordInput = nil,
    eventFrame = CreateFrame("Frame"),
}

ns.Core = Core

local function clamp(v)
    v = tonumber(v) or 0
    if v < 0 then return 0 end
    if v > 1 then return 1 end
    return v
end

local function cloneColor(c)
    c = c or DEFAULT_COLOR

    local r = tonumber(c.r) or DEFAULT_COLOR.r
    local g = tonumber(c.g) or DEFAULT_COLOR.g
    local b = tonumber(c.b) or DEFAULT_COLOR.b

    -- 兼容 0-255 的旧颜色数据
    if r > 1 or g > 1 or b > 1 then
        r = r / 255
        g = g / 255
        b = b / 255
    end

    return { r = clamp(r), g = clamp(g), b = clamp(b) }
end

local function encodeCoord(x, y)
    if not x or not y then return nil end
    local xPart = floor(x * 10000 + 0.5)
    local yPart = floor(y * 10000 + 0.5)
    return xPart * 10000 + yPart
end

local function decodeCoord(coord)
    if not coord then return 0, 0 end
    local x = floor(coord / 10000) / 10000
    local y = (coord % 10000) / 10000
    return x, y
end

local function toHex(c)
    c = cloneColor(c)
    return string.format("%02X%02X%02X", floor(c.r * 255 + 0.5), floor(c.g * 255 + 0.5), floor(c.b * 255 + 0.5))
end

local function fromHex(hex)
    if type(hex) ~= "string" then return cloneColor(DEFAULT_COLOR) end
    local h = hex:match("^#?(%x%x%x%x%x%x)$")
    if not h then return cloneColor(DEFAULT_COLOR) end
    return {
        r = tonumber(h:sub(1, 2), 16) / 255,
        g = tonumber(h:sub(3, 4), 16) / 255,
        b = tonumber(h:sub(5, 6), 16) / 255,
    }
end

local function base64Encode(data)
    local b = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
    data = tostring(data or "")
    return ((data:gsub('.', function(x)
        local r, byte = '', x:byte()
        for i = 8, 1, -1 do
            r = r .. ((byte % 2 ^ i - byte % 2 ^ (i - 1) > 0) and '1' or '0')
        end
        return r
    end) .. '0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
        if #x < 6 then return '' end
        local c = 0
        for i = 1, 6 do
            c = c + ((x:sub(i, i) == '1') and 2 ^ (6 - i) or 0)
        end
        return b:sub(c + 1, c + 1)
    end) .. ({ '', '==', '=' })[#data % 3 + 1])
end

local function base64Decode(data)
    local b = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
    data = tostring(data or ""):gsub('%s', '')
    if data == "" then return "" end

    data = data:gsub('[^' .. b .. '=]', '')
    return (data:gsub('.', function(x)
        if x == '=' then return '' end
        local f = (b:find(x, 1, true) or 1) - 1
        local r = ''
        for i = 6, 1, -1 do
            r = r .. ((f % 2 ^ i - f % 2 ^ (i - 1) > 0) and '1' or '0')
        end
        return r
    end):gsub('%d%d%d%d%d%d%d%d', function(x)
        local c = 0
        for i = 1, 8 do
            c = c + ((x:sub(i, i) == '1') and 2 ^ (8 - i) or 0)
        end
        return string.char(c)
    end))
end

local function escapeField(str)
    str = tostring(str or "")
    return (str:gsub("%%", "%%25"):gsub("\n", "%%0A"):gsub("|", "%%7C"))
end

local function unescapeField(str)
    str = tostring(str or "")
    return (str:gsub("%%(%x%x)", function(hex)
        return string.char(tonumber(hex, 16) or 0)
    end))
end

local function parseQuickCoordInput(text)
    local xStr, yStr = tostring(text or ""):match("^%s*([%d%.]+)[,%s]+([%d%.]+)%s*$")
    if not xStr or not yStr then return nil, nil end

    local x = tonumber(xStr)
    local y = tonumber(yStr)
    if not x or not y then return nil, nil end

    if x > 1 or y > 1 then
        x = x / 100
        y = y / 100
    end

    if x < 0 or x > 1 or y < 0 or y > 1 then
        return nil, nil
    end

    return x, y
end

function Core:GetDB()
    return _G[DB_NAME]
end

function Core:EnsureDB()
    if type(_G[DB_NAME]) ~= "table" then
        _G[DB_NAME] = {}
    end

    local db = _G[DB_NAME]
    db.markersByMap = db.markersByMap or {}
    db.lastColor = cloneColor(db.lastColor or DEFAULT_COLOR)
    db.settings = db.settings or {}

    if db.settings.enableCustomMarkers == nil then db.settings.enableCustomMarkers = true end
    if db.settings.enableQuickCoordInput == nil then db.settings.enableQuickCoordInput = true end
    if db.settings.markerSize == nil then db.settings.markerSize = 15 end

    -- 老数据迁移（账号级）
    if not db.migratedFromRoyMapGuide and type(_G.RoyMapGuideDB) == "table" and type(_G.RoyMapGuideDB.customMarkers) == "table" then
        for mapID, list in pairs(_G.RoyMapGuideDB.customMarkers) do
            mapID = tonumber(mapID)
            if mapID and type(list) == "table" then
                db.markersByMap[mapID] = db.markersByMap[mapID] or {}
                for _, marker in ipairs(list) do
                    if marker and marker.coord then
                        table.insert(db.markersByMap[mapID], {
                            coord = marker.coord,
                            title = marker.title or marker.text or L.CUSTOM_POINT,
                            note = marker.note or marker.info or "",
                            customColor = cloneColor(marker.customColor or db.lastColor),
                        })
                    end
                end
            end
        end
        db.migratedFromRoyMapGuide = true
    end
end

function Core:GetLastColor()
    self:EnsureDB()
    local db = self:GetDB()
    db.lastColor = cloneColor(db.lastColor or DEFAULT_COLOR)
    return cloneColor(db.lastColor)
end

function Core:GetMapList(mapID)
    self:EnsureDB()
    local db = self:GetDB()
    db.markersByMap[mapID] = db.markersByMap[mapID] or {}
    return db.markersByMap[mapID]
end

function Core:GetMapName(mapID)
    local info = C_Map and C_Map.GetMapInfo and C_Map.GetMapInfo(mapID)
    if info and info.name and info.name ~= "" then
        return info.name
    end
    return string.format("%s %d", L.UNKNOWN_MAP, tonumber(mapID) or 0)
end

function Core:GetCurrentPlayerMapCoord()
    local mapID = C_Map.GetBestMapForUnit("player")
    if not mapID and WorldMapFrame then
        mapID = WorldMapFrame:GetMapID()
    end
    if not mapID then return nil, nil, nil end

    local pos = C_Map.GetPlayerMapPosition(mapID, "player")
    if not pos then return mapID, nil, nil end
    return mapID, pos.x, pos.y
end

function Core:AddCurrentPositionMarker(title, note, customColor)
    local mapID, x, y = self:GetCurrentPlayerMapCoord()
    if not mapID or not x or not y then
        print(string.format("%s丨%s", L.PREFIX, L.COORD_FETCH_FAILED))
        return false
    end

    local db = self:GetDB()
    local list = self:GetMapList(mapID)
    table.insert(list, {
        coord = encodeCoord(x, y),
        title = title,
        note = note or "",
        customColor = cloneColor(customColor or db.lastColor),
    })
    db.lastColor = cloneColor(customColor or db.lastColor)

    self:RefreshMapMarkers(true)
    if ns and ns.NotifyDataChanged then
        ns.NotifyDataChanged()
    end
    print(string.format("%s丨" .. L.ADDED_MARKER, L.PREFIX, title, x * 100, y * 100))
    return true
end

function Core:RemoveMarker(mapID, index)
    local list = self:GetMapList(mapID)
    if not list[index] then return false end
    table.remove(list, index)

    if #list == 0 then
        local db = self:GetDB()
        db.markersByMap[mapID] = nil
    end

    self:RefreshMapMarkers(true)
    if ns and ns.NotifyDataChanged then
        ns.NotifyDataChanged()
    end
    print(string.format("%s丨%s", L.PREFIX, L.DELETED_MARKER))
    return true
end

function Core:ClearAllMarkerFrames()
    for _, frame in ipairs(self.activeMarkers) do
        frame:Hide()
        frame:SetParent(nil)
    end
    self.activeMarkers = {}
end

function Core:CreateMarkerFrame(parent, marker)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetFrameStrata("MEDIUM")
    frame:SetFrameLevel(2200)

    frame.fontString = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    local size = self:GetDB().settings.markerSize or 15
    local fontPath = GameFontNormal:GetFont()
    frame.fontString:SetFont(fontPath, size, "OUTLINE")
    frame.fontString:SetShadowOffset(0, 0)
    frame.fontString:SetText(marker.title or L.CUSTOM_POINT)

    local c = cloneColor(marker.customColor)
    frame.fontString:SetTextColor(c.r, c.g, c.b, 1)

    local w = frame.fontString:GetStringWidth()
    local h = frame.fontString:GetStringHeight()
    frame:SetSize(w, h)
    frame.fontString:SetPoint("CENTER", frame, "CENTER")

    frame:EnableMouse(true)
    frame:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(marker.title or L.CUSTOM_POINT, 1, 0.82, 0)
        if marker.note and marker.note ~= "" then
            GameTooltip:AddLine(marker.note, 1, 1, 1, true)
        end
        GameTooltip:Show()
    end)

    frame:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    frame:SetScript("OnMouseUp", function(_, button)
        if button ~= "LeftButton" then return end
        local mapID = WorldMapFrame and WorldMapFrame:GetMapID()
        if not mapID then return end

        local x, y = decodeCoord(marker.coord)
        local waypoint = UiMapPoint.CreateFromCoordinates(mapID, x, y)
        if not waypoint then return end

        C_Map.SetUserWaypoint(waypoint)
        if C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint then
            C_SuperTrack.SetSuperTrackedUserWaypoint(true)
        end
    end)

    return frame
end

function Core:RefreshMapMarkers(_)
    self:EnsureDB()
    self:ClearAllMarkerFrames()

    local db = self:GetDB()
    if not db.settings.enableCustomMarkers then return end
    if not WorldMapFrame or not WorldMapFrame:IsShown() then return end

    local mapID = WorldMapFrame:GetMapID()
    if not mapID then return end

    local list = self:GetMapList(mapID)
    if #list == 0 then return end

    local canvas = WorldMapFrame:GetCanvas()
    if not canvas then return end

    local width = canvas:GetWidth()
    local height = canvas:GetHeight()

    for _, marker in ipairs(list) do
        if marker.coord then
            local frame = self:CreateMarkerFrame(canvas, marker)
            local x, y = decodeCoord(marker.coord)
            frame:SetPoint("CENTER", canvas, "TOPLEFT", x * width, -y * height)
            table.insert(self.activeMarkers, frame)
        end
    end
end

function Core:InitializeQuickCoordInput()
    if self.quickCoordInput or not WorldMapFrame then return end

    local anchorParent = WorldMapFrame.BorderFrame or WorldMapFrame
    local input = CreateFrame("EditBox", nil, anchorParent, "InputBoxTemplate")
    input:SetSize(170, 18)
    input:SetPoint("TOPLEFT", anchorParent, "TOPLEFT", 8, -8)
    input:SetAutoFocus(false)
    input:SetMaxLetters(32)
    input:SetTextInsets(6, 6, 0, 0)
    input:SetFontObject(GameFontHighlightSmall)

    input.hint = input:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    input.hint:SetPoint("LEFT", input, "LEFT", 8, 0)
    input.hint:SetText(L.HINT_COORD)

    input:SetScript("OnTextChanged", function(self)
        self.hint:SetShown((self:GetText() or "") == "")
    end)

    input:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)

    input:SetScript("OnEnterPressed", function(self)
        local mapID = WorldMapFrame and WorldMapFrame:GetMapID()
        if not mapID then
            self:ClearFocus()
            return
        end

        local x, y = parseQuickCoordInput(self:GetText())
        if not x or not y then
            print(string.format("%s丨%s", L.PREFIX, L.INVALID_COORD))
            return
        end

        local waypoint = UiMapPoint.CreateFromCoordinates(mapID, x, y)
        if waypoint then
            C_Map.SetUserWaypoint(waypoint)
            if C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint then
                C_SuperTrack.SetSuperTrackedUserWaypoint(true)
            end
            print(string.format("%s丨" .. L.WAYPOINT_SET, L.PREFIX, x * 100, y * 100))
        end

        self:ClearFocus()
    end)

    self.quickCoordInput = input
end

function Core:UpdateQuickCoordInputVisibility()
    if not self.quickCoordInput then return end
    local db = self:GetDB()
    local show = db.settings.enableQuickCoordInput and WorldMapFrame and WorldMapFrame:IsShown()
    self.quickCoordInput:SetShown(show)
end

function Core:ExportMarkers()
    self:EnsureDB()
    local db = self:GetDB()
    local lines = { EXPORT_HEADER }
    local mapIDs = {}

    for mapID in pairs(db.markersByMap) do
        if tonumber(mapID) then
            table.insert(mapIDs, tonumber(mapID))
        end
    end
    table.sort(mapIDs)

    for _, mapID in ipairs(mapIDs) do
        local list = db.markersByMap[mapID]
        if type(list) == "table" then
            for _, marker in ipairs(list) do
                if marker and marker.coord and marker.title and marker.title ~= "" then
                    table.insert(lines,
                        string.format("%d|%d|%s|%s|%s", mapID, marker.coord, toHex(marker.customColor),
                            escapeField(marker.title), escapeField(marker.note or "")))
                end
            end
        end
    end

    return base64Encode(table.concat(lines, "\n"))
end

function Core:ImportMarkers(input)
    self:EnsureDB()
    local db = self:GetDB()
    local imported = 0
    local payload = base64Decode(input)
    if payload == "" then payload = tostring(input or "") end

    for line in payload:gmatch("[^\r\n]+") do
        if line ~= "" and line ~= EXPORT_HEADER then
            local mapID, coord, colorHex, titleEscaped, noteEscaped = line:match("^(%d+)|(%d+)|([#%x]+)|([^|]*)|?(.*)$")
            mapID = tonumber(mapID)
            coord = tonumber(coord)
            local title = titleEscaped and strtrim(unescapeField(titleEscaped)) or ""
            local note = noteEscaped and unescapeField(noteEscaped) or ""

            if mapID and coord and title ~= "" then
                db.markersByMap[mapID] = db.markersByMap[mapID] or {}
                table.insert(db.markersByMap[mapID], {
                    coord = coord,
                    title = title,
                    note = note,
                    customColor = fromHex(colorHex),
                })
                imported = imported + 1
            end
        end
    end

    self:RefreshMapMarkers(true)
    if ns and ns.NotifyDataChanged then
        ns.NotifyDataChanged()
    end
    return imported
end

function Core:InitializeMapHooks()
    WorldMapFrame:HookScript("OnShow", function()
        self:RefreshMapMarkers(true)
        self:UpdateQuickCoordInputVisibility()
    end)

    WorldMapFrame:HookScript("OnHide", function()
        self:ClearAllMarkerFrames()
        self:UpdateQuickCoordInputVisibility()
    end)

    hooksecurefunc(WorldMapFrame, "OnMapChanged", function()
        self:RefreshMapMarkers(true)
    end)

    if WorldMapFrame.ScrollContainer then
        hooksecurefunc(WorldMapFrame.ScrollContainer, "ZoomIn", function()
            self:RefreshMapMarkers(true)
        end)
        hooksecurefunc(WorldMapFrame.ScrollContainer, "ZoomOut", function()
            self:RefreshMapMarkers(true)
        end)
    end

    self:InitializeQuickCoordInput()
    self:UpdateQuickCoordInputVisibility()
end

function Core:Initialize()
    self:EnsureDB()
    if WorldMapFrame then
        self:InitializeMapHooks()
    end
end

ns.RefreshMapPins = function()
    Core:RefreshMapMarkers(true)
end

Core.eventFrame:RegisterEvent("ADDON_LOADED")
Core.eventFrame:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addonName then
        Core:Initialize()
    end
end)
