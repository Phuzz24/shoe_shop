import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shop_shop/providers/auth_provider.dart';
import 'package:shop_shop/screens/admin/overview_screen.dart';
import 'package:shop_shop/screens/admin/product_management_screen.dart';
import 'package:shop_shop/screens/admin/order_management_screen.dart';
import 'package:shop_shop/screens/admin/user_management_screen.dart';
import 'package:shop_shop/screens/admin/notification_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  final List<Widget> _screens = [
    const OverviewScreen(),
    const ProductManagementScreen(),
    const OrderManagementScreen(),
    const UserManagementScreen(),
    const NotificationScreen(),
  ];

  final List<String> _titles = ['Tổng quan', 'Sản phẩm', 'Đơn hàng', 'Người dùng', 'Thông báo'];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<AuthProvider>(context).isDarkMode;
    final themeColor = const Color(0xFF5A9BD4);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _titles[_selectedIndex],
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: themeColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => Provider.of<AuthProvider>(context, listen: false).toggleTheme(),
            color: Colors.white,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await Provider.of<AuthProvider>(context, listen: false).signOut();
              Navigator.pushReplacementNamed(context, '/login');
            },
            color: Colors.white,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDarkMode
                ? [const Color(0xFF1F2A44), const Color(0xFF2E3B55).withOpacity(0.9)]
                : [Colors.white, Colors.grey[100]!.withOpacity(0.9)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: _screens[_selectedIndex],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
            _controller.reset();
            _controller.forward();
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Tổng quan'),
          BottomNavigationBarItem(icon: Icon(Icons.store), label: 'Sản phẩm'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt), label: 'Đơn hàng'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Người dùng'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Thông báo'),
        ],
        selectedItemColor: themeColor,
        unselectedItemColor: isDarkMode ? Colors.grey[400] : Colors.grey[600],
        backgroundColor: isDarkMode ? Colors.grey[850] : Colors.white,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}