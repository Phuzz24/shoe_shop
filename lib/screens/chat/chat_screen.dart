import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/providers/auth_provider.dart';
import '/screens/auth/login_screen.dart';
import '/widgets/custom_app_bar.dart';
import 'dart:developer' as developer;

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isLoading = false;
  String? _selectedChatId;
  List<DocumentSnapshot> _messages = [];
  DocumentSnapshot? _lastMessageDoc;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels == _scrollController.position.minScrollExtent && !_isLoading && _lastMessageDoc != null) {
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

  Future<void> _createNewChat() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    if (user == null || _isLoading) {
      developer.log('Error: User is null or loading in _createNewChat', name: 'ChatDebug');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final newChatId = FirebaseFirestore.instance.collection('chats').doc().id;
      final chatRef = FirebaseFirestore.instance.collection('chats').doc(newChatId);
      final userData = authProvider.userData;
      final name = userData?['name'] ?? 'User';

      await chatRef.set({
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastSenderId': '',
      });
      await chatRef.collection('participants').doc(user.uid).set({
        'userId': user.uid,
        'joinedAt': FieldValue.serverTimestamp(),
      });
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'chatIds': FieldValue.arrayUnion([newChatId]),
      }, SetOptions(merge: true));

      if (mounted) {
        setState(() {
          _selectedChatId = newChatId;
          _messages = [];
          _lastMessageDoc = null;
        });
        await _loadMoreMessages();
      }
    } catch (e) {
      developer.log('Error creating chat: $e', name: 'ChatDebug');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tạo chat: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _sendMessage(String chatId, String userId, String name, [String? initialMessage]) async {
    if ((initialMessage == null && _messageController.text.trim().isEmpty) || chatId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng nhập tin nhắn!'), backgroundColor: Colors.red),
        );
      }
      return;
    }

    setState(() => _isLoading = true);
    try {
      final message = initialMessage ?? _messageController.text.trim();
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add({
        'senderId': userId,
        'senderName': name,
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });
      await FirebaseFirestore.instance.collection('chats').doc(chatId).update({
        'lastMessage': message,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastSenderId': userId,
      });

      if (initialMessage == null) _messageController.clear();
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
    } catch (e) {
      developer.log('Error sending message: $e', name: 'ChatDebug');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi gửi tin nhắn: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
      if (snapshot.docs.isNotEmpty) {
        setState(() {
          _messages.insertAll(0, snapshot.docs);
          _lastMessageDoc = snapshot.docs.last;
        });
      }
    } catch (e) {
      developer.log('Error loading messages: $e', name: 'ChatDebug');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải thêm tin nhắn: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<List<DocumentSnapshot>> _getChatList(String userId) async {
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      final chatIds = List<String>.from(userDoc.data()?['chatIds'] ?? []);
      developer.log('ChatIds for user $userId: $chatIds', name: 'ChatDebug');
      final allDocs = <DocumentSnapshot>[];
      for (final chatId in chatIds) {
        final chatDoc = await FirebaseFirestore.instance.collection('chats').doc(chatId).get();
        if (chatDoc.exists) {
          allDocs.add(chatDoc);
          developer.log('Fetched chat $chatId', name: 'ChatDebug');
        } else {
          developer.log('Chat $chatId does not exist', name: 'ChatDebug');
        }
      }
      developer.log('Total valid chats: ${allDocs.length}', name: 'ChatDebug');
      return allDocs;
    } catch (e) {
      developer.log('Error fetching chat list: $e', name: 'ChatDebug');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final userData = authProvider.userData;

    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        }
      });
      return const SizedBox();
    }

    final name = userData?['name'] ?? 'User';
    final isDarkMode = authProvider.isDarkMode;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Chat Hỗ Trợ',
        showUserName: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Container(
              color: isDarkMode ? const Color(0xFF1A1A2E) : Colors.white,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _createNewChat,
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : const Text('Tạo Cuộc Trò Chuyện Mới'),
                          ),
                        ),
                        if (_selectedChatId != null)
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteChat(_selectedChatId!),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: FutureBuilder<List<DocumentSnapshot>>(
                      future: _getChatList(user.uid),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          developer.log('ChatScreen: Error loading chats: ${snapshot.error}', name: 'ChatDebug');
                          return Center(
                            child: Text(
                              'Lỗi tải danh sách chat: ${snapshot.error}',
                              style: const TextStyle(color: Colors.red),
                            ),
                          );
                        }
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return const Center(
                            child: Text(
                              'Chưa có cuộc trò chuyện nào',
                              style: TextStyle(color: Colors.grey),
                            ),
                          );
                        }

                        final chats = snapshot.data!.whereType<DocumentSnapshot>().toList();
                        return ListView.builder(
                          itemCount: chats.length,
                          itemBuilder: (context, index) {
                            final chat = chats[index];
                            final chatId = chat.id;
                            return ListTile(
                              title: const Text('Chat với ai đó'), // Tạm thời, sẽ cải thiện sau
                              subtitle: StreamBuilder<DocumentSnapshot>(
                                stream: FirebaseFirestore.instance.collection('chats').doc(chatId).snapshots(),
                                builder: (context, chatSnapshot) {
                                  if (!chatSnapshot.hasData) return const SizedBox.shrink();
                                  final lastMessage = chatSnapshot.data?.get('lastMessage') ?? '';
                                  return Text(lastMessage, maxLines: 1, overflow: TextOverflow.ellipsis);
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
                    ),
                  ),
                  if (_selectedChatId != null)
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('chats')
                            .doc(_selectedChatId!)
                            .collection('messages')
                            .orderBy('timestamp', descending: true)
                            .limit(20)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          if (snapshot.hasError) {
                            return Center(child: Text('Lỗi: ${snapshot.error}'));
                          }
                          _messages = snapshot.data!.docs;
                          return Column(
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
                                    final isUserMessage = message['senderId'] == user.uid;
                                    final isSystemMessage = message['senderId'] == 'system';

                                    return Row(
                                      mainAxisAlignment: isUserMessage
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
                                                  : isUserMessage
                                                      ? const Color(0xFF4A90E2)
                                                      : (isDarkMode ? Colors.grey[800] : Colors.grey[200]),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Padding(
                                                padding: const EdgeInsets.all(12.0),
                                                child: Column(
                                                  crossAxisAlignment: isUserMessage
                                                      ? CrossAxisAlignment.end
                                                      : CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      message['senderName'] ?? 'Unknown',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.bold,
                                                        color: isUserMessage || isSystemMessage
                                                            ? Colors.white
                                                            : (isDarkMode ? Colors.white : Colors.black87),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      message['message'],
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                        color: isUserMessage || isSystemMessage
                                                            ? Colors.white
                                                            : (isDarkMode ? Colors.white : Colors.black87),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      _formatTimestamp(message['timestamp']),
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        color: isUserMessage || isSystemMessage
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
                                        if (isUserMessage && !isSystemMessage)
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
                                        onPressed: _isLoading
                                            ? null
                                            : () => _sendMessage(_selectedChatId!, user.uid, name),
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
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final dateTime = timestamp.toDate();
    return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')} '
        '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  Future<void> _recallMessage(String messageId, String chatId) async {
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
          if (currentTime.difference(sentTime).inMinutes <= 1) {
            await messageRef.delete();
            await FirebaseFirestore.instance
                .collection('chats')
                .doc(chatId)
                .collection('messages')
                .add({
              'senderId': 'system',
              'senderName': 'System',
              'message': 'Tin nhắn đã được thu hồi',
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
                const SnackBar(content: Text('Chỉ có thể thu hồi trong 1 phút!'), backgroundColor: Colors.red),
              );
            }
          }
        }
      }
    } catch (e) {
      developer.log('Error recalling message: $e', name: 'ChatDebug');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi thu hồi tin nhắn: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteChat(String chatId) async {
    try {
      final chatRef = FirebaseFirestore.instance.collection('chats').doc(chatId);
      final batch = FirebaseFirestore.instance.batch();
      final participants = await chatRef.collection('participants').get();
      for (var doc in participants.docs) {
        batch.delete(doc.reference);
      }
      final messages = await chatRef.collection('messages').get();
      for (var doc in messages.docs) {
        batch.delete(doc.reference);
      }
      batch.delete(chatRef);
      final user = Provider.of<AuthProvider>(context, listen: false).user;
      if (user != null) {
        batch.update(FirebaseFirestore.instance.collection('users').doc(user.uid), {
          'chatIds': FieldValue.arrayRemove([chatId]),
        });
      }
      await batch.commit();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa cuộc trò chuyện!'), backgroundColor: Colors.green),
        );
        setState(() {
          _selectedChatId = null;
          _messages = [];
          _lastMessageDoc = null;
        });
      }
    } catch (e) {
      developer.log('Error deleting chat: $e', name: 'ChatDebug');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi xóa cuộc trò chuyện: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}