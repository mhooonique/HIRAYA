import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  // Phase 2 — Voice/Video stubs (Jitsi Meet — jitsi_meet_flutter_sdk)
  final bool isCallActive;
  final String? activeCallRoomId;
  final String? activeCallType; // 'voice' | 'video'

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
      );
}

// ─────────────────────────────────────────────────────────────────────────────
//  NOTIFIER
// ─────────────────────────────────────────────────────────────────────────────
class MessagingNotifier extends StateNotifier<MessagingState> {
  MessagingNotifier() : super(const MessagingState()) {
    _loadDummy();
  }

  // ── Seed data ─────────────────────────────────────────────────────────────
  void _loadDummy() {
    final now = DateTime.now();
    state = state.copyWith(conversations: [
      Conversation(
        id: 'conv_1',
        innovatorId: '4',
        innovatorName: 'Carlo Reyes',
        clientId: '3',
        clientName: 'Maria Santos',
        originProductId: 3,
        originProductName: 'Modular Solar Microgrids',
        originProductCategory: 'Energy',
        lastActivity: now.subtract(const Duration(minutes: 15)),
        messages: [
          ChatMessage(
            id: 'm1', senderId: '3', senderName: 'Maria Santos',
            text: 'Hi Carlo! I\'m very interested in your Solar Microgrid solution for our cooperative in Bukidnon. Can we discuss pricing and deployment timelines?',
            timestamp: now.subtract(const Duration(hours: 2)), status: MessageStatus.read,
          ),
          ChatMessage(
            id: 'm2', senderId: '4', senderName: 'Carlo Reyes',
            text: 'Hello Maria! The modular system is perfect for cooperatives. A standard 10kW setup covers about 15-20 households. What\'s your current load requirement?',
            timestamp: now.subtract(const Duration(hours: 1, minutes: 45)), status: MessageStatus.read,
          ),
          ChatMessage(
            id: 'm3', senderId: '3', senderName: 'Maria Santos',
            text: 'We have about 40 households. We\'re open to a pilot of 10 units first to evaluate performance before full rollout.',
            timestamp: now.subtract(const Duration(hours: 1, minutes: 20)), status: MessageStatus.read,
          ),
          ChatMessage(
            id: 'm4', senderId: '4', senderName: 'Carlo Reyes',
            text: 'For 40 households I\'d recommend the 25kW industrial package with a 6-month performance guarantee. Here are the full specs.',
            timestamp: now.subtract(const Duration(minutes: 50)), status: MessageStatus.read,
            attachment: ChatAttachment(name: 'SolarMicrogrid_TechSpecs_v2.pdf', sizeKb: 2340, type: MessageType.file),
          ),
          ChatMessage(
            id: 'm5', senderId: '3', senderName: 'Maria Santos',
            text: 'Are there financing options available? Our cooperative may qualify for DA-DILG grants.',
            timestamp: now.subtract(const Duration(minutes: 15)), status: MessageStatus.delivered,
          ),
        ],
      ),
      Conversation(
        id: 'conv_2',
        innovatorId: '2',
        innovatorName: 'Juan dela Cruz',
        clientId: '3',
        clientName: 'Maria Santos',
        originProductId: 1,
        originProductName: 'Smart Rice Monitoring System',
        originProductCategory: 'Agriculture',
        lastActivity: now.subtract(const Duration(days: 1)),
        messages: [
          ChatMessage(
            id: 'm6', senderId: '3', senderName: 'Maria Santos',
            text: 'Juan, your rice monitoring system is exactly what our AgriTech fund is looking for. We\'d like to discuss a pilot in Cagayan Valley.',
            timestamp: now.subtract(const Duration(days: 1, hours: 3)), status: MessageStatus.read,
          ),
          ChatMessage(
            id: 'm7', senderId: '2', senderName: 'Juan dela Cruz',
            text: 'Our system has been validated in 3 municipalities in Nueva Ecija with a 23% average yield improvement. I\'d love to discuss Cagayan Valley deployment.',
            timestamp: now.subtract(const Duration(days: 1, hours: 2)), status: MessageStatus.read,
          ),
          ChatMessage(
            id: 'm8', senderId: '3', senderName: 'Maria Santos',
            text: 'Impressive. Can you share the validation reports for our investment committee?',
            timestamp: now.subtract(const Duration(days: 1, hours: 1)), status: MessageStatus.read,
          ),
          ChatMessage(
            id: 'm9', senderId: '2', senderName: 'Juan dela Cruz',
            text: 'Of course! Here is the full validation report and market analysis.',
            timestamp: now.subtract(const Duration(days: 1)), status: MessageStatus.read,
            attachment: ChatAttachment(name: 'RiceMonitor_Validation_Report_2025.pdf', sizeKb: 3120, type: MessageType.file),
          ),
        ],
      ),
      Conversation(
        id: 'conv_3',
        innovatorId: '2',
        innovatorName: 'Juan dela Cruz',
        clientId: '7',
        clientName: 'Dr. Pedro Tan',
        originProductId: 5,
        originProductName: 'HydroFarm Sensor Array',
        originProductCategory: 'Agriculture',
        lastActivity: now.subtract(const Duration(days: 3)),
        messages: [
          ChatMessage(
            id: 'm10', senderId: '7', senderName: 'Dr. Pedro Tan',
            text: 'We\'re interested in integrating HydroFarm into our research greenhouse. Can you share the sensor calibration documentation?',
            timestamp: now.subtract(const Duration(days: 3, hours: 5)), status: MessageStatus.read,
          ),
          ChatMessage(
            id: 'm11', senderId: '2', senderName: 'Juan dela Cruz',
            text: 'Dr. Tan, here is the full calibration guide and integration API docs.',
            timestamp: now.subtract(const Duration(days: 3, hours: 4)), status: MessageStatus.read,
            attachment: ChatAttachment(name: 'HydroFarm_Calibration_Guide.pdf', sizeKb: 920, type: MessageType.file),
          ),
          ChatMessage(
            id: 'm12', senderId: '7', senderName: 'Dr. Pedro Tan',
            text: 'What is the lead time for a 20-unit order?',
            timestamp: now.subtract(const Duration(days: 3)), status: MessageStatus.read,
          ),
        ],
      ),
    ]);
  }

