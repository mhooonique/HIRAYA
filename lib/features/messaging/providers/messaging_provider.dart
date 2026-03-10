import 'package:flutter_riverpod/flutter_riverpod.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  MODELS
// ─────────────────────────────────────────────────────────────────────────────
class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String text;
  final DateTime timestamp;
  final bool isRead;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.timestamp,
    this.isRead = false,
  });

  ChatMessage copyWith({bool? isRead}) => ChatMessage(
        id: id,
        senderId: senderId,
        senderName: senderName,
        text: text,
        timestamp: timestamp,
        isRead: isRead ?? this.isRead,
      );
}

class Conversation {
  final String id;
  final int productId;
  final String productName;
  final String productCategory;
  final String innovatorId;
  final String innovatorName;
  final String clientId;
  final String clientName;
  final List<ChatMessage> messages;
  final DateTime lastActivity;

  Conversation({
    required this.id,
    required this.productId,
    required this.productName,
    required this.productCategory,
    required this.innovatorId,
    required this.innovatorName,
    required this.clientId,
    required this.clientName,
    required this.messages,
    required this.lastActivity,
  });

  ChatMessage? get lastMessage => messages.isEmpty ? null : messages.last;

  int unreadCount(String currentUserId) =>
      messages.where((m) => !m.isRead && m.senderId != currentUserId).length;

  String otherPersonName(String currentUserId) =>
      currentUserId == innovatorId ? clientName : innovatorName;

  String otherPersonId(String currentUserId) =>
      currentUserId == innovatorId ? clientId : innovatorId;

