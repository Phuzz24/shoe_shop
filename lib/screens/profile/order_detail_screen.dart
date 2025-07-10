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
                ? [const Color(0xFF1F1F38), const Color(0xFF2A2A4D)]
                : [Colors.white, const Color(0xFFF5F7FA)],
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
                      icon: const Icon(Icons.arrow_back, color: Color(0xFF6B48FF)),
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
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    color: isDarkMode ? Colors.grey[850] : Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle('Thông tin giao hàng', isDarkMode),
                          _buildDetailRow('Tên', orderData['name'] ?? 'Chưa cập nhật', isDarkMode),
                          _buildDetailRow('SĐT', orderData['phone'] ?? 'Chưa cập nhật', isDarkMode),
                          _buildDetailRow(
                            'Địa chỉ',
                            '${orderData['address'] ?? ''}, ${orderData['ward'] ?? ''}, ${orderData['district'] ?? ''}, ${orderData['city'] ?? ''}',
                            isDarkMode,
                            maxLines: 2,
                          ),
                          _buildDetailRow('Phương thức', orderData['paymentMethod'] ?? 'Chưa xác định', isDarkMode),
                          _buildDetailRow('Trạng thái thanh toán', paymentStatus, isDarkMode),
                          const SizedBox(height: 16),
                          _buildSectionTitle('Thông tin đơn hàng', isDarkMode),
                          _buildDetailRow('Ngày đặt', DateFormat('dd/MM/yyyy HH:mm').format((orderData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now()), isDarkMode),
                          _buildDetailRow('Ngày giao dự kiến', DateFormat('dd/MM/yyyy').format(estimatedDelivery), isDarkMode),
                          _buildDetailRow('Mã vận đơn', trackingCode, isDarkMode),
                          _buildDetailRow(
                            'Trạng thái',
                            orderData['status'] ?? 'Unknown',
                            isDarkMode,
                            color: _getStatusColor(orderData['status'] ?? 'Unknown', isDarkMode),
                          ),
                          const SizedBox(height: 16),
                          _buildSectionTitle('Sản phẩm', isDarkMode),
                          ...items.map((item) {
                            final productId = item['productId'] ?? 'Unknown';
                            final productName = productProvider.getProductName(productId) ?? productId;
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      '- ${item['quantity']} x $productName',
                                      style: TextStyle(fontSize: 16, color: isDarkMode ? Colors.white : const Color(0xFF2A2A4D)),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    '${NumberFormat('#,###').format(item['salePrice'] > 0 ? item['salePrice'] : item['price'])} VNĐ',
                                    style: TextStyle(fontSize: 16, color: isDarkMode ? Colors.grey[300] : Colors.grey[700]),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          const SizedBox(height: 16),
                          Text(
                            'Tổng cộng: ${NumberFormat('#,###').format(orderData['totalAmount'] ?? 0)} VNĐ',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.white : const Color(0xFF2A2A4D),
                            ),
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
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: isDarkMode ? Colors.white : const Color(0xFF2A2A4D),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, bool isDarkMode, {Color? color, int? maxLines}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: isDarkMode ? Colors.grey[400] : Colors.grey[700]),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 16, color: color ?? (isDarkMode ? Colors.white : const Color(0xFF2A2A4D))),
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