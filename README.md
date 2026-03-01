# RoyMapGuide

一个偏实用向的魔兽世界地图插件：
把常用 NPC / 功能点集中标在大地图上，同时支持自定义坐标、颜色和备注，方便自己做路线和日常记录。

## 功能

- 全地图 NPC 标记（可按类型开关）
  - 传送、旅店、商业、专业、服务、兽栏、藏品、商人、军需官、PVP、副本、地下堡等
- 标记显示样式可调
  - 文本 / 图标
  - 文本轮廓、图标外发光
  - 全局标记大小
- 专业过滤
  - 仅显示已学习专业相关点位（钓鱼/烹饪/考古除外）
- 城市与区域分组控制
  - 每个分组可独立开关与缩放
- 自定义坐标扩展
  - 当前地图坐标快速保存
  - 自定义标题、备注、颜色
  - 历史坐标分页管理、单条移除
- 自定义坐标导入导出
  - 支持批量分享与迁移

## 安装

1. 下载或克隆仓库。
2. 将 `RoyMapGuide` 文件夹放到：

   `World of Warcraft/_retail_/Interface/AddOns/`

3. 进入游戏，在角色选择界面勾选插件（必要时勾选“加载过期插件”）。

## 使用

- 打开设置：`/rmg`
- 快速添加当前坐标：`/yx`

设置路径：

`ESC -> 选项 -> 插件 -> RoyMapGuide`

## 数据保存位置

本插件使用账号级保存变量：`RoyMapGuideDB`

典型路径（Windows）：

`World of Warcraft/_retail_/WTF/Account/<账号>/SavedVariables/RoyMapGuide.lua`

其中自定义坐标主要存放在：

- `RoyMapGuideDB.customMarkers`
- `RoyMapGuideDB.customMarkerLastColor`

## 兼容版本

- Interface: `120000, 120001`

## 反馈

欢迎提 Issue：

- 描述复现步骤
- 附上 Lua 报错（如有）
- 说明游戏版本、客户端语言和插件版本

这样定位会快很多。