  Conversation copyWith({List<ChatMessage>? messages, DateTime? lastActivity}) =>
      Conversation(
        id: id,
        productId: productId,
        productName: productName,
        productCategory: productCategory,
        innovatorId: innovatorId,
        innovatorName: innovatorName,
        clientId: clientId,
        clientName: clientName,
        messages: messages ?? this.messages,
        lastActivity: lastActivity ?? this.lastActivity,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
//  STATE
// ─────────────────────────────────────────────────────────────────────────────
class MessagingState {
  final List<Conversation> conversations;
  final String? activeConversationId;
  final bool isSending;

  MessagingState({
    this.conversations = const [],
    this.activeConversationId,
    this.isSending = false,
  });

  Conversation? get activeConversation => activeConversationId == null
      ? null
      : conversations.where((c) => c.id == activeConversationId).firstOrNull;

  MessagingState copyWith({
    List<Conversation>? conversations,
    String? activeConversationId,
    bool? clearActive,
    bool? isSending,
  }) =>
      MessagingState(
        conversations: conversations ?? this.conversations,
        activeConversationId:
            clearActive == true ? null : (activeConversationId ?? this.activeConversationId),
        isSending: isSending ?? this.isSending,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
//  NOTIFIER
// ─────────────────────────────────────────────────────────────────────────────
class MessagingNotifier extends StateNotifier<MessagingState> {
  MessagingNotifier() : super(MessagingState()) {
    _loadDummy();
  }

  void _loadDummy() {
    final now = DateTime.now();
    state = state.copyWith(conversations: [
      Conversation(
        id: 'conv_1',
        productId: 3,
        productName: 'Modular Solar Microgrids',
        productCategory: 'Energy',
        innovatorId: '4',
        innovatorName: 'Carlo Reyes',
        clientId: '3',
        clientName: 'Maria Santos',
        lastActivity: now.subtract(const Duration(minutes: 15)),
        messages: [
          ChatMessage(id: 'm1', senderId: '3', senderName: 'Maria Santos', text: 'Hi Carlo! I\'m very interested in your Solar Microgrid solution for our cooperative in Bukidnon. Can we discuss pricing and deployment timelines?', timestamp: now.subtract(const Duration(hours: 2)), isRead: true),
          ChatMessage(id: 'm2', senderId: '4', senderName: 'Carlo Reyes', text: 'Hello Maria! Thanks for reaching out. The modular system is perfect for cooperatives. A standard 10kW setup covers about 15-20 households. What\'s your cooperative\'s current load requirement?', timestamp: now.subtract(const Duration(hours: 1, minutes: 45)), isRead: true),
          ChatMessage(id: 'm3', senderId: '3', senderName: 'Maria Santos', text: 'We have about 40 households. We\'re also open to a pilot deployment of 10 units first to evaluate performance before full rollout.', timestamp: now.subtract(const Duration(hours: 1, minutes: 20)), isRead: true),
          ChatMessage(id: 'm4', senderId: '4', senderName: 'Carlo Reyes', text: 'Perfect. For 40 households I\'d recommend the 25kW industrial package. I can arrange a pilot for 10 units with a 6-month performance guarantee. Let me send you the technical specs and pricing sheet.', timestamp: now.subtract(const Duration(minutes: 50)), isRead: true),
          ChatMessage(id: 'm5', senderId: '3', senderName: 'Maria Santos', text: 'That sounds great! Are there financing options available? Our cooperative may qualify for DA-DILG grants.', timestamp: now.subtract(const Duration(minutes: 15)), isRead: false),
        ],
      ),
      Conversation(
        id: 'conv_2',
        productId: 1,
        productName: 'Smart Rice Monitoring System',
        productCategory: 'Agriculture',
        innovatorId: '2',
        innovatorName: 'Juan dela Cruz',
        clientId: '3',
        clientName: 'Maria Santos',
        lastActivity: now.subtract(const Duration(days: 1)),
        messages: [
          ChatMessage(id: 'm6', senderId: '3', senderName: 'Maria Santos', text: 'Juan, your rice monitoring system is exactly what our AgriTech fund has been looking for. We\'d like to discuss a potential investment and pilot in Cagayan Valley.', timestamp: now.subtract(const Duration(days: 1, hours: 3)), isRead: true),
          ChatMessage(id: 'm7', senderId: '2', senderName: 'Juan dela Cruz', text: 'Maria! This is exciting news. Our system has already been validated in 3 municipalities in Nueva Ecija with 23% average yield improvement. I\'d love to discuss Cagayan Valley deployment.', timestamp: now.subtract(const Duration(days: 1, hours: 2)), isRead: true),
          ChatMessage(id: 'm8', senderId: '3', senderName: 'Maria Santos', text: 'Those numbers are impressive. Can you share the validation reports? We\'ll need them for our investment committee review next month.', timestamp: now.subtract(const Duration(days: 1)), isRead: true),
        ],
      ),
      Conversation(
        id: 'conv_3',
        productId: 2,
        productName: 'AI-Assisted Diabetic Retinopathy Screener',
        productCategory: 'Healthcare',
        innovatorId: '3',
        innovatorName: 'Maria Santos',
        clientId: '7',
        clientName: 'Dr. Pedro Tan',
        lastActivity: now.subtract(const Duration(days: 3)),
        messages: [
          ChatMessage(id: 'm9', senderId: '7', senderName: 'Dr. Pedro Tan', text: 'We\'re looking to integrate AI screening tools in our 5 provincial hospitals in Davao Region. Your retinopathy screener looks promising.', timestamp: now.subtract(const Duration(days: 3, hours: 5)), isRead: true),
          ChatMessage(id: 'm10', senderId: '3', senderName: 'Maria Santos', text: 'Dr. Tan, thank you for your interest. Our model achieves 94.2% sensitivity and 91.8% specificity on the validation set. It\'s designed to work with standard fundus cameras already deployed in PhilHealth-accredited facilities.', timestamp: now.subtract(const Duration(days: 3, hours: 4)), isRead: true),
          ChatMessage(id: 'm11', senderId: '7', senderName: 'Dr. Pedro Tan', text: 'FDA-clearance and PHAP compliance documentation?', timestamp: now.subtract(const Duration(days: 3)), isRead: true),
        ],
      ),
    ]);
  }

  void openConversation(String id) {
    // Mark messages as read
    final updated = state.conversations.map((c) {
      if (c.id != id) return c;
      return c.copyWith(
        messages: c.messages.map((m) => m.copyWith(isRead: true)).toList(),
      );
    }).toList();
    state = state.copyWith(conversations: updated, activeConversationId: id);
  }

  void closeConversation() => state = state.copyWith(clearActive: true);

  Future<void> sendMessage(String conversationId, String senderId, String senderName, String text) async {
    if (text.trim().isEmpty) return;
    state = state.copyWith(isSending: true);

    await Future.delayed(const Duration(milliseconds: 150)); // simulate network

    final msg = ChatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      senderId: senderId,
      senderName: senderName,
      text: text.trim(),
      timestamp: DateTime.now(),
      isRead: false,
    );

    final updated = state.conversations.map((c) {
      if (c.id != conversationId) return c;
      return c.copyWith(
        messages: [...c.messages, msg],
        lastActivity: DateTime.now(),
      );
    }).toList();

    // Sort by lastActivity
    updated.sort((a, b) => b.lastActivity.compareTo(a.lastActivity));

    state = state.copyWith(conversations: updated, isSending: false);
  }

  /// Start a new conversation from product detail / express interest
  String startOrGetConversation({
    required int productId,
    required String productName,
    required String productCategory,
    required String innovatorId,
    required String innovatorName,
    required String clientId,
    required String clientName,
  }) {
    final existing = state.conversations.where(
      (c) => c.productId == productId && c.clientId == clientId,
    ).firstOrNull;

    if (existing != null) {
      openConversation(existing.id);
      return existing.id;
    }

    final newConv = Conversation(
      id: 'conv_${DateTime.now().millisecondsSinceEpoch}',
      productId: productId,
      productName: productName,
      productCategory: productCategory,
      innovatorId: innovatorId,
      innovatorName: innovatorName,
      clientId: clientId,
      clientName: clientName,
      messages: [],
      lastActivity: DateTime.now(),
    );

    state = state.copyWith(
      conversations: [newConv, ...state.conversations],
      activeConversationId: newConv.id,
    );
    return newConv.id;
  }

  int get totalUnread {
    // This would use current user id — kept simple for now
    return state.conversations.fold(0, (sum, c) => sum + c.unreadCount('3'));
  }
}

final messagingProvider = StateNotifierProvider<MessagingNotifier, MessagingState>(
  (ref) => MessagingNotifier(),
);