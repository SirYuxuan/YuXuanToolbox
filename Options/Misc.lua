local addonName, ns = ...
local Core = ns.Core
local LibSharedMedia = LibStub("LibSharedMedia-3.0")

local S = ns.OptionsShared
local MI = S.MIcfg

local DELVE_QUICK_LEAVE_ICON_OPTIONS = {
    ["Interface\\Icons\\spell_arcane_teleportdalaran"] =
    "|TInterface\\Icons\\spell_arcane_teleportdalaran:16:16:0:0|t 达拉然传送",
    ["Interface\\Icons\\inv_misc_rune_01"] = "|TInterface\\Icons\\inv_misc_rune_01:16:16:0:0|t 符文石",
    ["Interface\\Icons\\ability_mage_massinvisibility"] =
    "|TInterface\\Icons\\ability_mage_massinvisibility:16:16:0:0|t 奥术漩涡",
    ["Interface\\Icons\\achievement_dungeon_ulduar80_raid_normal"] =
    "|TInterface\\Icons\\achievement_dungeon_ulduar80_raid_normal:16:16:0:0|t 地城徽记",
    ["Interface\\Icons\\inv_111_achievement_delves_season1"] =
    "|TInterface\\Icons\\inv_111_achievement_delves_season1:16:16:0:0|t 地下堡徽记",
    ["Interface\\Icons\\spell_shadow_teleport"] = "|TInterface\\Icons\\spell_shadow_teleport:16:16:0:0|t 暗影传送",
}

