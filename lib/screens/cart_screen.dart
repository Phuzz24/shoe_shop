import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/providers/auth_provider.dart';
import '/providers/product_provider.dart';
import '/models/product.dart';
import '/widgets/custom_app_bar.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  String? _userId;

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _userId = authProvider.user?.uid;
    if (_userId != null) {
      Provider.of<ProductProvider>(context, listen: false).fetchCartItems(_userId!);
    }
  }

  void _updateQuantity(String productId, num newQuantity) async {
    if (_userId != null && newQuantity.toInt() > 0) {
      try {
        final productProvider = Provider.of<ProductProvider>(context, listen: false);
        final cartItem = productProvider.cartItems.firstWhere((item) => item['productId'] == productId);
        final size = cartItem['size'] as num;
        await productProvider.addToCart(_userId!, productId, newQuantity.toInt() - cartItem['quantity'].toInt(), size.toInt());
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật số lượng thành công!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  void _updateSize(String productId, num newSize) async {
    if (_userId != null && newSize.toInt() != 0) {
      try {
        final productProvider = Provider.of<ProductProvider>(context, listen: false);
        final cartItem = productProvider.cartItems.firstWhere((item) => item['productId'] == productId);
        final quantity = cartItem['quantity'] as num;
        await productProvider.removeFromCart(_userId!, productId);
        await productProvider.addToCart(_userId!, productId, quantity.toInt(), newSize.toInt());
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật kích cỡ thành công!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  void _removeFromCart(String productId) async {
    if (_userId != null) {
      try {
        final productProvider = Provider.of<ProductProvider>(context, listen: false);
        await productProvider.removeFromCart(_userId!, productId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa sản phẩm khỏi giỏ hàng!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  void _checkout() {
    if (_userId != null) {
      Navigator.pushNamed(context, '/checkout');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập để thanh toán!')),
      );
    }
  }

  double _calculateTotal(List<Map<String, dynamic>> cartItems, List<Product> products) {
    double total = 0.0;
    for (var item in cartItems) {
      final product = products.firstWhere(
        (p) => p.id == item['productId'],
        orElse: () => Product(id: '', name: '', price: 0.0, salePrice: 0.0, imageUrl: '', category: '', sizes: [], stock: 0),
      );
      total += (product.isOnSale ?? false) ? product.salePrice * item['quantity'].toDouble() : product.price * item['quantity'].toDouble();
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final productProvider = Provider.of<ProductProvider>(context);
    final isDarkMode = authProvider.isDarkMode;
    final cartItems = productProvider.cartItems;
    final products = productProvider.products;

    if (_userId == null) {
      return Scaffold(
        appBar: const CustomAppBar(title: 'Giỏ hàng',  showUserName: false),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Vui lòng đăng nhập để xem giỏ hàng!'),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/login'),
                child: const Text('Đăng nhập ngay', style: TextStyle(color: Color(0xFF4A90E2))),
              ),
            ],
          ),
        ),
      );
    }

    if (cartItems.isEmpty) {
      return Scaffold(
        appBar: const CustomAppBar(title: 'Giỏ hàng',  showUserName: false),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Giỏ hàng của bạn trống!'),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/main'),
                child: const Text('Mua sắm ngay', style: TextStyle(color: Color(0xFF4A90E2))),
              ),
            ],
          ),
        ),
      );
    }

    final total = _calculateTotal(cartItems, products);

    return Scaffold(
      appBar: const CustomAppBar(title: 'Giỏ hàng',  showUserName: false),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDarkMode
                ? [const Color(0xFF1A1A2E), const Color(0xFF16213E)]
                : [Colors.white, Colors.grey[100]!],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: cartItems.length,
                itemBuilder: (context, index) {
                  final item = cartItems[index];
                  final product = products.firstWhere(
                    (p) => p.id == item['productId'],
                    orElse: () => Product(id: '', name: '', price: 0.0, salePrice: 0.0, imageUrl: '', category: '', sizes: [], stock: 0),
                  );
                  final quantity = item['quantity'] as num;
                  final size = item['size'] as num;

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    color: isDarkMode ? Colors.grey[800] : Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    child: ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: CachedNetworkImage(
                          imageUrl: product.imageUrl,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => SpinKitFadingCircle(
                            color: isDarkMode ? const Color(0xFF1E90FF) : Colors.blue[600],
                            size: 20,
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                            child: const Icon(Icons.error, color: Colors.red),
                          ),
                        ),
                      ),
                      title: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          product.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              (product.isOnSale ?? false)
                                  ? NumberFormat('#,###').format(product.salePrice) + ' VNĐ'
                                  : NumberFormat('#,###').format(product.price) + ' VNĐ',
                              style: TextStyle(
                                fontSize: 16,
                                color: isDarkMode ? const Color(0xFF1E90FF) : Colors.blue[600],
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              Text('Kích cỡ: $size', style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54)),
                              const SizedBox(width: 10),
                              Text('Số lượng: $quantity', style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54)),
                            ],
                          ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _removeFromCart(product.id),
                      ),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) {
                            int newQuantity = quantity.toInt();
                            int newSize = size.toInt();
                            return StatefulBuilder(
                              builder: (context, setState) {
                                return Dialog(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                  child: Container(
                                    padding: const EdgeInsets.all(20),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Cập nhật ${product.name}',
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: isDarkMode ? Colors.white : Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                                        Text('Kích cỡ:', style: TextStyle(fontSize: 16, color: isDarkMode ? Colors.white70 : Colors.black54)),
                                        Wrap(
                                          spacing: 10,
                                          children: product.sizes.map((s) {
                                            return ChoiceChip(
                                              label: Text(s.toString()),
                                              selected: newSize == s,
                                              onSelected: (selected) {
                                                if (selected) {
                                                  setState(() {
                                                    newSize = s;
                                                  });
                                                }
                                              },
                                              selectedColor: const Color(0xFF4A90E2),
                                              labelStyle: TextStyle(
                                                color: newSize == s ? Colors.white : (isDarkMode ? Colors.white70 : Colors.black87),
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                        const SizedBox(height: 20),
                                        Text('Số lượng:', style: TextStyle(fontSize: 16, color: isDarkMode ? Colors.white70 : Colors.black54)),
                                        Row(
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.remove),
                                              onPressed: newQuantity > 1
                                                  ? () => setState(() => newQuantity--)
                                                  : null,
                                              color: isDarkMode ? Colors.white70 : Colors.black87,
                                            ),
                                            Text(
                                              newQuantity.toString(),
                                              style: TextStyle(fontSize: 16, color: isDarkMode ? Colors.white : Colors.black87),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.add),
                                              onPressed: newQuantity < product.stock
                                                  ? () => setState(() => newQuantity++)
                                                  : null,
                                              color: isDarkMode ? Colors.white70 : Colors.black87,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 20),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(context),
                                              child: const Text('Hủy'),
                                            ),
                                            ElevatedButton(
                                              onPressed: () {
                                                _updateQuantity(product.id, newQuantity);
                                                _updateSize(product.id, newSize);
                                                Navigator.pop(context);
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(0xFF4A90E2),
                                                foregroundColor: Colors.white,
                                              ),
                                              child: const Text('Lưu'),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tổng cộng:',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      Text(
                        NumberFormat('#,###').format(total) + ' VNĐ',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? const Color(0xFF1E90FF) : Colors.blue[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _checkout,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Thanh toán'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}