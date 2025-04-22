import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String messageId;
  final String threadId;
  final String senderId;
  final String receiverId;
  final String senderName;
  final String content;
  final DateTime timestamp;
  final bool isRead;
  final String? senderAvatarUrl;

  Message({
    required this.messageId,
    required this.threadId,
    required this.senderId,
    required this.receiverId,
    required this.senderName,
    required this.content,
    required this.timestamp,
    this.isRead = false,
    this.senderAvatarUrl,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      messageId: json['message_id'] as String,
      threadId: json['thread_id'] as String,
      senderId: json['sender_id'] as String,
      receiverId: json['receiver_id'] as String,
      senderName: json['sender_name'] as String,
      content: json['content'] as String,
      timestamp: (json['timestamp'] as Timestamp).toDate(),
      isRead: json['is_read'] as bool? ?? false,
      senderAvatarUrl: json['sender_avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message_id': messageId,
      'thread_id': threadId,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'sender_name': senderName,
      'content': content,
      'timestamp': Timestamp.fromDate(timestamp),
      'is_read': isRead,
      'sender_avatar_url': senderAvatarUrl,
    };
  }
}

class MessageThread {
  final String threadId;
  final List<String> participantIds;
  final Map<String, String> participantNames;
  final DateTime lastMessageTime;
  final String lastMessageContent;
  final String lastMessageSenderId;
  final Map<String, bool> unreadByUser;

  MessageThread({
    required this.threadId,
    required this.participantIds,
    required this.participantNames,
    required this.lastMessageTime,
    required this.lastMessageContent,
    required this.lastMessageSenderId,
    required this.unreadByUser,
  });

  factory MessageThread.fromJson(Map<String, dynamic> json) {
    return MessageThread(
      threadId: json['thread_id'] as String,
      participantIds: List<String>.from(json['participant_ids']),
      participantNames: Map<String, String>.from(json['participant_names']),
      lastMessageTime: (json['last_message_time'] as Timestamp).toDate(),
      lastMessageContent: json['last_message_content'] as String,
      lastMessageSenderId: json['last_message_sender_id'] as String,
      unreadByUser: Map<String, bool>.from(json['unread_by_user']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'thread_id': threadId,
      'participant_ids': participantIds,
      'participant_names': participantNames,
      'last_message_time': Timestamp.fromDate(lastMessageTime),
      'last_message_content': lastMessageContent,
      'last_message_sender_id': lastMessageSenderId,
      'unread_by_user': unreadByUser,
    };
  }
}
