local addonName, ns = ...

local locale = GetLocale()

local L = {
    ADDON_TITLE = "雨轩地图标点",
    PREFIX = "|cFF33FF99雨轩地图标点|r",

    ENABLE_CUSTOM_MARKERS = "启用自定义点位",
    ENABLE_QUICK_COORD = "启用地图坐标输入",
    MARKER_SIZE = "标点大小",

    QUICK_ADD_TITLE = "快速添加点位",
    LABEL_TITLE = "标题",
    LABEL_NOTE = "备注",
    LABEL_COLOR = "颜色",
    BTN_SAVE = "保存",
    BTN_CANCEL = "取消",
    BTN_ADD_CURRENT = "添加当前位置点位",

    BTN_MANAGE = "管理点位",
    BTN_EXPORT_IMPORT = "导入/导出",

    MANAGER_TITLE = "全部地图点位管理",
    MANAGER_EMPTY = "暂无自定义点位",
    MANAGER_MAP_HEADER = "%s (地图ID: %d)",
    BTN_DELETE = "删除",

    IO_TITLE = "点位导入/导出",
    BTN_EXPORT = "导出",
    BTN_IMPORT = "导入",
    EXPORT_OK = "导出完成",
    IMPORT_OK = "导入成功：%d 条",
    IMPORT_EMPTY = "未导入任何条目",

    HINT_COORD = "坐标: 12.34 56.78",
    INVALID_COORD = "坐标格式错误，示例：12.34 56.78",
    COORD_FETCH_FAILED = "未获取到当前位置坐标，请走两步再试。",
    WAYPOINT_SET = "已设置导航点：%.2f %.2f",

    ADDED_MARKER = "已添加：%s (%.2f, %.2f)",
    DELETED_MARKER = "已删除点位",

    CUSTOM_POINT = "自定义点位",
    UNKNOWN_MAP = "未知地图",
}

if locale ~= "zhCN" then
    L.ADDON_TITLE = "YuXuan Map Pin"
    L.PREFIX = "|cFF33FF99YuXuan Map Pin|r"

    L.ENABLE_CUSTOM_MARKERS = "Enable custom map pins"
    L.ENABLE_QUICK_COORD = "Enable quick coordinate input"
    L.MARKER_SIZE = "Pin size"

    L.QUICK_ADD_TITLE = "Quick Add Pin"
    L.LABEL_TITLE = "Title"
    L.LABEL_NOTE = "Note"
    L.LABEL_COLOR = "Color"
    L.BTN_SAVE = "Save"
    L.BTN_CANCEL = "Cancel"
    L.BTN_ADD_CURRENT = "Add current position"

    L.BTN_MANAGE = "Manage Pins"
    L.BTN_EXPORT_IMPORT = "Import/Export"

    L.MANAGER_TITLE = "All Map Pins"
    L.MANAGER_EMPTY = "No custom pins"
    L.MANAGER_MAP_HEADER = "%s (MapID: %d)"
    L.BTN_DELETE = "Delete"

    L.IO_TITLE = "Pin Import / Export"
    L.BTN_EXPORT = "Export"
    L.BTN_IMPORT = "Import"
    L.EXPORT_OK = "Export completed"
    L.IMPORT_OK = "Imported: %d"
    L.IMPORT_EMPTY = "No valid entries imported"

    L.HINT_COORD = "Coord: 12.34 56.78"
    L.INVALID_COORD = "Invalid coordinate format. Example: 12.34 56.78"
    L.COORD_FETCH_FAILED = "Unable to read current position. Please move a few steps and try again."
    L.WAYPOINT_SET = "Waypoint set: %.2f %.2f"

    L.ADDED_MARKER = "Added: %s (%.2f, %.2f)"
    L.DELETED_MARKER = "Pin deleted"

    L.CUSTOM_POINT = "Custom Pin"
    L.UNKNOWN_MAP = "Unknown Map"
end

ns.L = L
