import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:pawsmatch/models/message.dart';
import 'package:pawsmatch/services/firebase_messaging_service.dart';
import 'package:pawsmatch/services/firebase_profile_service.dart';
import 'package:pawsmatch/widgets/user_profile_image.dart';
import 'dart:async';

class MessageThreadView extends StatefulWidget {
  final String threadId;
  final FirebaseMessagingService messagingService;
  
  const MessageThreadView({
    Key? key,
    required this.threadId,
    required this.messagingService,
  }) : super(key: key);

  @override
  State<MessageThreadView> createState() => _MessageThreadViewState();
}

class _MessageThreadViewState extends State<MessageThreadView> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseProfileService _profileService = FirebaseProfileService();
  
  // Thread state variables
  String _userType = 'Conversation Participant';
  bool _isSending = false;
  
  // UI state management
  bool _forceLoading = true;
  bool _transitionInProgress = false;
  String _currentThreadId = '';
  Timer? _loadingTimer;
  
  // Constructor thread ID to track changes
  String? _constructorThreadId;
  
  @override
  void initState() {
    super.initState();
    _constructorThreadId = widget.threadId;
    _currentThreadId = widget.threadId;
    
    // Mark thread as read immediately
    _markThreadAsRead();
    
    // Set a short timer to show loading state briefly
    _loadingTimer = Timer(Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _forceLoading = false;
        });
      }
    });
  }
  
  @override
  void didUpdateWidget(MessageThreadView oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Clear thread data and start fresh if thread ID changed
    if (oldWidget.threadId != widget.threadId) {
      // Cancel any existing timer
      _loadingTimer?.cancel();
      
      // Update constructor thread ID
      _constructorThreadId = widget.threadId;
      
      // Force reload with new thread ID
      setState(() {
        _currentThreadId = widget.threadId;
        _forceLoading = true;
        _transitionInProgress = true;
        
        // Clear previous thread data immediately to avoid showing wrong content
        _userType = 'Conversation Participant';
      });
      
      // Mark new thread as read
      _markThreadAsRead();
      
      // Set timer to remove loading state after a delay
      _loadingTimer = Timer(Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _forceLoading = false;
            _transitionInProgress = false;
          });
        }
      });
    }
  }
  
  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _loadingTimer?.cancel();
    super.dispose();
  }
  
  // Mark thread as read
  void _markThreadAsRead() {
    if (_currentThreadId.isNotEmpty) {
      widget.messagingService.markThreadAsRead(_currentThreadId);
    }
  }
  
  // Scroll to bottom when messages are loaded
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }
  
  // Load user type in background
  Future<void> _loadUserType(String userId) async {
    if (userId.isEmpty) return;
    
    try {
      final profileId = await _profileService.getProfileID(userId);
      
      if (profileId != 'No profile found' && profileId != 'Error retrieving profile ID') {
        final userType = await _profileService.getUserType(profileId);
        
        if (mounted) {
          setState(() {
            if (userType.toLowerCase() == 'adopter') {
              _userType = 'Potential Adopter';
            } else if (userType.toLowerCase() == 'surrenderer') {
              _userType = 'Surrenderer';
            } else if (userType.isNotEmpty) {
              _userType = userType[0].toUpperCase() + userType.substring(1);
            }
          });
        }
      }
    } catch (e) {
      print('Error loading user type: $e');
    }
  }

  // Send message with better error handling
  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _isSending) return;
    
    setState(() {
      _isSending = true;
    });
    
    try {
      await widget.messagingService.sendMessage(
        threadId: widget.threadId,
        receiverId: _auth.currentUser?.uid ?? '',
        content: message,
      );
      
      _messageController.clear();
      
      // Scroll to bottom after sending
      Future.delayed(Duration(milliseconds: 100), _scrollToBottom);
    } catch (e) {
      print('Error sending message: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }
  
  // Helper methods for date formatting
  String _formatMessageTime(DateTime time) {
    return DateFormat('h:mm a').format(time);
  }
  
  String _formatMessageDate(DateTime date) {
    final today = DateTime.now();
    final yesterday = today.subtract(Duration(days: 1));
    
    if (date.year == today.year && date.month == today.month && date.day == today.day) {
      return 'Today';
    } else if (date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day) {
      return 'Yesterday';
    } else {
      return DateFormat('EEEE, MMMM d').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Force loading state during transitions
    if (_forceLoading || _transitionInProgress) {
      return _buildLoadingState();
    }
    
    return Column(
      children: [
        // Thread header that independently loads thread details
        _buildThreadHeader(),
        
        // Message list with loading states
        Expanded(
          child: Container(
            color: Color(0xFFF9F9F9),
            child: StreamBuilder<List<Message>>(
              stream: widget.messagingService.getMessagesForThread(widget.threadId),
              builder: (context, snapshot) {
                // Show loading state while waiting for messages
                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                  return Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFC0D6B6)),
                    ),
                  );
                }
                
                // Handle error state with retry button
                if (snapshot.hasError) {
                  return _buildErrorState(snapshot.error.toString());
                }
                
                // No messages case
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildEmptyMessagesView();
                }
                
                // We have messages - scroll to bottom after building
                final messages = snapshot.data!;
                WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
                return _buildMessageList(messages);
              },
            ),
          ),
        ),
        
        // Message input area
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                offset: Offset(0, -2),
                blurRadius: 5,
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Message input field
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  constraints: BoxConstraints(
                    maxHeight: 120,
                  ),
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      hintStyle: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 16,
                        fontFamily: 'DM Sans',
                      ),
                    ),
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'DM Sans',
                      color: Color(0xFF545454),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.newline,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
              ),
              SizedBox(width: 12),
              
              // Send button
              GestureDetector(
                onTap: _sendMessage,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFFC0D6B6),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFFC0D6B6).withOpacity(0.4),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: _isSending
                    ? Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                      )
                    : Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Thread header with independent loading
  Widget _buildThreadHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: Offset(0, 2),
            blurRadius: 5,
          ),
        ],
      ),
      child: StreamBuilder(
        stream: widget.messagingService.getThreadById(widget.threadId),
        builder: (context, threadSnapshot) {
          // Always use loading UI if transition is in progress
          if (_transitionInProgress) {
            return _buildHeaderSkeleton();
          }
          
          // Loading state
          if (!threadSnapshot.hasData) {
            return _buildHeaderSkeleton();
          }
          
          // Error state
          if (threadSnapshot.hasError) {
            return _buildHeaderError();
          }
          
          // Thread data loaded successfully
          final thread = threadSnapshot.data;
          if (thread != null) {
            // Find the other participant
            final currentUserId = _auth.currentUser?.uid ?? '';
            final otherParticipantId = thread.participantIds
                .firstWhere((id) => id != currentUserId, orElse: () => '');
            final threadName = thread.participantNames[otherParticipantId] ?? 'User';
            final otherUserAvatar = thread.participantAvatars[otherParticipantId];

            // Load user type in background without blocking UI
            _loadUserType(otherParticipantId);

            // Build UI with loaded data
            return Row(
              children: [
                // Avatar
                UserProfileImage(
                  imageUrl: otherUserAvatar,
                  fallbackText: threadName,
                  size: 48,
                  borderColor: Color(0xFFC0D6B6),
                  borderWidth: 2.0,
                ),
                SizedBox(width: 16),
                
                // Name and status
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        threadName,
                        style: TextStyle(
                          color: const Color(0xFF545454),
                          fontSize: 20,
                          fontFamily: 'DM Sans',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        _userType,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                          fontFamily: 'DM Sans',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }
          
          // Fallback for empty thread data
          return _buildHeaderSkeleton();
        },
      ),
    );
  }
  
  // Header error state
  Widget _buildHeaderError() {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.red.shade100,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.error_outline, color: Colors.red),
        ),
        SizedBox(width: 16),
        
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Error Loading Conversation',
                style: TextStyle(
                  color: Colors.red.shade700,
                  fontSize: 16,
                  fontFamily: 'DM Sans',
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Try refreshing the page',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                  fontFamily: 'DM Sans',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  // Header skeleton loading state
  Widget _buildHeaderSkeleton() {
    return Row(
      children: [
        // Avatar skeleton
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 16),
        
        // User info skeleton
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 150,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              SizedBox(height: 6),
              Container(
                width: 100,
                height: 14,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  // Loading state for the entire view
  Widget _buildLoadingState() {
    return Column(
      children: [
        // Header skeleton
        Container(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                offset: Offset(0, 2),
                blurRadius: 5,
              ),
            ],
          ),
          child: _buildHeaderSkeleton(),
        ),
        
        // Message loading skeleton
        Expanded(
          child: Container(
            color: Color(0xFFF9F9F9),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFC0D6B6)),
                  ),
                  SizedBox(height: 24),
                  Text(
                    'Loading messages...',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 16,
                      fontFamily: 'DM Sans',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        
        // Input area skeleton
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                offset: Offset(0, -2),
                blurRadius: 5,
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
              SizedBox(width: 12),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Color(0xFFC0D6B6).withOpacity(0.5),
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Error state for message list
  Widget _buildErrorState(String errorMessage) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red.shade300,
          ),
          SizedBox(height: 16),
          Text(
            'Failed to load messages',
            style: TextStyle(
              color: Colors.red.shade700,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Container(
            width: 300,
            child: Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 14,
              ),
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => setState(() {}), // Retrigger build to reload
            icon: Icon(Icons.refresh),
            label: Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFC0D6B6),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // Empty state for message list
  Widget _buildEmptyMessagesView() {
    return Center(
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
              Icons.chat_bubble_outline,
              size: 40,
              color: Color(0xFFC0D6B6),
            ),
          ),
          SizedBox(height: 24),
          Text(
            'No messages yet',
            style: TextStyle(
              color: const Color(0xFF545454),
              fontSize: 20,
              fontFamily: 'DM Sans',
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Send a message to start the conversation',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
              fontFamily: 'DM Sans',
            ),
          ),
        ],
      ),
    );
  }

  // Message list with grouped dates
  Widget _buildMessageList(List<Message> messages) {
    // Group messages by date
    final Map<String, List<Message>> messagesByDate = {};
    for (final message in messages) {
      final dateKey = _formatMessageDate(message.timestamp);
      if (!messagesByDate.containsKey(dateKey)) {
        messagesByDate[dateKey] = [];
      }
      messagesByDate[dateKey]!.add(message);
    }
    
    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemCount: messagesByDate.keys.length,
      itemBuilder: (context, index) {
        final dateKey = messagesByDate.keys.elementAt(index);
        final dateMessages = messagesByDate[dateKey]!;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Date header
            Container(
              alignment: Alignment.center,
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  dateKey,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 13,
                    fontFamily: 'DM Sans',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            
            // Messages for this date
            ...dateMessages.map((message) {
              final isCurrentUser = message.senderId == _auth.currentUser?.uid;
              return _buildMessageItem(message, isCurrentUser);
            }),
          ],
        );
      },
    );
  }
  
  // Individual message bubble
  Widget _buildMessageItem(Message message, bool isCurrentUser) {
    return Padding(
      padding: EdgeInsets.only(
        top: 6,
        bottom: 6,
        left: isCurrentUser ? 60 : 0,
        right: isCurrentUser ? 0 : 60,
      ),
      child: Row(
        mainAxisAlignment: isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Avatar (only for other user's messages)
          if (!isCurrentUser)
            UserProfileImage(
              imageUrl: _auth.currentUser?.photoURL,
              fallbackText: 'User',
              size: 36,
              borderColor: Colors.grey.shade300,
              borderWidth: 1.5,
            ),
          
          SizedBox(width: !isCurrentUser ? 12 : 0),
          
          // Message content
          Flexible(
            child: Column(
              crossAxisAlignment: isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                // Message bubble
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isCurrentUser ? const Color(0xFFD1E7CC) : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                      bottomLeft: isCurrentUser ? Radius.circular(20) : Radius.circular(6),
                      bottomRight: isCurrentUser ? Radius.circular(6) : Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        offset: Offset(0, 2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Text(
                    message.content,
                    style: TextStyle(
                      color: const Color(0xFF545454),
                      fontSize: 15,
                      fontFamily: 'DM Sans',
                      height: 1.4,
                    ),
                  ),
                ),
                
                // Timestamp and read status
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isCurrentUser && message.isRead)
                        Icon(
                          Icons.done_all,
                          size: 12,
                          color: Color(0xFF89B273),
                        ),
                      SizedBox(width: isCurrentUser && message.isRead ? 4 : 0),
                      Text(
                        _formatMessageTime(message.timestamp),
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 11,
                          fontFamily: 'DM Sans',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
