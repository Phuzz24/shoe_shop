import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shop_shop/providers/auth_provider.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shop_shop/providers/product_provider.dart';

class OrderManagementScreen extends StatefulWidget {
  const OrderManagementScreen({super.key});

  @override
  State<OrderManagementScreen> createState() => _OrderManagementScreenState();
}

class _OrderManagementScreenState extends State<OrderManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatus = 'Tất cả';
  final List<String> _statusOptions = ['Chờ xử lý', 'Đang giao', 'Đã giao', 'Đã hủy', 'Unknown'];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showOrderDetailsDialog(Map<String, dynamic> order, String orderId) {
    final List<dynamic> items = order['items'] ?? [];
    final estimatedDelivery = (order['estimatedDelivery'] as Timestamp?)?.toDate() ?? DateTime.now().add(const Duration(days: 3));
    final trackingCode = order['trackingCode'] ?? 'Chưa có mã vận đơn';
    final paymentStatus = order['paymentStatus'] ?? 'Chưa thanh toán';
    final paymentMethod = order['paymentMethod'] ?? 'Chưa xác định';
    final address = '${order['address'] ?? ''}, ${order['ward'] ?? ''}, ${order['district'] ?? ''}, ${order['city'] ?? ''}';
    final createdAt = (order['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Chi tiết đơn hàng #${orderId.substring(0, 8)}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Khách hàng: ${order['userName'] ?? 'Unknown'}'),
              Text('SĐT: ${order['phone'] ?? 'Chưa cập nhật'}'),
              Text('Địa chỉ: $address'),
              Text('Phương thức thanh toán: $paymentMethod'),
              Text('Trạng thái thanh toán: $paymentStatus'),
              Text('Tổng: ${NumberFormat('#,###').format(order['totalAmount'] ?? 0)} VNĐ'),
              Text('Ngày đặt: ${DateFormat('dd/MM/yyyy HH:mm').format(createdAt)}'),
              Text('Ngày giao dự kiến: ${DateFormat('dd/MM/yyyy').format(estimatedDelivery)}'),
              Text('Mã vận đơn: $trackingCode'),
              Text('Trạng thái: ${order['status'] ?? 'Unknown'}'),
              const SizedBox(height: 10),
              const Text('Sản phẩm:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...items.map((item) {
                return ListTile(
                  title: Text(item['name'] ?? 'Unknown'),
                  subtitle: Text('Số lượng: ${item['quantity'] ?? 0}, Giá: ${NumberFormat('#,###').format(item['price'] ?? 0)} VNĐ, Size: ${item['size'] ?? 'Không rõ'}'),
                );
              }).toList(),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmationDialog(String orderId) {
    final isDarkMode = Provider.of<AuthProvider>(context, listen: false).isDarkMode;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        backgroundColor: isDarkMode ? Colors.grey[850] : Colors.white,
        title: const Text('Xác nhận xóa đơn'),
        content: const Text('Bạn có chắc muốn xóa đơn hàng này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy', style: TextStyle(color: isDarkMode ? Colors.grey[400] : Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteOrder(orderId);
            },
            child: const Text('Xác nhận', style: TextStyle(color: Color(0xFF5A9BD4))),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteOrder(String orderId) async {
    try {
      final orderDoc = await FirebaseFirestore.instance.collection('orders').doc(orderId).get();
      final orderData = orderDoc.data() as Map<String, dynamic>?;
      final userId = orderData?['userId'];
      final totalAmount = orderData?['totalAmount'] ?? 0.0;

      await FirebaseFirestore.instance.collection('orders').doc(orderId).delete();

      if (userId != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('notifications')
            .add({
          'title': 'Đơn hàng đã bị hủy',
          'message': 'Đơn hàng #${orderId.substring(0, 8)} với tổng giá trị ${NumberFormat('#,###').format(totalAmount)} VNĐ đã bị hủy.',
          'type': 'Đơn hàng',
          'createdAt': FieldValue.serverTimestamp(),
          'isRead': false,
        });

        final productProvider = Provider.of<ProductProvider>(context, listen: false);
        await productProvider.productService.sendPushNotification(
          userId,
          'Đơn hàng đã bị hủy',
          'Đơn hàng #${orderId.substring(0, 8)} đã bị hủy.',
        );
      }

      Fluttertoast.showToast(msg: 'Xóa đơn hàng thành công!');
    } catch (e) {
      Fluttertoast.showToast(msg: 'Lỗi khi xóa đơn hàng: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<AuthProvider>(context).isDarkMode;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm đơn hàng...',
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF5A9BD4)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: ['Tất cả', ..._statusOptions].map((status) {
                  return ChoiceChip(
                    label: Text(status),
                    selected: _selectedStatus == status,
                    onSelected: (selected) => setState(() => _selectedStatus = status),
                    selectedColor: const Color(0xFF5A9BD4),
                    backgroundColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                    labelStyle: TextStyle(
                      color: _selectedStatus == status
                          ? Colors.white
                          : (isDarkMode ? Colors.white70 : Colors.black87),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('orders').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFF5A9BD4)));
              }
              if (snapshot.hasError) {
                return Center(child: Text('Lỗi: ${snapshot.error}'));
              }
              final orders = snapshot.data?.docs ?? [];
              final filteredOrders = _selectedStatus == 'Tất cả'
                  ? orders
                  : orders.where((order) {
                      final data = order.data() as Map<String, dynamic>;
                      final matchesStatus = data['status'] == _selectedStatus;
                      final matchesSearch = _searchController.text.isEmpty ||
                          order.id.toLowerCase().contains(_searchController.text.toLowerCase()) ||
                          (data['createdAt'] as Timestamp?)!
                              .toDate()
                              .toString()
                              .toLowerCase()
                              .contains(_searchController.text.toLowerCase());
                      return matchesStatus && matchesSearch;
                    }).toList();

              return ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: filteredOrders.length,
                itemBuilder: (context, index) {
                  final order = filteredOrders[index].data() as Map<String, dynamic>;
                  final orderId = filteredOrders[index].id;
                  final status = order['status'] ?? 'Unknown';
                  final totalAmount = order['totalAmount'] ?? 0.0;
                  final createdAt = (order['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
                  final userId = order['userId'] ?? 'Unknown';
                  final paymentStatus = order['paymentStatus'] ?? 'Chưa thanh toán';
                  final address = '${order['address'] ?? ''}, ${order['ward'] ?? ''}, ${order['district'] ?? ''}, ${order['city'] ?? ''}';
                  final paymentMethod = order['paymentMethod'] ?? 'Chưa xác định';

                  final displayStatus = _statusOptions.contains(status) ? status : 'Unknown';

                  return FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
                    builder: (context, userSnapshot) {
                      if (userSnapshot.connectionState == ConnectionState.waiting) {
                        return const ListTile(title: Text('Đang tải...'));
                      }
                      final userName = userSnapshot.data?.data() != null
                          ? (userSnapshot.data!.data() as Map<String, dynamic>)['name'] ?? 'Unknown'
                          : 'Unknown';

                      return Slidable(
                        key: ValueKey(orderId),
                        endActionPane: ActionPane(
                          motion: const ScrollMotion(),
                          children: [
                            SlidableAction(
                              onPressed: (context) => _showDeleteConfirmationDialog(orderId),
                              backgroundColor: const Color(0xFFD32F2F),
                              foregroundColor: Colors.white,
                              icon: Icons.delete,
                              label: 'Xóa',
                            ),
                          ],
                        ),
                        child: Card(
                          elevation: 6,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          color: isDarkMode ? Colors.grey[900] : Colors.white,
                          shadowColor: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                          margin: const EdgeInsets.only(bottom: 12.0),
                          child: ListTile(
                            title: Text(
                              'Đơn #${orderId.substring(0, 8)}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Khách hàng: $userName'),
                                Text('Tổng: ${NumberFormat('#,###').format(totalAmount)} VNĐ'),
                                Text('Địa chỉ: $address'),
                                Text('Phương thức: $paymentMethod'),
                                Text('Trạng thái thanh toán: $paymentStatus'),
                                Text('Ngày: ${DateFormat('dd/MM/yyyy HH:mm').format(createdAt)}'),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.visibility, color: Color(0xFF5A9BD4)),
                                  onPressed: () => _showOrderDetailsDialog(order, orderId),
                                ),
                                DropdownButton<String>(
                                  value: displayStatus,
                                  items: _statusOptions
                                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                                      .toList(),
                                  onChanged: (value) async {
                                    if (value != null && value != displayStatus) {
                                      try {
                                        await FirebaseFirestore.instance
                                            .collection('orders')
                                            .doc(orderId)
                                            .update({'status': value});

                                        if (userId != null) {
                                          await FirebaseFirestore.instance
                                              .collection('users')
                                              .doc(userId)
                                              .collection('notifications')
                                              .add({
                                            'title': 'Cập nhật trạng thái đơn hàng',
                                            'message': 'Đơn hàng #${orderId.substring(0, 8)} đã được cập nhật sang trạng thái "$value".',
                                            'type': 'Đơn hàng',
                                            'createdAt': FieldValue.serverTimestamp(),
                                            'isRead': false,
                                          });

                                          final productProvider = Provider.of<ProductProvider>(context, listen: false);
                                          await productProvider.productService.sendPushNotification(
                                            userId,
                                            'Cập nhật trạng thái đơn hàng',
                                            'Đơn hàng #${orderId.substring(0, 8)} đã được cập nhật sang trạng thái "$value".',
                                          );
                                        }

                                        Fluttertoast.showToast(msg: 'Cập nhật trạng thái thành công!');
                                      } catch (e) {
                                        Fluttertoast.showToast(msg: 'Lỗi: $e');
                                      }
                                    }
                                  },
                                  style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
                                  dropdownColor: isDarkMode ? Colors.grey[800] : Colors.white,
                                  underline: const SizedBox(),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}