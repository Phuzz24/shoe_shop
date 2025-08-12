import 'dart:html' as html;
import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shop_shop/providers/auth_provider.dart';
import 'package:shop_shop/providers/product_provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:universal_html/html.dart' as uh;

class ProductManagementScreen extends StatefulWidget {
  const ProductManagementScreen({super.key});

  @override
  State<ProductManagementScreen> createState() => _ProductManagementScreenState();
}

class _ProductManagementScreenState extends State<ProductManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _salePriceController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();
  final TextEditingController _stockController = TextEditingController();
  final TextEditingController _sizesController = TextEditingController();
  final TextEditingController _additionalImageController = TextEditingController();
  bool _isOnSale = false;
  String? _editingProductId;
  List<String> _additionalImages = [];
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      Provider.of<ProductProvider>(context, listen: false).filterProducts(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _nameController.dispose();
    _priceController.dispose();
    _salePriceController.dispose();
    _imageUrlController.dispose();
    _stockController.dispose();
    _sizesController.dispose();
    _additionalImageController.dispose();
    super.dispose();
  }

  Future<String?> _saveImageLocally(XFile image) async {
    try {
      print('Bắt đầu lưu ảnh cục bộ: ${image.name}');
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator(color: Color(0xFF5A9BD4))),
      );

      String? filePath;
      if (kIsWeb) {
        // Trên web, sử dụng universal_html để lưu tạm thời
        final bytes = await image.readAsBytes();
        final blob = uh.Blob([bytes]);
        final url = uh.Url.createObjectUrl(blob);
        filePath = url; // Trả về URL tạm thời trên web
        print('Lưu ảnh tạm trên web, URL: $filePath');
      } else {
        // Trên di động, sử dụng documents directory
        final directory = await getApplicationDocumentsDirectory();
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_${image.name}';
        filePath = '${directory.path}/$fileName';
        await File(image.path).copy(filePath);
        print('Lưu ảnh trên di động, đường dẫn: $filePath');
      }

      Navigator.pop(context);
      return filePath; // Trả về đường dẫn hoặc URL
    } catch (e) {
      print('Lỗi khi lưu ảnh: $e');
      Navigator.pop(context);
      Fluttertoast.showToast(msg: 'Lỗi lưu ảnh: $e');
      return null;
    }
  }

  Future<void> _pickImage({required bool isMainImage}) async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      print('Đã chọn ảnh: ${pickedFile.name}');
      final imagePath = await _saveImageLocally(pickedFile);
      if (imagePath != null) {
        setState(() {
          if (isMainImage) {
            _imageUrlController.text = imagePath;
          } else {
            if (_additionalImages.length >= 5) {
              Fluttertoast.showToast(msg: 'Tối đa 5 ảnh bổ sung!');
              return;
            }
            _additionalImages.add(imagePath);
            print('Đã thêm ảnh bổ sung: $_additionalImages');
          }
        });
      } else {
        Fluttertoast.showToast(msg: 'Không thể lưu ảnh, vui lòng thử lại.');
      }
    } else {
      print('Không có ảnh nào được chọn.');
    }
  }

  void _showAddOrEditProductDialog({Map<String, dynamic>? product}) {
    _nameController.text = product?['name'] ?? '';
    _priceController.text = product?['price']?.toString() ?? '';
    _salePriceController.text = product?['salePrice']?.toString() ?? '';
    _imageUrlController.text = product?['imageUrl'] ?? '';
    _stockController.text = product?['stock']?.toString() ?? '100';
    _sizesController.text = (product?['sizes'] as List?)?.join(',') ?? '';
    _isOnSale = product?['isOnSale'] ?? false;
    _additionalImages = List<String>.from(product?['additionalImages'] ?? []);
    _editingProductId = product != null ? product['id'] : null;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: StatefulBuilder(
          builder: (context, setState) => SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _editingProductId == null ? 'Thêm sản phẩm' : 'Sửa sản phẩm',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Tên sản phẩm',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.grey[100],
                    ),
                    validator: (value) => value!.isEmpty ? 'Vui lòng nhập tên sản phẩm' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _priceController,
                    decoration: InputDecoration(
                      labelText: 'Giá gốc',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.grey[100],
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) =>
                        value!.isEmpty || double.tryParse(value) == null ? 'Vui lòng nhập giá hợp lệ' : null,
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text('Đang sale'),
                    value: _isOnSale,
                    activeColor: const Color(0xFF5A9BD4),
                    onChanged: (value) => setState(() => _isOnSale = value),
                  ),
                  if (_isOnSale)
                    TextFormField(
                      controller: _salePriceController,
                      decoration: InputDecoration(
                        labelText: 'Giá sale',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.grey[100],
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) =>
                          value!.isEmpty || double.tryParse(value) == null ? 'Vui lòng nhập giá sale hợp lệ' : null,
                    ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _imageUrlController,
                          decoration: InputDecoration(
                            labelText: 'Đường dẫn ảnh chính',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.grey[100],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.photo, color: Color(0xFF5A9BD4)),
                        onPressed: () => _pickImage(isMainImage: true),
                      ),
                    ],
                  ),
                  if (_imageUrlController.text.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: kIsWeb
                          ? Image.network(
                              _imageUrlController.text,
                              height: 100,
                              width: 100,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Icon(Icons.error, color: Colors.red, semanticLabel: 'Lỗi tải ảnh: $error'),
                            )
                          : Image.file(
                              File.fromUri(Uri.parse(_imageUrlController.text.replaceFirst('file://', ''))),
                              height: 100,
                              width: 100,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Icon(Icons.error, color: Colors.red, semanticLabel: 'Lỗi tải ảnh: $error'),
                            ),
                    ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _stockController,
                    decoration: InputDecoration(
                      labelText: 'Tồn kho',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.grey[100],
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) =>
                        value!.isEmpty || int.tryParse(value) == null ? 'Vui lòng nhập số tồn kho hợp lệ' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _sizesController,
                    decoration: InputDecoration(
                      labelText: 'Kích cỡ (dùng dấu phẩy)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.grey[100],
                    ),
                    validator: (value) => value!.isEmpty ? 'Vui lòng nhập kích cỡ' : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _additionalImageController,
                          decoration: InputDecoration(
                            labelText: 'Đường dẫn ảnh bổ sung',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.grey[100],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.add_photo_alternate, color: Color(0xFF5A9BD4)),
                        onPressed: () {
                          if (_additionalImageController.text.isNotEmpty) {
                            if (_additionalImages.length >= 5) {
                              Fluttertoast.showToast(msg: 'Tối đa 5 ảnh bổ sung!');
                              return;
                            }
                            setState(() {
                              _additionalImages.add(_additionalImageController.text);
                              _additionalImageController.clear();
                              print('Đã thêm ảnh bổ sung thủ công: $_additionalImages');
                            });
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.photo_library, color: Color(0xFF5A9BD4)),
                        onPressed: () => _pickImage(isMainImage: false),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_additionalImages.isNotEmpty)
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _additionalImages.length,
                        itemBuilder: (context, index) {
                          print('Hiển thị ảnh bổ sung tại index $index: ${_additionalImages[index]}');
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Stack(
                              children: [
                                if (_additionalImages[index].startsWith('file://') && !kIsWeb)
                                  Image.file(
                                    File.fromUri(Uri.parse(_additionalImages[index].replaceFirst('file://', ''))),
                                    height: 80,
                                    width: 80,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Icon(Icons.error, color: Colors.red, semanticLabel: 'Lỗi tải ảnh: $error'),
                                  )
                                else if (kIsWeb)
                                  Image.network(
                                    _additionalImages[index],
                                    height: 80,
                                    width: 80,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Icon(Icons.error, color: Colors.red, semanticLabel: 'Lỗi tải ảnh: $error'),
                                  ),
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: GestureDetector(
                                    onTap: () => setState(() => _additionalImages.removeAt(index)),
                                    child: const Icon(Icons.close, color: Colors.red, size: 20),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            final productProvider = Provider.of<ProductProvider>(context, listen: false);
                            final productData = {
                              'name': _nameController.text,
                              'price': double.tryParse(_priceController.text) ?? 0.0,
                              'salePrice': _isOnSale ? (double.tryParse(_salePriceController.text) ?? 0.0) : 0.0,
                              'imageUrl': _imageUrlController.text,
                              'stock': int.tryParse(_stockController.text) ?? 100,
                              'sizes': _sizesController.text
                                  .split(',')
                                  .map((s) => int.tryParse(s.trim()) ?? 0)
                                  .where((s) => s != 0)
                                  .toList(),
                              'isOnSale': _isOnSale,
                              'additionalImages': _additionalImages,
                            };
                            try {
                              if (_editingProductId == null) {
                                await productProvider.addProduct(productData);
                                Fluttertoast.showToast(msg: 'Thêm sản phẩm thành công!');
                              } else {
                                await productProvider.updateProduct(_editingProductId!, productData);
                                Fluttertoast.showToast(msg: 'Cập nhật sản phẩm thành công!');
                              }
                              Navigator.pop(context);
                              _clearFields();
                            } catch (e) {
                              Fluttertoast.showToast(msg: 'Lỗi: $e');
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF5A9BD4), Color(0xFF3B6FA3)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          child: Text(
                            _editingProductId == null ? 'Thêm' : 'Lưu',
                            style: const TextStyle(color: Colors.white),
                          ),
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
    );
  }

  void _clearFields() {
    _nameController.clear();
    _priceController.clear();
    _salePriceController.clear();
    _imageUrlController.clear();
    _stockController.clear();
    _sizesController.clear();
    _additionalImageController.clear();
    setState(() {
      _isOnSale = false;
      _additionalImages.clear();
      _editingProductId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<AuthProvider>(context).isDarkMode;
    final productProvider = Provider.of<ProductProvider>(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm sản phẩm...',
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF5A9BD4)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => _showAddOrEditProductDialog(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF5A9BD4), Color(0xFF3B6FA3)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: const Text(
                    'Thêm sản phẩm mới',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('products').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFF5A9BD4)));
              }
              if (snapshot.hasError) {
                return Center(child: Text('Lỗi: ${snapshot.error}'));
              }
              final products = snapshot.data?.docs ?? [];

              return GridView.builder(
                padding: const EdgeInsets.all(16.0),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.65,
                ),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index].data() as Map<String, dynamic>;
                  final productId = products[index].id;

                  return Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    color: isDarkMode ? Colors.grey[900] : Colors.white,
                    shadowColor: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(15),
                            topRight: Radius.circular(15),
                          ),
                          child: product['imageUrl'] != null
                              ? (kIsWeb
                                  ? Image.network(
                                      product['imageUrl'],
                                      height: 140,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => Icon(Icons.error, color: Colors.red, semanticLabel: 'Lỗi tải ảnh: $error'),
                                    )
                                  : Image.file(
                                      File.fromUri(Uri.parse(product['imageUrl'].replaceFirst('file://', ''))),
                                      height: 140,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => Icon(Icons.error, color: Colors.red, semanticLabel: 'Lỗi tải ảnh: $error'),
                                    ))
                              : const SizedBox.shrink(),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product['name'] ?? 'Chưa có tên',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Giá: ${NumberFormat('#,###').format(product['price'] ?? 0)} VNĐ',
                                style: const TextStyle(fontSize: 12),
                              ),
                              if (product['isOnSale'] == true)
                                Text(
                                  'Sale: ${NumberFormat('#,###').format(product['salePrice'] ?? 0)} VNĐ',
                                  style: const TextStyle(fontSize: 12, color: Colors.redAccent),
                                ),
                              Text(
                                'Tồn kho: ${product['stock'] ?? 0}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              if (product['additionalImages'] != null && (product['additionalImages'] as List).isNotEmpty)
                                Text(
                                  'Ảnh bổ sung: ${(product['additionalImages'] as List).length}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Color(0xFF5A9BD4), size: 20),
                                    onPressed: () => _showAddOrEditProductDialog(product: {
                                      'id': productId,
                                      'name': product['name'],
                                      'price': product['price'],
                                      'salePrice': product['salePrice'],
                                      'imageUrl': product['imageUrl'],
                                      'stock': product['stock'],
                                      'sizes': product['sizes'],
                                      'isOnSale': product['isOnSale'],
                                      'additionalImages': product['additionalImages'],
                                    }),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Color(0xFFD32F2F), size: 20),
                                    onPressed: () async {
                                      try {
                                        await productProvider.deleteProduct(productId);
                                        Fluttertoast.showToast(msg: 'Xóa sản phẩm thành công!');
                                      } catch (e) {
                                        Fluttertoast.showToast(msg: 'Lỗi: $e');
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
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