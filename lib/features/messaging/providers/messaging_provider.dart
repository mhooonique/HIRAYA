import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/api_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  ENUMS
// ─────────────────────────────────────────────────────────────────────────────
enum MessageType   { text, image, file }
enum MessageStatus { sending, sent, delivered, read }

// ─────────────────────────────────────────────────────────────────────────────
//  MODELS
// ─────────────────────────────────────────────────────────────────────────────
class ChatAttachment {
  final String name;
  final int sizeKb;
  final MessageType type;
  final Uint8List? bytes;

  const ChatAttachment({
    required this.name,
    required this.sizeKb,
    required this.type,
    this.bytes,
  });

  String get displaySize =>
      sizeKb < 1024 ? '$sizeKb KB' : '${(sizeKb / 1024).toStringAsFixed(1)} MB';

  factory ChatAttachment.fromJson(Map<String, dynamic> json) {
    MessageType type;
    switch (json['attachment_type'] as String?) {
      case 'image':
        type = MessageType.image;
        break;
      case 'file':
      default:
        type = MessageType.file;
        break;
    }

    Uint8List? bytes;
    final b64 = json['attachment_base64'] as String?;
    if (b64 != null && b64.isNotEmpty) {
      try {
        bytes = base64Decode(b64);
      } catch (_) {
        bytes = null;
      }
    }

    return ChatAttachment(
      name: json['attachment_name'] as String? ?? '',
      sizeKb: (json['attachment_size_kb'] as num?)?.toInt() ?? 0,
      type: type,
      bytes: bytes,
    );
  }
}

class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String text;
  final DateTime timestamp;
  final MessageStatus status;
  final ChatAttachment? attachment;
  final bool isReported;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.timestamp,
    this.status = MessageStatus.sent,
    this.attachment,
    this.isReported = false,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    MessageStatus status;
    switch (json['status'] as String?) {
      case 'delivered':
        status = MessageStatus.delivered;
        break;
      case 'read':
        status = MessageStatus.read;
        break;
      case 'sent':
      default:
        status = MessageStatus.sent;
        break;
    }

    ChatAttachment? attachment;
    if (json['attachment_name'] != null) {
      attachment = ChatAttachment.fromJson(json);
    }

    return ChatMessage(
      id: (json['id'] as num).toInt().toString(),
      senderId: (json['sender_id'] as num).toInt().toString(),
      senderName: json['sender_name'] as String? ?? '',
      text: json['text'] as String? ?? '',
      timestamp: DateTime.parse(json['created_at'] as String),
      status: status,
      attachment: attachment,
      isReported: (json['is_reported'] as bool?) ?? false,
    );
  }

  ChatMessage copyWith({MessageStatus? status, bool? isReported}) => ChatMessage(
        id: id,
        senderId: senderId,
        senderName: senderName,
        text: text,
        timestamp: timestamp,
        status: status ?? this.status,
        attachment: attachment,
        isReported: isReported ?? this.isReported,
      );

  bool matchesQuery(String q) {
    final lower = q.toLowerCase();
    return text.toLowerCase().contains(lower) ||
        (attachment?.name.toLowerCase().contains(lower) ?? false);
  }
}

class Conversation {
  final String id;
  // Single thread per Client-Innovator pair (spec 5.1)
  final String innovatorId;
  final String innovatorName;
  final String clientId;
  final String clientName;
  // Origin product context (informational only — does NOT create separate threads)
  final int originProductId;
  final String originProductName;
  final String originProductCategory;
  final List<ChatMessage> messages;
  final DateTime lastActivity;
  final bool isReported;
  final bool isBlockedByInnovator;
  final bool isBlockedByClient;

