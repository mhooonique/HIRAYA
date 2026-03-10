import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/messaging_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  MESSAGING SCREEN  (route: /messages)
//  Layout: ConversationList (left) | ChatPanel (right) — side-by-side on web
// ─────────────────────────────────────────────────────────────────────────────
class MessagingScreen extends ConsumerWidget {
  const MessagingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mState = ref.watch(messagingProvider);
    final user = ref.watch(authProvider).user;
    final currentUserId = user?.id.toString() ?? '3';
    final activeConv = mState.activeConversation;
    final width = MediaQuery.of(context).size.width;
    final isNarrow = width < 800;

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: Column(children: [
        _MessagingTopBar(user: user, unreadCount: ref.read(messagingProvider.notifier).totalUnread),
        Expanded(
          child: isNarrow
              ? _NarrowLayout(
                  conversations: mState.conversations,
                  activeConversation: activeConv,
                  currentUserId: currentUserId,
                  isSending: mState.isSending,
                )
              : _WideLayout(
                  conversations: mState.conversations,
                  activeConversation: activeConv,
                  currentUserId: currentUserId,
                  isSending: mState.isSending,
                ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  TOP BAR
// ─────────────────────────────────────────────────────────────────────────────
class _MessagingTopBar extends ConsumerWidget {
  final dynamic user;
  final int unreadCount;
  const _MessagingTopBar({this.user, required this.unreadCount});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.lightGray)),
      ),
      child: Row(children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.navy, size: 20),
          onPressed: () {
            final role = ref.read(authProvider).user?.role ?? 'client';
            context.go(role == 'innovator' ? '/innovator/dashboard' : '/client/dashboard');
          },
          tooltip: 'Back to Dashboard',
        ),
        const SizedBox(width: 4),
        const Icon(Icons.chat_bubble_rounded, color: AppColors.sky, size: 20),
        const SizedBox(width: 10),
        const Text('Messages',
            style: TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.navy)),
        if (unreadCount > 0) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: AppColors.crimson, borderRadius: BorderRadius.circular(20)),
            child: Text('$unreadCount',
                style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
          ),
        ],
        const Spacer(),
        if (user != null)
          Row(children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.sky.withValues(alpha: 0.15),
              child: Text(user.firstName.substring(0, 1).toUpperCase(),
                  style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.sky)),
            ),
            const SizedBox(width: 8),
            Text(user.firstName,
                style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.navy)),
          ]),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  WIDE LAYOUT  (side-by-side)
// ─────────────────────────────────────────────────────────────────────────────
class _WideLayout extends StatelessWidget {
  final List<Conversation> conversations;
  final Conversation? activeConversation;
  final String currentUserId;
  final bool isSending;

  const _WideLayout({
    required this.conversations,
    required this.activeConversation,
    required this.currentUserId,
    required this.isSending,
  });

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      // Conversation list — fixed width
      SizedBox(
        width: 320,
        child: _ConversationList(
          conversations: conversations,
          activeId: activeConversation?.id,
          currentUserId: currentUserId,
        ),
      ),
      const VerticalDivider(width: 1, color: AppColors.lightGray),
      // Chat panel — takes remaining space
      Expanded(
        child: activeConversation == null
            ? const _EmptyChatPlaceholder()
            : _ChatPanel(
                key: ValueKey(activeConversation!.id),
                conversation: activeConversation!,
                currentUserId: currentUserId,
                isSending: isSending,
              ),
      ),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  NARROW LAYOUT  (single view, back button)
// ─────────────────────────────────────────────────────────────────────────────
class _NarrowLayout extends StatelessWidget {
  final List<Conversation> conversations;
  final Conversation? activeConversation;
  final String currentUserId;
  final bool isSending;

  const _NarrowLayout({
    required this.conversations,
    required this.activeConversation,
    required this.currentUserId,
    required this.isSending,
  });

