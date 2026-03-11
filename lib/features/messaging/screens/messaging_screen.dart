import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/messaging_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  MESSAGING SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class MessagingScreen extends ConsumerWidget {
  const MessagingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mState   = ref.watch(messagingProvider);
    final user     = ref.watch(authProvider).user;
    final uid      = user?.id.toString() ?? '2';
    final isNarrow = MediaQuery.of(context).size.width < 820;

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: Column(children: [
        _TopBar(user: user, uid: uid),
        Expanded(
          child: isNarrow
              ? _NarrowLayout(mState: mState, uid: uid)
              : _WideLayout(mState: mState, uid: uid),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  TOP BAR
// ─────────────────────────────────────────────────────────────────────────────
class _TopBar extends ConsumerWidget {
  final dynamic user;
  final String uid;
  const _TopBar({this.user, required this.uid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role   = user?.role ?? 'client';
    final unread = ref.watch(messagingProvider.notifier).totalUnread(uid);

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
          onPressed: () => context.go(role == 'innovator' ? '/innovator/dashboard' : '/client/dashboard'),
          tooltip: 'Back',
        ),
        const SizedBox(width: 4),
        const Icon(Icons.chat_bubble_rounded, color: AppColors.sky, size: 20),
        const SizedBox(width: 10),
        const Text('Messages',
            style: TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.navy)),
        if (unread > 0) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: AppColors.crimson, borderRadius: BorderRadius.circular(20)),
            child: Text('$unread',
                style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
          ),
        ],
        const Spacer(),
        _GlobalSearchBar(),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  GLOBAL SEARCH BAR
// ─────────────────────────────────────────────────────────────────────────────
class _GlobalSearchBar extends ConsumerStatefulWidget {
  @override
  ConsumerState<_GlobalSearchBar> createState() => _GlobalSearchBarState();
}

class _GlobalSearchBarState extends ConsumerState<_GlobalSearchBar> {
  bool _expanded = false;
  final _ctrl = TextEditingController();

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: _expanded
          ? SizedBox(
              key: const ValueKey('expanded'),
              width: 280, height: 36,
              child: TextField(
                controller: _ctrl,
                autofocus: true,
                onChanged: (v) => ref.read(messagingProvider.notifier).setGlobalSearch(v),
                style: const TextStyle(fontFamily: 'Poppins', fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Search all messages...',
                  hintStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.black38),
                  prefixIcon: const Icon(Icons.search, size: 16, color: Colors.black38),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.close, size: 14),
                    onPressed: () {
                      _ctrl.clear();
                      ref.read(messagingProvider.notifier).clearSearch();
                      setState(() => _expanded = false);
                    },
                  ),
                  filled: true, fillColor: AppColors.offWhite,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: AppColors.lightGray)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: AppColors.lightGray)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: AppColors.sky)),
                ),
              ),
            )
          : IconButton(
              key: const ValueKey('icon'),
              icon: const Icon(Icons.search, color: AppColors.navy),
              tooltip: 'Search all messages',
              onPressed: () => setState(() => _expanded = true),
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  LAYOUTS
// ─────────────────────────────────────────────────────────────────────────────
class _WideLayout extends StatelessWidget {
  final MessagingState mState;
  final String uid;
  const _WideLayout({required this.mState, required this.uid});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      SizedBox(width: 320, child: _ConversationList(mState: mState, uid: uid)),
      const VerticalDivider(width: 1, color: AppColors.lightGray),
      Expanded(
        child: mState.activeConversation == null
            ? const _EmptyChatPlaceholder()
            : _ChatPanel(
                key: ValueKey(mState.activeConversation!.id),
                conversation: mState.activeConversation!,
                uid: uid,
                isOtherTyping: mState.isOtherTyping,
              ),
      ),
    ]);
  }
}

class _NarrowLayout extends StatelessWidget {
  final MessagingState mState;
  final String uid;
  const _NarrowLayout({required this.mState, required this.uid});

