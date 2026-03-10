import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/api_service.dart';
import '../../../core/models/product_model.dart';
import '../../../core/models/user_model.dart';

class AdminStats {
  final int totalUsers;
  final int totalProducts;
  final int pendingProducts;
  final int totalInterests;

  AdminStats({
    this.totalUsers = 0,
    this.totalProducts = 0,
    this.pendingProducts = 0,
    this.totalInterests = 0,
  });

  factory AdminStats.fromJson(Map<String, dynamic> j) => AdminStats(
        totalUsers: j['total_users'] ?? 0,
        totalProducts: j['total_products'] ?? 0,
        pendingProducts: j['pending_products'] ?? 0,
        totalInterests: j['total_interests'] ?? 0,
      );
}

class AdminState {
  final AdminStats stats;
  final List<ProductModel> pendingProducts;
  final List<UserModel> users;
  final bool isLoading;
  final String? error;
  final String activeTab;

  AdminState({
    AdminStats? stats,
    this.pendingProducts = const [],
    this.users = const [],
    this.isLoading = false,
    this.error,
    this.activeTab = 'dashboard',
  }) : stats = stats ?? AdminStats();

  AdminState copyWith({
    AdminStats? stats,
    List<ProductModel>? pendingProducts,
    List<UserModel>? users,
    bool? isLoading,
    String? error,
    String? activeTab,
  }) =>
      AdminState(
        stats: stats ?? this.stats,
        pendingProducts: pendingProducts ?? this.pendingProducts,
        users: users ?? this.users,
        isLoading: isLoading ?? this.isLoading,
        error: error,
        activeTab: activeTab ?? this.activeTab,
      );
}

class AdminNotifier extends StateNotifier<AdminState> {
  AdminNotifier() : super(AdminState());

  Future<void> loadAll() async {
    state = state.copyWith(isLoading: true);
    await Future.wait([
      _loadStats(),
      _loadPending(),
      _loadUsers(),
    ]);
    state = state.copyWith(isLoading: false);
  }

  Future<void> _loadStats() async {
    try {
      final res = await ApiService.get('/admin/analytics', auth: true);
      if (res.data['success'] == true) {
        state = state.copyWith(
            stats: AdminStats.fromJson(res.data['data']));
      }
    } catch (_) {
      // Use dummy stats
      state = state.copyWith(
        stats: AdminStats(
          totalUsers: 12,
          totalProducts: 6,
          pendingProducts: 3,
          totalInterests: 28,
        ),
      );
    }
  }

  Future<void> _loadPending() async {
    try {
      final res = await ApiService.get('/admin/pending', auth: true);
      if (res.data['success'] == true) {
        final list = (res.data['data'] as List)
            .map((j) => ProductModel.fromJson({
                  ...j,
                  'innovator_name': j['innovator_name'] ?? '',
                  'innovator_username': j['username'] ?? '',
                  'innovator_id': j['user_id'] ?? 0,
                  'images': [],
                }))
            .toList();
        state = state.copyWith(pendingProducts: list);
      }
    } catch (_) {}
  }

  Future<void> _loadUsers() async {
    try {
      final res = await ApiService.get('/admin/users', auth: true);
      if (res.data['success'] == true) {
        final list = (res.data['data'] as List)
            .map((j) => UserModel.fromJson(j))
            .toList();
        state = state.copyWith(users: list);
      }
    } catch (_) {}
  }

  Future<void> approveProduct(int id) async {
    try {
      await ApiService.put('/admin/products/$id/approve', {});
      state = state.copyWith(
        pendingProducts: state.pendingProducts
            .where((p) => p.id != id)
            .toList(),
        stats: AdminStats(
          totalUsers: state.stats.totalUsers,
          totalProducts: state.stats.totalProducts + 1,
          pendingProducts: state.stats.pendingProducts - 1,
          totalInterests: state.stats.totalInterests,
        ),
      );
    } catch (_) {}
  }

  Future<void> rejectProduct(int id) async {
    try {
      await ApiService.put('/admin/products/$id/reject', {});
      state = state.copyWith(
        pendingProducts: state.pendingProducts
            .where((p) => p.id != id)
            .toList(),
        stats: AdminStats(
          totalUsers: state.stats.totalUsers,
          totalProducts: state.stats.totalProducts,
          pendingProducts: state.stats.pendingProducts - 1,
          totalInterests: state.stats.totalInterests,
        ),
      );
    } catch (_) {}
  }

  Future<void> approveUser(int id) async {
    try {
      await ApiService.put('/admin/users/$id/approve', {});
      final updated = state.users.map((u) {
        if (u.id == id) {
          return UserModel(
            id: u.id,
            firstName: u.firstName,
            lastName: u.lastName,
            username: u.username,
            email: u.email,
            role: u.role,
            kycStatus: u.kycStatus,
            userStatus: 1,
          );
        }
        return u;
      }).toList();
      state = state.copyWith(users: updated);
    } catch (_) {}
  }

  void setTab(String tab) => state = state.copyWith(activeTab: tab);
}

final adminProvider =
    StateNotifierProvider<AdminNotifier, AdminState>(
  (ref) => AdminNotifier(),
);