import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/providers/auth_provider.dart';
import '/providers/product_provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '/screens/order_success_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  String? _city;
  String? _district;
  String? _ward;
  String? _paymentMethod = 'COD'; // Default to COD
  bool _isLoading = false;
  bool _isFetching = true; // Thêm trạng thái tải dữ liệu

  // Danh sách để lưu dữ liệu từ API
  List<dynamic> _cities = [];
  Map<String, List<dynamic>> _districts = {};
  Map<String, List<dynamic>> _wards = {};

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userData = authProvider.userData;
    if (userData != null) {
      _nameController.text = userData['name'] ?? '';
      _phoneController.text = userData['phone'] ?? '';
      _addressController.text = userData['address'] ?? '';
      _city = userData['city']; // Không gán mặc định nếu chưa tải xong
      _district = userData['district'];
      _ward = userData['ward'];
    }
    _fetchProvinces(); // Gọi API để lấy danh sách tỉnh/thành phố
  }

  Future<void> _fetchProvinces() async {
    setState(() => _isFetching = true);
    try {
      final response = await http.get(Uri.parse('https://provinces.open-api.vn/api/?depth=2'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List<dynamic>;
        setState(() {
          _cities = data;
          if (_city == null && _cities.isNotEmpty) {
            _city = _cities[0]['name'];
            _fetchDistricts(_city!);
          } else if (_city != null && _cities.any((c) => c['name'] == _city)) {
            _fetchDistricts(_city!);
          }
          _isFetching = false;
        });
      } else {
        throw Exception('Failed to load provinces: Status ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tải danh sách tỉnh: $e')),
      );
      setState(() => _isFetching = false);
    }
  }

  Future<void> _fetchDistricts(String cityName) async {
    setState(() => _isFetching = true);
    try {
      final city = _cities.firstWhere((c) => c['name'] == cityName);
      final response = await http.get(Uri.parse('https://provinces.open-api.vn/api/p/${city['code']}?depth=2'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        setState(() {
          _districts[cityName] = data['districts'] as List<dynamic>;
          if (_district == null && _districts[cityName]!.isNotEmpty) {
            _district = _districts[cityName]![0]['name'];
            _fetchWards(cityName, _district!);
          } else if (_district != null && _districts[cityName]!.any((d) => d['name'] == _district)) {
            _fetchWards(cityName, _district!);
          }
          _isFetching = false;
        });
      } else {
        throw Exception('Failed to load districts: Status ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tải danh sách quận/huyện: $e')),
      );
      setState(() => _isFetching = false);
    }
  }

  Future<void> _fetchWards(String cityName, String districtName) async {
    setState(() => _isFetching = true);
    try {
      final district = _districts[cityName]!.firstWhere((d) => d['name'] == districtName);
      final response = await http.get(Uri.parse('https://provinces.open-api.vn/api/d/${district['code']}?depth=2'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        setState(() {
          _wards[districtName] = data['wards'] as List<dynamic>;
          if (_ward == null && _wards[districtName]!.isNotEmpty) {
            _ward = _wards[districtName]![0]['name'];
          } else if (_ward != null && _wards[districtName]!.any((w) => w['name'] == _ward)) {
            _ward = _ward; // Giữ nguyên nếu hợp lệ
          }
          _isFetching = false;
        });
      } else {
        throw Exception('Failed to load wards: Status ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tải danh sách xã/phường: $e')),
      );
      setState(() => _isFetching = false);
    }
  }

  Future<void> _createOrder() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    final userId = authProvider.user?.uid;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập để thanh toán!')),
      );
      return;
    }

    if (_nameController.text.isEmpty || _phoneController.text.isEmpty || _addressController.text.isEmpty || _city == null || _district == null || _ward == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng điền đầy đủ thông tin!')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final cartItems = productProvider.cartItems;
      if (cartItems.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Giỏ hàng trống!')),
        );
        return;
      }

      final totalAmount = cartItems.fold(0.0, (sum, item) {
        final product = productProvider.getProductById(item['productId']);
        if (product != null) {
          return sum + (product.isOnSale ?? false
              ? product.salePrice * (item['quantity'] as num)
              : product.price * (item['quantity'] as num));
        }
        return sum;
      });

      final orderData = {
        'userId': userId,
        'items': cartItems.map((item) => {
              'productId': item['productId'],
              'quantity': item['quantity'],
              'size': item['size'],
              'price': productProvider.getProductById(item['productId'])?.price ?? 0.0,
              'salePrice': productProvider.getProductById(item['productId'])?.salePrice ?? 0.0,
              'isOnSale': productProvider.getProductById(item['productId'])?.isOnSale ?? false,
            }).toList(),
        'totalAmount': totalAmount,
        'name': _nameController.text,
        'phone': _phoneController.text,
        'address': _addressController.text,
        'city': _city,
        'district': _district,
        'ward': _ward,
        'paymentMethod': _paymentMethod,
        'status': 'shipping', // Mặc định trạng thái là "đang giao"
        'createdAt': FieldValue.serverTimestamp(),
        'orderDate': DateTime.now().toIso8601String(),
      };

      final docRef = await FirebaseFirestore.instance.collection('orders').add(orderData);

      // Xóa giỏ hàng sau khi tạo đơn hàng
      for (var item in cartItems) {
        await productProvider.removeFromCart(userId, item['productId']);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đơn hàng đã được tạo!')),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const OrderSuccessScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tạo đơn hàng: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final productProvider = Provider.of<ProductProvider>(context);
    final isDarkMode = authProvider.isDarkMode;
    final cartItems = productProvider.cartItems;
    final totalAmount = cartItems.fold(0.0, (sum, item) {
      final product = productProvider.getProductById(item['productId']);
      if (product != null) {
        return sum + (product.isOnSale ?? false
            ? product.salePrice * (item['quantity'] as num)
            : product.price * (item['quantity'] as num));
      }
      return sum;
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thanh toán'),
        backgroundColor: isDarkMode ? const Color(0xFF2E2E48) : const Color(0xFFE0E0E0),
      ),
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height - kToolbarHeight - 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Thông tin giao hàng',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Tên người nhận',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    filled: true,
                    fillColor: isDarkMode ? Colors.grey[700] : Colors.grey[200],
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: 'Số điện thoại',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    filled: true,
                    fillColor: isDarkMode ? Colors.grey[700] : Colors.grey[200],
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _addressController,
                  decoration: InputDecoration(
                    labelText: 'Địa chỉ cụ thể (số nhà, đường)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    filled: true,
                    fillColor: isDarkMode ? Colors.grey[700] : Colors.grey[200],
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  value: _isFetching || _cities.isEmpty ? null : _city,
                  hint: const Text('Chọn tỉnh/thành phố'),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    filled: true,
                    fillColor: isDarkMode ? Colors.grey[700] : Colors.grey[200],
                  ),
                  items: _cities.map<DropdownMenuItem<String>>((dynamic city) {
                    return DropdownMenuItem<String>(
                      value: city['name'],
                      child: Text(city['name']),
                    );
                  }).toList(),
                  onChanged: _isFetching
                      ? null
                      : (value) async {
                          if (value != null) {
                            setState(() {
                              _city = value;
                              _district = null;
                              _ward = null;
                            });
                            await _fetchDistricts(value);
                          }
                        },
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  value: _isFetching || _districts[_city]?.isEmpty == true ? null : _district,
                  hint: const Text('Chọn quận/huyện'),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    filled: true,
                    fillColor: isDarkMode ? Colors.grey[700] : Colors.grey[200],
                  ),
                  items: _districts[_city]?.map<DropdownMenuItem<String>>((dynamic district) {
                    return DropdownMenuItem<String>(
                      value: district['name'],
                      child: Text(district['name']),
                    );
                  }).toList(),
                  onChanged: _isFetching
                      ? null
                      : (value) async {
                          if (value != null && _city != null) {
                            setState(() {
                              _district = value;
                              _ward = null;
                            });
                            await _fetchWards(_city!, value);
                          }
                        },
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  value: _isFetching || _wards[_district]?.isEmpty == true ? null : _ward,
                  hint: const Text('Chọn xã/phường'),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    filled: true,
                    fillColor: isDarkMode ? Colors.grey[700] : Colors.grey[200],
                  ),
                  items: _wards[_district]?.map<DropdownMenuItem<String>>((dynamic ward) {
                    return DropdownMenuItem<String>(
                      value: ward['name'],
                      child: Text(ward['name']),
                    );
                  }).toList(),
                  onChanged: _isFetching
                      ? null
                      : (value) {
                          if (value != null) {
                            setState(() {
                              _ward = value;
                            });
                          }
                        },
                ),
                const SizedBox(height: 20),
                const Text(
                  'Phương thức thanh toán',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Radio<String>(
                      value: 'COD',
                      groupValue: _paymentMethod,
                      onChanged: (value) {
                        setState(() {
                          _paymentMethod = value;
                        });
                      },
                    ),
                    const Text('Thanh toán khi nhận hàng (COD)'),
                  ],
                ),
                Row(
                  children: [
                    Radio<String>(
                      value: 'ZaloPay',
                      groupValue: _paymentMethod,
                      onChanged: (value) {
                        setState(() {
                          _paymentMethod = value;
                        });
                      },
                    ),
                    const Text('Thanh toán online (ZaloPay)'),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  'Sản phẩm trong giỏ hàng',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: cartItems.length,
                    itemBuilder: (context, index) {
                      final item = cartItems[index];
                      final product = productProvider.getProductById(item['productId']);
                      if (product == null) return const SizedBox.shrink();
                      final itemTotal = (product.isOnSale ?? false
                          ? product.salePrice
                          : product.price) * (item['quantity'] as num);
                      return ListTile(
                        title: Text(product.name),
                        subtitle: Text('Số lượng: ${item['quantity']} - Kích cỡ: ${item['size']}'),
                        trailing: Text(NumberFormat('#,###').format(itemTotal) + ' VNĐ'),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Tổng cộng:',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      NumberFormat('#,###').format(totalAmount) + ' VNĐ',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? const Color(0xFF1E90FF) : Colors.blue[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading || _isFetching ? null : _createOrder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4A90E2),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('Xác nhận thanh toán'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }
}