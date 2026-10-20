import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/connect_stats.dart';

/// 青橘不提供 Linux.do Connect 统计；保留类型供统计卡优雅显示空值。
final connectStatsProvider = FutureProvider<ConnectStats?>((ref) async => null);
