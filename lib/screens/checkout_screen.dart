import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/providers/auth_provider.dart';
import '/providers/product_provider.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';
import 'package:url_launcher/url_launcher.dart';
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
  String? _paymentMethod = 'COD';
  bool _isLoading = false;
  bool _isFetching = true;

  List<dynamic> _cities = [];
  Map<String, List<dynamic>> _districts = {};
  Map<String, List<dynamic>> _wards = {};

  // Cấu hình ZaloPay mới
  static const String zpAppId = '2553';
  static const String zpKey1 = 'PcY4iZIKFCIdgZvA6ueMcMHHUbRLYjPL';
  static const String zpKey2 = 'kLtgPl8HHhfvMuDHPwKfgfsY4Ydm9eIz';
  static const String zpEndpoint = 'https://sb-openapi.zalopay.vn/v2/create';

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userData = authProvider.userData;
    if (userData != null) {
      _nameController.text = userData['name'] ?? '';
      _phoneController.text = userData['phone'] ?? '';
      _addressController.text = userData['address'] ?? '';
      _city = userData['city'];
      _district = userData['district'];
      _ward = userData['ward'];
    }
    _fetchProvinces();
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
        throw Exception('Không thể tải danh sách tỉnh: Mã trạng thái ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Lỗi fetchProvinces: $e');
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
        throw Exception('Không thể tải danh sách quận/huyện: Mã trạng thái ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Lỗi fetchDistricts: $e');
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
            _ward = _ward;
          }
          _isFetching = false;
        });
      } else {
        throw Exception('Không thể tải danh sách xã/phường: Mã trạng thái ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Lỗi fetchWards: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tải danh sách xã/phường: $e')),
      );
      setState(() => _isFetching = false);
    }
  }

  

 Future<Map<String, dynamic>?> _createZaloPayOrder(double amount, String orderId) async {
  try {
    final uuid = Uuid();
    final appTransId = '${DateFormat('yyMMdd').format(DateTime.now())}_${uuid.v1()}';
    final embedData = {
      'redirecturl': 'shopshop://zalopay',
      'callback_url': 'https://8d7e18be4a63.ngrok-free.app/api/zalopay-callback', // Ngrok URL của bạn
    };
    final items = [];

    final currentTime = DateTime.now().millisecondsSinceEpoch; // 01:36 AM +07, 01/08/2025 ≈ 1722468960000
    debugPrint('Current time (milliseconds): $currentTime');

    final params = {
      'app_id': zpAppId,
      'app_trans_id': appTransId,
      'app_user': 'user123',
      'app_time': currentTime.toString(),
      'amount': amount.toInt().toString(),
      'item': jsonEncode(items),
      'embed_data': jsonEncode(embedData),
      'description': 'Thanh toán đơn hàng #$orderId',
      'bank_code': '',
      'mac': '',
    };

   final dataToSign = '${params['app_id']}|${params['app_trans_id']}|${params['app_user']}|${params['amount']}|${params['app_time']}|${params['embed_data']}|${params['item']}';
final hmac = Hmac(sha256, utf8.encode(zpKey1));
final mac = hmac.convert(utf8.encode(dataToSign)).toString();
params['mac'] = mac;

    debugPrint('Params gửi đến ZaloPay: $params');

    final response = await http.post(
      Uri.parse(zpEndpoint),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: params.map((k, v) => MapEntry(k, v.toString())),
    ).timeout(const Duration(seconds: 10), onTimeout: () {
      throw Exception('Kết nối đến ZaloPay timeout');
    });

    debugPrint('Response từ ZaloPay: ${response.statusCode} - ${response.body}');

    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);
      if (result['return_code'] == 1) {
        return {
          'zp_trans_token': result['zp_trans_token'],
          'app_trans_id': appTransId,
        };
      } else {
        throw Exception('ZaloPay: ${result['return_message']}');
      }
    } else {
      throw Exception('Lỗi gọi API ZaloPay: ${response.statusCode} - ${response.body}');
    }
  } catch (e) {
    debugPrint('Lỗi trong _createZaloPayOrder: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Lỗi tạo giao dịch ZaloPay: $e')),
    );
    return null;
  }
}

  Future<bool> _openZaloPayApp(String zpTransToken) async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thanh toán ZaloPay không hỗ trợ trên web. Vui lòng thử trên Android.')),
      );
      return false;
    }
    final url = 'zalo://zaloapp?token=$zpTransToken';
    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        return true;
      } else {
        throw Exception('Không thể mở ứng dụng ZaloPay');
      }
    } catch (e) {
      debugPrint('Lỗi trong _openZaloPayApp: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi mở ứng dụng ZaloPay: $e')),
      );
      return false;
    }
  }

  Future<void> _checkZaloPayStatus(String appTransId) async {
    try {
      final params = {
        'app_id': zpAppId,
        'app_trans_id': appTransId,
        'mac': '',
      };
      final dataToSign = '${params['app_id']}|${params['app_trans_id']}|$zpKey1';
      final hmac = Hmac(sha256, utf8.encode(zpKey1));
      final mac = hmac.convert(utf8.encode(dataToSign)).toString();
      params['mac'] = mac;

      final response = await http.post(
        Uri.parse('https://sb-openapi.zalopay.vn/v2/query'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: params.map((k, v) => MapEntry(k, v.toString())),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        debugPrint('Status check result: $result');
        if (result['return_code'] == 1 && result['is_processing'] == false) {
          final snapshot = await FirebaseFirestore.instance
              .collection('orders')
              .where('app_trans_id', isEqualTo: appTransId)
              .get();
          if (snapshot.docs.isNotEmpty) {
            final orderId = snapshot.docs.first.id;
            await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
              'status': 'Đã thanh toán',
              'paymentStatus': 'Thành công',
              'updatedAt': FieldValue.serverTimestamp(),
            });
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const OrderSuccessScreen()),
            );
          }
        } else if (result['return_code'] != 1) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Thanh toán thất bại: ${result['return_message']}')),
          );
        }
      }
    } catch (e) {
      debugPrint('Lỗi kiểm tra trạng thái: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi kiểm tra trạng thái: $e')),
      );
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

    if (_nameController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _addressController.text.isEmpty ||
        _city == null ||
        _district == null ||
        _ward == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng điền đầy đủ thông tin!')),
      );
      return;
    }

    setState(() => _isLoading = true);

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
          return sum +
              (product.isOnSale ?? false
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
              'name': productProvider.getProductName(item['productId']),
            }).toList(),
        'totalAmount': totalAmount,
        'name': _nameController.text,
        'phone': _phoneController.text,
        'address': _addressController.text,
        'city': _city,
        'district': _district,
        'ward': _ward,
        'paymentMethod': _paymentMethod,
        'status': _paymentMethod == 'COD' ? 'Chờ xử lý' : 'Chờ thanh toán',
        'createdAt': FieldValue.serverTimestamp(),
        'orderDate': DateTime.now().toIso8601String(),
      };

      final docRef = await FirebaseFirestore.instance.collection('orders').add(orderData);

      if (_paymentMethod == 'ZaloPay') {
        final zpOrder = await _createZaloPayOrder(totalAmount, docRef.id);
        if (zpOrder != null) {
          final zpTransToken = zpOrder['zp_trans_token'];
          final appTransId = zpOrder['app_trans_id'];
          if (!kIsWeb) {
            final success = await _openZaloPayApp(zpTransToken);
            if (!success) throw Exception('Không thể mở ZaloPay');
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Web: Mở ZaloPay không hỗ trợ. Kiểm tra trạng thái thủ công.')),
            );
            Future.delayed(const Duration(seconds: 5), () {
              _checkZaloPayStatus(appTransId);
            });
          }
          await FirebaseFirestore.instance.collection('orders').doc(docRef.id).update({
            'status': 'Chờ xác nhận',
            'app_trans_id': appTransId,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } else {
          throw Exception('Không thể tạo giao dịch ZaloPay. Vui lòng kiểm tra log: ${e.toString()}');
        }
      }

      await productProvider.productService.addNotification(
        userId,
        {
          'title': 'Đặt hàng thành công',
          'message': 'Đơn hàng #${docRef.id.substring(0, 8)} đã được tạo thành công với tổng giá trị ${NumberFormat('#,###').format(totalAmount)} VNĐ.',
          'type': 'Đơn hàng',
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        },
      );

      try {
        await productProvider.productService.sendPushNotification(
          userId,
          'Đặt hàng thành công',
          'Đơn hàng #${docRef.id.substring(0, 8)} đã được tạo thành công.',
        );
      } catch (e) {
        debugPrint('Lỗi gửi thông báo đẩy: $e');
      }

      for (var item in cartItems) {
        await productProvider.removeFromCart(userId, item['productId']);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đơn hàng đã được tạo!')),
      );
      if (_paymentMethod != 'ZaloPay' || kIsWeb) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const OrderSuccessScreen()),
        );
      }
    } catch (e) {
      debugPrint('Lỗi trong _createOrder: ${e.toString()}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tạo đơn hàng: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
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
        return sum +
            (product.isOnSale ?? false
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
                            setState(() => _ward = value);
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
                      onChanged: (value) => setState(() => _paymentMethod = value),
                    ),
                    const Text('Thanh toán khi nhận hàng (COD)'),
                  ],
                ),
                Row(
                  children: [
                    Radio<String>(
                      value: 'ZaloPay',
                      groupValue: _paymentMethod,
                      onChanged: (value) => setState(() => _paymentMethod = value),
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