  @override
  Widget build(BuildContext context) {
    if (mState.activeConversation != null) {
      return _ChatPanel(
        key: ValueKey(mState.activeConversation!.id),
        conversation: mState.activeConversation!,
        uid: uid,
        isOtherTyping: mState.isOtherTyping,
        showBackButton: true,
      );
    }
    return _ConversationList(mState: mState, uid: uid);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  CONVERSATION LIST
// ─────────────────────────────────────────────────────────────────────────────
class _ConversationList extends ConsumerStatefulWidget {
  final MessagingState mState;
  final String uid;
  const _ConversationList({required this.mState, required this.uid});

  @override
  ConsumerState<_ConversationList> createState() => _ConversationListState();
}

class _ConversationListState extends ConsumerState<_ConversationList> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  List<Conversation> get _filtered {
    if (_query.isEmpty) return widget.mState.conversations;
    final q = _query.toLowerCase();
    return widget.mState.conversations.where((c) =>
        c.otherPersonName(widget.uid).toLowerCase().contains(q) ||
        c.originProductName.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    // Show global search results if active
    final globalQ = widget.mState.globalSearchQuery;
    if (globalQ.isNotEmpty) {
      return _GlobalSearchResults(
          results: widget.mState.searchMessages(globalQ), uid: widget.uid);
    }

    final filtered = _filtered;
    return Container(
      color: Colors.white,
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
          child: SizedBox(
            height: 38,
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v),
              style: const TextStyle(fontFamily: 'Poppins', fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Filter conversations...',
                hintStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.black38),
                prefixIcon: const Icon(Icons.search, size: 16, color: Colors.black38),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.clear, size: 14),
                        onPressed: () { _searchCtrl.clear(); setState(() => _query = ''); })
                    : null,
                filled: true, fillColor: AppColors.offWhite, contentPadding: EdgeInsets.zero,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.lightGray)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.lightGray)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.sky, width: 1.5)),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 6),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('${filtered.length} conversation${filtered.length == 1 ? '' : 's'}',
                style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Colors.black38)),
          ),
        ),
        const Divider(height: 1, color: AppColors.lightGray),
        Expanded(
          child: filtered.isEmpty
              ? const _EmptyState(icon: Icons.chat_bubble_outline_rounded,
                  title: 'No conversations', subtitle: 'Start one from a product listing.')
              : ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.lightGray, indent: 68),
                  itemBuilder: (ctx, i) => _ConvTile(
                    conv: filtered[i], uid: widget.uid,
                    isActive: filtered[i].id == widget.mState.activeConversationId,
                    index: i,
                  ),
                ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  GLOBAL SEARCH RESULTS
// ─────────────────────────────────────────────────────────────────────────────
class _GlobalSearchResults extends ConsumerWidget {
  final List<MessageSearchResult> results;
  final String uid;
  const _GlobalSearchResults({required this.results, required this.uid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      color: Colors.white,
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('${results.length} result${results.length == 1 ? '' : 's'} found',
                style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.black45)),
          ),
        ),
        const Divider(height: 1, color: AppColors.lightGray),
        Expanded(
          child: results.isEmpty
              ? const _EmptyState(icon: Icons.search_off_rounded,
                  title: 'No results', subtitle: 'Try a different keyword.')
              : ListView.separated(
                  itemCount: results.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.lightGray),
                  itemBuilder: (ctx, i) {
                    final r        = results[i];
                    final catColor = AppColors.categoryColors[r.conversation.originProductCategory] ?? AppColors.navy;
                    return ListTile(
                      onTap: () => ref.read(messagingProvider.notifier).openConversation(r.conversation.id),
                      leading: CircleAvatar(radius: 18,
                          backgroundColor: catColor.withValues(alpha: 0.15),
                          child: Text(r.conversation.otherPersonName(uid).substring(0, 1),
                              style: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w700, color: catColor))),
                      title: Text(r.message.text,
                          style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AppColors.navy),
                          maxLines: 2, overflow: TextOverflow.ellipsis),
                      subtitle: Text(
                          '${r.conversation.otherPersonName(uid)} · ${r.conversation.originProductName}',
                          style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Colors.black38),
                          overflow: TextOverflow.ellipsis),
                      trailing: Text(DateFormat('MMM d').format(r.message.timestamp),
                          style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Colors.black38)),
                    );
                  },
                ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  CONVERSATION TILE
// ─────────────────────────────────────────────────────────────────────────────
class _ConvTile extends ConsumerWidget {
  final Conversation conv;
  final String uid;
  final bool isActive;
  final int index;
  const _ConvTile({required this.conv, required this.uid, required this.isActive, required this.index});