  // ── Open / Close ──────────────────────────────────────────────────────────
  void openConversation(String id) {
    final updated = state.conversations.map((c) {
      if (c.id != id) return c;
      return c.copyWith(
        messages: c.messages
            .map((m) => m.status != MessageStatus.read ? m.copyWith(status: MessageStatus.read) : m)
            .toList(),
      );
    }).toList();
    state = state.copyWith(conversations: updated, activeConversationId: id);
  }

  void closeConversation() => state = state.copyWith(clearActive: true);

  // ── Send ──────────────────────────────────────────────────────────────────
  Future<void> sendMessage(
    String conversationId,
    String senderId,
    String senderName,
    String text, {
    ChatAttachment? attachment,
  }) async {
    if (text.trim().isEmpty && attachment == null) return;

    final msg = ChatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      senderId: senderId,
      senderName: senderName,
      text: text.trim(),
      timestamp: DateTime.now(),
      status: MessageStatus.sending,
      attachment: attachment,
    );

    _insertMessage(conversationId, msg);

    // Simulate: sending → delivered
    await Future.delayed(const Duration(milliseconds: 500));
    _updateStatus(conversationId, msg.id, MessageStatus.delivered);

    // Simulate: typing indicator appears
    await Future.delayed(const Duration(milliseconds: 700));
    state = state.copyWith(isOtherTyping: true);

