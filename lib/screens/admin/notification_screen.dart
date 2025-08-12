import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shop_shop/providers/auth_provider.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isDarkMode = authProvider.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo'),
        backgroundColor: const Color(0xFF5A9BD4),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('admin_notifications')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Không có thông báo nào'));
          }

          final notifications = snapshot.data!.docs;

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index].data() as Map<String, dynamic>;
              final notificationId = notifications[index].id;
              final isRead = notification['isRead'] ?? false;

              return ListTile(
                title: Text(notification['title'] ?? 'Thông báo mới'),
                subtitle: Text(notification['message'] ?? ''),
                trailing: isRead
                    ? null
                    : const Icon(Icons.circle, color: Colors.blue, size: 12),
                onTap: () async {
                  if (!isRead) {
                    await FirebaseFirestore.instance
                        .collection('admin_notifications')
                        .doc(notificationId)
                        .update({'isRead': true});
                  }
                },
                tileColor: isDarkMode ? Colors.grey[800] : null,
              );
            },
          );
        },
      ),
    );
  }
}