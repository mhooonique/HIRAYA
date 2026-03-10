import 'package:flutter_riverpod/flutter_riverpod.dart';

// Mock data models — will be replaced by real API calls
class UserGrowthData {
  final String month;
  final int innovators;
  final int clients;
  final int deactivations;
  UserGrowthData({
    required this.month,
    required this.innovators,
    required this.clients,
    required this.deactivations,
  });
  int get total => innovators + clients;
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
}

class TopProduct {
  final String name;
  final String category;
  final String innovator;
  final int likes;
  final int views;
  final int interests;
  final int messages;
  final bool rising;
  TopProduct({
    required this.name,
    required this.category,
    required this.innovator,
    required this.likes,
    required this.views,
    required this.interests,
    required this.messages,
    this.rising = false,
  });
}

class AnalyticsState {
  final List<UserGrowthData> userGrowth;
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

  AnalyticsState({
    this.userGrowth = const [],
    this.leaderboard = const [],
    this.topProducts = const [],
    this.dau = 0,
    this.mau = 0,
    this.inactiveUsers30 = 0,
    this.inactiveUsers60 = 0,
    this.inactiveUsers90 = 0,
    this.selectedLeaderboardMetric = 'most_products',
    this.filterCategory = 'All',
    this.filterStatus = 'All',
    this.isLoading = false,
  });

  AnalyticsState copyWith({
    List<UserGrowthData>? userGrowth,
    List<LeaderboardEntry>? leaderboard,
    List<TopProduct>? topProducts,
    int? dau,
    int? mau,
    int? inactiveUsers30,
    int? inactiveUsers60,
    int? inactiveUsers90,
    String? selectedLeaderboardMetric,
    String? filterCategory,
    String? filterStatus,
    bool? isLoading,
  }) =>
      AnalyticsState(
        userGrowth: userGrowth ?? this.userGrowth,
        leaderboard: leaderboard ?? this.leaderboard,
        topProducts: topProducts ?? this.topProducts,
        dau: dau ?? this.dau,
        mau: mau ?? this.mau,
        inactiveUsers30: inactiveUsers30 ?? this.inactiveUsers30,
        inactiveUsers60: inactiveUsers60 ?? this.inactiveUsers60,
        inactiveUsers90: inactiveUsers90 ?? this.inactiveUsers90,
        selectedLeaderboardMetric:
            selectedLeaderboardMetric ?? this.selectedLeaderboardMetric,
        filterCategory: filterCategory ?? this.filterCategory,
        filterStatus: filterStatus ?? this.filterStatus,
        isLoading: isLoading ?? this.isLoading,
      );
}

class AnalyticsNotifier extends StateNotifier<AnalyticsState> {
  AnalyticsNotifier() : super(AnalyticsState()) {
    loadAnalytics();
  }

  void loadAnalytics() {
    state = state.copyWith(
      userGrowth: _dummyGrowth(),
      leaderboard: _dummyLeaderboard('most_products'),
      topProducts: _dummyTopProducts(),
      dau: 34,
      mau: 187,
      inactiveUsers30: 12,
      inactiveUsers60: 7,
      inactiveUsers90: 3,
      isLoading: false,
    );
  }

  void setLeaderboardMetric(String metric) {
    state = state.copyWith(
      selectedLeaderboardMetric: metric,
      leaderboard: _dummyLeaderboard(metric),
    );
  }

  void setFilterCategory(String cat) =>
      state = state.copyWith(filterCategory: cat);
  void setFilterStatus(String s) =>
      state = state.copyWith(filterStatus: s);

  List<UserGrowthData> _dummyGrowth() => [
        UserGrowthData(month: 'Aug', innovators: 3, clients: 2, deactivations: 0),
        UserGrowthData(month: 'Sep', innovators: 5, clients: 4, deactivations: 1),
        UserGrowthData(month: 'Oct', innovators: 8, clients: 6, deactivations: 0),
        UserGrowthData(month: 'Nov', innovators: 12, clients: 9, deactivations: 2),
        UserGrowthData(month: 'Dec', innovators: 7, clients: 11, deactivations: 1),
        UserGrowthData(month: 'Jan', innovators: 15, clients: 14, deactivations: 3),
        UserGrowthData(month: 'Feb', innovators: 18, clients: 16, deactivations: 1),
        UserGrowthData(month: 'Mar', innovators: 22, clients: 20, deactivations: 2),
      ];

