import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String messageId;
  final String threadId;
  final String senderId;
  final String receiverId;
  final String senderName;
  final String content;
  final DateTime timestamp;
  bool isRead;
  String? senderAvatarUrl;

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
  
  // New fields for enhanced participant info
  final Map<String, String?> participantAvatars;
  final Map<String, bool> participantIsOrg;
  final Map<String, bool> participantIsVerified;

  MessageThread({
    required this.threadId,
    required this.participantIds,
    required this.participantNames,
    required this.lastMessageTime,
    required this.lastMessageContent,
    required this.lastMessageSenderId,
    required this.unreadByUser,
    Map<String, String?>? participantAvatars,
    Map<String, bool>? participantIsOrg,
    Map<String, bool>? participantIsVerified,
  }) : 
    participantAvatars = participantAvatars ?? {},
    participantIsOrg = participantIsOrg ?? {},
    participantIsVerified = participantIsVerified ?? {};

  factory MessageThread.fromJson(Map<String, dynamic> json) {
    // Parse participant avatars if available
    Map<String, String?> participantAvatars = {};
    if (json['participant_avatars'] != null) {
      final avatars = json['participant_avatars'] as Map<String, dynamic>;
      avatars.forEach((key, value) {
        participantAvatars[key] = value as String?;
      });
    }
    
    // Parse participant organization status
    Map<String, bool> participantIsOrg = {};
    if (json['participant_is_org'] != null) {
      final orgs = json['participant_is_org'] as Map<String, dynamic>;
      orgs.forEach((key, value) {
        participantIsOrg[key] = value as bool? ?? false;
      });
    }
    
    // Parse participant verified status
    Map<String, bool> participantIsVerified = {};
    if (json['participant_is_verified'] != null) {
      final verified = json['participant_is_verified'] as Map<String, dynamic>;
      verified.forEach((key, value) {
        participantIsVerified[key] = value as bool? ?? false;
      });
    }
    
    return MessageThread(
      threadId: json['thread_id'] as String,
      participantIds: List<String>.from(json['participant_ids']),
      participantNames: Map<String, String>.from(json['participant_names']),
      lastMessageTime: (json['last_message_time'] as Timestamp).toDate(),
      lastMessageContent: json['last_message_content'] as String,
      lastMessageSenderId: json['last_message_sender_id'] as String,
      unreadByUser: Map<String, bool>.from(json['unread_by_user']),
      participantAvatars: participantAvatars,
      participantIsOrg: participantIsOrg,
      participantIsVerified: participantIsVerified,
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
      'participant_avatars': participantAvatars,
      'participant_is_org': participantIsOrg,
      'participant_is_verified': participantIsVerified,
    };
  }
  
  // Helper method to get the other participant (not the current user)
  String? getOtherParticipantId(String currentUserId) {
    try {
      return participantIds
          .firstWhere((id) => id != currentUserId, orElse: () => '');
    } catch (e) {
      return null;
    }
  }
}