  @override
  Widget build(BuildContext context) {
    if (activeConversation != null) {
      return _ChatPanel(
        key: ValueKey(activeConversation!.id),
        conversation: activeConversation!,
        currentUserId: currentUserId,
        isSending: isSending,
        showBackButton: true,
      );
    }
    return _ConversationList(
      conversations: conversations,
      activeId: null,
      currentUserId: currentUserId,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  CONVERSATION LIST
// ─────────────────────────────────────────────────────────────────────────────
class _ConversationList extends ConsumerStatefulWidget {
  final List<Conversation> conversations;
  final String? activeId;
  final String currentUserId;

  const _ConversationList({
    required this.conversations,
    required this.activeId,
    required this.currentUserId,
  });

  @override
  ConsumerState<_ConversationList> createState() => _ConversationListState();
}

class _ConversationListState extends ConsumerState<_ConversationList> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Conversation> get _filtered {
    if (_query.isEmpty) return widget.conversations;
    final q = _query.toLowerCase();
    return widget.conversations.where((c) =>
        c.productName.toLowerCase().contains(q) ||
        c.otherPersonName(widget.currentUserId).toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return Container(
      color: Colors.white,
      child: Column(children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: SizedBox(
            height: 40,
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v),
              style: const TextStyle(fontFamily: 'Poppins', fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Search conversations...',
                hintStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.black38),
                prefixIcon: const Icon(Icons.search, size: 18, color: Colors.black38),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 14, color: Colors.black38),
                        onPressed: () { _searchCtrl.clear(); setState(() => _query = ''); })
                    : null,
                filled: true,
                fillColor: AppColors.offWhite,
                contentPadding: EdgeInsets.zero,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.lightGray)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.lightGray)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.sky, width: 1.5)),
              ),
            ),
          ),
        ),

        // Count
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Row(children: [
            Text('${filtered.length} conversation${filtered.length == 1 ? '' : 's'}',
                style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Colors.black38)),
          ]),
        ),

        const Divider(height: 1, color: AppColors.lightGray),

        Expanded(
          child: filtered.isEmpty
              ? const _EmptyState(icon: Icons.search_off_rounded, title: 'No results', subtitle: 'Try a different name or product.')
              : ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.lightGray, indent: 68),
                  itemBuilder: (ctx, i) => _ConversationTile(
                    conversation: filtered[i],
                    isActive: filtered[i].id == widget.activeId,
                    currentUserId: widget.currentUserId,
                    index: i,
                  ),
                ),
        ),
      ]),
    );
  }
}

class _ConversationTile extends ConsumerWidget {
  final Conversation conversation;
  final bool isActive;
  final String currentUserId;
  final int index;

  const _ConversationTile({
    required this.conversation,
    required this.isActive,
    required this.currentUserId,
    required this.index,
  });

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inDays < 1) return DateFormat('h:mm a').format(dt);
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return DateFormat('EEE').format(dt);
    return DateFormat('MMM d').format(dt);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = conversation.unreadCount(currentUserId);
    final catColor = AppColors.categoryColors[conversation.productCategory] ?? AppColors.navy;
    final otherName = conversation.otherPersonName(currentUserId);
    final lastMsg = conversation.lastMessage;

    return GestureDetector(
      onTap: () => ref.read(messagingProvider.notifier).openConversation(conversation.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        color: isActive ? AppColors.sky.withValues(alpha: 0.06) : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Avatar
          Stack(children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: catColor.withValues(alpha: 0.15),
              child: Text(otherName.substring(0, 1).toUpperCase(),
                  style: TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w700, color: catColor)),
            ),
            if (unread > 0)
              Positioned(
                right: 0, top: 0,
                child: Container(
                  width: 16, height: 16,
                  decoration: const BoxDecoration(color: AppColors.crimson, shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: Text('$unread',
                      style: const TextStyle(fontFamily: 'Poppins', fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white)),
                ),
              ),
          ]),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                child: Text(otherName,
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: unread > 0 ? FontWeight.w700 : FontWeight.w500, color: AppColors.navy),
                    overflow: TextOverflow.ellipsis),
              ),
              Text(_formatTime(conversation.lastActivity),
                  style: TextStyle(fontFamily: 'Poppins', fontSize: 11,
                      color: unread > 0 ? AppColors.sky : Colors.black38,
                      fontWeight: unread > 0 ? FontWeight.w700 : FontWeight.w400)),
            ]),
            const SizedBox(height: 2),
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(color: catColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                child: Text(conversation.productCategory,
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 9, fontWeight: FontWeight.w600, color: catColor)),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(conversation.productName,
                    style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Colors.black45),
                    overflow: TextOverflow.ellipsis),
              ),
            ]),
            if (lastMsg != null) ...[
              const SizedBox(height: 4),
              Text(
                lastMsg.senderId == currentUserId ? 'You: ${lastMsg.text}' : lastMsg.text,
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: unread > 0 ? AppColors.navy : Colors.black45,
                    fontWeight: unread > 0 ? FontWeight.w600 : FontWeight.w400),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ])),
        ]),
      ),
    ).animate(delay: Duration(milliseconds: 40 * index)).fadeIn(duration: 300.ms);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  CHAT PANEL