  String _fmtTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inHours < 1)   return '${diff.inMinutes}m';
    if (diff.inDays < 1)    return DateFormat('h:mm a').format(dt);
    if (diff.inDays == 1)   return 'Yesterday';
    if (diff.inDays < 7)    return DateFormat('EEE').format(dt);
    return DateFormat('MMM d').format(dt);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread    = conv.unreadCount(uid);
    final catColor  = AppColors.categoryColors[conv.originProductCategory] ?? AppColors.navy;
    final otherName = conv.otherPersonName(uid);
    final lastMsg   = conv.lastMessage;
    final blocked   = conv.isBlockedByMe(uid) || conv.amIBlocked(uid);

    return GestureDetector(
      onTap: () => ref.read(messagingProvider.notifier).openConversation(conv.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        color: isActive ? AppColors.sky.withValues(alpha: 0.07) : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Stack(children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: blocked ? Colors.grey.withValues(alpha: 0.2) : catColor.withValues(alpha: 0.15),
              child: Text(otherName.substring(0, 1).toUpperCase(),
                  style: TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w700,
                      color: blocked ? Colors.grey : catColor)),
            ),
            if (unread > 0)
              Positioned(right: 0, top: 0,
                child: Container(
                  width: 16, height: 16,
                  decoration: const BoxDecoration(color: AppColors.crimson, shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: Text('$unread', style: const TextStyle(fontFamily: 'Poppins', fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white)),
                )),
            if (conv.isReported)
              Positioned(right: 0, bottom: 0,
                child: const Icon(Icons.flag_rounded, color: AppColors.crimson, size: 14)),
          ]),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                child: Text(otherName,
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 13,
                        fontWeight: unread > 0 ? FontWeight.w700 : FontWeight.w500,
                        color: blocked ? Colors.grey : AppColors.navy),
                    overflow: TextOverflow.ellipsis),
              ),
              Text(_fmtTime(conv.lastActivity),
                  style: TextStyle(fontFamily: 'Poppins', fontSize: 11,
                      color: unread > 0 ? AppColors.sky : Colors.black38,
                      fontWeight: unread > 0 ? FontWeight.w700 : FontWeight.w400)),
            ]),
            const SizedBox(height: 2),
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(color: catColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                child: Text(conv.originProductCategory,
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 9, fontWeight: FontWeight.w600, color: catColor)),
              ),
              const SizedBox(width: 4),
              Expanded(child: Text(conv.originProductName,
                  style: const TextStyle(fontFamily: 'Poppins', fontSize: 10, color: Colors.black45),
                  overflow: TextOverflow.ellipsis)),
            ]),
            if (lastMsg != null) ...[
              const SizedBox(height: 3),
              Row(children: [
                if (lastMsg.attachment != null)
                  const Padding(padding: EdgeInsets.only(right: 3),
                      child: Icon(Icons.attach_file_rounded, size: 11, color: Colors.black38)),
                Expanded(
                  child: Text(
                    lastMsg.senderId == uid
                        ? 'You: ${lastMsg.attachment?.name ?? lastMsg.text}'
                        : lastMsg.attachment?.name ?? lastMsg.text,
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 12,
                        color: unread > 0 ? AppColors.navy : Colors.black45,
                        fontWeight: unread > 0 ? FontWeight.w600 : FontWeight.w400),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                ),
              ]),
            ],
            if (blocked)
              const Padding(padding: EdgeInsets.only(top: 2),
                child: Text('Blocked', style: TextStyle(fontFamily: 'Poppins', fontSize: 10, color: Colors.grey, fontStyle: FontStyle.italic))),
          ])),
        ]),
      ),
    ).animate(delay: Duration(milliseconds: 40 * index)).fadeIn(duration: 280.ms);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  CHAT PANEL
// ─────────────────────────────────────────────────────────────────────────────
class _ChatPanel extends ConsumerStatefulWidget {
  final Conversation conversation;
  final String uid;
  final bool isOtherTyping;
  final bool showBackButton;

  const _ChatPanel({
    super.key,
    required this.conversation,
    required this.uid,
    required this.isOtherTyping,
    this.showBackButton = false,
  });

  @override
  ConsumerState<_ChatPanel> createState() => _ChatPanelState();
}

