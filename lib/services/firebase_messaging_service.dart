import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pawsmatch/models/message.dart';
import 'package:pawsmatch/services/firebase_account_service.dart';
import 'package:pawsmatch/services/firebase_organization_service.dart';
import 'package:pawsmatch/services/firebase_profile_service.dart';

class FirebaseMessagingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DatabaseAccountService _accountService = DatabaseAccountService();
  final FirebaseProfileService _profileService = FirebaseProfileService();
  final FirebaseOrganizationService _organizationService = FirebaseOrganizationService();
  
  final CollectionReference _threadsCollection = 
      FirebaseFirestore.instance.collection('message_threads');
  final CollectionReference _messagesCollection = 
      FirebaseFirestore.instance.collection('messages');

  Stream<List<MessageThread>> getThreadsForCurrentUser() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }

    return _threadsCollection
        .where('participant_ids', arrayContains: currentUser.uid)
        .orderBy('last_message_time', descending: true)
        .snapshots()
        .handleError((error) {
          print('Error fetching message threads: $error');
          return [];
        })
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => MessageThread.fromJson(doc.data() as Map<String, dynamic>))
              .toList();
        });
  }

  // Fallback method that doesn't require the composite index
  // Use this temporarily if the index creation is delayed
  Future<List<MessageThread>> getThreadsForCurrentUserFallback() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return [];
    }

    try {
      // Just filter by participant_ids without ordering
      final querySnapshot = await _threadsCollection
          .where('participant_ids', arrayContains: currentUser.uid)
          .get();
      
      // Convert to thread objects
      final threads = querySnapshot.docs
          .map((doc) => MessageThread.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
      
      // Sort in-memory instead of in the query
      threads.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
      
      return threads;
    } catch (e) {
      print('Error in fallback thread fetching: $e');
      return [];
    }
  }

  // Get messages for a specific thread
  Stream<List<Message>> getMessagesForThread(String threadId) {
    return _messagesCollection
        .where('thread_id', isEqualTo: threadId)
        .orderBy('timestamp')
        .snapshots()
        .handleError((error) {
          print('Error fetching messages: $error');
          // Return empty list if there's an error (e.g., missing index)
          return [];
        })
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Message.fromJson(doc.data() as Map<String, dynamic>))
              .toList();
        });
  }

  // Fallback method to get messages without ordering
  Future<List<Message>> getMessagesForThreadFallback(String threadId) async {
    try {
      final querySnapshot = await _messagesCollection
          .where('thread_id', isEqualTo: threadId)
          .get();
      
      // Convert to Message objects
      final messages = querySnapshot.docs
          .map((doc) => Message.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
      
      // Sort in-memory instead of in the query
      messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      
      return messages;
    } catch (e) {
      print('Error in fallback message fetching: $e');
      return [];
    }
  }

  // Create new thread or get existing one between user and organization
  Future<String> createOrGetThreadId(String organizationId, {String? petId}) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    // Check if thread already exists
    final querySnapshot = await _threadsCollection
        .where('participant_ids', arrayContains: currentUser.uid)
        .get();
    
    for (var doc in querySnapshot.docs) {
      final thread = MessageThread.fromJson(doc.data() as Map<String, dynamic>);
      if (thread.participantIds.contains(organizationId)) {
        // Thread exists
        return thread.threadId;
      }
    }

    // Thread doesn't exist, create a new one
    final String threadId = _firestore.collection('message_threads').doc().id;
    
    // Get current user's name
    final Map<String, String> dashboardInfo = 
        await _profileService.getUserDashboardInfo();
    final String userName = dashboardInfo['displayName'] ?? 'User';
    
    // Get organization name
    final organization = await _organizationService.getOrganizationById(organizationId);
    final String orgName = organization?.org_name ?? 'Organization';
    
    // Create thread participants info
    final Map<String, String> participantNames = {
      currentUser.uid: userName,
      organizationId: orgName,
    };
    
    // Create unread status (initially false for both)
    final Map<String, bool> unreadByUser = {
      currentUser.uid: false,
      organizationId: false,
    };
    
    // Create thread
    final MessageThread newThread = MessageThread(
      threadId: threadId,
      participantIds: [currentUser.uid, organizationId],
      participantNames: participantNames,
      lastMessageTime: DateTime.now(),
      lastMessageContent: petId != null 
          ? "New adoption inquiry" 
          : "New conversation",
      lastMessageSenderId: currentUser.uid,
      unreadByUser: unreadByUser,
    );
    
    await _threadsCollection.doc(threadId).set(newThread.toJson());
    return threadId;
  }

  // Send a message
  Future<void> sendMessage({
    required String threadId,
    required String receiverId,
    required String content,
  }) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }
    
    // Get sender's name
    final Map<String, String> dashboardInfo = 
        await _profileService.getUserDashboardInfo();
    final String senderName = dashboardInfo['displayName'] ?? 'User';

    // Create message
    final String messageId = _firestore.collection('messages').doc().id;
    final Message message = Message(
      messageId: messageId,
      threadId: threadId,
      senderId: currentUser.uid,
      receiverId: receiverId,
      senderName: senderName,
      content: content,
      timestamp: DateTime.now(),
    );
    
    // Add message to database
    await _messagesCollection.doc(messageId).set(message.toJson());
    
    // Update thread with latest message info
    await _threadsCollection.doc(threadId).update({
      'last_message_time': Timestamp.fromDate(message.timestamp),
      'last_message_content': content,
      'last_message_sender_id': currentUser.uid,
      'unread_by_user.$receiverId': true,
    });
  }

  // Mark messages as read
  Future<void> markThreadAsRead(String threadId) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }
    
    await _threadsCollection.doc(threadId).update({
      'unread_by_user.${currentUser.uid}': false,
    });
    
    // Mark all unread messages as read
    final querySnapshot = await _messagesCollection
        .where('thread_id', isEqualTo: threadId)
        .where('receiver_id', isEqualTo: currentUser.uid)
        .where('is_read', isEqualTo: false)
        .get();
    
    final batch = _firestore.batch();
    for (var doc in querySnapshot.docs) {
      batch.update(doc.reference, {'is_read': true});
    }
    
    await batch.commit();
  }
  
  FirebaseProfileService get profileService => _profileService;
  
  FirebaseOrganizationService get organizationService => _organizationService;
}
