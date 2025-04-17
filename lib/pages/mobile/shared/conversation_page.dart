import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pawsmatch/models/message.dart';
import 'package:pawsmatch/models/organization.dart';
import 'package:pawsmatch/pages/mobile/surrenderer/organization_profile.dart';
import 'package:pawsmatch/services/firebase_messaging_service.dart';
import 'package:pawsmatch/services/firebase_organization_service.dart';
import 'package:intl/intl.dart';

class ConversationPage extends StatefulWidget {
  final String threadId;
  final String receiverId;
  final String receiverName;

  const ConversationPage({
    Key? key,
    required this.threadId,
    required this.receiverId,
    required this.receiverName,
  }) : super(key: key);

  @override
  _ConversationPageState createState() => _ConversationPageState();
}

class _ConversationPageState extends State<ConversationPage> {
  final FirebaseMessagingService _messagingService = FirebaseMessagingService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;
  bool _usingFallback = false;
  List<Message> _allMessages = [];
  List<Message> _localMessages = []; 
  bool _isLoadingFallback = false;
  bool _isLoadingOrg = false;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _messagingService.markThreadAsRead(widget.threadId);
      _loadMessagesFallback();
    });
  }
  
  Future<void> _loadMessagesFallback() async {
    setState(() {
      _isLoadingFallback = true;
    });
    
    try {
      final messages = await _messagingService.getMessagesForThreadFallback(widget.threadId);
      
      if (mounted) {
        setState(() {
          _allMessages = [...messages, ..._localMessages];
          _allMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
          _usingFallback = true;
          _isLoadingFallback = false;
        });
        
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });
      }
    } catch (e) {
      print('Error loading fallback messages: $e');
      if (mounted) {
        setState(() {
          _isLoadingFallback = false;
        });
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    final String content = _messageController.text.trim();
    if (content.isEmpty || _isSending) return;

    setState(() {
      _isSending = true;
    });

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      setState(() {
        _isSending = false;
      });
      return;
    }
    
    try {
      final userInfo = await _messagingService.profileService.getUserDashboardInfo();
      final senderName = userInfo['displayName'] ?? 'You';
      
      final newMessage = Message(
        messageId: DateTime.now().millisecondsSinceEpoch.toString(),
        threadId: widget.threadId,
        senderId: currentUser.uid,
        receiverId: widget.receiverId,
        senderName: senderName,
        content: content,
        timestamp: DateTime.now(),
        isRead: false,
      );

      _messageController.clear();
      
      setState(() {
        _localMessages.add(newMessage);
        
        if (_usingFallback) {
          _allMessages = [..._allMessages, newMessage];
        }
      });
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });

      await _messagingService.sendMessage(
        threadId: widget.threadId,
        receiverId: widget.receiverId,
        content: content,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  Future<void> _navigateToOrgProfile() async {
    if (_isLoadingOrg) return;
    
    setState(() {
      _isLoadingOrg = true;
    });
    
    try {
      final organization = await _messagingService.organizationService.getOrganizationById(widget.receiverId);
      
      if (organization != null && mounted) {
        Navigator.push(
          context, 
          MaterialPageRoute(
            builder: (context) => OrganizationProfile(
              organization: organization,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not load organization profile')),
        );
      }
    } catch (e) {
      print('Error navigating to organization profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingOrg = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEF5F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFEF5F0),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Color(0xFF545454)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.receiverName,
          style: TextStyle(
            color: Color(0xFF545454),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: _isLoadingOrg 
              ? SizedBox(
                  width: 20,
                  height: 20, 
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF545454),
                  )
                )
              : Icon(Icons.info_outline, color: Color(0xFF545454)),
            onPressed: _navigateToOrgProfile,
            tooltip: 'View organization profile',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: _usingFallback 
                  ? _buildMessageListWithLocal()
                  : StreamBuilder<List<Message>>(
                      stream: _messagingService.getMessagesForThread(widget.threadId),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting && _allMessages.isEmpty) {
                          return Center(child: CircularProgressIndicator());
                        }

                        if (snapshot.hasError) {
                          if (!_usingFallback && !_isLoadingFallback) {
                            _usingFallback = true;
                            _loadMessagesFallback();
                          }
                          
                          return _isLoadingFallback 
                              ? Center(child: CircularProgressIndicator())
                              : _buildMessageListWithLocal();
                        }

                        final serverMessages = snapshot.data ?? [];
                        
                        _localMessages = _localMessages.where((localMsg) {
                          return !serverMessages.any((serverMsg) => 
                            localMsg.content == serverMsg.content && 
                            localMsg.timestamp.difference(serverMsg.timestamp).inSeconds.abs() < 5
                          );
                        }).toList();
                        
                        final allMessages = [...serverMessages, ..._localMessages];
                        allMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
                        
                        _allMessages = allMessages;
                        
                        if (_allMessages.isEmpty) {
                          return _buildEmptyState();
                        }

                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _scrollToBottom();
                        });

                        return ListView.builder(
                          controller: _scrollController,
                          padding: EdgeInsets.all(16),
                          itemCount: _allMessages.length,
                          itemBuilder: (context, index) {
                            return _buildMessageItem(_allMessages[index]);
                          },
                        );
                      },
                    ),
            ),
          ),
          
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          hintStyle: TextStyle(color: Colors.grey[500]),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        minLines: 1,
                        maxLines: 5,
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Color(0xFF725F63),
                        shape: BoxShape.circle,
                      ),
                      child: _isSending 
                          ? SizedBox(
                              height: 24, 
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Icon(
                              Icons.send,
                              color: Colors.white,
                              size: 24,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageItem(Message message) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final bool isMyMessage = currentUser != null && message.senderId == currentUser.uid;
    
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: isMyMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMyMessage)
            Container(
              width: 36,
              height: 36,
              margin: EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  message.senderName.isNotEmpty ? message.senderName[0].toUpperCase() : 'U',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          
          Flexible(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isMyMessage ? Color(0xFFECC8C0) : Colors.grey[200],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: TextStyle(
                      color: Color(0xFF545454),
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    _formatDateTime(message.timestamp),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          if (isMyMessage)
            Container(
              margin: EdgeInsets.only(left: 8),
              width: 16,
              height: 16,
              child: message.isRead 
                  ? Icon(Icons.done_all, size: 16, color: Colors.blue)
                  : Icon(Icons.done, size: 16, color: Colors.grey),
            ),
        ],
      ),
    );
  }
  
  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    
    if (messageDate == today) {
      return DateFormat.jm().format(dateTime);
    } else if (messageDate == yesterday) {
      return "Yesterday, ${DateFormat.jm().format(dateTime)}";
    } else {
      return DateFormat('MMM d, ').add_jm().format(dateTime);
    }
  }

  Widget _buildMessageListFallback() {
    if (_isLoadingFallback) {
      return Center(child: CircularProgressIndicator());
    }
    
    if (_allMessages.isEmpty) {
      return _buildEmptyState();
    }
    
    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.all(16),
      itemCount: _allMessages.length,
      itemBuilder: (context, index) {
        return _buildMessageItem(_allMessages[index]);
      },
    );
  }

  Widget _buildMessageListWithLocal() {
    if (_isLoadingFallback && _allMessages.isEmpty) {
      return Center(child: CircularProgressIndicator());
    }
    
    if (_allMessages.isEmpty) {
      return _buildEmptyState();
    }
    
    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.all(16),
      itemCount: _allMessages.length,
      itemBuilder: (context, index) {
        return _buildMessageItem(_allMessages[index]);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 60,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'No messages yet',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Start the conversation!',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
