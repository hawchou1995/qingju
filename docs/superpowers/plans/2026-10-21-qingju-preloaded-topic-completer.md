# 预加载话题列表异步完成竞态修复计划

> **For agentic workers:** 本计划已获批准，当前会话直接执行。步骤用 checkbox 跟踪。

**Goal:** 防止并发 HTML 补水或旧 Isolate 回调重复完成/污染 `PreloadedDataService` 的话题列表结果。

**Architecture:** 每个解析任务捕获创建时的 `Completer<TopicListResponse?>`；完成、失败或写入缓存前，确认它仍是服务当前持有且尚未完成的 completer。失效或重复回调直接丢弃，避免旧任务写入新一轮缓存。以公开 `hydrateFromHtml` 路径并发提交损坏 topicList 的测试复现双失败。

**Tech Stack:** Flutter / Dart、`compute`、`flutter_test`。

## Global Constraints

- 不新增依赖，不改 Android / WebView bootstrap 行为。
- 保留现有缓存消费与页面网络回退语义。
- 保留未跟踪 `.workflow/`，不提交凭据、私人日志或截图。
- 修改后运行指定测试、定点 analyzer、format 与 `git diff --check`；真机行为不在本地测试结论内。

---

### Task 1: 复现并修复重复完成

**Files:**
- Modify: `lib/services/preloaded_data_service.dart`
- Create: `test/services/preloaded_data_service_test.dart`

**接口约束:**
- `_decodeTopicListAsync` 捕获其启动时的 completer，并将同一个实例传入后续解析。
- `_parseTopicListResponseAsync` 仅在捕获的 completer 仍是当前实例且未完成时缓存并完成；错误回调同样执行此校验。
- `_clearCachedData` 后的旧异步任务不能操作新一轮缓存或 completer。

- [x] 写测试：并发调用两次 `hydrateFromHtml`，夹带 `topic_list.topics: [null]` 使两次 isolate 转换都失败；等待 `getInitialTopicList()` 得到 `null`，且测试不接收 `Future already completed` 未处理异步错误。
- [x] 运行 `flutter test --no-pub --no-test-assets test/services/preloaded_data_service_test.dart`；修复前捕获到 `StateError: Bad state: Future already completed`。
- [x] 用局部 completer 捕获与 identity / `isCompleted` 守卫修复成功、失败和旧回调路径。
- [x] 验证：目标测试连续三次通过；`dart analyze lib/services/preloaded_data_service.dart test/services/preloaded_data_service_test.dart` 无问题；`dart format --output=none --set-exit-if-changed lib/services/preloaded_data_service.dart test/services/preloaded_data_service_test.dart` 与 `git diff --check` 通过。
