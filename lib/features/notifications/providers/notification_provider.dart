import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/api_service.dart';

class AppNotification {
  final int id;
  final String type;
  final String title;
  final String body;
  final bool isRead;
  final String? actionUrl;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.isRead,
    this.actionUrl,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> j) => AppNotification(
        id:        j['id'],
        type:      j['type']      ?? 'system',
        title:     j['title']     ?? '',
        body:      j['body']      ?? j['message'] ?? '',
        isRead:    (j['is_read']  ?? j['read'] ?? 0) == 1,
        actionUrl: j['action_url'],
        createdAt: DateTime.tryParse(j['created_at'] ?? '') ?? DateTime.now(),
      );

  AppNotification copyWith({bool? isRead}) => AppNotification(
        id:        id,
        type:      type,
        title:     title,
        body:      body,
        isRead:    isRead    ?? this.isRead,
        actionUrl: actionUrl,
        createdAt: createdAt,
      );
}

class NotificationState {
  final bool isLoading;
  final List<AppNotification> notifications;
  final int unreadCount;
  final String? error;

  const NotificationState({
    this.isLoading     = false,
    this.notifications = const [],
    this.unreadCount   = 0,
    this.error,
  });

  NotificationState copyWith({
    bool?                  isLoading,
    List<AppNotification>? notifications,
    int?                   unreadCount,
    String?                error,
  }) =>
      NotificationState(
        isLoading:     isLoading     ?? this.isLoading,
        notifications: notifications ?? this.notifications,
        unreadCount:   unreadCount   ?? this.unreadCount,
        error:         error,
      );
}

class NotificationNotifier extends StateNotifier<NotificationState> {
  final ApiService _api;
  Timer? _pollTimer;
  bool _started = false;

  NotificationNotifier(this._api) : super(const NotificationState());

  /// Call once after login — safe to call multiple times (guarded)
  Future<void> start() async {
    if (_started) return;
    final token = await _api.getStoredToken();
    if (token == null) return;
    _started = true;
    await load();
    _startPolling();
  }

  void _startPolling() {
    _pollTimer?.cancel();
    // ✅ 60 seconds — prevents notification spam
    _pollTimer = Timer.periodic(
      const Duration(seconds: 60),
      (_) => _silentRefresh(),
    );
  }

  Future<bool> _isLoggedIn() async {
    final token = await _api.getStoredToken();
    return token != null;
  }

  Future<void> _silentRefresh() async {
    if (!mounted) return;
    if (!await _isLoggedIn()) { stop(); return; }
    try {
      final res  = await _api.get('notifications', auth: true);
      final list = (res['notifications'] as List? ?? [])
          .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
          .toList();
      if (mounted) {
        state = state.copyWith(
          notifications: list,
          unreadCount:   list.where((n) => !n.isRead).length,
        );
      }
    } catch (_) {}
  }

  Future<void> load() async {
    if (!await _isLoggedIn()) return;
    if (mounted) state = state.copyWith(isLoading: true, error: null);
    try {
      final res  = await _api.get('notifications', auth: true);
      final list = (res['notifications'] as List? ?? [])
          .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
          .toList();
      if (mounted) {
        state = state.copyWith(
          isLoading:     false,
          notifications: list,
          unreadCount:   list.where((n) => !n.isRead).length,
        );
      }
    } catch (_) {
      if (mounted) {
        state = state.copyWith(
          isLoading: false,
          error:     'Could not load notifications.',
        );
      }
    }
  }

  /// Call on logout
  void stop() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _started   = false;
    if (mounted) state = const NotificationState();
  }

  Future<void> markRead(int id) async {
    final updated = state.notifications
        .map((n) => n.id == id ? n.copyWith(isRead: true) : n)
        .toList();
    state = state.copyWith(
      notifications: updated,
      unreadCount:   updated.where((n) => !n.isRead).length,
    );
    try {
      await _api.put('notifications/$id/read', {}, auth: true);
    } catch (_) {
      await load();
    }
  }

  Future<void> markAllRead() async {
    final updated = state.notifications
        .map((n) => n.copyWith(isRead: true))
        .toList();
    state = state.copyWith(notifications: updated, unreadCount: 0);
    try {
      await _api.put('notifications/read-all', {}, auth: true);
    } catch (_) {
      await load();
    }
  }

  Future<void> deleteNotification(int id) async {
    final updated = state.notifications.where((n) => n.id != id).toList();
    state = state.copyWith(
      notifications: updated,
      unreadCount:   updated.where((n) => !n.isRead).length,
    );
    try {
      await _api.delete('notifications/$id', auth: true);
    } catch (_) {
      await load();
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }
}

final notificationProvider =
    StateNotifierProvider<NotificationNotifier, NotificationState>(
  (ref) => NotificationNotifier(ref.read(apiServiceProvider)),
);