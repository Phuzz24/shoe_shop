import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/providers/auth_provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '/providers/product_provider.dart';
import '/screens/cart_screen.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final bool showBackButton;
  final List<Widget>? actions;

  const CustomAppBar({
    super.key,
    this.title,
    this.showBackButton = false,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isDarkMode = authProvider.isDarkMode;
    final photoUrl = authProvider.userData?['photoURL'] as String?;
    final userName = authProvider.userData?['name'] as String? ?? 'User';
    final productProvider = Provider.of<ProductProvider>(context);
    final cartItemCount = productProvider.cartItems.length;

    return AppBar(
      backgroundColor: isDarkMode ? const Color(0xFF2E2E48) : const Color(0xFFE0E0E0),
      elevation: 2,
      leading: showBackButton
          ? IconButton(
              icon: Icon(Icons.arrow_back, color: isDarkMode ? Colors.white : Colors.black87),
              onPressed: () => Navigator.pop(context),
            )
          : null,
      title: title != null
          ? Row(
              children: [
                Text(
                  title!,
                  style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
                ),
                const SizedBox(width: 8),
                if (userName.isNotEmpty)
                  Text(
                    '($userName)',
                    style: TextStyle(
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                      fontSize: 14,
                    ),
                  ),
              ],
            )
          : Image.asset(
              'assets/logo2.png',
              height: 40,
              fit: BoxFit.contain,
            ),
      actions: [
        IconButton(
          icon: Icon(
            isDarkMode ? Icons.light_mode : Icons.dark_mode,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
          onPressed: () {
            authProvider.toggleDarkMode();
          },
        ),
        IconButton(
          icon: Stack(
            children: [
              CircleAvatar(
                radius: 15,
                backgroundImage: photoUrl != null && photoUrl.isNotEmpty
                    ? CachedNetworkImageProvider(photoUrl)
                    : null,
                child: photoUrl == null || photoUrl.isEmpty
                    ? const Icon(Icons.person, color: Color(0xFF4A90E2))
                    : null,
                backgroundColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
              ),
              if (authProvider.hasUnreadNotifications)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 10,
                      minHeight: 10,
                    ),
                  ),
                ),
            ],
          ),
          onPressed: () {
            Navigator.pushNamed(context, '/profile');
          },
        ),
        // Thêm biểu tượng giỏ hàng với badge
        Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.shopping_cart, color: Color(0xFF4A90E2)),
              onPressed: () => Navigator.pushNamed(context, '/cart'),
            ),
            if (cartItemCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    cartItemCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
        if (actions != null) ...actions!,
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}