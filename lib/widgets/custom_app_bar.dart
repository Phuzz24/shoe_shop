import 'dart:convert'; // Thêm import này để sử dụng base64Decode
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/providers/auth_provider.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showUserName;
  final List<Widget>? actions; // Thêm tham số actions

  const CustomAppBar({
    super.key,
    required this.title,
    this.showUserName = false,
    this.actions, // Thêm vào constructor
  });

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isDarkMode = authProvider.isDarkMode;
    final userData = authProvider.userData;
    final isLoggedIn = authProvider.user != null; // Kiểm tra trạng thái đăng nhập
    final currentRoute = ModalRoute.of(context)?.settings.name;

    // Chỉ hiển thị nút back khi không ở các màn hình gốc và có thể quay lại
    bool shouldShowBackButton = Navigator.canPop(context) &&
        currentRoute != '/main' &&
        currentRoute != '/login' &&
        currentRoute != '/register';

    return AppBar(
      leading: SizedBox(
        width: 56, // Giới hạn chiều rộng của leading
        child: Row(
          children: [
            if (shouldShowBackButton)
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.only(left: 8.0), // Margin-left cho logo
                child: Image.asset(
                  'assets/logo2.png', // Đường dẫn logo đã khai báo trong pubspec.yaml
                  height: 40,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.store, color: Colors.white, size: 40);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDarkMode ? Colors.white : Colors.black87,
          fontWeight: FontWeight.bold,
          overflow: TextOverflow.ellipsis, // Ngăn tràn văn bản
        ),
      ),
      backgroundColor: isDarkMode ? const Color(0xFF263238) : const Color(0xFF4FC3F7),
      elevation: 4,
      actions: [
        IconButton(
          icon: Icon(
            isDarkMode ? Icons.light_mode : Icons.dark_mode,
            color: Colors.white,
          ),
          tooltip: isDarkMode ? 'Chuyển sang chế độ sáng' : 'Chuyển sang chế độ tối',
          onPressed: () {
            authProvider.toggleDarkMode();
          },
        ),
        Padding(
          padding: const EdgeInsets.only(right: 12.0),
          child: GestureDetector(
            onTap: () => Navigator.pushNamed(context, isLoggedIn ? '/profile' : '/login'),
            child: CircleAvatar(
              radius: 18,
              backgroundImage: _getAvatarImageProvider(userData, isLoggedIn),
              child: _getAvatarChild(userData, isLoggedIn),
              backgroundColor: isDarkMode ? Colors.grey[700] : Colors.grey[300],
            ),
          ),
        ),
      ],
    );
  }

  ImageProvider? _getAvatarImageProvider(Map<String, dynamic>? userData, bool isLoggedIn) {
    if (!isLoggedIn || userData == null || userData['photoURL'] == null || userData['photoURL'].isEmpty) {
      return null; // Không có ảnh khi chưa đăng nhập hoặc không có photoURL
    }

    final photoUrl = userData['photoURL'] as String;
    // Kiểm tra xem photoURL có phải là base64
    if (photoUrl.contains(RegExp(r'^data:image\/[a-z]+;base64,')) || photoUrl.contains(RegExp(r'^[A-Za-z0-9+/=]+'))) {
      try {
        // Loại bỏ tiền tố "data:image/..." nếu có
        final base64String = photoUrl.startsWith('data:image')
            ? photoUrl.split(',')[1]
            : photoUrl;
        return MemoryImage(base64Decode(base64String)); // Giải mã base64
      } catch (e) {
        debugPrint('Invalid base64 in CustomAppBar: $photoUrl, Error: $e');
        return null;
      }
    }
    return CachedNetworkImageProvider(photoUrl); // Ảnh từ URL
  }

  Widget? _getAvatarChild(Map<String, dynamic>? userData, bool isLoggedIn) {
    if (!isLoggedIn || userData == null || userData['photoURL'] == null || userData['photoURL'].isEmpty) {
      return const Icon(Icons.person, size: 18, color: Colors.grey); // Biểu tượng mặc định
    }
    return null;
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}