class _ChatPanelState extends ConsumerState<_ChatPanel> {
  final _textCtrl   = TextEditingController();
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
    if (widget.conversation.messages.length != old.conversation.messages.length ||
        widget.isOtherTyping != old.isOtherTyping) {
      SchedulerBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }
  }

  @override
  void dispose() { _textCtrl.dispose(); _scrollCtrl.dispose(); super.dispose(); }

  void _scrollToBottom() {
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  Future<void> _send({ChatAttachment? attachment}) async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty && attachment == null) return;
    final user = ref.read(authProvider).user;
    _textCtrl.clear();
    setState(() => _canSend = false);
    await ref.read(messagingProvider.notifier).sendMessage(
      widget.conversation.id, widget.uid, user?.fullName ?? 'You', text,
      attachment: attachment,
    );
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'ppt', 'pptx', 'xls', 'xlsx', 'png', 'jpg', 'jpeg'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final f = result.files.first;
    final isImage = ['png', 'jpg', 'jpeg'].contains(f.extension?.toLowerCase());
    await _send(attachment: ChatAttachment(
      name: f.name,
      sizeKb: (f.size / 1024).round(),
      type: isImage ? MessageType.image : MessageType.file,
      bytes: f.bytes != null ? Uint8List.fromList(f.bytes!) : null,
    ));
  }

  void _showConvMenu(BuildContext ctx, Conversation conv) {
    final isBlocked = conv.isBlockedByMe(widget.uid);
    showMenu(
      context: ctx,
      position: RelativeRect.fromLTRB(MediaQuery.of(ctx).size.width - 200, 120, 16, 0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      items: [
        PopupMenuItem(
          onTap: () => _confirmReport(ctx, conv),
          child: const Row(children: [
            Icon(Icons.flag_rounded, color: AppColors.crimson, size: 16),
            SizedBox(width: 10),
            Text('Report conversation', style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AppColors.crimson)),
          ]),
        ),
        PopupMenuItem(
          onTap: () {
            if (isBlocked) {
              ref.read(messagingProvider.notifier).unblockUser(widget.uid, conv.id);
            } else {
              ref.read(messagingProvider.notifier).blockUser(widget.uid, conv.id);
            }
          },
          child: Row(children: [
            Icon(isBlocked ? Icons.lock_open_rounded : Icons.block_rounded,
                color: isBlocked ? AppColors.teal : Colors.black54, size: 16),
            const SizedBox(width: 10),
            Text(isBlocked ? 'Unblock user' : 'Block user',
                style: TextStyle(fontFamily: 'Poppins', fontSize: 13,
                    color: isBlocked ? AppColors.teal : Colors.black87)),
          ]),
        ),
      ],
    );
  }

  void _confirmReport(BuildContext ctx, Conversation conv) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Report Conversation',
            style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, color: AppColors.navy)),
        content: const Text(
            'This flags the conversation for Admin review. The other party will not be notified. Continue?',
            style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Colors.black54, height: 1.5)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(fontFamily: 'Poppins', color: Colors.black45))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.crimson,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            onPressed: () {
              ref.read(messagingProvider.notifier).reportConversation(conv.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                content: Text('Conversation reported to Admin.', style: TextStyle(fontFamily: 'Poppins')),
                backgroundColor: AppColors.crimson, behavior: SnackBarBehavior.floating,
              ));
            },
            child: const Text('Report', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mState    = ref.watch(messagingProvider);
    final conv      = mState.conversations.where((c) => c.id == widget.conversation.id).firstOrNull
        ?? widget.conversation;
    final catColor  = AppColors.categoryColors[conv.originProductCategory] ?? AppColors.navy;
    final otherName = conv.otherPersonName(widget.uid);
    final messages  = conv.messages;
    final blocked   = conv.isBlockedByMe(widget.uid);
    final amBlocked = conv.amIBlocked(widget.uid);

    return Column(children: [
      // ── Header ───────────────────────────────────────────────────────────
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: AppColors.lightGray))),
        child: Row(children: [
          if (widget.showBackButton) ...[
            IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: AppColors.navy, size: 20),
              onPressed: () => ref.read(messagingProvider.notifier).closeConversation(),
            ),
            const SizedBox(width: 4),
          ],
          CircleAvatar(radius: 18,
              backgroundColor: catColor.withValues(alpha: 0.15),
              child: Text(otherName.substring(0, 1).toUpperCase(),
                  style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w700, color: catColor))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(otherName,
                  style: const TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.navy)),
              if (conv.isReported) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: AppColors.crimson.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                  child: const Text('Reported', style: TextStyle(fontFamily: 'Poppins', fontSize: 10, color: AppColors.crimson, fontWeight: FontWeight.w600)),
                ),
              ],
              if (blocked) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                  child: const Text('Blocked', style: TextStyle(fontFamily: 'Poppins', fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w600)),
                ),
              ],
            ]),
            Row(children: [
              Container(width: 5, height: 5, decoration: BoxDecoration(color: catColor, shape: BoxShape.circle)),
              const SizedBox(width: 5),
              Expanded(child: Text(conv.originProductName,
                  style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Colors.black45),
                  overflow: TextOverflow.ellipsis)),
            ]),
          ])),
          // Phase 2 — Jitsi Meet (disabled until implemented)
          IconButton(
            icon: const Icon(Icons.call_rounded, size: 18),
            color: Colors.black26,
            tooltip: 'Voice call — coming soon',
            onPressed: null, // null = disabled
          ),
          IconButton(
            icon: const Icon(Icons.videocam_rounded, size: 18),
            color: Colors.black26,
            tooltip: 'Video call — coming soon',
            onPressed: null,
          ),
          TextButton.icon(
            onPressed: () => context.go('/product/${conv.originProductId}'),
            icon: const Icon(Icons.open_in_new_rounded, size: 13, color: AppColors.sky),
            label: const Text('View Product', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.sky)),
            style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
          ),
          Builder(builder: (ctx) => IconButton(
            icon: const Icon(Icons.more_vert_rounded, color: Colors.black45),
            onPressed: () => _showConvMenu(ctx, conv),
          )),
        ]),
      ),

      // ── Messages ─────────────────────────────────────────────────────────
      Expanded(
        child: messages.isEmpty
            ? _EmptyChat(otherName: otherName, catColor: catColor)
            : ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                itemCount: messages.length + (mState.isOtherTyping ? 1 : 0),
                itemBuilder: (ctx, i) {
                  if (i == messages.length && mState.isOtherTyping) {
                    return _TypingIndicator(name: otherName, catColor: catColor);
                  }
                  final msg       = messages[i];
                  final isMine    = msg.senderId == widget.uid;
                  final showDate  = i == 0 || !_sameDay(messages[i - 1].timestamp, msg.timestamp);
                  final showAvatar = !isMine &&
                      (i == messages.length - 1 || messages[i + 1].senderId != msg.senderId);

                  return Column(children: [
                    if (showDate) _DateDivider(dt: msg.timestamp),
                    _MessageBubble(
                      message: msg, isMine: isMine, showAvatar: showAvatar,
                      catColor: catColor, uid: widget.uid, convId: conv.id,
                    ),
                  ]);
                },
              ),
      ),

      // ── Blocked banner ───────────────────────────────────────────────────
      if (blocked || amBlocked)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          color: Colors.grey.shade100,
          child: Text(
            blocked ? 'You have blocked this user. Unblock to send messages.'
                    : 'You cannot send messages to this user.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.grey),
          ),
        )
      else
        // ── Input bar ───────────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
          decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppColors.lightGray))),
          child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            IconButton(
              icon: const Icon(Icons.attach_file_rounded, color: Colors.black45, size: 20),
              onPressed: _pickFile,
              tooltip: 'Attach file or image (PDF, DOCX, PPTX, JPG, PNG)',
              padding: const EdgeInsets.only(bottom: 2),
            ),
            const SizedBox(width: 4),
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
                  maxLines: null, minLines: 1,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  style: const TextStyle(fontFamily: 'Poppins', fontSize: 13),
                  decoration: const InputDecoration(
                    hintText: 'Type a message...',
                    hintStyle: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Colors.black38),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _canSend ? () => _send() : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 42, height: 42,
                decoration: BoxDecoration(
                  color: _canSend ? AppColors.sky : AppColors.lightGray,
                  shape: BoxShape.circle,
                  boxShadow: _canSend
                      ? [BoxShadow(color: AppColors.sky.withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 2))]
                      : null,
                ),
                child: Icon(Icons.send_rounded,
                    color: _canSend ? Colors.white : Colors.black26, size: 17),
              ),
            ),
          ]),
        ),
    ]);
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

