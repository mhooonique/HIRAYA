// lib/features/admin/providers/admin_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/api_service.dart';
import '../../../core/models/product_model.dart';
import '../../../core/models/user_model.dart';

// ─── Stats model ──────────────────────────────────────────────────────────────
class AdminStats {
  final int totalUsers;
  final int totalProducts;
  final int pendingProducts;
  final int totalInterests;

  AdminStats({
    this.totalUsers      = 0,
    this.totalProducts   = 0,
    this.pendingProducts = 0,
    this.totalInterests  = 0,
  });

  factory AdminStats.fromJson(Map<String, dynamic> j) => AdminStats(
    totalUsers:      (j['total_users']      as num?) ?.toInt() ?? 0,
    totalProducts:   (j['total_products']   as num?) ?.toInt() ?? 0,
    pendingProducts: (j['pending_products'] as num?) ?.toInt() ?? 0,
    totalInterests:  (j['total_interests']  as num?) ?.toInt() ?? 0,
  );

  AdminStats copyWith({int? totalUsers, int? totalProducts, int? pendingProducts, int? totalInterests}) =>
      AdminStats(
        totalUsers:      totalUsers      ?? this.totalUsers,
        totalProducts:   totalProducts   ?? this.totalProducts,
        pendingProducts: pendingProducts ?? this.pendingProducts,
        totalInterests:  totalInterests  ?? this.totalInterests,
      );
}

// ─── State ────────────────────────────────────────────────────────────────────
class AdminState {
  final AdminStats         stats;
  final List<ProductModel> pendingProducts;
  final List<UserModel>    users;
  final bool               isLoading;
  final String?            error;
  final String             activeTab;

  AdminState({
    AdminStats? stats,
    this.pendingProducts = const [],
    this.users           = const [],
    this.isLoading       = false,
    this.error,
    this.activeTab = 'dashboard',
  }) : stats = stats ?? AdminStats();

  AdminState copyWith({
    AdminStats?         stats,
    List<ProductModel>? pendingProducts,
    List<UserModel>?    users,
    bool?               isLoading,
    String?             error,
    String?             activeTab,
  }) => AdminState(
    stats:           stats           ?? this.stats,
    pendingProducts: pendingProducts ?? this.pendingProducts,
    users:           users           ?? this.users,
    isLoading:       isLoading       ?? this.isLoading,
    error:           error,
    activeTab:       activeTab       ?? this.activeTab,
  );
}

// ─── Notifier ─────────────────────────────────────────────────────────────────
class AdminNotifier extends StateNotifier<AdminState> {
  final ApiService _api;
  AdminNotifier(this._api) : super(AdminState());

  // ── Load all ────────────────────────────────────────────────────────────────
  Future<void> loadAll() async {
    state = state.copyWith(isLoading: true);
    await Future.wait([_loadStats(), _loadPending(), _loadUsers()]);
    state = state.copyWith(isLoading: false);
  }

  Future<void> _loadStats() async {
    try {
      final res = await _api.get('admin/analytics', auth: true);
      if (res['success'] == true) {
        state = state.copyWith(stats: AdminStats.fromJson(res['data'] as Map<String, dynamic>));
      }
    } catch (_) {}
  }

  Future<void> _loadPending() async {
    try {
      final res = await _api.get('admin/pending', auth: true);
      if (res['success'] == true) {
        final list = (res['data'] as List).map((j) => ProductModel.fromJson({
          ...j as Map<String, dynamic>,
          'innovator_name':     j['innovator_name'] ?? '',
          'innovator_username': j['username']       ?? '',
          'innovator_id':       j['user_id']        ?? 0,
          'images':             <dynamic>[],
        })).toList();
        state = state.copyWith(pendingProducts: list);
      }
    } catch (_) {}
  }

  Future<void> _loadUsers() async {
    try {
      final res = await _api.get('admin/users', auth: true);
      if (res['success'] == true) {
        final list = (res['data'] as List)
            .map((j) => UserModel.fromJson(j as Map<String, dynamic>))
            .toList();
        state = state.copyWith(users: list);
      }
    } catch (_) {}
  }

  // ── Products ─────────────────────────────────────────────────────────────────
  /// Returns null on success, error message string on failure.
  Future<String?> approveProduct(int id) async {
    final snapshot = state.pendingProducts;
    state = state.copyWith(
      pendingProducts: state.pendingProducts.where((p) => p.id != id).toList(),
    );
    try {
      final res = await _api.put('admin/products/$id/approve', {}, auth: true);
      if (res['success'] != true) {
        state = state.copyWith(pendingProducts: snapshot);
        return res['message'] as String? ?? 'Failed to approve product.';
      }
      await _loadStats();
      return null;
    } catch (_) {
      state = state.copyWith(pendingProducts: snapshot);
      return 'Network error. Please try again.';
    }
  }