// ─────────────────────────────────────────────────────────────────────────────
class _ChatPanel extends ConsumerStatefulWidget {
  final Conversation conversation;
  final String currentUserId;
  final bool isSending;
  final bool showBackButton;

  const _ChatPanel({
    super.key,
    required this.conversation,
    required this.currentUserId,
    required this.isSending,
    this.showBackButton = false,
  });

  @override
  ConsumerState<_ChatPanel> createState() => _ChatPanelState();
}

class _ChatPanelState extends ConsumerState<_ChatPanel> {
  final _textCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _canSend = false;

  @override
  void initState() {
    super.initState();
    _textCtrl.addListener(() => setState(() => _canSend = _textCtrl.text.trim().isNotEmpty));
    SchedulerBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  void didUpdateWidget(_ChatPanel old) {
    super.didUpdateWidget(old);
    if (widget.conversation.messages.length != old.conversation.messages.length) {
      SchedulerBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _send() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;
    final user = ref.read(authProvider).user;
    _textCtrl.clear();
    setState(() => _canSend = false);
    await ref.read(messagingProvider.notifier).sendMessage(
          widget.conversation.id,
          widget.currentUserId,
          user?.fullName ?? 'You',
          text,
        );
    SchedulerBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  Widget build(BuildContext context) {
    // Re-read live conversation from provider
    final mState = ref.watch(messagingProvider);
    final conv = mState.conversations.where((c) => c.id == widget.conversation.id).firstOrNull
        ?? widget.conversation;
    final catColor = AppColors.categoryColors[conv.productCategory] ?? AppColors.navy;
    final otherName = conv.otherPersonName(widget.currentUserId);
    final messages = conv.messages;

    return Column(children: [
      // ── Chat Header ──────────────────────────────────────────────────────
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: AppColors.lightGray)),
        ),
        child: Row(children: [
          if (widget.showBackButton) ...[
            IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: AppColors.navy, size: 20),
              onPressed: () => ref.read(messagingProvider.notifier).closeConversation(),
            ),
            const SizedBox(width: 4),
          ],
          CircleAvatar(
            radius: 18,
            backgroundColor: catColor.withValues(alpha: 0.15),
            child: Text(otherName.substring(0, 1).toUpperCase(),
                style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w700, color: catColor)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(otherName,
                style: const TextStyle(fontFamily: 'Poppins', fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.navy)),
            Row(children: [
              Container(
                width: 6, height: 6,
                decoration: BoxDecoration(color: catColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(conv.productName,
                    style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.black45),
                    overflow: TextOverflow.ellipsis),
              ),
            ]),
          ])),
          // View product button
          TextButton.icon(
            onPressed: () => context.go('/product/${conv.productId}'),
            icon: const Icon(Icons.open_in_new_rounded, size: 14, color: AppColors.sky),
            label: const Text('View Product', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.sky)),
            style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6)),
          ),
        ]),
      ),

      // ── Messages ─────────────────────────────────────────────────────────
      Expanded(
        child: messages.isEmpty
            ? _EmptyChat(otherName: otherName, catColor: catColor)
            : ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                itemCount: messages.length,
                itemBuilder: (ctx, i) {
                  final msg = messages[i];
                  final isMine = msg.senderId == widget.currentUserId;
                  final showDate = i == 0 ||
                      !_isSameDay(messages[i - 1].timestamp, msg.timestamp);
                  final showAvatar = !isMine &&
                      (i == messages.length - 1 || messages[i + 1].senderId != msg.senderId);

                  return Column(children: [
                    if (showDate) _DateDivider(dt: msg.timestamp),
                    _MessageBubble(
                      message: msg,
                      isMine: isMine,
                      showAvatar: showAvatar,
                      catColor: catColor,
                    ),
                  ]);
                },
              ),
      ),

      // ── Input bar ────────────────────────────────────────────────────────
      Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.lightGray)),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              decoration: BoxDecoration(
                color: AppColors.offWhite,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.lightGray),
              ),
              child: TextField(
                controller: _textCtrl,
                maxLines: null,
                minLines: 1,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                style: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: TextStyle(fontFamily: 'Poppins', fontSize: 14, color: Colors.black38),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                ),
                onSubmitted: (_) => _canSend ? _send() : null,
              ),
            ),
          ),
          const SizedBox(width: 10),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: GestureDetector(
              onTap: _canSend && !widget.isSending ? _send : null,
              child: Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: _canSend ? AppColors.sky : AppColors.lightGray,
                  shape: BoxShape.circle,
                  boxShadow: _canSend
                      ? [BoxShadow(color: AppColors.sky.withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 2))]
                      : null,
                ),
                child: widget.isSending
                    ? const Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)))
                    : Icon(Icons.send_rounded, color: _canSend ? Colors.white : Colors.black26, size: 18),
              ),
            ),
          ),
        ]),
      ),
    ]);
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

