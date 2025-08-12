import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/providers/auth_provider.dart';
import 'dart:developer' as developer;

class ChatManagementScreen extends StatefulWidget {
  const ChatManagementScreen({super.key});

  @override
  State<ChatManagementScreen> createState() => _ChatManagementScreenState();
}

class _ChatManagementScreenState extends State<ChatManagementScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  String? _selectedChatId;
  DocumentSnapshot? _lastMessageDoc;
  List<DocumentSnapshot> _messages = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels == _scrollController.position.minScrollExtent && !_isLoading) {
        _loadMoreMessages();
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  bool _isLoading = false;

  Future<void> _sendMessage(String chatId) async {
    if (_messageController.text.trim().isEmpty || _selectedChatId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vui lòng chọn cuộc trò chuyện và nhập tin nhắn!'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add({
        'senderId': 'admin',
        'senderName': 'Admin',
        'message': _messageController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });
      await FirebaseFirestore.instance.collection('chats').doc(chatId).update({
        'lastMessage': _messageController.text.trim(),
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastSenderId': 'admin',
      });
      _messageController.clear();
      if (mounted && _scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tin nhắn đã gửi!'), backgroundColor: Colors.green),
        );
      }
      // Đánh dấu tin nhắn của user là đã đọc
      final messages = await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('senderId', isNotEqualTo: 'admin')
          .where('isRead', isEqualTo: false)
          .get();
      for (var message in messages.docs) {
        await message.reference.update({'isRead': true});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi gửi tin nhắn: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _recallMessage(String messageId, String chatId) async {
    if (!mounted) return;
    try {
      final messageRef = FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId);
      final messageSnapshot = await messageRef.get();
      if (messageSnapshot.exists) {
        final timestamp = messageSnapshot.get('timestamp') as Timestamp?;
        if (timestamp != null) {
          final sentTime = timestamp.toDate();
          final currentTime = DateTime.now();
          if (currentTime.difference(sentTime).inMinutes <= 5) {
            await messageRef.delete();
            await FirebaseFirestore.instance
                .collection('chats')
                .doc(chatId)
                .collection('messages')
                .add({
              'senderId': 'system',
              'senderName': 'System',
              'message': 'Tin nhắn đã được thu hồi bởi Admin',
              'timestamp': FieldValue.serverTimestamp(),
              'type': 'recall',
            });
            if (mounted && _scrollController.hasClients) {
              _scrollController.animateTo(
                _scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tin nhắn đã được thu hồi!'), backgroundColor: Colors.green),
              );
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Chỉ có thể thu hồi trong 5 phút!'), backgroundColor: Colors.red),
              );
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi thu hồi tin nhắn: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _loadMoreMessages() async {
    if (_selectedChatId == null || _isLoading) return;
    setState(() => _isLoading = true);
    try {
      Query<Map<String, dynamic>> query = FirebaseFirestore.instance
          .collection('chats')
          .doc(_selectedChatId!)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(20);
      if (_lastMessageDoc != null) {
        query = query.startAfterDocument(_lastMessageDoc!);
      }
      final snapshot = await query.get();
      setState(() {
        _messages.addAll(snapshot.docs);
        _lastMessageDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải thêm tin nhắn: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isDarkMode = authProvider.isDarkMode;
    final isAdmin = authProvider.user != null && authProvider.userData?['role'] == 'admin';

    if (!isAdmin) {
      return const Center(
        child: Text(
          'Bạn không có quyền truy cập trang này!',
          style: TextStyle(color: Colors.red),
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            decoration: InputDecoration(
              hintText: 'Tìm kiếm theo tên người dùng...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[100],
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('chats').snapshots(),
            builder: (context, snapshot) {
              developer.log('ChatManagementScreen: Chat list snapshot: ${snapshot.data?.docs.length ?? 0} chats', name: 'ChatDebug');
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                developer.log('ChatManagementScreen: Error loading chats: ${snapshot.error}', name: 'ChatDebug');
                return Center(
                  child: Text(
                    'Lỗi tải danh sách chat: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red),
                  ),
                );
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                developer.log('ChatManagementScreen: No chats found', name: 'ChatDebug');
                return const Center(
                  child: Text(
                    'Không có cuộc trò chuyện nào',
                    style: TextStyle(color: Colors.grey),
                  ),
                );
              }

              final chats = snapshot.data!.docs;

              return ListView.builder(
                itemCount: chats.length,
                itemBuilder: (context, index) {
                  final chat = chats[index];
                  final chatId = chat.id;
                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('chats')
                        .doc(chatId)
                        .collection('participants')
                        .snapshots(),
                    builder: (context, participantSnapshot) {
                      if (participantSnapshot.connectionState == ConnectionState.waiting) {
                        return const ListTile(title: Text('Đang tải...'));
                      }
                      final participants = participantSnapshot.data?.docs ?? [];
                      final userIds = participants.map((doc) => doc.id).where((id) => id != 'admin').toList();
                      return FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('users')
                            .doc(userIds.isNotEmpty ? userIds.first : 'unknown')
                            .get(),
                        builder: (context, userSnapshot) {
                          if (!userSnapshot.hasData) return const ListTile(title: Text('Đang tải...'));
                          final userName = userSnapshot.data?.get('name') ?? 'Unknown User';
                          if (_searchQuery.isNotEmpty && !userName.toLowerCase().contains(_searchQuery.toLowerCase())) {
                            return const SizedBox.shrink();
                          }
                          return ListTile(
                            title: Text('Chat với $userName'),
                            subtitle: StreamBuilder<DocumentSnapshot>(
                              stream: FirebaseFirestore.instance.collection('chats').doc(chatId).snapshots(),
                              builder: (context, chatSnapshot) {
                                if (!chatSnapshot.hasData) return const SizedBox.shrink();
                                final lastMessage = chatSnapshot.data?.get('lastMessage') ?? '';
                                return Text(
                                  lastMessage,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                );
                              },
                            ),
                            onTap: () {
                              setState(() {
                                _selectedChatId = chatId;
                                _messages = [];
                                _lastMessageDoc = null;
                                _loadMoreMessages();
                              });
                            },
                            selected: _selectedChatId == chatId,
                            tileColor: _selectedChatId == chatId
                                ? (isDarkMode ? Colors.grey[800] : Colors.grey[200])
                                : null,
                          );
                        },
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
        if (_selectedChatId != null)
          Expanded(
            flex: 3,
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.all(16.0),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index].data() as Map<String, dynamic>;
                      final messageId = _messages[index].id;
                      final isAdminMessage = message['senderId'] == 'admin';
                      final isSystemMessage = message['senderId'] == 'system';

                      return Row(
                        mainAxisAlignment: isAdminMessage
                            ? MainAxisAlignment.end
                            : MainAxisAlignment.start,
                        children: [
                          Flexible(
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4.0),
                              constraints: BoxConstraints(
                                maxWidth: MediaQuery.of(context).size.width * 0.6,
                              ),
                              child: Card(
                                elevation: 2,
                                color: isSystemMessage
                                    ? Colors.grey[600]
                                    : isAdminMessage
                                        ? const Color(0xFF50C9C3)
                                        : (isDarkMode ? Colors.grey[800] : Colors.grey[200]),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment: isAdminMessage
                                        ? CrossAxisAlignment.end
                                        : CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        message['senderName'] ?? 'Unknown',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: isAdminMessage || isSystemMessage
                                              ? Colors.white
                                              : (isDarkMode ? Colors.white : Colors.black87),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        message['message'],
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: isAdminMessage || isSystemMessage
                                              ? Colors.white
                                              : (isDarkMode ? Colors.white : Colors.black87),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _formatTimestamp(message['timestamp']),
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: isAdminMessage || isSystemMessage
                                              ? Colors.white70
                                              : (isDarkMode ? Colors.white70 : Colors.grey),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          if (!isSystemMessage)
                            IconButton(
                              icon: const Icon(Icons.undo, color: Colors.red),
                              onPressed: () => _recallMessage(messageId, _selectedChatId!),
                            ),
                        ],
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: isDarkMode ? const Color(0xFF1A1A2E) : Colors.white,
                    border: Border(
                      top: BorderSide(
                        color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          style: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Nhập tin nhắn...',
                            hintStyle: TextStyle(
                              color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF4A90E2), Color(0xFF50C9C3)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          onPressed: _isLoading ? null : () => _sendMessage(_selectedChatId!),
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Icon(Icons.send, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final dateTime = timestamp.toDate();
    return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')} '
        '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
}