  List<LeaderboardEntry> _dummyLeaderboard(String metric) {
    switch (metric) {
      case 'most_products':
        return [
          LeaderboardEntry(rank: 1, name: 'Maria Santos', username: 'maria_santos', role: 'innovator', value: 6, metric: 'products uploaded'),
          LeaderboardEntry(rank: 2, name: 'Rico Bautista', username: 'rico_dev', role: 'innovator', value: 4, metric: 'products uploaded'),
          LeaderboardEntry(rank: 3, name: 'Dr. Ana Reyes', username: 'dr_ana', role: 'innovator', value: 3, metric: 'products uploaded'),
          LeaderboardEntry(rank: 4, name: 'Carlo Mendoza', username: 'carlo_m', role: 'innovator', value: 2, metric: 'products uploaded'),
          LeaderboardEntry(rank: 5, name: 'Liza Tan', username: 'liza_tan', role: 'innovator', value: 1, metric: 'products uploaded'),
        ];
      case 'most_approved':
        return [
          LeaderboardEntry(rank: 1, name: 'Dr. Ana Reyes', username: 'dr_ana', role: 'innovator', value: 5, metric: 'approved'),
          LeaderboardEntry(rank: 2, name: 'Maria Santos', username: 'maria_santos', role: 'innovator', value: 4, metric: 'approved'),
          LeaderboardEntry(rank: 3, name: 'Rico Bautista', username: 'rico_dev', role: 'innovator', value: 3, metric: 'approved'),
        ];
      case 'most_interest':
        return [
          LeaderboardEntry(rank: 1, name: 'Juan dela Cruz', username: 'juan_dc', role: 'client', value: 18, metric: 'interests sent'),
          LeaderboardEntry(rank: 2, name: 'Pedro Reyes', username: 'pedro_r', role: 'client', value: 12, metric: 'interests sent'),
          LeaderboardEntry(rank: 3, name: 'Ana Garcia', username: 'ana_g', role: 'client', value: 9, metric: 'interests sent'),
        ];
      case 'most_liked':
        return [
          LeaderboardEntry(rank: 1, name: 'Pedro Reyes', username: 'pedro_r', role: 'client', value: 45, metric: 'likes given'),
          LeaderboardEntry(rank: 2, name: 'Juan dela Cruz', username: 'juan_dc', role: 'client', value: 38, metric: 'likes given'),
          LeaderboardEntry(rank: 3, name: 'Rosa Cruz', username: 'rosa_c', role: 'client', value: 27, metric: 'likes given'),
        ];
      case 'most_liked_innovator':
        return [
          LeaderboardEntry(rank: 1, name: 'Dr. Ana Reyes', username: 'dr_ana', role: 'innovator', value: 211, metric: 'total likes received'),
          LeaderboardEntry(rank: 2, name: 'Rico Bautista', username: 'rico_dev', role: 'innovator', value: 189, metric: 'total likes received'),
          LeaderboardEntry(rank: 3, name: 'Maria Santos', username: 'maria_santos', role: 'innovator', value: 142, metric: 'total likes received'),
        ];
      default:
        return [];
    }
  }

  List<TopProduct> _dummyTopProducts() => [
        TopProduct(name: 'AI Diagnostic Tablet', category: 'Healthcare', innovator: 'Dr. Ana Reyes', likes: 211, views: 1203, interests: 45, messages: 23, rising: true),
        TopProduct(name: 'BarangayConnect App', category: 'Information Technology', innovator: 'Rico Bautista', likes: 189, views: 987, interests: 34, messages: 18),
        TopProduct(name: 'Smart Rice Monitoring', category: 'Agriculture', innovator: 'Maria Santos', likes: 142, views: 890, interests: 23, messages: 11, rising: true),
        TopProduct(name: 'Solar Water Purifier', category: 'Energy', innovator: 'Juan dela Cruz', likes: 98, views: 654, interests: 17, messages: 8),
        TopProduct(name: 'Modular Ergonomic Desk', category: 'Product Design', innovator: 'Liza Tan', likes: 54, views: 321, interests: 8, messages: 4),
        TopProduct(name: 'Bamboo Composite Panel', category: 'Construction', innovator: 'Carlo Mendoza', likes: 76, views: 432, interests: 12, messages: 6),
      ];
}

final analyticsProvider =
    StateNotifierProvider<AnalyticsNotifier, AnalyticsState>(
  (ref) => AnalyticsNotifier(),
);