// ─────────────────────────────────────────────────────────────────────────────
//  TYPING INDICATOR  (animated 3-dot bounce — auto-triggered by provider)
// ─────────────────────────────────────────────────────────────────────────────
class _TypingIndicator extends StatefulWidget {
  final String name;
  final Color catColor;
  const _TypingIndicator({required this.name, required this.catColor});

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator> with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _anims;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(3, (i) => AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500)));
    _anims = _controllers.map((c) =>
        Tween<double>(begin: 0, end: -6).animate(CurvedAnimation(parent: c, curve: Curves.easeInOut))).toList();
    for (var i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: i * 150), () {
        if (mounted) _controllers[i].repeat(reverse: true);
      });
    }
  }

  @override
  void dispose() { for (final c in _controllers) c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        CircleAvatar(radius: 14,
            backgroundColor: widget.catColor.withValues(alpha: 0.15),
            child: Text(widget.name.substring(0, 1),
                style: TextStyle(fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.w700, color: widget.catColor))),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18), topRight: Radius.circular(18),
              bottomLeft: Radius.circular(4), bottomRight: Radius.circular(18)),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)],
            border: Border.all(color: AppColors.lightGray),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            for (var i = 0; i < 3; i++) ...[
              AnimatedBuilder(
                animation: _anims[i],
                builder: (_, __) => Transform.translate(
                  offset: Offset(0, _anims[i].value),
                  child: Container(width: 6, height: 6,
                      decoration: const BoxDecoration(color: Colors.black38, shape: BoxShape.circle)),
                ),
              ),
              if (i < 2) const SizedBox(width: 4),
            ],
          ]),
        ),
        const SizedBox(width: 8),
        Text('${widget.name.split(' ').first} is typing...',
            style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Colors.black38, fontStyle: FontStyle.italic)),
      ]),
    ).animate().fadeIn(duration: 200.ms);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  MESSAGE BUBBLE
