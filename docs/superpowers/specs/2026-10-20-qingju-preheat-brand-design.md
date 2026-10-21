# 青橘预热加载页品牌修复设计

## 背景

Android APK 的 Flutter 预热页 `lib/widgets/preheat_gate.dart` 仍硬编码显示 `FluxDO`；其 `PreheatLogo` 根据旧的 classic/modern 图标路径绘制 Linux.do/FluxDO 标记。当前应用的青橘品牌图形已存在于 `assets/logo.svg`，站点统一名称为 `SiteIdentity.name`（“青橘”）。因此首次启动或预热阶段仍暴露上游品牌。

Android 12+ 的系统 splash 与 Flutter 预热页是两个不同阶段：前者使用 Android launcher icon/label，后者是 Flutter 首帧后由 `PreheatGate` 展示。本设计只处理已从代码定位到的 Flutter 预热页，不扩大到应用桌面图标、原生平台启动屏或其它品牌文案。

## 目标与验收标准

- 预热加载页显示青橘现有标志和统一名称“青橘”。
- 启动画面不再调用旧 Linux.do/FluxDO 图标绘制路径，也不再显示硬编码 `FluxDO`。
- 保留预热行为、跳过按钮、版本号、失败重试、应用图标设置和加载状态切换。
- 不新增依赖，不改应用导航、登录或网络行为。
- 回归测试覆盖名称来源与启动标志组件；Flutter 静态分析通过。

## 方案

推荐将 `PreheatLogo` 从旧几何 CustomPainter 换为 `assets/logo.svg` 的现有青橘标志，并保留轻量的透明度/缩放入场动效；将预热标题改为 `SiteIdentity.name`，避免再次硬编码不同站点名。预热页不再按旧 classic/modern 图标偏好改变品牌标志，应用桌面图标偏好本身保持不变。

另一方案是重写 CustomPainter 几何形状来复刻当前 SVG。它能完全控制逐段描边动效，但会重复维护现有 SVG 的绘图数据，易发生图形漂移；本次不采用。

## 组件与数据流

`PreheatGate` 的加载分支继续创建 `_PreheatLoading`；该组件显示 `PreheatLogo` 与标题。`PreheatLogo` 使用项目现有 SVG asset，由 `flutter_svg` 渲染，并以 Flutter 动画包装以保持启动过渡。标题直接读取 `SiteIdentity.name`，品牌单一事实源继续位于 `lib/config/site_identity.dart`。

## 验证策略

1. 为预热标志/标题补充或调整单元测试，确保组件使用青橘 asset 和 `SiteIdentity.name`，不再引用旧品牌字样。
2. 执行聚焦测试与 `dart analyze`。
3. 静态检查启动页相关文件中旧 `FluxDO` 标题和 Linux.do/FluxDO 图标 painter 已退出预热路径。
4. 如 Android 工具链可用，构建 debug APK 并在 Android 设备/模拟器确认预热页；否则明确记录设备验收未执行。

## 范围边界

包含 `lib/widgets/preheat_gate.dart`、`lib/widgets/preheat_logo.dart` 及相应测试。除非后续证据表明用户指的是 Flutter 首帧前的 Android 系统 splash，否则不改 Android/iOS 原生 splash、启动器图标资源、其它平台或关于页中的 GPL/上游归属说明。
