import 'package:flutter_test/flutter_test.dart';
import 'package:fluxdo/models/profile_stats_config.dart';

/// 旧版本曾支持、当前 [ProfileStatType] 已移除的统计项名称
const _removedStatNames = [
  'topicsRepliedTo',
  'likesReceivedDays',
  'likesReceivedUsers',
];

void main() {
  test('未配置时使用默认项与默认布局', () {
    final config = ProfileStatsConfig.fromJson(const {});

    expect(config.enabledStats, ProfileStatsConfig.defaultEnabledStats);
    expect(config.layoutMode, StatsLayoutMode.grid);
    expect(config.columnsPerRow, 4);
  });

  test('明确保存的空列表保持为空', () {
    final config = ProfileStatsConfig.fromJson(const {
      'enabledStats': <String>[],
      'layoutMode': 'scroll',
      'columnsPerRow': 2,
    });

    expect(config.enabledStats, isEmpty);
    expect(config.layoutMode, StatsLayoutMode.scroll);
    expect(config.columnsPerRow, 2);
  });

  test('已移除的旧项被过滤，保留其余项与原顺序', () {
    final config = ProfileStatsConfig.fromJson(const {
      'enabledStats': [
        'likesReceivedDays',
        'postCount',
        'likesReceivedUsers',
        'likesGiven',
        'topicsRepliedTo',
        'daysVisited',
      ],
      'layoutMode': 'scroll',
      'columnsPerRow': 3,
    });

    expect(config.enabledStats, const [
      ProfileStatType.postCount,
      ProfileStatType.likesGiven,
      ProfileStatType.daysVisited,
    ]);
    expect(config.layoutMode, StatsLayoutMode.scroll);
    expect(config.columnsPerRow, 3);
  });

  test('旧配置只剩已移除项时回落到默认项，不重复退化成 daysVisited', () {
    final config = ProfileStatsConfig.fromJson(const {
      'enabledStats': _removedStatNames,
      'layoutMode': 'scroll',
      'columnsPerRow': 3,
    });

    expect(config.enabledStats, ProfileStatsConfig.defaultEnabledStats);
    expect(
      config.enabledStats.toSet().length,
      config.enabledStats.length,
      reason: '过滤后不应出现重复的统计项',
    );
    expect(config.layoutMode, StatsLayoutMode.scroll);
    expect(config.columnsPerRow, 3);
  });

  test('未知统计项全部被忽略时不产生重复卡片', () {
    final config = ProfileStatsConfig.fromJson(const {
      'enabledStats': ['__unknown__', '__legacy__'],
    });

    expect(config.enabledStats, ProfileStatsConfig.defaultEnabledStats);
  });

  test('序列化往返保留启用项与布局', () {
    const original = ProfileStatsConfig(
      enabledStats: [ProfileStatType.likesGiven, ProfileStatType.timeRead],
      layoutMode: StatsLayoutMode.scroll,
      columnsPerRow: 2,
    );

    final restored = ProfileStatsConfig.fromJsonString(original.toJsonString());

    expect(restored.enabledStats, original.enabledStats);
    expect(restored.layoutMode, original.layoutMode);
    expect(restored.columnsPerRow, original.columnsPerRow);
  });
}
