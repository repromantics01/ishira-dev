import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:pawsmatch/models/message.dart';
import 'package:pawsmatch/services/firebase_messaging_service.dart';
import 'package:pawsmatch/pages/mobile/shared/conversation_page.dart';
import 'package:pawsmatch/services/firebase_profile_service.dart';



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
  
  String _threadName = '';
  String _otherUserId = '';
  bool _isLoading = true;
  bool _isSending = false;
  String? _otherUserAvatar;
  String _userType = 'Conversation Participant'; // Add state variable for user type
  
  @override
  void initState() {
    super.initState();
    _loadThreadDetails();
  }
  
  @override
  void didUpdateWidget(MessageThreadView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.threadId != widget.threadId) {
      _loadThreadDetails();
    }
  }
  
  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
  
  Future<void> _loadThreadDetails() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Get message thread from Firestore
      final threads = await widget.messagingService.getThreadsForCurrentUserFallback();
      
      if (threads.isEmpty) {
        setState(() {
          _isLoading = false;
          _threadName = 'No threads found';
        });
        return;
      }
      
      try {
        final thread = threads.firstWhere((t) => t.threadId == widget.threadId);
        
        // Find the other participant (not the current user)
        final currentUserId = _auth.currentUser?.uid ?? '';
        _otherUserId = thread.participantIds
            .firstWhere((id) => id != currentUserId, orElse: () => '');
        
        _threadName = thread.participantNames[_otherUserId] ?? 'User';
        
        // Generate avatar placeholder
        _otherUserAvatar = 'https://placehold.co/60x60/E4E4E4/545454?text=${_threadName[0].toUpperCase()}';
        
        // Load user type
        _loadUserType(_otherUserId);
        
        // Mark as read
        widget.messagingService.markThreadAsRead(widget.threadId);
      } catch (e) {
        print('Error finding thread: $e');
        setState(() {
          _threadName = 'Thread not found';
        });
      }
    } catch (e) {
      print('Error loading thread details: $e');
      setState(() {
        _threadName = 'Error loading conversation';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  // New method to load user type
  Future<void> _loadUserType(String userId) async {
    try {
      // First get the profile ID for the user
      final profileId = await _profileService.getProfileID(userId);
      
      // If we got a valid profile ID, get the user type
      if (profileId != 'No profile found' && profileId != 'Error retrieving profile ID') {
        final userType = await _profileService.getUserType(profileId);
        
        // Update the UI with the user type
        if (mounted) {
          setState(() {
            // Format the user type for display
            if (userType.toLowerCase() == 'adopter') {
              _userType = 'Potential Adopter';
            } else if (userType.toLowerCase() == 'surrenderer') {
              _userType = 'Surrenderer';
            } else if (userType.isNotEmpty) {
              // Capitalize the first letter of the user type
              _userType = userType[0].toUpperCase() + userType.substring(1);
            } else {
              _userType = 'Conversation Participant';
            }
          });
        }
      }
    } catch (e) {
      print('Error loading user type: $e');
      if (mounted) {
        setState(() {
          _userType = 'Conversation Participant';
        });
      }
    }
  }
  
  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _isSending) return;
    
    setState(() {
      _isSending = true;
    });
    
    try {
      await widget.messagingService.sendMessage(
        threadId: widget.threadId,
        receiverId: _otherUserId,
        content: message,
      );
      
      _messageController.clear();
      
      // Scroll to bottom after sending
      Future.delayed(Duration(milliseconds: 300), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      print('Error sending message: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message')),
      );
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }
  
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
    return Column(
      children: [
        // Chat header with improved design
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
          child: Row(
            children: [
              // Avatar
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFE9F1E5),
                  border: Border.all(
                    color: Color(0xFFC0D6B6),
                    width: 2,
                  ),
                  image: _otherUserAvatar != null ? DecorationImage(
                    image: NetworkImage(_otherUserAvatar!),
                    fit: BoxFit.cover,
                  ) : null,
                ),
                child: _otherUserAvatar == null ? 
                  Center(
                    child: Text(
                      _threadName.isNotEmpty ? _threadName[0].toUpperCase() : '?',
                      style: TextStyle(
                        color: const Color(0xFF545454),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ) : null,
              ),
              SizedBox(width: 16),
              
              // Name and status
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    Text(
                      _threadName,
                      style: TextStyle(
                      color: const Color(0xFF545454),
                      fontSize: 20,
                      fontFamily: 'DM Sans',
                      fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      _userType, // Use the state variable that we've loaded
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
          ),
        ),
        
        // Messages list with improved error handling and loading state management
        Expanded(
          child: Container(
            color: Color(0xFFF9F9F9),
            child: StreamBuilder<List<Message>>(
              stream: widget.messagingService.getMessagesForThread(widget.threadId),
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
                          'Loading messages...',
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
                
                // Handle error state with retry button
                if (snapshot.hasError) {
                  print('Error loading messages: ${snapshot.error}');
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
                        SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () => setState(() {
                            _isLoading = true;
                            Future.delayed(Duration(milliseconds: 500), () {
                              if (mounted) setState(() => _isLoading = false);
                            });
                          }),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFFC0D6B6),
                            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: Text(
                            'Retry',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                
                // No data case
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildEmptyMessagesView();
                }
                
                // Success case - we have messages
                _isLoading = false;
                return _buildMessageList(snapshot.data!);
              },
            ),
          ),
        ),
        
        // Message input area with improved design
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
              // Input field
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  constraints: BoxConstraints(
                    maxHeight: 120, // Limit the height
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

  Widget _buildEmptyMessagesView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
      ),
    );
  }

  // Extract message list building logic to a separate method
  Widget _buildMessageList(List<Message> messages) {
    // Scroll to bottom on new messages
    Future.delayed(Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
    
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
            // Date header with improved styling
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
            
            // Messages for the date
            ...dateMessages.map((message) {
              final isCurrentUser = message.senderId == _auth.currentUser?.uid;
              return _buildMessageItem(message, isCurrentUser);
            }),
          ],
        );
      },
    );
  }
  
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
            Container(
              width: 36,
              height: 36,
              margin: EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF5F5F5),
                border: Border.all(
                  color: Color(0xFFE0E0E0),
                  width: 2,
                ),
                image: _otherUserAvatar != null ? DecorationImage(
                  image: NetworkImage(_otherUserAvatar!),
                  fit: BoxFit.cover,
                ) : null,
              ),
              child: _otherUserAvatar == null ? 
                Center(
                  child: Text(
                    _threadName.isNotEmpty ? _threadName[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: const Color(0xFF545454),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ) : null,
            ),
          
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
                
                // Timestamp with improved position and styling
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
