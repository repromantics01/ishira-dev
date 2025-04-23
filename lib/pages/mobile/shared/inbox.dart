import 'package:flutter/material.dart';
import 'package:pawsmatch/pages/mobile/shared/conversation_page.dart';
import 'package:pawsmatch/widgets/logout_button.dart';
import 'package:pawsmatch/models/message.dart';
import 'package:pawsmatch/services/firebase_messaging_service.dart';
import 'package:pawsmatch/services/firebase_organization_service.dart'; // Add this import
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class InboxPage extends StatefulWidget {
  const InboxPage({Key? key}) : super(key: key);

  @override
  _InboxPageState createState() => _InboxPageState();
}

class _InboxPageState extends State<InboxPage> {
  final FirebaseMessagingService _messagingService = FirebaseMessagingService();
  final FirebaseOrganizationService _organizationService = FirebaseOrganizationService(); // Add this
  bool _usingFallback = false;
  List<MessageThread> _fallbackThreads = [];
  bool _isLoading = false;
  
  final Map<String, String?> _orgLogoCache = {};
  
  @override
  void initState() {
    super.initState();
    _tryLoadThreads();
  }
  
  Future<void> _tryLoadThreads() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Get current user ID
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }
      
      // Attempt to get threads using fallback method - explicitly pass current user ID
      final threads = await _messagingService.getThreadsForCurrentUserFallback(
        organizationId: currentUser.uid
      );
      
      if (mounted) {
        setState(() {
          _fallbackThreads = threads;
          _usingFallback = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading threads: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEF5F0),
      body: Stack(
        children: [
          // Back button area
          Positioned(
            left: 23,
            top: 50,
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back,
                color: Color(0xFF545454),
                size: 24,
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ),
          
          // Inbox title
          Positioned(
            left: 40,
            top: 105,
            child: Text(
              'Inbox',
              style: TextStyle(
                color: const Color(0xFF545454),
                fontSize: 30,
                fontFamily: 'Arial',
                fontWeight: FontWeight.w700,
                height: 1.0,
              ),
            ),
          ),
          
          // Fixed divider with better alignment
          Positioned(
            left: 0,
            right: 0,
            top: 150,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 0.5,
                color: const Color(0xFF9E9E9E),
              ),
            ),
          ),
          
          // Thread list or empty state
          Positioned(
            top: 165,
            left: 0,
            right: 0,
            bottom: 100,
            child: _buildThreadList(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildThreadList() {
    // If using fallback (because index is missing), use the pre-loaded threads
    if (_usingFallback) {
      if (_isLoading) {
        return Center(child: CircularProgressIndicator());
      }
      
      if (_fallbackThreads.isEmpty) {
        return _buildEmptyStateContent();
      }
      
      return ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        physics: const BouncingScrollPhysics(),
        itemCount: _fallbackThreads.length,
        separatorBuilder: (context, index) => Divider(
          height: 1,
          thickness: 0.5,
          color: const Color(0xFF9E9E9E),
        ),
        itemBuilder: (context, index) {
          return _buildThreadItem(_fallbackThreads[index]);
        },
      );
    }
    
    // Otherwise, use the original stream-based approach with error handling
    return StreamBuilder<List<MessageThread>>(
      stream: _messagingService.getThreadsForCurrentUser(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          // If there's an error with the stream, switch to fallback
          if (!_usingFallback) {
            _usingFallback = true;
            _tryLoadThreads();
          }
          
          // Show error state if fallback hasn't loaded yet
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.sync_problem, size: 48, color: Colors.amber),
                SizedBox(height: 16),
                Text(
                  'Loading messages...',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Please wait while we set up your inbox',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }
        
        final threads = snapshot.data ?? [];
        
        if (threads.isEmpty) {
          return _buildEmptyStateContent();
        }
        
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          physics: const BouncingScrollPhysics(),
          itemCount: threads.length,
          separatorBuilder: (context, index) => Divider(
            height: 1,
            thickness: 0.5,
            color: const Color(0xFF9E9E9E),
          ),
          itemBuilder: (context, index) {
            return _buildThreadItem(threads[index]);
          },
        );
      },
    );
  }
  
  Widget _buildEmptyStateContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.mark_email_unread_outlined,
          size: 80,
          color: Colors.grey[400],
        ),
        const SizedBox(height: 20),
        Text(
          'No Messages',
          style: TextStyle(
            color: const Color(0xFF545454),
            fontSize: 22,
            fontFamily: 'Arial',
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            'You have no messages. When organizations respond to your requests, they will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xFF545454),
              fontSize: 14,
              fontFamily: 'Arial',
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildThreadItem(MessageThread thread) {
    // Get current user id
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return SizedBox.shrink();
    
    // Get the other participant (not current user)
    final String otherParticipantId = thread.participantIds.firstWhere(
      (id) => id != currentUser.uid,
      orElse: () => '',
    );
    
    if (otherParticipantId.isEmpty) return SizedBox.shrink();
    
    // Get other participant name
    final String otherParticipantName = thread.participantNames[otherParticipantId] ?? 'Unknown';
    
    // Format timestamp
    final String time = _formatMessageTime(thread.lastMessageTime);
    
    // Check if unread by current user
    final bool isUnread = thread.unreadByUser[currentUser.uid] ?? false;
    
    // Check if last message was sent by current user
    final bool sentByMe = thread.lastMessageSenderId == currentUser.uid;
    
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ConversationPage(
              threadId: thread.threadId,
              receiverId: otherParticipantId, 
              receiverName: otherParticipantName,
            ),
          ),
        ).then((_) {
          // Refresh the list when returning from conversation page
          setState(() {});
        });
      },
      child: Container(
        height: 80,
        margin: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            // Organization avatar - updated to show logo
            _buildOrganizationAvatar(otherParticipantId),
            
            const SizedBox(width: 15),
            
            // Message content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        otherParticipantName,
                        style: TextStyle(
                          color: const Color(0xFF545454),
                          fontSize: 16,
                          fontFamily: 'Arial',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        time,
                        style: TextStyle(
                          color: const Color(0xFF545454),
                          fontSize: 12,
                          fontFamily: 'Arial',
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 5),
                  Row(
                    children: [
                      if (sentByMe) Text(
                        'You: ',
                        style: TextStyle(
                          color: const Color(0xFF545454),
                          fontSize: 14,
                          fontFamily: 'Arial',
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          thread.lastMessageContent,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isUnread ? const Color(0xFF545454) : Colors.grey[600],
                            fontSize: 14,
                            fontFamily: 'Arial',
                            fontWeight: isUnread ? FontWeight.w700 : FontWeight.w400,
                          ),
                        ),
                      ),
                      if (isUnread)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
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
    );
  }
  
  // New method to build organization avatar with logo
  Widget _buildOrganizationAvatar(String organizationId) {
    return FutureBuilder<String?>(
      future: _getOrganizationLogo(organizationId),
      builder: (context, snapshot) {
        // Show placeholder while loading or if no logo
        if (!snapshot.hasData || snapshot.data == null) {
          return Container(
            width: 60,
            height: 60,
            decoration: ShapeDecoration(
              color: Colors.grey[200],
              shape: RoundedRectangleBorder(
                side: BorderSide(
                  width: 1,
                  color: Colors.black.withOpacity(0.5),
                ),
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: Icon(
              Icons.business,
              color: Colors.grey[600],
              size: 30,
            ),
          );
        }
        
        // Show organization logo
        return Container(
          width: 60,
          height: 60,
          decoration: ShapeDecoration(
            shape: RoundedRectangleBorder(
              side: BorderSide(
                width: 1,
                color: Colors.black.withOpacity(0.5),
              ),
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: Image.network(
              snapshot.data!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                // Fallback to default icon on error
                return Container(
                  color: Colors.grey[200],
                  child: Icon(
                    Icons.business,
                    color: Colors.grey[600],
                    size: 30,
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
  
  // Method to get organization logo with caching
  Future<String?> _getOrganizationLogo(String organizationId) async {
    // Return from cache if available
    if (_orgLogoCache.containsKey(organizationId)) {
      return _orgLogoCache[organizationId];
    }
    
    try {
      // Fetch organization details
      final organization = await _organizationService.getOrganizationById(organizationId);
      
      // Store logo URL in cache
      _orgLogoCache[organizationId] = organization?.logo_url;
      
      return organization?.logo_url;
    } catch (e) {
      print('Error fetching organization logo: $e');
      return null;
    }
  }
  
  String _formatMessageTime(DateTime messageTime) {
    final now = DateTime.now();
    final difference = now.difference(messageTime);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return DateFormat('MM/dd').format(messageTime);
    }
  }
}