function ns.BuildMiscOptions()
    return {
        type = "group",
        name = "杂项",
        order = 85,
        args = {
            quest = {
                type = "group",
                name = "任务助手",
                order = 10,
                args = {
                    questToolsEnabled = {
                        type = "toggle",
                        name = "启用任务助手",
                        desc = "开启后显示独立的任务助手框体，包含“任务通报”和“自动交接”两个切换按钮。",
                        order = 1,
                        get = function() return MI().questToolsEnabled end,
                        set = function(_, val)
                            MI().questToolsEnabled = val
                            Core:ApplyMiscSettings()
                        end,
                    },
                    questToolsLocked = {
                        type = "toggle",
                        name = function() return MI().questToolsLocked and "解锁拖动" or "锁定框体" end,
                        order = 2,
                        disabled = function() return not MI().questToolsEnabled end,
                        get = function() return MI().questToolsLocked end,
                        set = function(_, val)
                            MI().questToolsLocked = val
                            Core:ApplyMiscSettings()
                        end,
                    },
                    questToolsOrientation = {
                        type = "select",
                        name = "排列方向",
                        order = 3,
                        disabled = function() return not MI().questToolsEnabled end,
                        values = {
                            HORIZONTAL = "横排",
                            VERTICAL = "竖排",
                        },
                        get = function() return MI().questToolsOrientation or "HORIZONTAL" end,
                        set = function(_, val)
                            MI().questToolsOrientation = val
                            Core:ApplyMiscSettings()
                        end,
                    },
                    questToolsFont = {
                        type = "select",
                        name = "字体",
                        order = 4,
                        disabled = function() return not MI().questToolsEnabled end,
                        dialogControl = "LSM30_Font",
                        values = LibSharedMedia:HashTable("font"),
                        get = function() return MI().questToolsFont or MI().font end,
                        set = function(_, val)
                            MI().questToolsFont = val
                            Core:ApplyMiscSettings()
                        end,
                    },
                    questToolsFontSize = {
                        type = "range",
                        name = "字体大小",
                        order = 5,
                        disabled = function() return not MI().questToolsEnabled end,
                        min = 10,
                        max = 24,
                        step = 1,
                        get = function() return MI().questToolsFontSize or 13 end,
                        set = function(_, val)
                            MI().questToolsFontSize = val
                            Core:ApplyMiscSettings()
                        end,
                    },
                    questToolsTextColor = {
                        type = "color",
                        name = "文字颜色",
                        order = 6,
                        disabled = function() return not MI().questToolsEnabled end,
                        hasAlpha = false,
                        get = function()
                            local c = MI().questToolsTextColor or { r = 1, g = 1, b = 1 }
                            return c.r, c.g, c.b
                        end,
                        set = function(_, r, g, b)
                            MI().questToolsTextColor = { r = r, g = g, b = b }
                            Core:ApplyMiscSettings()
                        end,
                    },
                    questToolsSpacing = {
                        type = "range",
                        name = "项目间隔",
                        order = 7,
                        disabled = function() return not MI().questToolsEnabled end,
                        min = 1,
                        max = 300,
                        step = 1,
                        get = function() return MI().questToolsSpacing or 18 end,
                        set = function(_, val)
                            MI().questToolsSpacing = math.max(1, math.min(300, val))
                            Core:ApplyMiscSettings()
                        end,
                    },
                    announceTemplate = {
                        type = "input",
                        name = "通报模板",
                        order = 8,
                        width = 1.6,
                        disabled = function() return not MI().questToolsEnabled end,
                        desc = "支持占位符：{action}=任务已接取/任务已完成、{quest}=任务名、{newline}=换行",
                        get = function() return MI().announceTemplate end,
                        set = function(_, val)
                            MI().announceTemplate = val ~= "" and val or
                                "|cFF33FF99【雨轩工具箱】|r |cFFFFFF00{action}|r：{quest}"
                        end,
                    },
                    tips = {
                        type = "description",
                        name = "任务助手会显示独立框体；“任务通报”和“自动交接”开关请直接点击框体上的按钮切换。",
                        order = 9,
                        width = "full",
                    },
                },
            },
            infoBar = {
                type = "group",
                name = "信息条",
                order = 20,
                args = {
                    infoBarEnabled = {
                        type = "toggle",
                        name = "启用信息条",
                        order = 1,
                        get = function() return MI().infoBarEnabled end,
                        set = function(_, val)
                            MI().infoBarEnabled = val
                            Core:ApplyMiscSettings()
                        end,
                    },
                    infoBarLocked = {
                        type = "toggle",
                        name = function() return MI().infoBarLocked and "解锁拖动" or "锁定信息条" end,
                        order = 2,
                        get = function() return MI().infoBarLocked end,
                        set = function(_, val)
                            MI().infoBarLocked = val
                            Core:ApplyMiscSettings()
                        end,
                    },
                    orientation = {
                        type = "select",
                        name = "排列方向",
                        order = 3,
                        values = {
                            HORIZONTAL = "横排",
                            VERTICAL = "竖排",
                        },
                        get = function() return MI().infoBarOrientation or "HORIZONTAL" end,
                        set = function(_, val)
                            MI().infoBarOrientation = val
                            Core:UpdateMiscBarLayout()
                        end,
                    },
                    fontSize = {
                        type = "range",
                        name = "字体大小",
                        order = 4,
                        min = 10,
                        max = 24,
                        step = 1,
                        get = function() return MI().fontSize end,
                        set = function(_, val)
                            MI().fontSize = val
                            Core:UpdateMiscBarLayout()
                        end,
                    },
                    font = {
                        type = "select",
                        name = "字体",
                        order = 5,
                        dialogControl = "LSM30_Font",
                        values = LibSharedMedia:HashTable("font"),
                        get = function() return MI().font end,
                        set = function(_, val)
                            MI().font = val
                            Core:UpdateMiscBarLayout()
                        end,
                    },
                    textColor = {
                        type = "color",
                        name = "文字颜色",
                        order = 6,
                        hasAlpha = false,
                        get = function()
                            local c = MI().textColor or { r = 1, g = 1, b = 1 }
                            return c.r, c.g, c.b
                        end,
                        set = function(_, r, g, b)
                            MI().textColor = { r = r, g = g, b = b }
                            Core:UpdateMiscBarLayout()
                        end,
                    },
                    barSpacing = {
                        type = "range",
                        name = "项目间隔",
                        order = 7,
                        min = 1,
                        max = 300,
                        step = 1,
                        get = function()
                            local value = MI().barSpacing or 18
                            return math.max(1, math.min(300, value))
                        end,
                        set = function(_, val)
                            MI().barSpacing = math.max(1, math.min(300, val))
                            Core:UpdateMiscBarLayout()
                        end,
                    },
                    barTips = {
                        type = "description",
                        name =
                        "信息条用于显示专精/天赋与耐久度；解锁后可直接拖动整条移动位置。",
                        order = 8,
                        width = "full",
                    },
                },
            },
            delveQuickLeave = {
                type = "group",
                name = "地下堡快速离开",
                order = 25,
                args = {
                    delveQuickLeaveEnabled = {
                        type = "toggle",
                        name = "开启快速离开",
                        desc = "进入地下堡后显示快速离开图标，点击图标即可离开当前地下堡。",
                        order = 1,
                        get = function() return MI().delveQuickLeaveEnabled end,
                        set = function(_, val)
                            MI().delveQuickLeaveEnabled = val
                            Core:ApplyMiscSettings()
                        end,
                    },
                    delveQuickLeaveLocked = {
                        type = "toggle",
                        name = function() return MI().delveQuickLeaveLocked and "解锁框架" or "锁定框架" end,
                        order = 2,
                        disabled = function() return not MI().delveQuickLeaveEnabled end,
                        get = function() return MI().delveQuickLeaveLocked end,
                        set = function(_, val)
                            MI().delveQuickLeaveLocked = val
                            Core:ApplyMiscSettings()
                        end,
                    },
                    delveQuickLeaveIconSize = {
                        type = "range",
                        name = "图标大小",
                        order = 3,
                        min = 24,
                        max = 72,
                        step = 1,
                        disabled = function() return not MI().delveQuickLeaveEnabled end,
                        get = function() return MI().delveQuickLeaveIconSize or 40 end,
                        set = function(_, val)
                            MI().delveQuickLeaveIconSize = val
                            Core:ApplyMiscSettings()
                        end,
                    },
                    delveQuickLeaveIconPreset = {
                        type = "select",
                        name = "预设图标",
                        order = 4,
                        disabled = function() return not MI().delveQuickLeaveEnabled end,
                        values = DELVE_QUICK_LEAVE_ICON_OPTIONS,
                        get = function()
                            return MI().delveQuickLeaveIconPreset or "Interface\\Icons\\spell_arcane_teleportdalaran"
                        end,
                        set = function(_, val)
                            MI().delveQuickLeaveIconPreset = val
                            Core:ApplyMiscSettings()
                        end,
                    },
                    delveQuickLeaveCustomIcon = {
                        type = "input",
                        name = "自定义图标",
                        order = 5,
                        width = 1.6,
                        disabled = function() return not MI().delveQuickLeaveEnabled end,
                        desc = "可填写图标路径或文件ID；留空时使用上方预设图标。",
                        get = function() return MI().delveQuickLeaveCustomIcon or "" end,
                        set = function(_, val)
                            MI().delveQuickLeaveCustomIcon = val or ""
                            Core:ApplyMiscSettings()
                        end,
                    },
                    delveQuickLeaveTips = {
                        type = "description",
                        name = "按钮仅在地下堡内显示；可从预设里选图标，也可输入自定义图标路径/文件ID；解锁后可拖动调整位置。",
                        order = 6,
                        width = "full",
                    },
                },
            },
            tooltip = {
                type = "group",
                name = "鼠标提示",
                order = 28,
                args = {
                    disableAllTooltips = {
                        type = "toggle",
                        name = "禁止鼠标提示",
                        desc = "勾选后尽量隐藏所有常见提示框。",
                        order = 1,
                        get = function() return MI().disableAllTooltips end,
                        set = function(_, val)
                            MI().disableAllTooltips = val
                            Core:ApplyMiscSettings()
                        end,
                    },
                    tooltipFollowCursor = {
                        type = "toggle",
                        name = "鼠标提示跟随鼠标",
                        order = 2,
                        disabled = function() return MI().disableAllTooltips end,
                        get = function() return MI().tooltipFollowCursor end,
                        set = function(_, val)
                            MI().tooltipFollowCursor = val
                            Core:ApplyMiscSettings()
                        end,
                    },
                    tooltipDesc = {
                        type = "description",
                        name = "“禁止鼠标提示”开启后会优先隐藏提示框；关闭后可选择让提示框跟随鼠标显示。",
                        order = 3,
                        width = "full",
                    },
                },
            },
        },
    }
end
