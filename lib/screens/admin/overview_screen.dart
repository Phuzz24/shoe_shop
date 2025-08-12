import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shop_shop/providers/auth_provider.dart';

class OverviewScreen extends StatelessWidget {
  const OverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<AuthProvider>(context).isDarkMode;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tổng quan',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatCard(
                context,
                title: 'Sản phẩm',
                stream: FirebaseFirestore.instance.collection('products').snapshots(),
                icon: Icons.store,
                isDarkMode: isDarkMode,
              ),
              _buildStatCard(
                context,
                title: 'Đơn hàng',
                stream: FirebaseFirestore.instance.collection('orders').snapshots(),
                icon: Icons.receipt,
                isDarkMode: isDarkMode,
              ),
              _buildStatCard(
                context,
                title: 'Người dùng',
                stream: FirebaseFirestore.instance.collection('users').snapshots(),
                icon: Icons.people,
                isDarkMode: isDarkMode,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required Stream<QuerySnapshot> stream,
    required IconData icon,
    required bool isDarkMode,
  }) {
    return Expanded(
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        color: isDarkMode ? Colors.grey[900] : Colors.white,
        shadowColor: isDarkMode ? Colors.grey[700] : Colors.grey[300],
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: StreamBuilder<QuerySnapshot>(
            stream: stream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFF5A9BD4)));
              }
              final count = snapshot.data?.docs.length ?? 0;
              return Column(
                children: [
                  Icon(icon, size: 40, color: const Color(0xFF5A9BD4)),
                  const SizedBox(height: 10),
                  Text(
                    title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    count.toString(),
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}