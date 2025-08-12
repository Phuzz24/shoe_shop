import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shop_shop/providers/auth_provider.dart';
import '/providers/product_provider.dart';

class OrderDetailScreen extends StatelessWidget {
  final String orderId;
  final Map<String, dynamic> orderData;

  const OrderDetailScreen({super.key, required this.orderId, required this.orderData});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<AuthProvider>(context, listen: false).isDarkMode;
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    final items = orderData['items'] as List? ?? [];

    // Giả định dữ liệu bổ sung (có thể thay đổi dựa trên Firestore)
    final estimatedDelivery = (orderData['estimatedDelivery'] as Timestamp?)?.toDate() ?? DateTime.now().add(const Duration(days: 3));
    final trackingCode = orderData['trackingCode'] ?? 'Chưa có mã vận đơn';
    final paymentStatus = orderData['paymentStatus'] ?? 'Chưa thanh toán';

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
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Color(0xFF5A9BD4)),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Text(
                      'Chi tiết đơn #${orderId.substring(0, 8)}',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : const Color(0xFF2A2A4D),
                      ),
                    ),
                    const SizedBox(width: 48), // Để cân đối
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    color: isDarkMode ? Colors.grey[900] : Colors.white,
                    shadowColor: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle('Thông tin giao hàng', isDarkMode),
                          const SizedBox(height: 12),
                          _buildDetailRow('Tên', orderData['name'] ?? 'Chưa cập nhật', isDarkMode, isBold: true),
                          _buildDetailRow('SĐT', orderData['phone'] ?? 'Chưa cập nhật', isDarkMode, isBold: true),
                          _buildDetailRow(
                            'Địa chỉ',
                            '${orderData['address'] ?? ''}, ${orderData['ward'] ?? ''}, ${orderData['district'] ?? ''}, ${orderData['city'] ?? ''}',
                            isDarkMode,
                            isBold: true,
                            maxLines: 2,
                          ),
                          _buildDetailRow('Phương thức', orderData['paymentMethod'] ?? 'Chưa xác định', isDarkMode, isBold: true),
                          _buildDetailRow('Trạng thái thanh toán', paymentStatus, isDarkMode, isBold: true),
                          const Divider(color: Color(0xFF5A9BD4), thickness: 1.5, height: 30),
                          _buildSectionTitle('Thông tin đơn hàng', isDarkMode),
                          const SizedBox(height: 12),
                          _buildDetailRow('Ngày đặt', DateFormat('dd/MM/yyyy HH:mm').format((orderData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now()), isDarkMode, isBold: true),
                          _buildDetailRow('Ngày giao dự kiến', DateFormat('dd/MM/yyyy').format(estimatedDelivery), isDarkMode, isBold: true),
                          _buildDetailRow('Mã vận đơn', trackingCode, isDarkMode, isBold: true),
                          _buildDetailRow(
                            'Trạng thái',
                            orderData['status'] ?? 'Unknown',
                            isDarkMode,
                            isBold: true,
                            color: _getStatusColor(orderData['status'] ?? 'Unknown', isDarkMode),
                          ),
                          const Divider(color: Color(0xFF5A9BD4), thickness: 1.5, height: 30),
                          _buildSectionTitle('Sản phẩm', isDarkMode),
                          const SizedBox(height: 12),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: items.length,
                            itemBuilder: (context, index) {
                              final item = items[index] as Map<String, dynamic>;
                              final productId = item['productId'] ?? 'Unknown';
                              final productName = productProvider.getProductName(productId) ?? productId;
                              final quantity = item['quantity'] ?? 1;
                              final price = item['isOnSale'] ?? false
                                  ? item['salePrice'] ?? 0.0
                                  : item['price'] ?? 0.0;
                              final itemTotal = price * quantity;

                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 10.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: CachedNetworkImage(
                                        imageUrl: item['imageUrl'] ??
                                            'https://png.pngtree.com/png-clipart/20240514/original/pngtree-delivery-orders-vector-png-image_15091616.png',
                                        width: 50,
                                        height: 50,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) =>
                                            const CircularProgressIndicator(color: Color(0xFF5A9BD4)),
                                        errorWidget: (context, url, error) =>
                                            const Icon(Icons.error, color: Colors.red),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            productName,
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: isDarkMode ? Colors.white : const Color(0xFF2A2A4D),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            'x$quantity - Size: ${item['size'] ?? 'Không rõ'}',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      '${NumberFormat('#,###').format(itemTotal)} VNĐ',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: isDarkMode ? Colors.grey[200] : Colors.grey[700],
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Tổng cộng:',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isDarkMode ? Colors.white : const Color(0xFF2A2A4D),
                                ),
                              ),
                              Text(
                                '${NumberFormat('#,###').format(orderData['totalAmount'] ?? 0)} VNĐ',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isDarkMode ? const Color(0xFF5A9BD4) : const Color(0xFF2A2A4D),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: isDarkMode ? Colors.white : const Color(0xFF2A2A4D),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, bool isDarkMode, {Color? color, int? maxLines, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                color: color ?? (isDarkMode ? Colors.white : const Color(0xFF2A2A4D)),
              ),
              maxLines: maxLines ?? 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status, bool isDarkMode) {
    switch (status.toLowerCase()) {
      case 'delivered':
      case 'đã giao':
        return isDarkMode ? Colors.green[300]! : Colors.green[700]!;
      case 'shipping':
      case 'đang giao':
        return isDarkMode ? Colors.blue[300]! : Colors.blue[700]!;
      case 'canceled':
      case 'đã hủy':
        return isDarkMode ? Colors.red[300]! : Colors.red[700]!;
      case 'pending':
      case 'chờ xử lý':
      default:
        return isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;
    }
  }
}