// lib/features/notifications/widgets/notification_bell.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/notification_provider.dart';
import '../../../core/constants/app_colors.dart';

class NotificationBell extends ConsumerStatefulWidget {
  const NotificationBell({super.key});

  @override
  ConsumerState<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends ConsumerState<NotificationBell> {
  bool _started = false;

  @override
  void initState() {
    super.initState();
    // ✅ Guard: only start once per widget lifecycle
    Future.microtask(() {
      if (mounted && !_started) {
        _started = true;
        ref.read(notificationProvider.notifier).start();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationProvider);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined, color: AppColors.navy),
          tooltip: 'Notifications',
          onPressed: () => _showPanel(context),
        ),
        if (state.unreadCount > 0)
          Positioned(
            top: 6, right: 6,
            child: GestureDetector(
              onTap: () => _showPanel(context),
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  color: AppColors.crimson,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                child: Text(
                  state.unreadCount > 99 ? '99+' : '${state.unreadCount}',
                  style: const TextStyle(
                    color: Colors.white, fontSize: 9,
                    fontWeight: FontWeight.bold, fontFamily: 'Poppins',
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _showPanel(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _NotificationPanel(parentContext: context),
    );
  }
}

class _NotificationPanel extends ConsumerWidget {
  final BuildContext parentContext;
  const _NotificationPanel({required this.parentContext});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize:     0.92,
      minChildSize:     0.4,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(children: [
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: 40, height: 4,
            decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
            child: Row(children: [
              const Text('Notifications',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700,
                      color: AppColors.navy, fontFamily: 'Poppins')),
              if (state.unreadCount > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                      color: AppColors.crimson,
                      borderRadius: BorderRadius.circular(10)),
                  child: Text('${state.unreadCount} new',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 11,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins')),
                ),
              ],
              const Spacer(),
              if (state.unreadCount > 0)
                TextButton(
                  onPressed: () =>
                      ref.read(notificationProvider.notifier).markAllRead(),
                  child: const Text('Mark all read',
                      style: TextStyle(
                          color: AppColors.navy, fontSize: 12,
                          fontFamily: 'Poppins')),
                ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded,
                    color: Colors.grey, size: 20),
                onPressed: () =>
                    ref.read(notificationProvider.notifier).load(),
              ),
            ]),
          ),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          Expanded(
            child: state.isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.navy))
                : state.notifications.isEmpty
                    ? _EmptyNotifications()
                    : ListView.separated(
                        controller: ctrl,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: state.notifications.length,
                        separatorBuilder: (_, __) => const Divider(
                            height: 1, color: Color(0xFFEEEEEE)),
                        itemBuilder: (ctx, i) => _NotificationTile(
                          notification: state.notifications[i],
                          onTap: () {
                            final n = state.notifications[i];
                            if (!n.isRead) {
                              ref
                                  .read(notificationProvider.notifier)
                                  .markRead(n.id);
                            }
                            // ✅ Capture router BEFORE closing sheet
                            final router  = GoRouter.of(parentContext);
                            final current = GoRouterState.of(parentContext)
                                .uri
                                .toString();
                            Navigator.pop(ctx);
                            if (n.actionUrl != null &&
                                n.actionUrl!.isNotEmpty &&
                                current != n.actionUrl) {
                              router.push(n.actionUrl!);
                            }
                          },
                          onDismiss: () => ref
                              .read(notificationProvider.notifier)
                              .deleteNotification(
                                  state.notifications[i].id),
                        ),
                      ),
          ),
        ]),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _NotificationTile({
    required this.notification,
    required this.onTap,
    required this.onDismiss,
  });

  IconData get _icon => switch (notification.type) {
        'product_approved' => Icons.check_circle_rounded,
        'product_rejected' => Icons.cancel_rounded,
        'new_interest'     => Icons.handshake_rounded,
        'product_liked'    => Icons.favorite_rounded,
        'new_message'      => Icons.chat_bubble_rounded,
        'review_posted'    => Icons.star_rounded,
        'new_user'         => Icons.person_add_rounded,
        'account_approved' => Icons.verified_rounded,
        'account_rejected' => Icons.cancel_rounded,
        _                  => Icons.notifications_rounded,
      };

  Color get _iconColor => switch (notification.type) {
        'product_approved' => AppColors.teal,
        'product_rejected' => AppColors.crimson,
        'new_interest'     => AppColors.golden,
        'product_liked'    => AppColors.crimson,
        'new_message'      => AppColors.sky,
        'review_posted'    => AppColors.golden,
        'new_user'         => AppColors.sky,
        'account_approved' => AppColors.teal,
        'account_rejected' => AppColors.crimson,
        _                  => AppColors.navy,
      };

  String get _timeAgo {
    final diff = DateTime.now().difference(notification.createdAt);
    if (diff.inMinutes < 1)  return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24)   return '${diff.inHours}h ago';
    if (diff.inDays < 7)     return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(notification.createdAt);
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss(),
      background: Container(
        alignment: Alignment.centerRight,
        color: AppColors.crimson.withValues(alpha: 0.1),
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline, color: AppColors.crimson),
      ),
      child: InkWell(
        onTap: onTap,
        child: Container(
          color: notification.isRead
              ? Colors.transparent
              : AppColors.navy.withValues(alpha: 0.03),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                  color: _iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(_icon, color: _iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
              Row(children: [
                Expanded(
                    child: Text(notification.title,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: notification.isRead
                                ? FontWeight.w500
                                : FontWeight.w700,
                            color: AppColors.navy,
                            fontFamily: 'Poppins'))),
                Text(_timeAgo,
                    style: const TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                        fontFamily: 'Poppins')),
              ]),
              const SizedBox(height: 3),
              Text(notification.body,
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      height: 1.4,
                      fontFamily: 'Poppins'),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ])),
            if (!notification.isRead) ...[
              const SizedBox(width: 8),
              Container(
                width: 8, height: 8,
                decoration: const BoxDecoration(
                    color: AppColors.crimson, shape: BoxShape.circle),
              ),
            ],
          ]),
        ),
      ),
    );
  }
}

class _EmptyNotifications extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.notifications_none_rounded, size: 64, color: Colors.grey),
        SizedBox(height: 16),
        Text('No notifications yet',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700,
                color: AppColors.navy, fontFamily: 'Poppins')),
        SizedBox(height: 8),
        Text("You're all caught up!",
            style: TextStyle(
                fontSize: 13, color: Colors.grey, fontFamily: 'Poppins')),
      ]),
    );
  }
}