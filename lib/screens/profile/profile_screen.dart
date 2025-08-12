import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '/providers/auth_provider.dart';
import '/screens/auth/login_screen.dart';
import '/screens/profile/order_history_screen.dart';
import '/widgets/custom_app_bar.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'dart:convert';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final userData = authProvider.userData;
    final isDarkMode = authProvider.isDarkMode;
    final screenWidth = MediaQuery.of(context).size.width;
    final avatarRadius = screenWidth < 400 ? 50.0 : 60.0;

    if (user == null) {
      return Scaffold(
        appBar: CustomAppBar(
          title: 'Hồ Sơ Của Bạn',
          showUserName: false,
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDarkMode
                  ? [const Color(0xFF1A1A2E), const Color(0xFF16213E).withOpacity(0.9)]
                  : [Colors.white, Colors.grey[100]!.withOpacity(0.9)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.person_outline,
                  size: 80,
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
                const SizedBox(height: 20),
                Text(
                  'Bạn chưa đăng nhập',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Vui lòng đăng nhập để xem thông tin hồ sơ.',
                  style: TextStyle(
                    fontSize: 16,
                    color: isDarkMode ? Colors.white70 : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/login');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A90E2),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Đăng nhập ngay'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Hồ Sơ Của Bạn',
        showUserName: false,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDarkMode
                ? [const Color(0xFF1A1A2E), const Color(0xFF16213E).withOpacity(0.9)]
                : [Colors.white, Colors.grey[100]!.withOpacity(0.9)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  color: isDarkMode ? Colors.grey[850] : Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: isDarkMode ? Colors.black45 : Colors.grey[400]!,
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: avatarRadius,
                            backgroundImage: _getAvatarImageProvider(userData?['photoURL']),
                            child: _getAvatarChild(userData?['photoURL']),
                            backgroundColor: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          userData?['name'] ?? user.email!.split('@')[0],
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isDarkMode ? Colors.white : Colors.black87,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          user.email!,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: isDarkMode ? Colors.white70 : Colors.grey[600],
                              ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 12,
                          runSpacing: 8,
                          children: [
                            if (userData?['bio'] != null && userData!['bio'].isNotEmpty)
                              _buildInfoChip(
                                context,
                                icon: Icons.info,
                                label: userData!['bio'],
                                isDarkMode: isDarkMode,
                              ),
                            if (userData?['phone'] != null && userData!['phone'].isNotEmpty)
                              _buildInfoChip(
                                context,
                                icon: Icons.phone,
                                label: userData!['phone'],
                                isDarkMode: isDarkMode,
                              ),
                            if (userData?['birthDate'] != null)
                              _buildInfoChip(
                                context,
                                icon: Icons.cake,
                                label: DateFormat('dd/MM/yyyy')
                                    .format((userData!['birthDate'] as Timestamp).toDate()),
                                isDarkMode: isDarkMode,
                              ),
                            if (userData?['gender'] != null && userData!['gender'].isNotEmpty)
                              _buildInfoChip(
                                context,
                                icon: Icons.person_outline,
                                label: userData!['gender'],
                                isDarkMode: isDarkMode,
                              ),
                            _buildInfoChip(
                              context,
                              icon: Icons.calendar_today,
                              label: userData?['createdAt'] != null
                                  ? 'Tham gia: ${DateFormat('dd/MM/yyyy').format((userData!['createdAt'] as Timestamp).toDate())}'
                                  : 'Tham gia: Chưa rõ',
                              isDarkMode: isDarkMode,
                            ),
                          ],
                        ),
                      ],
                    ),
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
                    tooltip: 'Cập nhật thông tin cá nhân',
                    onPressed: () => Navigator.pushNamed(context, '/edit_profile'),
                    isDarkMode: isDarkMode,
                  ),
                  const SizedBox(height: 10),
                  _buildActionCard(
                    context,
                    icon: Icons.history,
                    label: 'Lịch sử đơn hàng',
                    tooltip: 'Xem các đơn hàng trước đây',
                    onPressed: () => Navigator.pushNamed(context, '/order_history'),
                    isDarkMode: isDarkMode,
                  ),
                  const SizedBox(height: 10),
                  _buildActionCard(
                    context,
                    icon: Icons.favorite,
                    label: 'Danh sách yêu thích',
                    tooltip: 'Xem sản phẩm yêu thích',
                    onPressed: () => Navigator.pushNamed(context, '/favorites'),
                    isDarkMode: isDarkMode,
                  ),
                  const SizedBox(height: 10),
                  _buildActionCard(
                    context,
                    icon: Icons.notifications,
                    label: 'Thông báo',
                    tooltip: 'Xem thông báo mới',
                    onPressed: () => Navigator.pushNamed(context, '/notifications'),
                    isDarkMode: isDarkMode,
                  ),
                  const SizedBox(height: 10),
                  _buildActionCard(
                    context,
                    icon: Icons.delete,
                    label: 'Xóa tài khoản',
                    tooltip: 'Xóa tài khoản vĩnh viễn',
                    onPressed: () async {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Xác nhận xóa'),
                          content: const Text('Bạn có chắc muốn xóa tài khoản? Hành động này không thể hoàn tác.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
                            ),
                            TextButton(
                              onPressed: () async {
                                await authProvider.deleteAccount();
                                Navigator.pushReplacementNamed(context, '/login');
                              },
                              child: const Text('Xóa', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                          backgroundColor: isDarkMode ? Colors.grey[850] : Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                      );
                    },
                    isDarkMode: isDarkMode,
                  ),
                  const SizedBox(height: 10),
                  _buildActionCard(
                    context,
                    icon: Icons.logout,
                    label: 'Đăng xuất',
                    tooltip: 'Đăng xuất khỏi tài khoản',
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

  ImageProvider? _getAvatarImageProvider(String? photoUrl) {
    if (photoUrl == null || photoUrl.isEmpty) return null;
    if (photoUrl.contains(RegExp(r'^[A-Za-z0-9+/=]+'))) {
      try {
        return MemoryImage(base64Decode(photoUrl));
      } catch (e) {
        print('Invalid base64 in profile: $photoUrl, Error: $e');
        return null;
      }
    }
    return CachedNetworkImageProvider(photoUrl);
  }

  Widget? _getAvatarChild(String? photoUrl) {
    if (photoUrl == null || photoUrl.isEmpty) {
      return Icon(Icons.person, size: 60, color: Colors.grey);
    }
    return null;
  }

  Widget _buildInfoChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool isDarkMode,
  }) {
    return Chip(
      avatar: Icon(icon, size: 16, color: isDarkMode ? Colors.blue[200] : Colors.blue[700]),
      label: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isDarkMode ? Colors.white70 : Colors.black87,
            ),
      ),
      backgroundColor: isDarkMode ? Colors.grey[800] : Colors.grey[100],
      padding: const EdgeInsets.symmetric(horizontal: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required bool isDarkMode,
    bool isLogout = false,
    String? tooltip,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: isLogout
            ? Colors.red[700]
            : (isDarkMode ? Colors.grey[800] : Colors.white),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onPressed,
          child: Tooltip(
            message: tooltip ?? '',
            child: ListTile(
              leading: Icon(
                icon,
                color: isLogout ? Colors.white : (isDarkMode ? Colors.blue[200] : Colors.blue[700]),
                size: 20,
              ),
              title: Text(
                label,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: isLogout ? Colors.white : (isDarkMode ? Colors.white : Colors.black87),
                      fontSize: 15,
                    ),
              ),
              trailing: Icon(
                Icons.chevron_right,
                color: isLogout ? Colors.white70 : Colors.grey,
                size: 20,
              ),
              tileColor: isLogout
                  ? Colors.red[700]
                  : (isDarkMode ? Colors.grey[800] : Colors.white),
              hoverColor: isLogout
                  ? Colors.red[600]
                  : (isDarkMode ? Colors.grey[700] : Colors.grey[100]),
              focusColor: isLogout
                  ? Colors.red[600]
                  : (isDarkMode ? Colors.grey[700] : Colors.grey[100]),
              splashColor: isLogout
                  ? Colors.red[500]!.withOpacity(0.3)
                  : (isDarkMode ? Colors.blue[200]!.withOpacity(0.2) : Colors.blue[100]!.withOpacity(0.2)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              visualDensity: VisualDensity.compact,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onTap: onPressed,
            ),
          ),
        ),
      ),
    );
  }
}