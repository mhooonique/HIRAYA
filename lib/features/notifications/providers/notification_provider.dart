import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/api_service.dart';

// ── Model ─────────────────────────────────────────────────────────────────────

class AppNotification {
  final int id;
  final String type;   // product_approved | product_rejected | new_interest
                       // new_message | review_posted | product_liked | system
  final String title;
  final String body;
  final bool isRead;
  final String? actionUrl; // e.g. /product/3  or /messages
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
        id: j['id'],
        type: j['type'] ?? 'system',
        title: j['title'] ?? '',
        body: j['body'] ?? j['message'] ?? '',
        isRead: (j['is_read'] ?? j['read'] ?? 0) == 1,
        actionUrl: j['action_url'],
        createdAt: DateTime.tryParse(j['created_at'] ?? '') ?? DateTime.now(),
      );

  AppNotification copyWith({bool? isRead}) => AppNotification(
        id: id,
        type: type,
        title: title,
        body: body,
        isRead: isRead ?? this.isRead,
        actionUrl: actionUrl,
        createdAt: createdAt,
      );
}

// ── State ─────────────────────────────────────────────────────────────────────

class NotificationState {
  final bool isLoading;
  final List<AppNotification> notifications;
  final int unreadCount;
  final String? error;

  const NotificationState({
    this.isLoading = false,
    this.notifications = const [],
    this.unreadCount = 0,
    this.error,
  });

  NotificationState copyWith({
    bool? isLoading,
    List<AppNotification>? notifications,
    int? unreadCount,
    String? error,
  }) =>
      NotificationState(
        isLoading: isLoading ?? this.isLoading,
        notifications: notifications ?? this.notifications,
        unreadCount: unreadCount ?? this.unreadCount,
        error: error,
      );
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class NotificationNotifier extends StateNotifier<NotificationState> {
  final ApiService _api;
  Timer? _pollTimer;

  NotificationNotifier(this._api) : super(const NotificationState()) {
    load();
    _startPolling();
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) => _silentRefresh());
  }

  /// Silent refresh — updates badge count without showing a loading spinner.
  Future<void> _silentRefresh() async {
    try {
      final res = await _api.get('/notifications');
      final list = (res['notifications'] as List? ?? [])
          .map((e) => AppNotification.fromJson(e))
          .toList();
      state = state.copyWith(
        notifications: list,
        unreadCount: list.where((n) => !n.isRead).length,
      );
    } catch (_) {
      // Silent — don't disrupt existing state on transient errors
    }
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _api.get('/notifications');
      final list = (res['notifications'] as List? ?? [])
          .map((e) => AppNotification.fromJson(e))
          .toList();
      state = state.copyWith(
        isLoading: false,
        notifications: list,
        unreadCount: list.where((n) => !n.isRead).length,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Could not load notifications.',
      );
    }
  }

  Future<void> markRead(int id) async {
    final updated = state.notifications.map((n) {
      return n.id == id ? n.copyWith(isRead: true) : n;
    }).toList();
    state = state.copyWith(
      notifications: updated,
      unreadCount: updated.where((n) => !n.isRead).length,
    );
    try {
      await _api.put('/notifications/$id/read', {});
    } catch (_) {}
  }

  Future<void> markAllRead() async {
    final updated = state.notifications.map((n) => n.copyWith(isRead: true)).toList();
    state = state.copyWith(notifications: updated, unreadCount: 0);
    try {
      await _api.put('/notifications/read-all', {});
    } catch (_) {}
  }

  Future<void> deleteNotification(int id) async {
    final updated = state.notifications.where((n) => n.id != id).toList();
    state = state.copyWith(
      notifications: updated,
      unreadCount: updated.where((n) => !n.isRead).length,
    );
    try {
      await _api.delete('/notifications/$id');
    } catch (_) {}
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }
}

final notificationProvider =
    StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  return NotificationNotifier(ref.read(apiServiceProvider));
});
