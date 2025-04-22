import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'org_sidebar.dart';
import 'package:pawsmatch/models/message.dart';
import 'package:pawsmatch/services/firebase_messaging_service.dart';
import 'package:pawsmatch/services/firebase_profile_service.dart';
import 'package:pawsmatch/widgets/message_thread_view.dart';

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  final FirebaseMessagingService _messagingService = FirebaseMessagingService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _searchController = TextEditingController();
  
  String _searchQuery = '';
  List<MessageThread> _threads = [];
  bool _isLoading = true;
  String? _selectedThreadId;
  
  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
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
      final otherParticipants = thread.participantIds
          .where((id) => id != currentUserId)
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
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEF5F0),
      body: Center(
        child: Container(
          width: 1584,
          height: 1024,
          child: Stack(
            children: [
              // Sidebar navigation
              const Positioned(
                left: 0,
                top: 0,
                child: OrgSidebar(),
              ),
              
              // Messages interface container - positioned in the center
              Positioned(
                left: 400, // Adjusted for better layout with sidebar
                top: 56,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Threads sidebar 
                    Container(
                      width: 397,
                      height: 912,
                      child: Stack(
                        children: [
                          // Background container
                          Container(
                            width: 397,
                            height: 912,
                            decoration: ShapeDecoration(
                              color: Colors.white.withOpacity(0.85),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                          ),
                          
                          // Messages title
                          Positioned(
                            left: 27,
                            top: 39,
                            child: SizedBox(
                              width: 356,
                              height: 40,
                              child: Text(
                                'Messages',
                                style: TextStyle(
                                  color: const Color(0xFF545454),
                                  fontSize: 36,
                                  fontFamily: 'DM Sans',
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          
                          // Search bar
                          Positioned(
                            left: 20,
                            top: 99,
                            child: Container(
                              width: 356,
                              height: 36,
                              child: TextField(
                                controller: _searchController,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: const Color(0xFFEDEDED),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: EdgeInsets.symmetric(vertical: 4, horizontal: 22),
                                  hintText: 'Search',
                                  hintStyle: TextStyle(
                                    color: Colors.black.withOpacity(0.5),
                                    fontSize: 14,
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w400,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.search,
                                    color: Colors.black.withOpacity(0.5),
                                    size: 18,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          
                          // Threads list with improved error handling
                          Positioned(
                            left: 0,
                            top: 150,
                            bottom: 0,
                            right: 0,
                            child: StreamBuilder<List<MessageThread>>(
                              stream: _messagingService.getThreadsForCurrentUser(),
                              builder: (context, snapshot) {
                                // Handle loading state
                                if (snapshot.connectionState == ConnectionState.waiting && _isLoading) {
                                  return Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        CircularProgressIndicator(
                                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFC0D6B6)),
                                        ),
                                        SizedBox(height: 16),
                                        Text(
                                          'Loading conversations...',
                                          style: TextStyle(
                                            color: const Color(0xFF545454),
                                            fontSize: 16,
                                            fontFamily: 'DM Sans',
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                                
                                // Handle error state with fallback
                                if (snapshot.hasError) {
                                  print("Error loading message threads: ${snapshot.error}");
                                  return FutureBuilder<List<MessageThread>>(
                                    future: _messagingService.getThreadsForCurrentUserFallback(),
                                    builder: (context, fallbackSnapshot) {
                                      if (fallbackSnapshot.connectionState == ConnectionState.waiting) {
                                        return Center(child: CircularProgressIndicator());
                                      }
                                      
                                      if (fallbackSnapshot.hasError || !fallbackSnapshot.hasData || fallbackSnapshot.data!.isEmpty) {
                                        return Center(
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                                              SizedBox(height: 16),
                                              Text(
                                                'Error loading messages',
                                                style: TextStyle(
                                                  color: Colors.red.shade700,
                                                  fontSize: 18,
                                                  fontFamily: 'DM Sans',
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              SizedBox(height: 8),
                                              Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                                child: Text(
                                                  snapshot.error.toString(),
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    color: Colors.red.shade400,
                                                    fontSize: 14,
                                                    fontFamily: 'DM Sans',
                                                  ),
                                                ),
                                              ),
                                              SizedBox(height: 24),
                                              ElevatedButton(
                                                onPressed: () {
                                                  setState(() {
                                                    _isLoading = true;
                                                  });
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Color(0xFFC0D6B6),
                                                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                                ),
                                                child: Text('Retry'),
                                              ),
                                            ],
                                          ),
                                        );
                                      }
                                      
                                      // Fallback succeeded
                                      _isLoading = false;
                                      _threads = fallbackSnapshot.data!;
                                      final filteredThreads = _getFilteredThreads(_threads);
                                      
                                      if (filteredThreads.isEmpty) {
                                        return _buildEmptyThreadsList();
                                      }
                                      
                                      return _buildThreadsList(filteredThreads);
                                    },
                                  );
                                }
                                
                                _isLoading = false;
                                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                  return _buildEmptyThreadsList();
                                }
                                
                                // Update threads list
                                _threads = snapshot.data!;
                                
                                // Filter threads based on search
                                final filteredThreads = _getFilteredThreads(_threads);
                                
                                if (filteredThreads.isEmpty) {
                                  return _buildEmptyThreadsList();
                                }
                                
                                return _buildThreadsList(filteredThreads);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Chat view container - show when a thread is selected
                    if (_selectedThreadId != null)
                      Container(
                        width: 750,
                        height: 912,
                        margin: EdgeInsets.only(left: 20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: MessageThreadView(
                          threadId: _selectedThreadId!,
                          messagingService: _messagingService,
                        ),
                      ),
                    
                    // Empty state when no thread is selected
                    if (_selectedThreadId == null)
                      Container(
                        width: 750,
                        height: 912,
                        margin: EdgeInsets.only(left: 20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.chat_outlined,
                                size: 80,
                                color: Colors.grey.shade400,
                              ),
                              SizedBox(height: 20),
                              Text(
                                'Select a conversation',
                                style: TextStyle(
                                  color: const Color(0xFF545454),
                                  fontSize: 24,
                                  fontFamily: 'DM Sans',
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(height: 10),
                              Text(
                                'Choose a conversation from the list to view messages',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: const Color(0xFF545454),
                                  fontSize: 16,
                                  fontFamily: 'DM Sans',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
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
            Icon(
              Icons.forum_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            SizedBox(height: 24),
            Text(
              _searchQuery.isEmpty 
                  ? 'No conversations yet'
                  : 'No matching conversations',
              style: TextStyle(
                color: const Color(0xFF545454),
                fontSize: 20,
                fontFamily: 'DM Sans',
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 12),
            Text(
              _searchQuery.isEmpty 
                  ? 'Messages from pet adopters will appear here'
                  : 'Try a different search term',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
                fontFamily: 'DM Sans',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThreadsList(List<MessageThread> filteredThreads) {
    return ListView.builder(
      padding: EdgeInsets.only(top: 10),
      itemCount: filteredThreads.length,
      itemBuilder: (context, index) {
        final thread = filteredThreads[index];
        
        // Get other participant info (not the org)
        final currentUserId = _auth.currentUser?.uid ?? '';
        final otherParticipantId = thread.participantIds
            .firstWhere((id) => id != currentUserId, orElse: () => '');
        
        final otherParticipantName = thread.participantNames[otherParticipantId] ?? 'Unknown User';
        
        // Check if thread has unread messages for current user
        final hasUnread = thread.unreadByUser[currentUserId] == true;
        
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedThreadId = thread.threadId;
              // Mark thread as read when selected
              _messagingService.markThreadAsRead(thread.threadId);
            });
          },
          child: Container(
            width: 340,
            height: 61,
            margin: EdgeInsets.symmetric(horizontal: 22, vertical: 5),
            decoration: BoxDecoration(
              color: _selectedThreadId == thread.threadId ? 
                  const Color(0xFFF5F5F5) : Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Stack(
              children: [
                // Bottom divider
                Positioned(
                  left: 5,
                  top: 60,
                  child: Container(
                    width: 330,
                    height: 1,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD9D9D9),
                    ),
                  ),
                ),
                
                // Message preview text
                Positioned(
                  left: 69,
                  top: 30,
                  child: SizedBox(
                    width: 252,
                    height: 22,
                    child: Text(
                      _getMessagePreview(thread.lastMessageContent),
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: const Color(0xFF545454),
                        fontSize: 10,
                        fontStyle: FontStyle.italic,
                        fontFamily: 'DM Sans',
                        fontWeight: hasUnread ? 
                            FontWeight.w700 : FontWeight.w400,
                      ),
                    ),
                  ),
                ),
                
                // Time indicator
                Positioned(
                  right: 20,
                  top: 9,
                  child: SizedBox(
                    height: 22,
                    child: Text(
                      _formatTimestamp(thread.lastMessageTime),
                      style: TextStyle(
                        color: const Color(0xFF545454),
                        fontSize: 10,
                        fontFamily: 'DM Sans',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ),
                
                // User name
                Positioned(
                  left: 69,
                  top: 12,
                  child: SizedBox(
                    width: 180,
                    height: 19,
                    child: Text(
                      otherParticipantName,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: const Color(0xFF545454),
                        fontSize: 15,
                        fontFamily: 'DM Sans',
                        fontWeight: hasUnread ? 
                            FontWeight.w700 : FontWeight.w400,
                      ),
                    ),
                  ),
                ),
                
                // User avatar
                Positioned(
                  left: 17,
                  top: 8,
                  child: Container(
                    width: 40.21,
                    height: 40.21,
                    decoration: ShapeDecoration(
                      color: const Color(0xFFF5F5F5),
                      shape: RoundedRectangleBorder(
                        side: BorderSide(
                          width: 1,
                          color: Colors.black.withOpacity(0.29),
                        ),
                        borderRadius: BorderRadius.circular(73),
                      ),
                      image: thread.participantNames[otherParticipantId] != null ?
                        DecorationImage(
                          image: NetworkImage('https://placehold.co/40x40/E4E4E4/545454?text=${otherParticipantName[0]}'),
                          fit: BoxFit.cover,
                        ) : null,
                    ),
                    child: thread.participantNames[otherParticipantId] == null ?
                      Center(
                        child: Text(
                          '?',
                          style: TextStyle(
                            color: const Color(0xFF545454),
                            fontSize: 16,
                          ),
                        ),
                      ) : null,
                  ),
                ),
                
                // Unread indicator
                if (hasUnread)
                  Positioned(
                    right: 10,
                    top: 28,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.blue,
                      ),
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
