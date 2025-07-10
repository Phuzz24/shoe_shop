import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '/providers/auth_provider.dart';
import '/providers/product_provider.dart';
import '/screens/profile/order_detail_screen.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  String _selectedStatus = 'All';
  final List<String> _statusOptions = ['All', 'Pending', 'Shipping', 'Delivered', 'Canceled'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      if (productProvider.products.isEmpty) {
        productProvider.fetchProducts();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.uid;
    final isDarkMode = authProvider.isDarkMode;
    final productProvider = Provider.of<ProductProvider>(context, listen: false);

    if (userId == null) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDarkMode ? [Colors.black, Colors.grey[900]!] : [Colors.white, Colors.grey[200]!],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Vui lòng đăng nhập để xem lịch sử đơn hàng!',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: Colors.grey),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, '/login'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6B48FF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Đăng nhập ngay', style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Lịch sử đơn hàng',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: isDarkMode
            ? const Color(0xFF2A2A4D)
            : const Color(0xFF6B48FF),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (context) => _buildFilterSheet(),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDarkMode
                ? [const Color(0xFF1F1F38), const Color(0xFF2A2A4D)]
                : [Colors.white, const Color(0xFFF5F7FA)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('orders')
                .where('userId', isEqualTo: userId)
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFF6B48FF)));
              }
              if (snapshot.hasError) {
                return Center(child: Text('Lỗi: ${snapshot.error}', style: TextStyle(color: isDarkMode ? Colors.white : Colors.black)));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Text(
                    'Chưa có đơn hàng nào!',
                    style: TextStyle(fontSize: 18, color: isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                  ),
                );
              }

              final orders = snapshot.data!.docs;
              final filteredOrders = _selectedStatus == 'All'
                  ? orders
                  : orders.where((order) {
                      final status = (order.data() as Map<String, dynamic>)['status'] ?? 'Unknown';
                      return status == _selectedStatus;
                    }).toList();

              return ListView.builder(
                padding: const EdgeInsets.all(12.0),
                itemCount: filteredOrders.length,
                itemBuilder: (context, index) {
                  final order = filteredOrders[index].data() as Map<String, dynamic>? ?? {};
                  final orderId = filteredOrders[index].id;

                  final orderDate = (order['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
                  final status = order['status'] ?? 'Unknown';
                  final totalAmount = order['totalAmount'] ?? 0.0;
                  final item = (order['items'] as List?)?.firstOrNull as Map<String, dynamic>?;
                  final productId = item?['productId'] ?? 'Unknown';
                  final productName = productProvider.getProductName(productId) ?? productId;
                  final imageUrl = item?['imageUrl'] ?? 'https://picsum.photos/150';

                  final canCancel = status == 'Pending' || status == 'Shipping';

                  return Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    color: isDarkMode ? Colors.grey[800] : Colors.white,
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12.0),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: CachedNetworkImage(
                          imageUrl: imageUrl,
                          placeholder: (context, url) => const CircularProgressIndicator(color: Color(0xFF6B48FF)),
                          errorWidget: (context, url, error) => const Icon(Icons.error, color: Colors.red),
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                        ),
                      ),
                      title: Text(
                        'Đơn #${orderId.substring(0, 8)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ngày: ${DateFormat('dd/MM/yyyy HH:mm').format(orderDate)}',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                          Text(
                            'Tổng: ${NumberFormat('#,###').format(totalAmount)} VNĐ',
                            style: TextStyle(
                              fontSize: 16,
                              color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(_getStatusIcon(status), color: _getStatusColor(status, isDarkMode), size: 16),
                              const SizedBox(width: 4),
                              Text(
                                status,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: _getStatusColor(status, isDarkMode),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      trailing: canCancel
                          ? IconButton(
                              icon: const Icon(Icons.cancel, color: Colors.redAccent),
                              onPressed: () => _showCancelConfirmationDialog(orderId),
                            )
                          : null,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => OrderDetailScreen(orderId: orderId, orderData: order),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildFilterSheet() {
    final isDarkMode = Provider.of<AuthProvider>(context, listen: false).isDarkMode;
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Wrap(
        spacing: 8.0,
        children: _statusOptions.map((status) {
          return ChoiceChip(
            label: Text(status),
            selected: _selectedStatus == status,
            onSelected: (selected) {
              setState(() {
                _selectedStatus = status;
              });
              Navigator.pop(context);
            },
            selectedColor: const Color(0xFF6B48FF),
            backgroundColor: isDarkMode ? Colors.grey[700] : Colors.grey[200],
            labelStyle: TextStyle(
              color: _selectedStatus == status ? Colors.white : (isDarkMode ? Colors.white70 : Colors.black87),
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          );
        }).toList(),
      ),
    );
  }

  void _showCancelConfirmationDialog(String orderId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text('Xác nhận hủy đơn', style: TextStyle(fontSize: 20)),
        content: const Text('Bạn có chắc muốn hủy đơn hàng này?', style: TextStyle(fontSize: 16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _cancelOrder(orderId);
            },
            child: const Text('Xác nhận', style: TextStyle(color: Color(0xFF6B48FF))),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelOrder(String orderId) async {
    try {
      await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
        'status': 'Canceled',
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đơn hàng đã được hủy thành công!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi hủy đơn hàng: $e')),
      );
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return Icons.check_circle;
      case 'shipping':
        return Icons.local_shipping;
      case 'canceled':
        return Icons.cancel;
      default:
        return Icons.hourglass_empty;
    }
  }

  Color _getStatusColor(String status, bool isDarkMode) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return isDarkMode ? Colors.green[300]! : Colors.green[700]!;
      case 'shipping':
        return isDarkMode ? Colors.blue[300]! : Colors.blue[700]!;
      case 'canceled':
        return isDarkMode ? Colors.red[300]! : Colors.red[700]!;
      default:
        return isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;
    }
  }
}