  Future<String?> rejectProduct(int id) async {
    final snapshot = state.pendingProducts;
    state = state.copyWith(
      pendingProducts: state.pendingProducts.where((p) => p.id != id).toList(),
    );
    try {
      final res = await _api.put('admin/products/$id/reject', {}, auth: true);
      if (res['success'] != true) {
        state = state.copyWith(pendingProducts: snapshot);
        return res['message'] as String? ?? 'Failed to reject product.';
      }
      await _loadStats();
      return null;
    } catch (_) {
      state = state.copyWith(pendingProducts: snapshot);
      return 'Network error. Please try again.';
    }
  }

  // ── Users ────────────────────────────────────────────────────────────────────
  Future<String?> approveUser(int id) async {
    try {
      final res = await _api.put('admin/users/$id/approve', {}, auth: true);
      if (res['success'] != true) return res['message'] as String? ?? 'Failed to approve user.';
      state = state.copyWith(
        users: state.users.map((u) => u.id != id ? u : _patchUser(u, kycStatus: 'verified', userStatus: 1)).toList(),
      );
      return null;
    } catch (_) {
      return 'Network error. Please try again.';
    }
  }

  Future<String?> rejectUser(int id) async {
    try {
      final res = await _api.put('admin/users/$id/reject', {}, auth: true);
      if (res['success'] != true) return res['message'] as String? ?? 'Failed to reject user.';
      state = state.copyWith(
        users: state.users.map((u) => u.id != id ? u : _patchUser(u, kycStatus: 'rejected', userStatus: 2)).toList(),
      );
      return null;
    } catch (_) {
      return 'Network error. Please try again.';
    }
  }

  Future<void> refresh() async => loadAll();

  Future<String?> deleteUser(int id) async {
    final snapshot = state.users;
    state = state.copyWith(
      users: state.users.where((u) => u.id != id).toList(),
      stats: state.stats.copyWith(totalUsers: state.stats.totalUsers - 1),
    );
    try {
      final res = await _api.delete('admin/users/$id', auth: true);
      if (res['success'] != true) {
        state = state.copyWith(users: snapshot);
        return res['message'] as String? ?? 'Failed to delete user.';
      }
      return null;
    } catch (_) {
      state = state.copyWith(users: snapshot);
      return 'Network error. Please try again.';
    }
  }

  Future<String?> promoteToAdmin(int id) async {
    try {
      final res = await _api.put('admin/users/$id/promote-admin', {}, auth: true);
      if (res['success'] != true) return res['message'] as String? ?? 'Failed to promote user.';
      state = state.copyWith(
        users: state.users.map((u) => u.id != id ? u : _patchUser(u, role: 'admin')).toList(),
      );
      return null;
    } catch (_) {
      return 'Network error. Please try again.';
    }
  }

  Future<String?> demoteFromAdmin(int id) async {
    try {
      final res = await _api.put('admin/users/$id/demote-admin', {}, auth: true);
      if (res['success'] != true) return res['message'] as String? ?? 'Failed to demote user.';
      final restoredRole = res['restored_role'] as String? ?? 'client';
      state = state.copyWith(
        users: state.users.map((u) => u.id != id ? u : _patchUser(u, role: restoredRole)).toList(),
      );
      return null;
    } catch (_) {
      return 'Network error. Please try again.';
    }
  }

  // ── Tab ──────────────────────────────────────────────────────────────────────
  void setTab(String tab) => state = state.copyWith(activeTab: tab);

  // ── Helper ───────────────────────────────────────────────────────────────────
  UserModel _patchUser(UserModel u, {String? kycStatus, int? userStatus, String? role}) =>
      UserModel(
        id:          u.id,
        firstName:   u.firstName,
        lastName:    u.lastName,
        username:    u.username,
        email:       u.email,
        role:        role       ?? u.role,
        phone:       u.phone,
        dateOfBirth: u.dateOfBirth,
        city:        u.city,
        province:    u.province,
        kycStatus:   kycStatus  ?? u.kycStatus,
        userStatus:  userStatus ?? u.userStatus,
      );
}

// ─── Provider ─────────────────────────────────────────────────────────────────
final adminProvider = StateNotifierProvider<AdminNotifier, AdminState>(
  (ref) => AdminNotifier(ref.read(apiServiceProvider)),
);