  const Conversation({
    required this.id,
    required this.innovatorId,
    required this.innovatorName,
    required this.clientId,
    required this.clientName,
    required this.originProductId,
    required this.originProductName,
    required this.originProductCategory,
    required this.messages,
    required this.lastActivity,
    this.isReported = false,
    this.isBlockedByInnovator = false,
    this.isBlockedByClient = false,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    final messagesJson = json['messages'] as List<dynamic>? ?? [];
    final messages = messagesJson
        .map((m) => ChatMessage.fromJson(m as Map<String, dynamic>))
        .toList();

    return Conversation(
      id: (json['id'] as num).toInt().toString(),
      innovatorId: (json['innovator_id'] as num).toInt().toString(),
      innovatorName: json['innovator_name'] as String? ?? '',
      clientId: (json['client_id'] as num).toInt().toString(),
      clientName: json['client_name'] as String? ?? '',
      originProductId: (json['origin_product_id'] as num?)?.toInt() ?? 0,
      originProductName: json['origin_product_name'] as String? ?? '',
      originProductCategory: json['origin_product_category'] as String? ?? '',
      messages: messages,
      lastActivity: DateTime.parse(
          (json['last_activity'] ?? json['created_at']) as String),
      isReported: false,
      isBlockedByInnovator: (json['is_blocked_by_innovator'] as num?)?.toInt() == 1,
      isBlockedByClient: (json['is_blocked_by_client'] as num?)?.toInt() == 1,
    );
  }

  ChatMessage? get lastMessage => messages.isEmpty ? null : messages.last;

  int unreadCount(String uid) => messages
      .where((m) => m.senderId != uid && m.status != MessageStatus.read)
      .length;

  String otherPersonName(String uid) =>
      uid == innovatorId ? clientName : innovatorName;

  String otherPersonId(String uid) =>
      uid == innovatorId ? clientId : innovatorId;

  bool isBlockedByMe(String uid) =>
      (uid == innovatorId && isBlockedByInnovator) ||
      (uid == clientId && isBlockedByClient);

  bool amIBlocked(String uid) =>
      (uid == innovatorId && isBlockedByClient) ||
      (uid == clientId && isBlockedByInnovator);

  Conversation copyWith({
    List<ChatMessage>? messages,
    DateTime? lastActivity,
    bool? isReported,
    bool? isBlockedByInnovator,
    bool? isBlockedByClient,
  }) =>
      Conversation(
        id: id,
        innovatorId: innovatorId,
        innovatorName: innovatorName,
        clientId: clientId,
        clientName: clientName,
        originProductId: originProductId,
        originProductName: originProductName,
        originProductCategory: originProductCategory,
        messages: messages ?? this.messages,
        lastActivity: lastActivity ?? this.lastActivity,
        isReported: isReported ?? this.isReported,
        isBlockedByInnovator: isBlockedByInnovator ?? this.isBlockedByInnovator,
        isBlockedByClient: isBlockedByClient ?? this.isBlockedByClient,
      );
}

class MessageSearchResult {
  final Conversation conversation;
  final ChatMessage message;
  const MessageSearchResult({required this.conversation, required this.message});
}

class IncomingCall {
  final int id;
  final String conversationId;
  final String callerName;
  final bool isVideo;
  final String roomUrl;

  const IncomingCall({
    required this.id,
    required this.conversationId,
    required this.callerName,
    required this.isVideo,
    required this.roomUrl,
  });

