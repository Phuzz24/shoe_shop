import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/providers/auth_provider.dart';
import '/providers/product_provider.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final productProvider = Provider.of<ProductProvider>(context);
    final isDarkMode = authProvider.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo'),
        backgroundColor: isDarkMode ? const Color(0xFF0F3460) : Colors.blue[600]!,
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
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: authProvider.user != null
              ? productProvider.fetchNotifications(authProvider.user!.uid) as Future<List<Map<String, dynamic>>>
              : Future.value(<Map<String, dynamic>>[]),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Text('Chưa có thông báo', style: TextStyle(fontSize: 18)),
              );
            }
            final notifications = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return Card(
                  color: isDarkMode ? Colors.grey[900] : Colors.white,
                  elevation: 4,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: ListTile(
                    title: Text(
                      notification['title'] ?? 'Thông báo',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    subtitle: Text(
                      notification['message'] ?? '',
                      style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54),
                    ),
                    trailing: IconButton(
                      icon: Icon(
                        Icons.delete,
                        color: isDarkMode ? Colors.red[700] : Colors.red[600],
                      ),
                      onPressed: () async {
                        if (authProvider.user != null) {
                          await FirebaseFirestore.instance
                              .collection('users')
                              .doc(authProvider.user!.uid)
                              .collection('notifications')
                              .doc(notification['id'])
                              .delete();
                          productProvider.notifyListeners(); // Refresh notifications
                        }
                      },
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}