// ─────────────────────────────────────────────────────────────────────────────
class _MessageBubble extends ConsumerWidget {
  final ChatMessage message;
  final bool isMine;
  final bool showAvatar;
  final Color catColor;
  final String uid;
  final String convId;

  const _MessageBubble({
    required this.message, required this.isMine, required this.showAvatar,
    required this.catColor, required this.uid, required this.convId,
  });

  IconData _statusIcon(MessageStatus s) => switch (s) {
    MessageStatus.sending   => Icons.access_time_rounded,
    MessageStatus.sent      => Icons.done_rounded,
    MessageStatus.delivered => Icons.done_all_rounded,
    MessageStatus.read      => Icons.done_all_rounded,
  };

  Color _statusColor(MessageStatus s) =>
      s == MessageStatus.read ? AppColors.sky : Colors.white54;

  void _showMsgMenu(BuildContext ctx, WidgetRef ref) {
    showMenu(
      context: ctx,
      position: RelativeRect.fromLTRB(
          isMine ? MediaQuery.of(ctx).size.width - 200 : 80, 0, isMine ? 16 : 0, 0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      color: Colors.white,
      items: [
        PopupMenuItem(
          onTap: () => Clipboard.setData(ClipboardData(text: message.text)),
          child: const Row(children: [
            Icon(Icons.copy_rounded, size: 15, color: Colors.black54),
            SizedBox(width: 8),
            Text('Copy text', style: TextStyle(fontFamily: 'Poppins', fontSize: 13)),
          ]),
        ),
        if (!isMine)
          PopupMenuItem(
            onTap: () => ref.read(messagingProvider.notifier).reportMessage(convId, message.id),
            child: const Row(children: [
              Icon(Icons.flag_rounded, size: 15, color: AppColors.crimson),
              SizedBox(width: 8),
              Text('Report message', style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AppColors.crimson)),
            ]),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final time = DateFormat('h:mm a').format(message.timestamp);

    return Padding(
      padding: EdgeInsets.only(top: 2, bottom: 2, left: isMine ? 60 : 0, right: isMine ? 0 : 60),
      child: Row(
        mainAxisAlignment: isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMine) ...[
            showAvatar
                ? CircleAvatar(radius: 14, backgroundColor: catColor.withValues(alpha: 0.15),
                    child: Text(message.senderName.substring(0, 1),
                        style: TextStyle(fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.w700, color: catColor)))
                : const SizedBox(width: 28),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: GestureDetector(
              onLongPress: () => _showMsgMenu(context, ref),
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
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      if (message.attachment != null)
                        _AttachmentPreview(attachment: message.attachment!, isMine: isMine),
                      if (message.text.isNotEmpty) ...[
                        if (message.attachment != null) const SizedBox(height: 6),
                        Text(message.text,
                            style: TextStyle(fontFamily: 'Poppins', fontSize: 13,
                                color: isMine ? Colors.white : AppColors.darkGray, height: 1.45)),
                      ],
                      if (message.isReported)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            const Icon(Icons.flag_rounded, size: 11, color: AppColors.crimson),
                            const SizedBox(width: 4),
                            Text('Reported', style: TextStyle(fontFamily: 'Poppins', fontSize: 10,
                                color: isMine ? Colors.white60 : AppColors.crimson)),
                          ]),
                        ),
                    ]),
                  ),
                  const SizedBox(height: 3),
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(time, style: const TextStyle(fontFamily: 'Poppins', fontSize: 10, color: Colors.black38)),
                    if (isMine) ...[
                      const SizedBox(width: 4),
                      Icon(_statusIcon(message.status), size: 12, color: _statusColor(message.status)),
                    ],
                  ]),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.04, end: 0);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  ATTACHMENT PREVIEW