    // Simulate: typing disappears after 2s
    await Future.delayed(const Duration(seconds: 2));
    state = state.copyWith(isOtherTyping: false);
  }

  void _insertMessage(String convId, ChatMessage msg) {
    final updated = state.conversations.map((c) {
      if (c.id != convId) return c;
      return c.copyWith(messages: [...c.messages, msg], lastActivity: DateTime.now());
    }).toList()
      ..sort((a, b) => b.lastActivity.compareTo(a.lastActivity));
    state = state.copyWith(conversations: updated);
  }

  void _updateStatus(String convId, String msgId, MessageStatus s) {
    state = state.copyWith(
      conversations: state.conversations.map((c) {
        if (c.id != convId) return c;
        return c.copyWith(
          messages: c.messages.map((m) => m.id == msgId ? m.copyWith(status: s) : m).toList(),
        );
      }).toList(),
    );
  }

  // ── Global message search ─────────────────────────────────────────────────
  void setGlobalSearch(String q) => state = state.copyWith(globalSearchQuery: q);
  void clearSearch() => state = state.copyWith(globalSearchQuery: '');

  // ── Report ────────────────────────────────────────────────────────────────
  void reportConversation(String convId) {
    state = state.copyWith(
      conversations: state.conversations
          .map((c) => c.id == convId ? c.copyWith(isReported: true) : c)
          .toList(),
    );
  }

  void reportMessage(String convId, String msgId) {
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
  }

  // ── Block / Unblock ───────────────────────────────────────────────────────
  void blockUser(String currentUserId, String convId) {
    final conv = state.conversations.where((c) => c.id == convId).firstOrNull;
    if (conv == null) return;
    final targetId = conv.otherPersonId(currentUserId);
    state = state.copyWith(
      blockedUserIds: [...state.blockedUserIds, targetId],
      conversations: state.conversations.map((c) {
        if (c.id != convId) return c;
        return c.copyWith(
          isBlockedByInnovator: currentUserId == c.innovatorId ? true : c.isBlockedByInnovator,
          isBlockedByClient: currentUserId == c.clientId ? true : c.isBlockedByClient,
        );
      }).toList(),
    );
  }

  void unblockUser(String currentUserId, String convId) {
    final conv = state.conversations.where((c) => c.id == convId).firstOrNull;
    if (conv == null) return;
    final targetId = conv.otherPersonId(currentUserId);
    state = state.copyWith(
      blockedUserIds: state.blockedUserIds.where((id) => id != targetId).toList(),
      conversations: state.conversations.map((c) {
        if (c.id != convId) return c;
        return c.copyWith(
          isBlockedByInnovator: currentUserId == c.innovatorId ? false : c.isBlockedByInnovator,
          isBlockedByClient: currentUserId == c.clientId ? false : c.isBlockedByClient,
        );
      }).toList(),
    );
  }

  bool isUserBlocked(String userId) => state.blockedUserIds.contains(userId);

  // ── Total unread count ────────────────────────────────────────────────────
  int totalUnread(String uid) =>
      state.conversations.fold(0, (sum, c) => sum + c.unreadCount(uid));

  // ── Start or get existing conversation ───────────────────────────────────
  /// Spec 5.1: single thread per Client-Innovator pair
  /// regardless of which product prompted the message
  String startOrGetConversation({
    required int productId,
    required String productName,
    required String productCategory,
    required String innovatorId,
    required String innovatorName,
    required String clientId,
    required String clientName,
  }) {
    // Reuse existing thread if pair already has one
    final existing = state.conversations
        .where((c) => c.innovatorId == innovatorId && c.clientId == clientId)
        .firstOrNull;

    if (existing != null) {
      openConversation(existing.id);
      return existing.id;
    }

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

  // ── Phase 2: Voice/Video stubs (Jitsi Meet) ───────────────────────────────
  // TODO: implement with jitsi_meet_flutter_sdk (free, self-hosted)
  // Room naming: 'hiraya_${conversationId}_${timestamp}'
  Future<void> initiateCall(String convId, {required bool isVideo}) async {
    throw UnimplementedError('Voice/Video calls — Phase 2 feature.');
  }

  Future<void> endCall(String convId) async {
    throw UnimplementedError('Voice/Video calls — Phase 2 feature.');
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  PROVIDER
// ─────────────────────────────────────────────────────────────────────────────
final messagingProvider =
    StateNotifierProvider<MessagingNotifier, MessagingState>(
  (ref) => MessagingNotifier(),
);