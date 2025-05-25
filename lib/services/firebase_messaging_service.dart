import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pawsmatch/models/message.dart';
import 'package:pawsmatch/models/account.dart';
import 'package:pawsmatch/models/organization.dart';
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
  final CollectionReference _accountsCollection =
      FirebaseFirestore.instance.collection('accounts');
  final CollectionReference _organizationsCollection =
      FirebaseFirestore.instance.collection('organizations');
      
  // In-memory cache for participant data to reduce database calls
  final Map<String, ParticipantData> _participantCache = {};

  // Get threads with enhanced participant info - avoid using orderBy
  Stream<List<MessageThread>> getThreadsForCurrentUser({String? organizationId}) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }

    // Use organization ID if provided, otherwise fall back to user ID
    final participantId = organizationId ?? currentUser.uid;

    // Only allow organizationId for org inboxes
    if (organizationId != null && organizationId.isEmpty) {
      return Stream.value([]);
    }

    try {
      return _threadsCollection
          .where('participant_ids', arrayContains: participantId)
          .snapshots()
          .asyncMap((snapshot) async {
            final threads = snapshot.docs
                .map((doc) => MessageThread.fromJson(doc.data() as Map<String, dynamic>))
                .toList();

            threads.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
            await _enhanceThreadsWithParticipantData(threads);
            return threads;
          });
    } catch (e) {
      print('Error setting up message threads stream: $e');
      return Stream.value([]);
    }
  }

  // Enhanced fallback method with participant data
  Future<List<MessageThread>> getThreadsForCurrentUserFallback({String? organizationId}) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return [];
    }

    // Use organization ID if provided, otherwise fall back to user ID
    final participantId = organizationId ?? currentUser.uid;

    // If organizationId is required but not provided, return empty
    if (organizationId != null && organizationId.isEmpty) {
      return [];
    }

    try {
      print('Using fallback method to get message threads for participant: $participantId');

      final querySnapshot = await _threadsCollection
          .where('participant_ids', arrayContains: participantId)
          .get();

      final threads = querySnapshot.docs
          .map((doc) => MessageThread.fromJson(doc.data() as Map<String, dynamic>))
          .toList();

      threads.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
      await _enhanceThreadsWithParticipantData(threads);

      print('Successfully retrieved ${threads.length} message threads with fallback method');
      return threads;
    } catch (e) {
      print('Error in fallback thread fetching: $e');
      
      // Last resort approach: Manual document fetching
      try {
        print('Trying manual thread fetching approach');
        final userThreadsRaw = await _firestore
            .collection('message_threads')
            .get();
        
        // Filter manually
        List<MessageThread> userThreads = [];
        for (var doc in userThreadsRaw.docs) {
          try {
            final data = doc.data();
            if (data['participant_ids'] != null) {
              List<dynamic> participantIds = data['participant_ids'];
              if (participantIds.contains(participantId)) {
                userThreads.add(MessageThread.fromJson(data));
              }
            }
          } catch (err) {
            print('Error parsing thread: $err');
          }
        }
        
        // Sort manually
        userThreads.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
        
        // Enhance threads with participant info
        await _enhanceThreadsWithParticipantData(userThreads);
        
        print('Successfully retrieved ${userThreads.length} message threads with manual approach');
        return userThreads;
      } catch (finalError) {
        print('All thread fetching approaches failed: $finalError');
        return [];
      }
    }
  }

  // Enhance message threads with additional participant info (avatars, status, etc.)
  Future<void> _enhanceThreadsWithParticipantData(List<MessageThread> threads) async {
    if (threads.isEmpty) return;
    
    // Collect unique participant IDs from all threads
    final Set<String> participantIds = {};
    for (final thread in threads) {
      participantIds.addAll(thread.participantIds);
    }
    
    // Remove already cached participants
    final uncachedParticipantIds = participantIds
        .where((id) => !_participantCache.containsKey(id))
        .toList();
    
    if (uncachedParticipantIds.isNotEmpty) {
      // Batch fetch participant data for uncached participants
      final participantData = await _batchFetchParticipantData(uncachedParticipantIds);
      
      // Update cache with new data
      _participantCache.addAll(participantData);
    }
    
    // Now enhance each thread with the participant data from cache
    for (final thread in threads) {
      _enhanceThreadWithCachedData(thread);
    }
  }

  // Batch fetch participant data (account users and organizations)
  Future<Map<String, ParticipantData>> _batchFetchParticipantData(List<String> participantIds) async {
    final result = <String, ParticipantData>{};
    
    try {
      // First try to find participants in accounts collection
      final accountsSnapshot = await _accountsCollection
          .where(FieldPath.documentId, whereIn: participantIds.length > 10 
              ? participantIds.sublist(0, 10) // Firestore limit is 10 for whereIn
              : participantIds)
          .get();
      
      // Process accounts
      for (final doc in accountsSnapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          data['account_id'] = doc.id; // Ensure ID is set
          
          final String username = data['account_username'] as String? ?? 'User';
          final accountType = _parseAccountType(data['account_type']);
          
          // Get user profile photo if available
          String? avatarUrl;
          try {
            if (accountType == AccountType.User) {
              final userProfile = await _firestore
                  .collection('profiles')
                  .doc(doc.id)
                  .get();
              
              if (userProfile.exists) {
                avatarUrl = (userProfile.data() as Map<String, dynamic>)['profile_photo_url'] as String?;
              }
            }
          } catch (e) {
            print('Error getting user profile photo: $e');
          }
          
          result[doc.id] = ParticipantData(
            id: doc.id,
            name: username,
            isOrganization: accountType == AccountType.OrgAdmin,
            avatarUrl: avatarUrl,
          );
        } catch (e) {
          print('Error processing account data: $e');
        }
      }
      
      // Next try to find remaining participants in organizations collection
      final remainingIds = participantIds
          .where((id) => !result.containsKey(id))
          .toList();
          
      if (remainingIds.isNotEmpty) {
        final orgsSnapshot = await _organizationsCollection
            .where(FieldPath.documentId, whereIn: remainingIds.length > 10 
                ? remainingIds.sublist(0, 10) 
                : remainingIds)
            .get();
            
        // Process organizations
        for (final doc in orgsSnapshot.docs) {
          try {
            final data = doc.data() as Map<String, dynamic>;
            data['org_id'] = doc.id; // Ensure ID is set
            
            final String orgName = data['org_name'] as String? ?? 'Organization';
            final String? logoUrl = data['logo_url'] as String?;
            
            result[doc.id] = ParticipantData(
              id: doc.id,
              name: orgName,
              isOrganization: true,
              avatarUrl: logoUrl,
              isVerified: data['isVerified'] as bool? ?? false,
            );
          } catch (e) {
            print('Error processing organization data: $e');
          }
        }
      }
      
      // For any remaining IDs, create generic placeholder entries
      for (final id in participantIds) {
        if (!result.containsKey(id)) {
          result[id] = ParticipantData(
            id: id,
            name: 'Unknown User',
            isOrganization: false,
          );
        }
      }
    } catch (e) {
      print('Error batch fetching participant data: $e');
    }
    
    return result;
  }
  
  // Enhance a thread with cached participant data
  void _enhanceThreadWithCachedData(MessageThread thread) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    
    // Find the other participant (not the current user)
    final otherParticipantIds = thread.participantIds
        .where((id) => id != currentUser.uid)
        .toList();
    
    if (otherParticipantIds.isEmpty) return;
    
    // Update thread with participant avatars and additional info
    for (final participantId in thread.participantIds) {
      final participantData = _participantCache[participantId];
      if (participantData != null) {
        // Update participant name if needed
        if (thread.participantNames[participantId] == null || 
            thread.participantNames[participantId]!.isEmpty) {
          thread.participantNames[participantId] = participantData.name;
        }
        
        // Set participant avatar
        thread.participantAvatars[participantId] = participantData.avatarUrl;
        
        // Set organization status
        thread.participantIsOrg[participantId] = participantData.isOrganization;
        
        // Set verified status for organizations
        if (participantData.isOrganization && participantData.isVerified) {
          thread.participantIsVerified[participantId] = true;
        }
      }
    }
  }

  // Get messages for a specific thread - use non-indexed method
  Stream<List<Message>> getMessagesForThread(String threadId) {
    // Create a polling stream using the fallback method
    return Stream.periodic(Duration(seconds: 3))
      .asyncMap((_) => getMessagesForThreadFallback(threadId))
      .handleError((error) {
        print('Error fetching messages: $error');
        return <Message>[];
      });
  }

  // Enhance messages with sender data (avatars, etc.)
  Future<void> _enhanceMessagesWithSenderData(List<Message> messages) async {
    if (messages.isEmpty) return;
    
    // Collect unique sender IDs
    final Set<String> senderIds = messages.map((m) => m.senderId).toSet();
    
    // Remove already cached senders
    final uncachedSenderIds = senderIds
        .where((id) => !_participantCache.containsKey(id))
        .toList();
    
    if (uncachedSenderIds.isNotEmpty) {
      // Batch fetch participant data for uncached senders
      final participantData = await _batchFetchParticipantData(uncachedSenderIds);
      
      // Update cache with new data
      _participantCache.addAll(participantData);
    }
    
    // Enhance each message with sender data from cache
    for (final message in messages) {
      final senderData = _participantCache[message.senderId];
      if (senderData != null && senderData.avatarUrl != null) {
        message.senderAvatarUrl = senderData.avatarUrl;
      }
    }
  }

  // Non-indexed method to get messages
  Future<List<Message>> getMessagesForThreadFallback(String threadId) async {
    try {
      //print('Using non-indexed method to get messages');
      
      final querySnapshot = await _messagesCollection
          .where('thread_id', isEqualTo: threadId)
          .get();
      
      // Convert to Message objects
      final messages = querySnapshot.docs
          .map((doc) => Message.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
      
      // Sort in-memory instead of in the query
      messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      
      // Enhance messages with sender data
      await _enhanceMessagesWithSenderData(messages);
      
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
    
    try {
      // Get both participants' data in parallel for efficiency
      final userData = await _fetchParticipantData(currentUser.uid);
      final orgData = await _fetchParticipantData(organizationId);
      
      // Create thread participants info
      final Map<String, String> participantNames = {
        currentUser.uid: userData?.name ?? 'User',
        organizationId: orgData?.name ?? 'Organization',
      };
      
      // Create participant avatar mapping
      final Map<String, String?> participantAvatars = {
        currentUser.uid: userData?.avatarUrl,
        organizationId: orgData?.avatarUrl,
      };
      
      // Create organization status mapping
      final Map<String, bool> participantIsOrg = {
        currentUser.uid: userData?.isOrganization ?? false,
        organizationId: orgData?.isOrganization ?? true,
      };
      
      // Create verified status mapping
      final Map<String, bool> participantIsVerified = {
        currentUser.uid: userData?.isVerified ?? false,
        organizationId: orgData?.isVerified ?? false,
      };
      
      // Create unread status (initially false for both)
      final Map<String, bool> unreadByUser = {
        currentUser.uid: false,
        organizationId: true, // Set to true for organization to show as unread
      };
      
      // Create thread
      final MessageThread newThread = MessageThread(
        threadId: threadId,
        participantIds: [currentUser.uid, organizationId],
        participantNames: participantNames,
        participantAvatars: participantAvatars,
        participantIsOrg: participantIsOrg,
        participantIsVerified: participantIsVerified,
        lastMessageTime: DateTime.now(),
        lastMessageContent: petId != null 
            ? "New adoption inquiry" 
            : "New conversation",
        lastMessageSenderId: currentUser.uid,
        unreadByUser: unreadByUser,
      );
      
      await _threadsCollection.doc(threadId).set(newThread.toJson());
      return threadId;
    } catch (e) {
      print('Error creating thread: $e');
      
      // Fallback with minimal data if fetching participant details fails
      final Map<String, String> participantNames = {
        currentUser.uid: 'User',
        organizationId: 'Organization',
      };
      
      final Map<String, bool> unreadByUser = {
        currentUser.uid: false,
        organizationId: true,
      };
      
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
    
    try {
      // Get sender's data
      ParticipantData? senderData = _participantCache[currentUser.uid];
      
      if (senderData == null) {
        // Fetch if not in cache
        senderData = await _fetchParticipantData(currentUser.uid);
        
        if (senderData != null) {
          // Update cache
          _participantCache[currentUser.uid] = senderData;
        }
      }
      
      final String senderName = senderData?.name ?? 'User';
      final String? senderAvatarUrl = senderData?.avatarUrl;

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
        senderAvatarUrl: senderAvatarUrl,
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
    } catch (e) {
      print('Error sending message: $e');
      // Fallback to simplified message sending if detailed info fails
      final String messageId = _firestore.collection('messages').doc().id;
      final Message message = Message(
        messageId: messageId,
        threadId: threadId,
        senderId: currentUser.uid,
        receiverId: receiverId,
        senderName: 'User',
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
  }

  // Helper to fetch single participant data
  Future<ParticipantData?> _fetchParticipantData(String participantId) async {
    // Check cache first
    if (_participantCache.containsKey(participantId)) {
      return _participantCache[participantId];
    }
    
    try {
      // Try account collection first
      final accountDoc = await _accountsCollection.doc(participantId).get();
      
      if (accountDoc.exists) {
        final data = accountDoc.data() as Map<String, dynamic>;
        final String username = data['account_username'] as String? ?? 'User';
        final accountType = _parseAccountType(data['account_type']);
        
        // Get user profile photo if available
        String? avatarUrl;
        try {
          if (accountType == AccountType.User) {
            final userProfile = await _firestore
                .collection('profiles')
                .doc(participantId)
                .get();
            
            if (userProfile.exists) {
              avatarUrl = (userProfile.data() as Map<String, dynamic>)['profile_photo_url'] as String?;
            }
          }
        } catch (e) {
          print('Error getting user profile photo: $e');
        }
        
        final participantData = ParticipantData(
          id: participantId,
          name: username,
          isOrganization: accountType == AccountType.OrgAdmin,
          avatarUrl: avatarUrl,
        );
        
        _participantCache[participantId] = participantData;
        return participantData;
      }
      
      // Try organization collection if not in accounts
      final orgDoc = await _organizationsCollection.doc(participantId).get();
      
      if (orgDoc.exists) {
        final data = orgDoc.data() as Map<String, dynamic>;
        final String orgName = data['org_name'] as String? ?? 'Organization';
        final String? logoUrl = data['logo_url'] as String?;
        final bool isVerified = data['isVerified'] as bool? ?? false;
        
        final participantData = ParticipantData(
          id: participantId,
          name: orgName,
          isOrganization: true,
          avatarUrl: logoUrl,
          isVerified: isVerified,
        );
        
        _participantCache[participantId] = participantData;
        return participantData;
      }
      
      // Not found in either collection
      return null;
    } catch (e) {
      print('Error fetching participant data: $e');
      return null;
    }
  }

  // Mark messages as read - avoid compound queries
  Future<void> markThreadAsRead(String threadId) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }
    
    // Update thread's unread status
    await _threadsCollection.doc(threadId).update({
      'unread_by_user.${currentUser.uid}': false,
    });
    
    // Get all unread messages without the compound query
    try {
      final querySnapshot = await _messagesCollection
          .where('thread_id', isEqualTo: threadId)
          .get();
          
      // Find messages to mark as read
      final batch = _firestore.batch();
      for (var doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final receiverId = data['receiver_id'] as String?;
        final isRead = data['is_read'] as bool? ?? false;
        
        if (receiverId == currentUser.uid && !isRead) {
          batch.update(doc.reference, {'is_read': true});
        }
      }
      
      await batch.commit();
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }
  
  // Parse account type with better error handling
  AccountType _parseAccountType(dynamic value) {
    if (value == null) return AccountType.User;
    
    if (value is String) {
      switch (value.toLowerCase()) {
        case 'orgadmin':
        case 'org_admin':
          return AccountType.OrgAdmin;
        case 'moderator':
          return AccountType.Moderator;
        case 'user':
        default:
          return AccountType.User;
      }
    }
    
    return AccountType.User;
  }
  
  // Clear cache (useful for testing or when user signs out)
  void clearCache() {
    _participantCache.clear();
  }
  
  // Getters for services
  FirebaseProfileService get profileService => _profileService;
  FirebaseOrganizationService get organizationService => _organizationService;
  
  // Add this method to get a single thread by ID
  Stream<MessageThread?> getThreadById(String threadId) {
    if (threadId.isEmpty) return Stream.value(null);
    
    return FirebaseFirestore.instance
        .collection('message_threads')
        .doc(threadId)
        .snapshots()
        .map((snapshot) {
          if (!snapshot.exists) return null;
          return MessageThread.fromJson(snapshot.data()!);
        });
  }
}

// Helper class to store participant data
class ParticipantData {
  final String id;
  final String name;
  final bool isOrganization;
  final String? avatarUrl;
  final bool isVerified;
  
  ParticipantData({
    required this.id,
    required this.name,
    required this.isOrganization,
    this.avatarUrl,
    this.isVerified = false,
  });
}
