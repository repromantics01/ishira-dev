import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:pawsmatch/models/message.dart';
import 'package:pawsmatch/services/firebase_messaging_service.dart';

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
  
  String _threadName = '';
  String _otherUserId = '';
  bool _isLoading = true;
  bool _isSending = false;
  int _loadingAttempts = 0; // Track loading attempts
  
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
      print('Loading thread details for thread ID: ${widget.threadId}');
      // Get message thread from Firestore
      final threads = await widget.messagingService.getThreadsForCurrentUserFallback();
      print('Retrieved ${threads.length} threads');
      
      if (threads.isEmpty) {
        print('No threads found');
        setState(() {
          _isLoading = false;
          _threadName = 'No threads found';
        });
        return;
      }
      
      try {
        final thread = threads.firstWhere((t) => t.threadId == widget.threadId);
        print('Found thread: ${thread.threadId}');
        
        // Find the other participant (not the current user)
        final currentUserId = _auth.currentUser?.uid ?? '';
        _otherUserId = thread.participantIds
            .firstWhere((id) => id != currentUserId, orElse: () => '');
        
        print('Other user ID: $_otherUserId');
        _threadName = thread.participantNames[_otherUserId] ?? 'User';
        
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
        _loadingAttempts++;
      });
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
      return DateFormat('MMMM d, y').format(date);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Chat header with improved alignment
        Container(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
              Container(
                width: 40,
                height: 40,
                decoration: ShapeDecoration(
                  color: const Color(0xFFF5F5F5),
                  shape: RoundedRectangleBorder(
                    side: BorderSide(width: 1, color: Colors.black.withOpacity(0.29)),
                    borderRadius: BorderRadius.circular(73),
                  ),
                  image: DecorationImage(
                    image: NetworkImage('https://placehold.co/40x40/E4E4E4/545454?text=${_threadName.isNotEmpty ? _threadName[0] : "?"}'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Text(
                  _threadName,
                  style: TextStyle(
                    color: const Color(0xFF545454),
                    fontSize: 20,
                    fontFamily: 'DM Sans',
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Messages list with improved error handling and loading state management
        Expanded(
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
                      SizedBox(height: 8),
                      Text(
                        '${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.red.shade400,
                          fontSize: 14,
                          fontFamily: 'DM Sans',
                        ),
                      ),
                      SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _loadThreadDetails,
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
              
              // If we're not loading and there's no data or error, try to use a fallback method
              if (!_isLoading && (!snapshot.hasData || snapshot.data!.isEmpty)) {
                return FutureBuilder<List<Message>>(
                  future: widget.messagingService.getMessagesForThreadFallback(widget.threadId),
                  builder: (context, fallbackSnapshot) {
                    if (fallbackSnapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }
                    
                    // If fallback also failed, show empty state
                    if (!fallbackSnapshot.hasData || fallbackSnapshot.data!.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.chat_bubble_outline,
                                size: 64,
                                color: Colors.grey.shade400,
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
                    
                    // Fallback succeeded, show messages
                    return _buildMessageList(fallbackSnapshot.data!);
                  },
                );
              }
              
              // Normal flow - we have data from the stream
              _isLoading = false;
              return _buildMessageList(snapshot.data!);
            },
          ),
        ),
        
        // Message input area - unchanged
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
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      hintStyle: TextStyle(
                        color: Colors.grey.shade500,
                      ),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
              ),
              SizedBox(width: 12),
              InkWell(
                onTap: _sendMessage,
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFC0D6B6),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: _isSending
                      ? Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Icon(
                          Icons.send,
                          color: Colors.white,
                        ),
                ),
              ),
            ],
          ),
        ),
      ],
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
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  dateKey,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 12,
                    fontFamily: 'DM Sans',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            
            // Messages for the date with consistent spacing
            ...dateMessages.map((message) {
              final isCurrentUser = message.senderId == _auth.currentUser?.uid;
              return _buildMessageItem(context, message, isCurrentUser);
            }),
          ],
        );
      },
    );
  }
  
  Widget _buildMessageItem(BuildContext context, Message message, bool isCurrentUser) {
    return Container(
      margin: EdgeInsets.only(
        top: 4, 
        bottom: 4,
        left: isCurrentUser ? 60 : 0,
        right: isCurrentUser ? 0 : 60,
      ),
      child: Row(
        mainAxisAlignment: isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar (only for other user's messages)
          if (!isCurrentUser)
            Container(
              width: 32,
              height: 32,
              margin: EdgeInsets.only(right: 8),
              decoration: ShapeDecoration(
                color: const Color(0xFFF5F5F5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                image: message.senderAvatarUrl != null
                    ? DecorationImage(
                        image: NetworkImage(message.senderAvatarUrl!),
                        fit: BoxFit.cover,
                      )
                    : DecorationImage(
                        image: NetworkImage('https://placehold.co/32x32/E4E4E4/545454?text=${message.senderName[0]}'),
                        fit: BoxFit.cover,
                      ),
              ),
            ),
          
          // Message content
          Flexible(
            child: Column(
              crossAxisAlignment: isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isCurrentUser ? const Color(0xFFD1E7CC) : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: !isCurrentUser ? Border.all(color: Colors.grey.shade200) : null,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        offset: Offset(0, 1),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                  child: Text(
                    message.content,
                    style: TextStyle(
                      color: const Color(0xFF545454),
                      fontSize: 15,
                      fontFamily: 'DM Sans',
                    ),
                  ),
                ),
                
                // Timestamp
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
                  child: Text(
                    _formatMessageTime(message.timestamp),
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 10,
                      fontFamily: 'DM Sans',
                    ),
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
