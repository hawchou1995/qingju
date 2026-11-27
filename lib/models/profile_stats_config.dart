import 'dart:convert';

/// 统计项类型
enum ProfileStatType {
  // Summary API 字段
  daysVisited,
  postsReadCount,
  likesReceived,
  likesGiven,
  topicCount,
  postCount,
  timeRead,
  recentTimeRead,
  bookmarkCount,
  topicsEntered,
}

/// 布局模式
enum StatsLayoutMode { grid, scroll }

/// 统计卡片配置
class ProfileStatsConfig {
  final List<ProfileStatType> enabledStats;
  final StatsLayoutMode layoutMode;
  final int columnsPerRow; // 网格模式 2/3/4

  /// 默认启用项：未配置或旧配置只剩已移除项时使用
  static const List<ProfileStatType> defaultEnabledStats = [
    ProfileStatType.daysVisited,
    ProfileStatType.postsReadCount,
    ProfileStatType.likesReceived,
    ProfileStatType.postCount,
  ];

  const ProfileStatsConfig({
    this.enabledStats = defaultEnabledStats,
    this.layoutMode = StatsLayoutMode.grid,
    this.columnsPerRow = 4,
  });

  ProfileStatsConfig copyWith({
    List<ProfileStatType>? enabledStats,
    StatsLayoutMode? layoutMode,
    int? columnsPerRow,
  }) {
    return ProfileStatsConfig(
      enabledStats: enabledStats ?? this.enabledStats,
      layoutMode: layoutMode ?? this.layoutMode,
      columnsPerRow: columnsPerRow ?? this.columnsPerRow,
    );
  }

  Map<String, dynamic> toJson() => {
    'enabledStats': enabledStats.map((e) => e.name).toList(),
    'layoutMode': layoutMode.name,
    'columnsPerRow': columnsPerRow,
  };

  factory ProfileStatsConfig.fromJson(Map<String, dynamic> json) {
    return ProfileStatsConfig(
      enabledStats: _resolveEnabledStats(json['enabledStats'] as List<dynamic>?),
      layoutMode: StatsLayoutMode.values.firstWhere(
        (v) => v.name == json['layoutMode'],
        orElse: () => StatsLayoutMode.grid,
      ),
      columnsPerRow: json['columnsPerRow'] as int? ?? 4,
    );
  }

  /// 解析持久化的统计项列表
  ///
  /// - 没有配置时用 [defaultEnabledStats]；
  /// - 明确保存为空列表时保持为空（用户主动清空）；
  /// - 逐项过滤已移除的旧统计项，保留仍支持的项及其原顺序，避免旧 key 全部
  ///   回退成同一个 `daysVisited` 造成重复卡片；
  /// - 旧列表只剩已移除项时回落到 [defaultEnabledStats]。
  static List<ProfileStatType> _resolveEnabledStats(List<dynamic>? raw) {
    if (raw == null) return defaultEnabledStats;
    final byName = ProfileStatType.values.asNameMap();
    final resolved = <ProfileStatType>[];
    for (final entry in raw) {
      final stat = byName[entry];
      if (stat != null) resolved.add(stat);
    }
    if (resolved.isEmpty && raw.isNotEmpty) return defaultEnabledStats;
    return resolved;
  }

  String toJsonString() => jsonEncode(toJson());

  factory ProfileStatsConfig.fromJsonString(String jsonStr) {
    return ProfileStatsConfig.fromJson(
      jsonDecode(jsonStr) as Map<String, dynamic>,
    );
  }
}