// ─────────────────────────────────────────────────────────────────────────────
class _AttachmentPreview extends StatelessWidget {
  final ChatAttachment attachment;
  final bool isMine;
  const _AttachmentPreview({required this.attachment, required this.isMine});

  @override
  Widget build(BuildContext context) {
    if (attachment.type == MessageType.image && attachment.bytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.memory(attachment.bytes!, width: 200, fit: BoxFit.cover),
      );
    }
    final textColor = isMine ? Colors.white : AppColors.navy;
    final subColor  = isMine ? Colors.white60 : Colors.black45;
    final bgColor   = isMine ? Colors.white.withValues(alpha: 0.15) : AppColors.offWhite;
    final ext       = attachment.name.split('.').last.toUpperCase();
    final extColor  = ext == 'PDF' ? AppColors.crimson
        : ext == 'PPT' || ext == 'PPTX' ? AppColors.golden
        : AppColors.sky;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(color: extColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
          child: Text(ext, style: TextStyle(fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.w800, color: extColor)),
        ),
        const SizedBox(width: 10),
        Flexible(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(attachment.name,
              style: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w600, color: textColor),
              overflow: TextOverflow.ellipsis, maxLines: 1),
          Text(attachment.displaySize,
              style: TextStyle(fontFamily: 'Poppins', fontSize: 10, color: subColor)),
        ])),
        const SizedBox(width: 8),
        Icon(Icons.download_rounded, color: textColor.withValues(alpha: 0.6), size: 16),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  DATE DIVIDER
// ─────────────────────────────────────────────────────────────────────────────
class _DateDivider extends StatelessWidget {
  final DateTime dt;
  const _DateDivider({required this.dt});

  String get _label {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    return DateFormat('MMMM d, y').format(dt);
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 14),
    child: Row(children: [
      const Expanded(child: Divider(color: AppColors.lightGray)),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text(_label, style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Colors.black38, fontWeight: FontWeight.w500)),
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
        decoration: BoxDecoration(color: AppColors.sky.withValues(alpha: 0.08), shape: BoxShape.circle),
        child: const Icon(Icons.chat_bubble_outline_rounded, size: 48, color: AppColors.sky),
      ),
      const SizedBox(height: 20),
      const Text('Select a conversation',
          style: TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.navy)),
      const SizedBox(height: 8),
      const Text('Choose from the list to start chatting.',
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
      CircleAvatar(radius: 30, backgroundColor: catColor.withValues(alpha: 0.12),
          child: Text(otherName.substring(0, 1),
              style: TextStyle(fontFamily: 'Poppins', fontSize: 22, fontWeight: FontWeight.w700, color: catColor))),
      const SizedBox(height: 14),
      Text('Start chatting with ${otherName.split(' ').first}',
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