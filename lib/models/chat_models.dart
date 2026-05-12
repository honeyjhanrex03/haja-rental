import 'package:intl/intl.dart';

class Conversation {
  final String id;
  final String buyerId;
  final String sellerId;
  final String? itemId;
  final DateTime createdAt;
  final String? otherUserName;
  final String? otherUserAvatar;
  final String? lastMessage;
  final DateTime? lastMessageTime;

  Conversation({
    required this.id,
    required this.buyerId,
    required this.sellerId,
    this.itemId,
    required this.createdAt,
    this.otherUserName,
    this.otherUserAvatar,
    this.lastMessage,
    this.lastMessageTime,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'],
      buyerId: json['buyer_id'],
      sellerId: json['seller_id'],
      itemId: json['item_id'],
      createdAt: DateTime.parse(json['created_at']),
      // These will be joined from profiles
      otherUserName: json['other_user_name'],
      otherUserAvatar: json['other_user_avatar'],
      lastMessage: json['last_message'],
      lastMessageTime: json['last_message_time'] != null 
          ? DateTime.parse(json['last_message_time']) 
          : null,
    );
  }
}

class DirectMessage {
  final String id;
  final String conversationId;
  final String senderId;
  final String text;
  final bool isRead;
  final DateTime createdAt;

  DirectMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.text,
    required this.isRead,
    required this.createdAt,
  });

  factory DirectMessage.fromJson(Map<String, dynamic> json) {
    return DirectMessage(
      id: json['id'],
      conversationId: json['conversation_id'],
      senderId: json['sender_id'],
      text: json['text'],
      isRead: json['is_read'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'conversation_id': conversationId,
      'sender_id': senderId,
      'text': text,
      'is_read': isRead,
    };
  }

  String get formattedTime => DateFormat('hh:mm a').format(createdAt.toLocal());
}
