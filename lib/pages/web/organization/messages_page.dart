import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:pawsmatch/services/firebase_organization_service.dart';
import 'org_sidebar.dart';
import 'package:pawsmatch/models/message.dart';
import 'package:pawsmatch/services/firebase_messaging_service.dart';
import 'package:pawsmatch/services/firebase_profile_service.dart';
import 'package:pawsmatch/widgets/message_thread_view.dart';
import 'package:pawsmatch/widgets/user_profile_image.dart'; // Add this import for user profile image

class MessagesPage extends StatefulWidget {
  final String? initialThreadId;
  final String? recipientId;
  final String? recipientName;

  const MessagesPage({
    Key? key, 
    this.initialThreadId,
    this.recipientId,
    this.recipientName,
  }) : super(key: key);

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  final FirebaseMessagingService _messagingService = FirebaseMessagingService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _searchController = TextEditingController();
  final FirebaseOrganizationService _organizationService = FirebaseOrganizationService();
  final FirebaseProfileService _profileService = FirebaseProfileService(); // Add this line
  
  String _searchQuery = '';
  List<MessageThread> _threads = [];
  bool _isLoading = true;
  String? _selectedThreadId;
  bool _showDebugInfo = false;
  String _debugInfo = '';
  String? _currentOrgID;
  bool _orgIdResolved = false; // Track if org ID is resolved
  
  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });

    // Only load threads after org ID is resolved
    _initializeOrganizationData();
    // Remove: _loadThreadsFallback();

    if (widget.initialThreadId != null) {
      _openThread(widget.initialThreadId!, widget.recipientId, widget.recipientName);
    }
  }

  // Initialize organization data
  Future<void> _initializeOrganizationData() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      try {
        _currentOrgID = await _organizationService.getOrganizationIDById(currentUser.uid);
        print('Current org ID: $_currentOrgID');
        if (mounted) {
          setState(() {
            _orgIdResolved = true;
          });
          // Only load threads after org ID is resolved
          _loadThreadsFallback();
        }
      } catch (e) {
        print('Error getting organization ID: $e');
        if (mounted) {
          setState(() {
            _orgIdResolved = true;
          });
        }
      }
    } else {
      print('No current user found');
      setState(() {
        _orgIdResolved = true;
      });
    }
  }

  Future<void> _loadThreadsFallback() async {
    if (_currentOrgID == null) {
      setState(() {
        _threads = [];
        _isLoading = false;
        _debugInfo += '\nNo organization ID available, cannot load threads.';
      });
      return;
    }
    try {
      setState(() {
        _debugInfo = 'Starting thread fetch for organization...';
        _isLoading = true;
      });

      final threads = await _messagingService.getThreadsForCurrentUserFallback(
        organizationId: _currentOrgID
      );

      if (mounted) {
        setState(() {
          _threads = threads;
          _isLoading = false;
          _debugInfo += '\nFetched ${threads.length} threads';
          _debugInfo += '\nUsed organization ID: $_currentOrgID';
        });
      }
    } catch (e) {
      print("Error in fallback loading: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
          _debugInfo += '\nError: $e';
        });
      }
    }
  }
  
  // Create a test conversation for debugging purposes
  Future<void> _createTestConversation() async {
    try {
      setState(() {
        _debugInfo = 'Creating test conversation...';
        _isLoading = true;
      });
      
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        setState(() {
          _debugInfo += '\nNo authenticated user.';
          _isLoading = false;
        });
        return;
      }
      
      // Create a thread with a test user
      final testUserId = 'test_adopter_${DateTime.now().millisecondsSinceEpoch}';
      final threadId = FirebaseFirestore.instance.collection('message_threads').doc().id;
      
      final threadData = {
        'thread_id': threadId,
        'participant_ids': [currentUser.uid, testUserId],
        'participant_names': {
          currentUser.uid: 'Your Organization',
          testUserId: 'Test Adopter',
        },
        'participant_avatars': {
          currentUser.uid: null,
          testUserId: null,
        },
        'last_message_time': Timestamp.now(),
        'last_message_content': "Hi, I'd like to adopt one of your pets!",
        'last_message_sender_id': testUserId,
        'unread_by_user': {
          currentUser.uid: true,
          testUserId: false,
        },
      };
      
      await FirebaseFirestore.instance.collection('message_threads').doc(threadId).set(threadData);
      
      setState(() {
        _debugInfo += '\nTest thread created with ID: $threadId';
      });
      
      // Add a test message
      final messageId = FirebaseFirestore.instance.collection('messages').doc().id;
      final messageData = {
        'message_id': messageId,
        'thread_id': threadId,
        'sender_id': testUserId,
        'receiver_id': currentUser.uid,
        'sender_name': 'Test Adopter',
        'content': "Hi, I'd like to adopt one of your pets! Is the cute German Shepherd still available?",
        'timestamp': Timestamp.now(),
        'is_read': false,
      };
      
      await FirebaseFirestore.instance.collection('messages').doc(messageId).set(messageData);
      setState(() {
        _debugInfo += '\nTest message created.';
      });
      
      // Reload threads
      await _loadThreadsFallback();
      
    } catch (e) {
      setState(() {
        _debugInfo += '\nError creating test conversation: $e';
        _isLoading = false;
      });
    }
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  // Format timestamp in relation to current time
  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inDays > 7) {
      // Over a week ago, show the date
      return DateFormat('MMM d').format(timestamp);
    } else if (difference.inDays > 0) {
      // Days ago
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      // Hours ago
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      // Minutes ago
      return '${difference.inMinutes}m';
    } else {
      // Just now
      return 'now';
    }
  }

  // Get thread preview by limiting message length
  String _getMessagePreview(String message) {
    if (message.length <= 40) return message;
    return message.substring(0, 37) + '...';
  }
  
  // Filter threads based on search query
  List<MessageThread> _getFilteredThreads(List<MessageThread> threads) {
    if (_searchQuery.isEmpty) return threads;
    
    return threads.where((thread) {
      // Get the other participant's name (not the current user)
      final currentUserId = _auth.currentUser?.uid ?? '';
      
      // Use the resolved org ID if available, otherwise fall back to the user ID
      final participantId = _currentOrgID ?? currentUserId;
      
      final otherParticipants = thread.participantIds
          .where((id) => id != participantId)
          .toList();
      
      if (otherParticipants.isEmpty) return false;
      
      // Check if any participant's name contains the search query
      for (final participantId in otherParticipants) {
        final participantName = thread.participantNames[participantId] ?? '';
        if (participantName.toLowerCase().contains(_searchQuery)) {
          return true;
        }
      }
      
      // Check if the last message contains the search query
      return thread.lastMessageContent.toLowerCase().contains(_searchQuery);
    }).toList();
  }
  
  // Method to open a specific conversation thread
  void _openThread(String threadId, String? recipientId, String? recipientName) {
    // Implementation would load messages for this thread
    print('Opening thread: $threadId with $recipientName (ID: $recipientId)');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEF5F0),
      floatingActionButton: _showDebugInfo ? FloatingActionButton(
        onPressed: _createTestConversation,
        backgroundColor: Color(0xFFC0D6B6),
        child: Icon(Icons.add_comment),
      ) : null,
      body: Center(
        child: Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child: Stack(
            children: [
              // Sidebar navigation
              const Positioned(
                left: 0,
                top: 0,
                child: OrgSidebar(),
              ),
              
              // Debug button in corner
              Positioned(
                right: 20,
                top: 20,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _showDebugInfo = !_showDebugInfo;
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _showDebugInfo ? Color(0xFFC0D6B6) : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.bug_report, 
                      color: _showDebugInfo ? Colors.white : Colors.grey.shade400,
                    ),
                  ),
                ),
              ),
              
              // Debug info panel
              if (_showDebugInfo)
                Positioned(
                  right: 20,
                  top: 60,
                  width: 300,
                  height: 200,
                  child: Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 5,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Debug Info', 
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            IconButton(
                              icon: Icon(Icons.refresh, size: 16),
                              onPressed: _loadThreadsFallback,
                              padding: EdgeInsets.zero,
                              constraints: BoxConstraints(),
                            ),
                          ],
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            child: Text(_debugInfo),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              
              // Messages interface container - responsive positioning
              Positioned(
                left: 400,
                top: 56,
                right: 20,
                bottom: 20,
                child: _orgIdResolved
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Threads sidebar with fixed width
                        Container(
                          width: 380,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              // Header section
                              Container(
                                padding: EdgeInsets.fromLTRB(24, 28, 24, 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Title with badge
                                    Row(
                                      children: [
                                        Text(
                                          'Messages',
                                          style: TextStyle(
                                            color: const Color(0xFF545454),
                                            fontSize: 32,
                                            fontFamily: 'DM Sans',
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        SizedBox(width: 12),
                                        Container(
                                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Color(0xFFC0D6B6),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: StreamBuilder<List<MessageThread>>(
                                            stream: _messagingService.getThreadsForCurrentUser(
                                              organizationId: _currentOrgID
                                            ),
                                            builder: (context, snapshot) {
                                              final threadCount = snapshot.hasData ? 
                                                  snapshot.data!.length : _threads.length;
                                              return Text(
                                                '$threadCount',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 14,
                                                  fontFamily: 'DM Sans',
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              );
                                            }
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 8),
                                    
                                    // Subtitle with generic description
                                    Text(
                                      'Conversations with users about your pets',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 14,
                                        fontFamily: 'DM Sans',
                                      ),
                                    ),
                                    
                                    SizedBox(height: 20),
                                    
                                    // Search bar with generic hint
                                    Container(
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF5F5F5),
                                        borderRadius: BorderRadius.circular(24),
                                      ),
                                      child: TextField(
                                        controller: _searchController,
                                        decoration: InputDecoration(
                                          filled: true,
                                          fillColor: const Color(0xFFF5F5F5),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(24),
                                            borderSide: BorderSide.none,
                                          ),
                                          contentPadding: EdgeInsets.symmetric(vertical: 4, horizontal: 22),
                                          hintText: 'Search conversations',
                                          hintStyle: TextStyle(
                                            color: Colors.black.withOpacity(0.5),
                                            fontSize: 16,
                                            fontFamily: 'DM Sans',
                                            fontWeight: FontWeight.w400,
                                          ),
                                          prefixIcon: Icon(
                                            Icons.search,
                                            color: Colors.black.withOpacity(0.5),
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Divider
                              Container(
                                height: 1,
                                color: Colors.grey.shade200,
                              ),
                              
                              // Threads list with improved error handling
                              Expanded(
                                child: StreamBuilder<List<MessageThread>>(
                                  stream: _currentOrgID == null
                                    ? Stream.value([])
                                    : _messagingService.getThreadsForCurrentUser(
                                        organizationId: _currentOrgID
                                      ),
                                  builder: (context, snapshot) {
                                    // Handle loading state with skeleton loaders
                                    if (snapshot.connectionState == ConnectionState.waiting && _isLoading) {
                                      return _buildLoadingThreads();
                                    }
                                    
                                    // Use stream data if available, otherwise use fallback data
                                    final List<MessageThread> threadsToDisplay;
                                    if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                                      threadsToDisplay = snapshot.data!;
                                      _threads = threadsToDisplay; // Update stored threads
                                    } else {
                                      // If stream fails, use our cached threads
                                      threadsToDisplay = _threads;
                                      
                                      // If both are empty, show empty state
                                      if (threadsToDisplay.isEmpty) {
                                        return _buildEmptyThreadsList();
                                      }
                                    }
                                    
                                    // Apply search filter
                                    final filteredThreads = _getFilteredThreads(threadsToDisplay);
                                    if (filteredThreads.isEmpty) {
                                      return _buildEmptySearchResults();
                                    }
                                    
                                    return _buildThreadsList(filteredThreads);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        SizedBox(width: 20),
                        
                        // Chat view container - expanded to fill available space
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: Offset(0, 5),
                                ),
                              ],
                            ),
                            child: _selectedThreadId != null
                                ? MessageThreadView(
                                    threadId: _selectedThreadId!,
                                    messagingService: _messagingService,
                                  )
                                : _buildEmptyConversationView(),
                          ),
                        ),
                      ],
                    )
                  : Center(child: CircularProgressIndicator()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyThreadsList() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Color(0xFFE9F1E5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.forum_outlined,
                size: 40,
                color: Color(0xFFC0D6B6),
              ),
            ),
            SizedBox(height: 24),
            Text(
              'No Messages Yet',
              style: TextStyle(
                color: const Color(0xFF545454),
                fontSize: 20,
                fontFamily: 'DM Sans',
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'When users message you, their conversations will appear here',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 16,
                  fontFamily: 'DM Sans',
                ),
              ),
            ),
            if (_showDebugInfo)
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: ElevatedButton(
                  onPressed: _createTestConversation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFD1E7CC),
                  ),
                  child: Text('Create Test Conversation'),
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildEmptySearchResults() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 64,
              color: Colors.grey.shade400,
            ),
            SizedBox(height: 24),
            Text(
              'No matching conversations',
              style: TextStyle(
                color: const Color(0xFF545454),
                fontSize: 20,
                fontFamily: 'DM Sans',
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Try a different search term',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
                fontFamily: 'DM Sans',
              ),
            ),
            SizedBox(height: 24),
            TextButton(
              onPressed: () {
                _searchController.clear();
              },
              child: Text(
                'Clear search',
                style: TextStyle(
                  color: Color(0xFFC0D6B6),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThreadsList(List<MessageThread> filteredThreads) {
    return ListView.builder(
      padding: EdgeInsets.symmetric(vertical: 8),
      itemCount: filteredThreads.length,
      itemBuilder: (context, index) {
        final thread = filteredThreads[index];
        
        // Get the other participant (not the organization)
        final currentUserId = _auth.currentUser?.uid ?? '';
        
        // Use the resolved org ID if available, otherwise fall back to the user ID
        final orgId = _currentOrgID ?? currentUserId;
        
        final otherParticipantId = thread.participantIds
            .firstWhere((id) => id != orgId, orElse: () => '');
        
        final otherParticipantName = thread.participantNames[otherParticipantId] ?? 'Unknown User';
        final otherParticipantAvatar = thread.participantAvatars[otherParticipantId];
        
        // Check if thread has unread messages for the organization
        final hasUnread = thread.unreadByUser[currentUserId] == true;
        
        // Check if this thread is selected
        final isSelected = _selectedThreadId == thread.threadId;
        
        // Determine who sent the last message
        final isLastMessageFromOtherParticipant = thread.lastMessageSenderId == otherParticipantId;
        
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedThreadId = thread.threadId;
              // Mark thread as read when selected
              _messagingService.markThreadAsRead(thread.threadId);
            });
          },
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: isSelected ? 
                  Color(0xFFE9F1E5) : hasUnread ? Color(0xFFF5F9F2) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? Color(0xFFC0D6B6) : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  // Avatar with notification badge - Use UserProfileImage widget now
                  Stack(
                    children: [
                      UserProfileImage(
                        imageUrl: otherParticipantAvatar,
                        fallbackText: otherParticipantName,
                        size: 50,
                        borderColor: isSelected ? Color(0xFFC0D6B6) : Colors.grey.shade200,
                        borderWidth: 2.0,
                      ),
                      if (hasUnread)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: Color(0xFFC0D6B6),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(width: 12),
                  
                  // Message content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            // Name
                            Expanded(
                              child: Text(
                                otherParticipantName,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: const Color(0xFF545454),
                                  fontSize: 16,
                                  fontFamily: 'DM Sans',
                                  fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w500,
                                ),
                              ),
                            ),
                            
                            // Time
                            Text(
                              _formatTimestamp(thread.lastMessageTime),
                              style: TextStyle(
                                color: hasUnread ? Color(0xFF545454) : Colors.grey.shade500,
                                fontSize: 12,
                                fontFamily: 'DM Sans',
                                fontWeight: hasUnread ? FontWeight.w600 : FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                        
                        // Message preview with sender indicator
                        Row(
                          children: [
                            if (!isLastMessageFromOtherParticipant)
                              Text(
                                'You: ',
                                style: TextStyle(
                                  color: Colors.grey.shade800,
                                  fontSize: 13,
                                  fontFamily: 'DM Sans',
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            Expanded(
                              child: Text(
                                _getMessagePreview(thread.lastMessageContent),
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: hasUnread ? Color(0xFF545454) : Colors.grey.shade600,
                                  fontSize: 13,
                                  fontFamily: 'DM Sans',
                                  fontWeight: hasUnread ? FontWeight.w600 : FontWeight.w400,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildEmptyConversationView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Color(0xFFE9F1E5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.chat_outlined,
              size: 60,
              color: Color(0xFFC0D6B6),
            ),
          ),
          SizedBox(height: 24),
          Text(
            'Select a Conversation',
            style: TextStyle(
              color: const Color(0xFF545454),
              fontSize: 24,
              fontFamily: 'DM Sans',
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 60),
            child: Text(
              'Select a conversation from the list to respond to messages',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: const Color(0xFF545454),
                fontSize: 16,
                fontFamily: 'DM Sans',
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Add this new method for thread skeleton loaders
  Widget _buildLoadingThreads() {
    return ListView.builder(
      padding: EdgeInsets.symmetric(vertical: 8),
      itemCount: 5, // Show 5 skeleton items
      itemBuilder: (context, index) {
        return Container(
          margin: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                // Avatar skeleton
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey.shade200,
                  ),
                ),
                SizedBox(width: 12),
                
                // Message content skeleton
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name skeleton
                      Container(
                        width: 120 + (index * 20) % 60, // Varying widths
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      SizedBox(height: 8),
                      
                      // Message preview skeleton
                      Container(
                        width: double.infinity,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Time skeleton
                Container(
                  width: 30,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
