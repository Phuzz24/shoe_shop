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
  String _selectedStatus = 'Tất cả';
  final List<String> _statusOptions = ['Tất cả', 'Chờ xử lý', 'Đang giao', 'Đã giao', 'Đã hủy'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final productProvider = Provider.of<ProductProvider>(context, listen: false);
        if (productProvider.products.isEmpty) {
          productProvider.fetchProducts();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.uid;
    final isDarkMode = authProvider.isDarkMode;
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    final screenWidth = MediaQuery.of(context).size.width;
    final imageSize = screenWidth < 400 ? 50.0 : 60.0;

    if (userId == null) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDarkMode
                  ? [const Color(0xFF1F2A44), const Color(0xFF2E3B55).withOpacity(0.9)]
                  : [Colors.white, Colors.grey[200]!.withOpacity(0.9)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Vui lòng đăng nhập để xem lịch sử đơn hàng!',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                      ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, '/login'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5A9BD4),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 4,
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
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Lịch sử đơn hàng',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
        ),
        backgroundColor: const Color(0xFF5A9BD4),
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            tooltip: 'Lọc nâng cao',
            onPressed: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: isDarkMode ? Colors.grey[850] : Colors.white,
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
                ? [const Color(0xFF1F2A44), const Color(0xFF2E3B55).withOpacity(0.9)]
                : [Colors.white, Colors.grey[200]!.withOpacity(0.9)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: _statusOptions.map((status) {
                    return ChoiceChip(
                      label: Text(status),
                      selected: _selectedStatus == status,
                      onSelected: (selected) {
                        setState(() {
                          _selectedStatus = status;
                        });
                      },
                      selectedColor: const Color(0xFF5A9BD4),
                      backgroundColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                      labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: _selectedStatus == status
                                ? Colors.white
                                : (isDarkMode ? Colors.white70 : Colors.black87),
                          ),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      visualDensity: VisualDensity.compact,
                    );
                  }).toList(),
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('orders')
                      .where('userId', isEqualTo: userId)
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: Color(0xFF5A9BD4)));
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Lỗi: ${snapshot.error}',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: isDarkMode ? Colors.white : Colors.black,
                              ),
                        ),
                      );
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Text(
                          'Chưa có đơn hàng nào!',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                              ),
                        ),
                      );
                    }

                    final orders = snapshot.data!.docs;
                    final filteredOrders = _selectedStatus == 'Tất cả'
                        ? orders
                        : orders.where((order) => (order.data() as Map<String, dynamic>)['status'] == _selectedStatus).toList();

                    return ListView.builder(
                      padding: const EdgeInsets.all(12.0),
                      itemCount: filteredOrders.length,
                      itemBuilder: (context, index) {
                        final order = filteredOrders[index].data() as Map<String, dynamic>? ?? {};
                        final orderId = filteredOrders[index].id;

                        final orderDate = (order['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
                        final status = order['status'] ?? 'Không rõ';
                        final totalAmount = order['totalAmount'] ?? 0.0;
                        final items = (order['items'] as List?) ?? [];
                        final item = items.firstOrNull as Map<String, dynamic>?;
                        final productId = item?['productId'] ?? 'Unknown';
                        final productName = productProvider.getProductName(productId) ?? productId;
                        final imageUrl = item?['imageUrl'] ??
                            'https://png.pngtree.com/png-clipart/20240514/original/pngtree-delivery-orders-vector-png-image_15091616.png';
                        final quantity = item?['quantity'] ?? 1;
                        final size = item?['size'] ?? 'Không rõ';

                        final canCancel = status == 'Chờ xử lý';

                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeInOut,
                          margin: const EdgeInsets.only(bottom: 12.0),
                          child: Card(
                            elevation: 6,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            color: isDarkMode ? Colors.grey[900] : Colors.white,
                            shadowColor: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                            child: InkWell(
                              borderRadius: BorderRadius.circular(15),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => OrderDetailScreen(
                                      orderId: orderId,
                                      orderData: {
                                        ...order,
                                        'status': status,
                                        'items': items,
                                      },
                                    ),
                                  ),
                                );
                              },
                              splashColor: isDarkMode
                                  ? Colors.blue[200]!.withOpacity(0.3)
                                  : Colors.blue[100]!.withOpacity(0.3),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(10),
                                          child: CachedNetworkImage(
                                            imageUrl: imageUrl,
                                            width: imageSize,
                                            height: imageSize,
                                            fit: BoxFit.cover,
                                            placeholder: (context, url) =>
                                                const CircularProgressIndicator(color: Color(0xFF5A9BD4)),
                                            errorWidget: (context, url, error) =>
                                                const Icon(Icons.error, color: Colors.red),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Đơn hàng #$orderId',
                                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                      fontWeight: FontWeight.w600,
                                                      color: isDarkMode ? Colors.white : Colors.black87,
                                                    ),
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                productName,
                                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                      color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                                                    ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              Text(
                                                'Size: $size',
                                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                                    ),
                                              ),
                                              Text(
                                                'Số lượng: $quantity',
                                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Ngày đặt: ${DateFormat('dd/MM/yyyy HH:mm').format(orderDate)}',
                                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                                  ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              'Tổng: ${NumberFormat('#,###').format(totalAmount)} VNĐ',
                                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                    color: isDarkMode ? Colors.grey[200] : Colors.black87,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                            ),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            Icon(_getStatusIcon(status),
                                                color: _getStatusColor(status, isDarkMode), size: 18),
                                            const SizedBox(width: 6),
                                            Text(
                                              status,
                                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                    color: _getStatusColor(status, isDarkMode),
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    if (canCancel)
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: TextButton(
                                          onPressed: () => _showCancelConfirmationDialog(orderId),
                                          style: TextButton.styleFrom(
                                            foregroundColor: const Color(0xFFD32F2F),
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                          ),
                                          child: const Text('Hủy đơn'),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
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
      ),
    );
  }

  Widget _buildFilterSheet() {
    final isDarkMode = Provider.of<AuthProvider>(context, listen: false).isDarkMode;
    return Container(
      padding: const EdgeInsets.all(12.0),
      child: Wrap(
        spacing: 8.0,
        runSpacing: 8.0,
        children: _statusOptions.map((status) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: ChoiceChip(
              label: Text(status),
              selected: _selectedStatus == status,
              onSelected: (selected) {
                setState(() {
                  _selectedStatus = status;
                });
                Navigator.pop(context);
              },
              selectedColor: const Color(0xFF5A9BD4),
              backgroundColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
              labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: _selectedStatus == status
                        ? Colors.white
                        : (isDarkMode ? Colors.white70 : Colors.black87),
                  ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              visualDensity: VisualDensity.compact,
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showCancelConfirmationDialog(String orderId) {
    final isDarkMode = Provider.of<AuthProvider>(context, listen: false).isDarkMode;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        backgroundColor: isDarkMode ? Colors.grey[850] : Colors.white,
        title: const Text('Xác nhận hủy đơn'),
        content: const Text('Bạn có chắc muốn hủy đơn hàng này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy', style: TextStyle(color: isDarkMode ? Colors.grey[400] : Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _cancelOrder(orderId);
            },
            child: const Text('Xác nhận', style: TextStyle(color: Color(0xFF5A9BD4))),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelOrder(String orderId) async {
    try {
      await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
        'status': 'Đã hủy',
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
    switch (status) {
      case 'Đã giao':
        return Icons.check_circle;
      case 'Đang giao':
        return Icons.local_shipping;
      case 'Đã hủy':
        return Icons.cancel;
      case 'Chờ xử lý':
      default:
        return Icons.hourglass_empty;
    }
  }

  Color _getStatusColor(String status, bool isDarkMode) {
    switch (status) {
      case 'Đã giao':
        return isDarkMode ? Colors.green[300]! : Colors.green[700]!;
      case 'Đang giao':
        return isDarkMode ? Colors.blue[300]! : Colors.blue[700]!;
      case 'Đã hủy':
        return isDarkMode ? Colors.red[300]! : Colors.red[700]!;
      case 'Chờ xử lý':
      default:
        return isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;
    }
  }
}