// ─────────────────────────────────────────────────────────────────────────────
//  MESSAGE BUBBLE
// ─────────────────────────────────────────────────────────────────────────────
class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMine;
  final bool showAvatar;
  final Color catColor;

  const _MessageBubble({
    required this.message,
    required this.isMine,
    required this.showAvatar,
    required this.catColor,
  });

  @override
  Widget build(BuildContext context) {
    final time = DateFormat('h:mm a').format(message.timestamp);

    return Padding(
      padding: EdgeInsets.only(
        top: 2, bottom: 2,
        left: isMine ? 60 : 0,
        right: isMine ? 0 : 60,
      ),
      child: Row(
        mainAxisAlignment: isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMine) ...[
            if (showAvatar)
              CircleAvatar(
                radius: 14,
                backgroundColor: catColor.withValues(alpha: 0.15),
                child: Text(message.senderName.substring(0, 1).toUpperCase(),
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.w700, color: catColor)),
              )
            else
              const SizedBox(width: 28),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMine ? AppColors.sky : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: isMine ? const Radius.circular(18) : const Radius.circular(4),
                      bottomRight: isMine ? const Radius.circular(4) : const Radius.circular(18),
                    ),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 1))],
                    border: isMine ? null : Border.all(color: AppColors.lightGray),
                  ),
                  child: Text(
                    message.text,
                    style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        color: isMine ? Colors.white : AppColors.darkGray,
                        height: 1.45),
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(time, style: const TextStyle(fontFamily: 'Poppins', fontSize: 10, color: Colors.black38)),
                    if (isMine) ...[
                      const SizedBox(width: 4),
                      Icon(
                        message.isRead ? Icons.done_all_rounded : Icons.done_rounded,
                        size: 12,
                        color: message.isRead ? AppColors.sky : Colors.black38,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.04, end: 0);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  DATE DIVIDER
// ─────────────────────────────────────────────────────────────────────────────
class _DateDivider extends StatelessWidget {
  final DateTime dt;
  const _DateDivider({required this.dt});

  String get _label {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    return DateFormat('MMMM d, y').format(dt);
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 16),
    child: Row(children: [
      const Expanded(child: Divider(color: AppColors.lightGray)),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text(_label,
            style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Colors.black38, fontWeight: FontWeight.w500)),
      ),
      const Expanded(child: Divider(color: AppColors.lightGray)),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
//  EMPTY STATES
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyChatPlaceholder extends StatelessWidget {
  const _EmptyChatPlaceholder();

  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.sky.withValues(alpha: 0.08),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.chat_bubble_outline_rounded, size: 48, color: AppColors.sky),
      ),
      const SizedBox(height: 20),
      const Text('Select a conversation', style: TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.navy)),
      const SizedBox(height: 8),
      const Text('Choose from the list on the left to start chatting.',
          style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Colors.black38)),
    ]),
  );
}

class _EmptyChat extends StatelessWidget {
  final String otherName;
  final Color catColor;
  const _EmptyChat({required this.otherName, required this.catColor});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      CircleAvatar(
        radius: 32,
        backgroundColor: catColor.withValues(alpha: 0.12),
        child: Text(otherName.substring(0, 1).toUpperCase(),
            style: TextStyle(fontFamily: 'Poppins', fontSize: 24, fontWeight: FontWeight.w700, color: catColor)),
      ),
      const SizedBox(height: 16),
      Text('Start a conversation with $otherName',
          style: const TextStyle(fontFamily: 'Poppins', fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.navy)),
      const SizedBox(height: 6),
      const Text('Send your first message below.',
          style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Colors.black38)),
    ]),
  );
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _EmptyState({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(icon, size: 48, color: AppColors.lightGray),
      const SizedBox(height: 12),
      Text(title, style: const TextStyle(fontFamily: 'Poppins', fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.navy)),
      const SizedBox(height: 4),
      Text(subtitle, style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.black38)),
    ]),
  );
}