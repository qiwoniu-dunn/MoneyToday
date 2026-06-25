# MoneyToday 1.2.1 发布记录

## 版本目标

1.2.1 是 1.2 系列的前端体验修正版。它不新增奖励候选池，也不改变收入计算逻辑，重点解决 1.2 试用中暴露出的视觉还原、弹层高度、资源加载和窗口边界问题。

## 主要变化

- 主界面重做为更接近确认设计稿的深色金色仪表盘样式。
- 设置页同步调整为深色金色列表结构，A/B 面切换使用 spring 过渡。
- 日/周/月/年切换时，弹层高度随内容自适应：日视图展开显示奖励舞台，周/月/年自动收成 compact 高度，避免上下空白。
- `NSPanel` 高度变化保持顶部挂点不动，底部向上/向下平滑收放。
- 资源读取兼容 `Bundle.main` 与 SwiftPM `Bundle.module`，确保源码 debug 运行和打包 App 都能加载芝麻动画与奖励图。
- 关闭系统 `NSPanel` 矩形阴影，保留 SwiftUI 异形面板阴影，修复 notch 和圆角外侧淡灰色矩形边界。
- 增加 `MONEYTODAY_SNAPSHOT_PERIOD` 验收变量，可固定日/周/月/年页面截图检查。

## 发布产物

- `MoneyToday-v1.2.1.zip`
- `MoneyToday-v1.2.1.pkg`

## 验证

- `swift build --disable-sandbox`
- `swift run --disable-sandbox MoneyTodayChecks`
- `./scripts/package_app.sh`

## 已知限制

- 仍未做正式开发者签名和公证。
- 菜单栏弹层截图自动化在多屏和当前前台 App 状态下仍不稳定，后续可补专用视觉验收工具。
