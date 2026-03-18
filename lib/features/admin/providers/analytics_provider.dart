// lib/features/admin/providers/analytics_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/api_service.dart';

// ── Models ────────────────────────────────────────────────────────────────────

class UserGrowthData {
  final String month;
  final int innovators;
  final int clients;
  final int deactivations;

  UserGrowthData({
    required this.month,
    required this.innovators,
    required this.clients,
    this.deactivations = 0,
  });

  int get total => innovators + clients;

  factory UserGrowthData.fromJson(Map<String, dynamic> j) => UserGrowthData(
    month:      j['month']      as String? ?? '',
    innovators: (j['innovators'] as num?)?.toInt() ?? 0,
    clients:    (j['clients']    as num?)?.toInt() ?? 0,
  );
}

class LeaderboardEntry {
  final int rank;
  final String name;
  final String username;
  final String role;
  final int value;
  final String metric;

  LeaderboardEntry({
    required this.rank,
    required this.name,
    required this.username,
    required this.role,
    required this.value,
    required this.metric,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> j, String metricLabel) =>
      LeaderboardEntry(
        rank:     (j['rank']  as num?)?.toInt() ?? 0,
        name:     j['name']     as String? ?? '',
        username: j['username'] as String? ?? '',
        role:     j['role']     as String? ?? '',
        value:    (j['value']  as num?)?.toInt() ?? 0,
        metric:   metricLabel,
      );
}

class TopProduct {
  final String name;
  final String category;
  final String innovator;
  final int likes;
  final int views;
  final int interests;
  final bool rising;

  TopProduct({
    required this.name,
    required this.category,
    required this.innovator,
    required this.likes,
    required this.views,
    required this.interests,
    this.rising = false,
  });

  factory TopProduct.fromJson(Map<String, dynamic> j) => TopProduct(
    name:      j['name']      as String? ?? '',
    category:  j['category']  as String? ?? '',
    innovator: j['innovator'] as String? ?? '',
    likes:     (j['likes']     as num?)?.toInt() ?? 0,
    views:     (j['views']     as num?)?.toInt() ?? 0,
    interests: (j['interests'] as num?)?.toInt() ?? 0,
    rising:    (j['rising']   as bool?) ?? false,
  );
}

// ── State ─────────────────────────────────────────────────────────────────────

class AnalyticsState {
  final List<UserGrowthData> userGrowth;
  final Map<String, List<LeaderboardEntry>> allLeaderboards;
  final List<LeaderboardEntry> leaderboard;
  final List<TopProduct> topProducts;
  final int dau;
  final int mau;
  final int inactiveUsers30;
  final int inactiveUsers60;
  final int inactiveUsers90;
  final String selectedLeaderboardMetric;
  final String filterCategory;
  final String filterStatus;
  final bool isLoading;
  final String? error;
  final List<Map<String, dynamic>> categoryDistribution;
  final List<Map<String, dynamic>> productStatus;

  AnalyticsState({
    this.userGrowth                 = const [],
    this.allLeaderboards            = const {},
    this.leaderboard                = const [],
    this.topProducts                = const [],
    this.dau                        = 0,
    this.mau                        = 0,
    this.inactiveUsers30            = 0,
    this.inactiveUsers60            = 0,
    this.inactiveUsers90            = 0,
    this.selectedLeaderboardMetric  = 'most_products',
    this.filterCategory             = 'All',
    this.filterStatus               = 'All',
    this.isLoading                  = false,
    this.error,
    this.categoryDistribution       = const [],
    this.productStatus              = const [],
  });

