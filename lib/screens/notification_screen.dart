import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/providers/auth_provider.dart';
import '/providers/product_provider.dart';
import '/widgets/custom_app_bar.dart';
import 'package:intl/intl.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  String _selectedFilter = 'Tất cả'; // Bộ lọc thông báo
  final List<String> _filterOptions = ['Tất cả', 'Đơn hàng', 'Yêu thích', 'Khuyến mãi'];

  // Đánh dấu tất cả thông báo là đã đọc
  Future<void> _markAllAsRead(String userId) async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      final notifications = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .get();
      for (var doc in notifications.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
      Provider.of<AuthProvider>(context, listen: false).checkNotifications();
    } catch (e) {
      debugPrint('Error marking all as read: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi đánh dấu tất cả là đã đọc: $e')),
      );
    }
  }

  // Xóa tất cả thông báo
  Future<void> _deleteAllNotifications(String userId) async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      final notifications = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .get();
      for (var doc in notifications.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      Provider.of<AuthProvider>(context, listen: false).checkNotifications();
    } catch (e) {
      debugPrint('Error deleting all notifications: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi xóa tất cả thông báo: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final productProvider = Provider.of<ProductProvider>(context);
    final isDarkMode = authProvider.isDarkMode;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Thông báo',
        showUserName: false,
        actions: [
          if (authProvider.user != null)
            PopupMenuButton<String>(
              icon: const Icon(Icons.filter_list),
              onSelected: (value) => setState(() => _selectedFilter = value),
              itemBuilder: (context) => _filterOptions
                  .map((option) => PopupMenuItem(
                        value: option,
                        child: Text(option),
                      ))
                  .toList(),
            ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDarkMode
                ? [const Color(0xFF1A1A2E), const Color(0xFF16213E)]
                : [Colors.white, Colors.grey[200]!],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: authProvider.user == null
            ? const Center(child: Text('Vui lòng đăng nhập để xem thông báo', style: TextStyle(fontSize: 18)))
            : Column(
                children: [
                  // Nút hành động
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _markAllAsRead(authProvider.user!.uid),
                          icon: const Icon(Icons.mark_email_read, size: 18),
                          label: const Text('Đánh dấu tất cả đã đọc'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDarkMode ? Colors.green[700] : Colors.green[500],
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _deleteAllNotifications(authProvider.user!.uid),
                          icon: const Icon(Icons.delete_sweep, size: 18),
                          label: const Text('Xóa tất cả'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDarkMode ? Colors.red[700] : Colors.red[500],
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Danh sách thông báo
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .doc(authProvider.user!.uid)
                          .collection('notifications')
                          .orderBy('createdAt', descending: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          debugPrint('Error fetching notifications: ${snapshot.error}');
                          return Center(
                            child: Text(
                              'Lỗi khi tải thông báo: ${snapshot.error}',
                              style: const TextStyle(fontSize: 18),
                              textAlign: TextAlign.center,
                            ),
                          );
                        }
                        final notifications = snapshot.data?.docs.map((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              return {
                                'id': doc.id,
                                'title': data['title'] ?? 'Thông báo',
                                'message': data['message'] ?? '',
                                'isRead': data['isRead'] ?? false,
                                'type': data['type'] ?? 'Khác', // Thêm trường type để lọc
                                'createdAt': data['createdAt'] is Timestamp
                                    ? (data['createdAt'] as Timestamp).toDate()
                                    : DateTime.now(),
                              };
                            }).toList() ?? <Map<String, dynamic>>[];

                        // Lọc thông báo theo type
                        final filteredNotifications = _selectedFilter == 'Tất cả'
                            ? notifications
                            : notifications.where((n) => n['type'] == _selectedFilter).toList();

                        if (filteredNotifications.isEmpty) {
                          return Center(
                            child: Text(
                              _selectedFilter == 'Tất cả'
                                  ? 'Chưa có thông báo'
                                  : 'Chưa có thông báo thuộc loại $_selectedFilter',
                              style: const TextStyle(fontSize: 18),
                            ),
                          );
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.all(16.0),
                          itemCount: filteredNotifications.length,
                          itemBuilder: (context, index) {
                            final notification = filteredNotifications[index];
                            final isRead = notification['isRead'] ?? false;
                            final createdAt = notification['createdAt'] as DateTime;

                            return Card(
                              color: isRead
                                  ? (isDarkMode ? Colors.grey[800] : Colors.grey[50])
                                  : (isDarkMode ? Colors.grey[900] : Colors.white),
                              elevation: isRead ? 2 : 6,
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: isRead
                                      ? (isDarkMode ? Colors.grey[700] : Colors.grey[300])
                                      : (isDarkMode ? Colors.blue[200] : Colors.blue[300]),
                                  child: Icon(
                                    notification['type'] == 'Đơn hàng'
                                        ? Icons.shopping_bag
                                        : notification['type'] == 'Yêu thích'
                                            ? Icons.favorite
                                            : Icons.notifications,
                                    color: isRead
                                        ? (isDarkMode ? Colors.grey[400] : Colors.grey[600])
                                        : Colors.white,
                                  ),
                                ),
                                title: Text(
                                  notification['title'] ?? 'Thông báo',
                                  style: TextStyle(
                                    fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                                    color: isDarkMode ? Colors.white : Colors.black87,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      notification['message'] ?? '',
                                      style: TextStyle(
                                        color: isDarkMode ? Colors.white70 : Colors.black54,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Ngày: ${DateFormat('dd/MM/yyyy HH:mm').format(createdAt)}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (!isRead)
                                      IconButton(
                                        icon: Icon(
                                          Icons.mark_email_read,
                                          color: isDarkMode ? Colors.green[300] : Colors.green[700],
                                        ),
                                        onPressed: () async {
                                          try {
                                            await FirebaseFirestore.instance
                                                .collection('users')
                                                .doc(authProvider.user!.uid)
                                                .collection('notifications')
                                                .doc(notification['id'])
                                                .update({'isRead': true});
                                            authProvider.checkNotifications();
                                          } catch (e) {
                                            debugPrint('Error marking as read: $e');
                                          }
                                        },
                                      ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.delete,
                                        color: isDarkMode ? Colors.red[700] : Colors.red[600],
                                      ),
                                      onPressed: () async {
                                        try {
                                          await FirebaseFirestore.instance
                                              .collection('users')
                                              .doc(authProvider.user!.uid)
                                              .collection('notifications')
                                              .doc(notification['id'])
                                              .delete();
                                          authProvider.checkNotifications();
                                        } catch (e) {
                                          debugPrint('Error deleting notification: $e');
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}