  factory IncomingCall.fromJson(Map<String, dynamic> json) => IncomingCall(
    id:             (json['id'] as num).toInt(),
    conversationId: (json['conversation_id'] as num).toInt().toString(),
    callerName:     json['caller_name'] as String? ?? 'Unknown',
    isVideo:        json['is_video'] == true || (json['is_video'] as num?) == 1,
    roomUrl:        json['room_url'] as String,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
//  STATE
// ─────────────────────────────────────────────────────────────────────────────
class MessagingState {
  final List<Conversation> conversations;
  final String? activeConversationId;
  final bool isSending;
  final bool isOtherTyping;
  final String globalSearchQuery;
  final List<String> blockedUserIds;
  final bool isCallActive;
  final String? activeCallRoomId;
  final String? activeCallType;
  final IncomingCall? incomingCall;

  const MessagingState({
    this.conversations = const [],
    this.activeConversationId,
    this.isSending = false,
    this.isOtherTyping = false,
    this.globalSearchQuery = '',
    this.blockedUserIds = const [],
    this.isCallActive = false,
    this.activeCallRoomId,
    this.activeCallType,
    this.incomingCall,
  });

  Conversation? get activeConversation => activeConversationId == null
      ? null
      : conversations.where((c) => c.id == activeConversationId).firstOrNull;

  List<MessageSearchResult> searchMessages(String q) {
    if (q.trim().isEmpty) return [];
    final results = <MessageSearchResult>[];
    for (final conv in conversations) {
      for (final msg in conv.messages) {
        if (msg.matchesQuery(q)) {
          results.add(MessageSearchResult(conversation: conv, message: msg));
        }
      }
    }
    results.sort((a, b) => b.message.timestamp.compareTo(a.message.timestamp));
    return results;
  }

  MessagingState copyWith({
    List<Conversation>? conversations,
    String? activeConversationId,
    bool clearActive = false,
    bool? isSending,
    bool? isOtherTyping,
    String? globalSearchQuery,
    List<String>? blockedUserIds,
    bool? isCallActive,
    String? activeCallRoomId,
    String? activeCallType,
    IncomingCall? incomingCall,
    bool clearIncomingCall = false,
  }) =>
      MessagingState(
        conversations: conversations ?? this.conversations,
        activeConversationId:
            clearActive ? null : (activeConversationId ?? this.activeConversationId),
        isSending: isSending ?? this.isSending,
        isOtherTyping: isOtherTyping ?? this.isOtherTyping,
        globalSearchQuery: globalSearchQuery ?? this.globalSearchQuery,
        blockedUserIds: blockedUserIds ?? this.blockedUserIds,
        isCallActive: isCallActive ?? this.isCallActive,
        activeCallRoomId: activeCallRoomId ?? this.activeCallRoomId,
        activeCallType: activeCallType ?? this.activeCallType,
        incomingCall: clearIncomingCall ? null : (incomingCall ?? this.incomingCall),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
//  NOTIFIER
// ─────────────────────────────────────────────────────────────────────────────
class MessagingNotifier extends StateNotifier<MessagingState> {
  final ApiService _api;
  int? _currentUserId;
  Timer? _pollTimer;
  Timer? _callPollTimer;

  MessagingNotifier(this._api) : super(const MessagingState());

  // ── Load conversations from API ────────────────────────────────────────────
  Future<void> loadConversations(int userId) async {
    _currentUserId = userId;
    try {
      final res = await _api.get('messages/conversations');
      final data = res['data'] as List<dynamic>? ?? [];
      final conversations = data
          .map((c) => Conversation.fromJson(c as Map<String, dynamic>))
          .toList();
      state = state.copyWith(conversations: conversations);
    } catch (_) {
      // Silently fail — conversations remain empty or stale
    }
    _startCallPolling();
  }

  // ── Open / Close ──────────────────────────────────────────────────────────
  void openConversation(String id) {
    state = state.copyWith(activeConversationId: id);
    _loadConversationDetail(id);
  }

  Future<void> _loadConversationDetail(String id) async {
    try {
      final res = await _api.get('messages/conversations/$id');
      final data = res['data'] as Map<String, dynamic>?;
      if (data == null) return;

      final conv = Conversation.fromJson(data);
      _upsertConversation(conv);

      // Mark messages from other person as read
      await markRead(id, _currentUserId ?? 0);

      // Start polling for new messages
      _startPolling(id);
    } catch (_) {
      // Fall back to local state
    }
  }

  void _startPolling(String convId) {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      try {
        final res = await _api.get('messages/conversations/$convId');
        final data = res['data'] as Map<String, dynamic>?;
        if (data == null) return;
        final conv = Conversation.fromJson(data);
        _upsertConversation(conv);
      } catch (_) {}
    });
  }

  void _upsertConversation(Conversation conv) {
    final exists = state.conversations.any((c) => c.id == conv.id);
    List<Conversation> updated;
    if (exists) {
      updated = state.conversations.map((c) => c.id == conv.id ? conv : c).toList();
    } else {
      updated = [conv, ...state.conversations];
    }
    updated.sort((a, b) => b.lastActivity.compareTo(a.lastActivity));
    state = state.copyWith(conversations: updated);
  }

  void closeConversation() {
    _pollTimer?.cancel();
    _pollTimer = null;
    state = state.copyWith(clearActive: true);
  }

  void _startCallPolling() {
    _callPollTimer?.cancel();
    _callPollTimer = Timer.periodic(const Duration(seconds: 3), (_) => _pollIncomingCalls());
  }

  Future<void> _pollIncomingCalls() async {
    try {
      final res = await _api.get('messages/calls/incoming');
      if (res['success'] != true) return;
      final data = res['data'];
      if (data == null) {
        if (state.incomingCall != null) {
          state = state.copyWith(clearIncomingCall: true);
        }
        return;
      }
      final incoming = IncomingCall.fromJson(data as Map<String, dynamic>);
      // Only update if it's a different call (avoid re-triggering dialog)
      if (state.incomingCall?.id != incoming.id) {
        state = state.copyWith(incomingCall: incoming);
      }
    } catch (_) {}
  }

  // ── Send ──────────────────────────────────────────────────────────────────
  Future<void> sendMessage(
    String conversationId,
    String senderId,
    String senderName,
    String text, {
    ChatAttachment? attachment,
  }) async {
    if (text.trim().isEmpty && attachment == null) return;

    state = state.copyWith(isSending: true);

    try {
      final body = <String, dynamic>{
        'text': text.trim(),
      };

      if (attachment != null) {
        body['attachment_name'] = attachment.name;
        body['attachment_size_kb'] = attachment.sizeKb;
        body['attachment_type'] =
            attachment.type == MessageType.image ? 'image' : 'file';
        if (attachment.bytes != null) {
          body['attachment_base64'] = base64Encode(attachment.bytes!);
        }
      }

      final res = await _api.post(
        'messages/conversations/$conversationId/send',
        body,
      );

      final data = res['data'] as Map<String, dynamic>?;
      if (data != null) {
        final msg = ChatMessage.fromJson(data);
        _insertMessage(conversationId, msg);
      }
    } catch (_) {
      // Silently fail
    } finally {
      state = state.copyWith(isSending: false);
    }
  }

  void _insertMessage(String convId, ChatMessage msg) {
    final updated = state.conversations.map((c) {
      if (c.id != convId) return c;
      return c.copyWith(messages: [...c.messages, msg], lastActivity: DateTime.now());
    }).toList()
      ..sort((a, b) => b.lastActivity.compareTo(a.lastActivity));
    state = state.copyWith(conversations: updated);
  }

  // ── Global message search ─────────────────────────────────────────────────
  void setGlobalSearch(String q) => state = state.copyWith(globalSearchQuery: q);
  void clearSearch() => state = state.copyWith(globalSearchQuery: '');

  // ── Report ────────────────────────────────────────────────────────────────
  Future<bool> reportConversation(String convId, {required String reason}) async {
    try {
      final res = await _api.post('messages/conversations/$convId/report', {'reason': reason});
      state = state.copyWith(
        conversations: state.conversations
            .map((c) => c.id == convId ? c.copyWith(isReported: true) : c)
            .toList(),
      );
      return res['suspended'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<void> reportMessage(String convId, String msgId, {String reason = 'Inappropriate content'}) async {
    try {
      await _api.post('messages/conversations/$convId/report', {
        'message_id': int.tryParse(msgId),
        'reason': reason,
      });
      state = state.copyWith(
        conversations: state.conversations.map((c) {
          if (c.id != convId) return c;
          return c.copyWith(
            isReported: true,
            messages: c.messages
                .map((m) => m.id == msgId ? m.copyWith(isReported: true) : m)
                .toList(),
          );
        }).toList(),
      );
    } catch (_) {}
  }

  // ── Block / Unblock ───────────────────────────────────────────────────────
  Future<void> blockUser(String currentUserId, String convId) async {
    try {
      await _api.post('messages/conversations/$convId/block', {});
      final conv = state.conversations.where((c) => c.id == convId).firstOrNull;
      if (conv == null) return;
      final targetId = conv.otherPersonId(currentUserId);
      state = state.copyWith(
        blockedUserIds: [...state.blockedUserIds, targetId],
        conversations: state.conversations.map((c) {
          if (c.id != convId) return c;
          return c.copyWith(
            isBlockedByInnovator:
                currentUserId == c.innovatorId ? true : c.isBlockedByInnovator,
            isBlockedByClient:
                currentUserId == c.clientId ? true : c.isBlockedByClient,
          );
        }).toList(),
      );
    } catch (_) {}
  }

  Future<void> unblockUser(String currentUserId, String convId) async {
    try {
      await _api.delete('messages/conversations/$convId/block');
      final conv = state.conversations.where((c) => c.id == convId).firstOrNull;
      if (conv == null) return;
      final targetId = conv.otherPersonId(currentUserId);
      state = state.copyWith(
        blockedUserIds: state.blockedUserIds.where((id) => id != targetId).toList(),
        conversations: state.conversations.map((c) {
          if (c.id != convId) return c;
          return c.copyWith(
            isBlockedByInnovator:
                currentUserId == c.innovatorId ? false : c.isBlockedByInnovator,
            isBlockedByClient:
                currentUserId == c.clientId ? false : c.isBlockedByClient,
          );
        }).toList(),
      );
    } catch (_) {}
  }

  bool isUserBlocked(String userId) => state.blockedUserIds.contains(userId);

  // ── Total unread count ────────────────────────────────────────────────────
  int totalUnread(String uid) =>
      state.conversations.fold(0, (sum, c) => sum + c.unreadCount(uid));

  // ── Mark read ─────────────────────────────────────────────────────────────
  Future<void> markRead(String convId, int userId) async {
    try {
      await _api.put('messages/conversations/$convId/read', {});
    } catch (_) {}
  }

  // ── Start or get existing conversation ───────────────────────────────────
  /// Spec 5.1: single thread per Client-Innovator pair
  /// regardless of which product prompted the message
  Future<String> startOrGetConversation({
    required int productId,
    required String productName,
    required String productCategory,
    required String innovatorId,
    required String innovatorName,
    required String clientId,
    required String clientName,
  }) async {
    // Reuse existing thread if pair already has one
    final existing = state.conversations
        .where((c) => c.innovatorId == innovatorId && c.clientId == clientId)
        .firstOrNull;

    if (existing != null) {
      openConversation(existing.id);
      return existing.id;
    }

    try {
      final res = await _api.post('messages/conversations', {
        'innovator_id': int.parse(innovatorId),
        'client_id': int.parse(clientId),
        'origin_product_id': productId,
        'origin_product_name': productName,
        'origin_product_category': productCategory,
      });

      final data = res['data'] as Map<String, dynamic>?;
      if (data != null) {
        final conv = Conversation.fromJson(data);
        _upsertConversation(conv);
        openConversation(conv.id);
        return conv.id;
      }
    } catch (_) {}

    // Fallback: create local-only conversation
    final newConv = Conversation(
      id: 'conv_${DateTime.now().millisecondsSinceEpoch}',
      innovatorId: innovatorId,
      innovatorName: innovatorName,
      clientId: clientId,
      clientName: clientName,
      originProductId: productId,
      originProductName: productName,
      originProductCategory: productCategory,
      messages: const [],
      lastActivity: DateTime.now(),
    );
    state = state.copyWith(
      conversations: [newConv, ...state.conversations],
      activeConversationId: newConv.id,
    );
    return newConv.id;
  }

  // ── Voice/Video calls via Jitsi Meet ──────────────────────────────────────
  Future<void> initiateCall(String convId, {required bool isVideo}) async {
    final conv = state.conversations.where((c) => c.id == convId).firstOrNull;
    if (conv == null || _currentUserId == null) return;

    final calleeId = conv.otherPersonId(_currentUserId.toString());

    try {
      final res = await _api.post('messages/calls', {
        'conversation_id': int.parse(convId),
        'callee_id':       int.parse(calleeId),
        'is_video':        isVideo,
      });
      if (res['success'] == true) {
        final roomUrl = res['data']['room_url'] as String;
        html.window.open(roomUrl, '_blank');
      }
    } catch (_) {
      // Fallback: open room directly
      html.window.open('https://meet.jit.si/hiraya-conv-$convId', '_blank');
    }
  }

  Future<void> acceptCall(int callId, String roomUrl) async {
    try {
      await _api.put('messages/calls/$callId/accept', {});
    } catch (_) {}
    state = state.copyWith(clearIncomingCall: true);
    html.window.open(roomUrl, '_blank');
  }

  Future<void> declineCall(int callId) async {
    try {
      await _api.put('messages/calls/$callId/decline', {});
    } catch (_) {}
    state = state.copyWith(clearIncomingCall: true);
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _callPollTimer?.cancel();
    super.dispose();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  PROVIDER
// ─────────────────────────────────────────────────────────────────────────────
final messagingProvider = StateNotifierProvider<MessagingNotifier, MessagingState>(
  (ref) => MessagingNotifier(ref.read(apiServiceProvider)),
);
