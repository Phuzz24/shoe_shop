import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '/providers/auth_provider.dart';
import '/screens/auth/login_screen.dart';
import '/screens/profile/order_history_screen.dart'; // Thêm màn hình lịch sử đơn hàng (sẽ tạo bên dưới)

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final userData = authProvider.userData;
    final isDarkMode = authProvider.isDarkMode;

    if (user == null) {
      return const LoginScreen();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hồ Sơ Của Bạn', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
        backgroundColor: isDarkMode ? const Color(0xFF1A1A2E) : Colors.blue[700],
        elevation: 4,
        centerTitle: true,
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Card(
                elevation: 8,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                color: isDarkMode ? Colors.grey[850] : Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundImage: userData?['photoURL'] != null &&
                                userData!['photoURL'].isNotEmpty
                            ? NetworkImage(userData!['photoURL']) as ImageProvider // Sử dụng NetworkImage thay FileImage
                            : null,
                        child: userData?['photoURL'] == null ||
                                userData!['photoURL'].isEmpty
                            ? const Icon(Icons.person, size: 60, color: Colors.grey)
                            : null,
                        backgroundColor: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        userData?['name'] ?? user.email!.split('@')[0],
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        user.email!,
                        style: TextStyle(
                          fontSize: 16,
                          color: isDarkMode ? Colors.white70 : Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (userData?['bio'] != null && userData!['bio'].isNotEmpty)
                        Text(
                          userData!['bio'],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDarkMode ? Colors.white54 : Colors.grey[500],
                          ),
                        ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.calendar_today, size: 16, color: isDarkMode ? Colors.white70 : Colors.grey[600]),
                          const SizedBox(width: 8),
                          Text(
                            userData?['createdAt'] != null
                                ? 'Tham gia: ${DateFormat('dd/MM/yyyy').format((userData!['createdAt'] as Timestamp).toDate())}'
                                : 'Tham gia: Chưa rõ',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDarkMode ? Colors.white70 : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildActionCard(
                    context,
                    icon: Icons.edit,
                    label: 'Chỉnh sửa hồ sơ',
                    onPressed: () => Navigator.pushNamed(context, '/edit_profile'),
                    isDarkMode: isDarkMode,
                  ),
                  const SizedBox(height: 12),
                  _buildActionCard(
                    context,
                    icon: Icons.history,
                    label: 'Xem lịch sử đơn hàng',
                    onPressed: () => Navigator.pushNamed(context, '/order_history'),
                    isDarkMode: isDarkMode,
                  ),
                  const SizedBox(height: 12),
                  _buildActionCard(
                    context,
                    icon: Icons.favorite,
                    label: 'Danh sách yêu thích',
                    onPressed: () => Navigator.pushNamed(context, '/favorites'),
                    isDarkMode: isDarkMode,
                  ),
                  const SizedBox(height: 12),
                  _buildActionCard(
                    context,
                    icon: Icons.notifications,
                    label: 'Thông báo',
                    onPressed: () => Navigator.pushNamed(context, '/notifications'),
                    isDarkMode: isDarkMode,
                  ),
                  const SizedBox(height: 12),
                  _buildActionCard(
                    context,
                    icon: Icons.delete,
                    label: 'Xóa tài khoản',
                    onPressed: () async {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Xác nhận xóa'),
                          content: const Text('Bạn có chắc muốn xóa tài khoản? Hành động này không thể hoàn tác.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Hủy'),
                            ),
                            TextButton(
                              onPressed: () async {
                                await authProvider.deleteAccount();
                                Navigator.pushReplacementNamed(context, '/login');
                              },
                              child: const Text('Xóa'),
                            ),
                          ],
                        ),
                      );
                    },
                    isDarkMode: isDarkMode,
                  ),
                  const SizedBox(height: 12),
                  _buildActionCard(
                    context,
                    icon: Icons.logout,
                    label: 'Đăng xuất',
                    onPressed: () async {
                      await authProvider.signOut();
                      Navigator.pushReplacementNamed(context, '/login');
                    },
                    isDarkMode: isDarkMode,
                    isLogout: true,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required bool isDarkMode,
    bool isLogout = false,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: isLogout
          ? Colors.red[700]
          : (isDarkMode ? Colors.grey[800] : Colors.white),
      child: ListTile(
        leading: Icon(icon, color: isLogout ? Colors.white : (isDarkMode ? Colors.blue[200] : Colors.blue[700])),
        title: Text(
          label,
          style: TextStyle(
            fontSize: 16,
            color: isLogout ? Colors.white : (isDarkMode ? Colors.white : Colors.black87),
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onPressed,
        tileColor: isLogout
            ? Colors.red[700]
            : (isDarkMode ? Colors.grey[800] : Colors.white),
      ),
    );
  }
}