  AnalyticsState copyWith({
    List<UserGrowthData>?                userGrowth,
    Map<String, List<LeaderboardEntry>>? allLeaderboards,
    List<LeaderboardEntry>?              leaderboard,
    List<TopProduct>?                    topProducts,
    int?                                 dau,
    int?                                 mau,
    int?                                 inactiveUsers30,
    int?                                 inactiveUsers60,
    int?                                 inactiveUsers90,
    String?                              selectedLeaderboardMetric,
    String?                              filterCategory,
    String?                              filterStatus,
    bool?                                isLoading,
    String?                              error,
    List<Map<String, dynamic>>?          categoryDistribution,
    List<Map<String, dynamic>>?          productStatus,
  }) =>
      AnalyticsState(
        userGrowth:                userGrowth                ?? this.userGrowth,
        allLeaderboards:           allLeaderboards           ?? this.allLeaderboards,
        leaderboard:               leaderboard               ?? this.leaderboard,
        topProducts:               topProducts               ?? this.topProducts,
        dau:                       dau                       ?? this.dau,
        mau:                       mau                       ?? this.mau,
        inactiveUsers30:           inactiveUsers30           ?? this.inactiveUsers30,
        inactiveUsers60:           inactiveUsers60           ?? this.inactiveUsers60,
        inactiveUsers90:           inactiveUsers90           ?? this.inactiveUsers90,
        selectedLeaderboardMetric: selectedLeaderboardMetric ?? this.selectedLeaderboardMetric,
        filterCategory:            filterCategory            ?? this.filterCategory,
        filterStatus:              filterStatus              ?? this.filterStatus,
        isLoading:                 isLoading                 ?? this.isLoading,
        error:                     error,
        categoryDistribution:      categoryDistribution      ?? this.categoryDistribution,
        productStatus:             productStatus             ?? this.productStatus,
      );
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class AnalyticsNotifier extends StateNotifier<AnalyticsState> {
  final ApiService _api;

  AnalyticsNotifier(this._api) : super(AnalyticsState()) {
    loadAnalytics();
  }

  Future<void> loadAnalytics() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _api.get('admin/analytics/full', auth: true);
      if (res['success'] != true) {
        state = state.copyWith(isLoading: false, error: 'Failed to load analytics');
        return;
      }
      final data = res['data'] as Map<String, dynamic>;

      // User growth
      final growth = ((data['user_growth'] as List?) ?? [])
          .map((j) => UserGrowthData.fromJson(j as Map<String, dynamic>))
          .toList();

      // All leaderboards cached
      final lbRaw = (data['leaderboard'] as Map<String, dynamic>?) ?? {};
      final allLb = <String, List<LeaderboardEntry>>{
        'most_products': _parseLb(lbRaw['most_products'], 'products uploaded'),
        'most_approved': _parseLb(lbRaw['most_approved'], 'approved'),
        'most_interest': _parseLb(lbRaw['most_interest'], 'interests received'),
        'most_liked':    _parseLb(lbRaw['most_liked'],    'likes received'),
      };

      // Top products
      final products = ((data['top_products'] as List?) ?? [])
          .map((j) => TopProduct.fromJson(j as Map<String, dynamic>))
          .toList();

      // Category & status distributions
      final cats = _toMapList(data['category_distribution']);
      final status = _toMapList(data['product_status']);

      state = state.copyWith(
        isLoading:            false,
        userGrowth:           growth,
        allLeaderboards:      allLb,
        leaderboard:          allLb[state.selectedLeaderboardMetric] ?? [],
        topProducts:          products,
        dau:                  (data['dau']          as num?)?.toInt() ?? 0,
        mau:                  (data['mau']          as num?)?.toInt() ?? 0,
        inactiveUsers30:      (data['inactive_30d'] as num?)?.toInt() ?? 0,
        inactiveUsers60:      (data['inactive_60d'] as num?)?.toInt() ?? 0,
        inactiveUsers90:      (data['inactive_90d'] as num?)?.toInt() ?? 0,
        categoryDistribution: cats,
        productStatus:        status,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Connection error: $e');
    }
  }

  void setLeaderboardMetric(String metric) => state = state.copyWith(
    selectedLeaderboardMetric: metric,
    leaderboard: state.allLeaderboards[metric] ?? [],
  );

  void setFilterCategory(String cat) => state = state.copyWith(filterCategory: cat);
  void setFilterStatus(String s)     => state = state.copyWith(filterStatus: s);

  // ── Helpers ──────────────────────────────────────────────────────────────

  List<LeaderboardEntry> _parseLb(dynamic raw, String label) {
    if (raw == null) return [];
    return (raw as List).asMap().entries.map((e) =>
      LeaderboardEntry.fromJson(e.value as Map<String, dynamic>, label),
    ).toList();
  }

  List<Map<String, dynamic>> _toMapList(dynamic raw) {
    if (raw == null) return [];
    return (raw as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final analyticsProvider = StateNotifierProvider<AnalyticsNotifier, AnalyticsState>(
  (ref) => AnalyticsNotifier(ref.read(apiServiceProvider)),
);
