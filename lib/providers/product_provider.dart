import 'package:flutter/material.dart';
import '../models/product.dart';
import '/services/product_service.dart';
import '../models/review.dart';

class ProductProvider with ChangeNotifier {
  final ProductService _productService = ProductService();
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  List<Product> _favoriteProducts = [];
  List<Map<String, dynamic>> _cartItems = [];
  List<Map<String, dynamic>> _notifications = [];
  List<Review> _reviews = [];
  Product? _selectedProduct;

  List<Product> get products => _filteredProducts.isNotEmpty ? _filteredProducts : _products;
  List<Product> get favoriteProducts => _favoriteProducts;
  List<Map<String, dynamic>> get cartItems => _cartItems;
  List<Map<String, dynamic>> get notifications => _notifications;
  List<Review> get reviews => _reviews;
  Product? get selectedProduct => _selectedProduct;

  String? getProductName(String productId) {
    try {
      final product = _products.firstWhere((product) => product.id == productId);
      return product.name;
    } catch (e) {
      print('Error: Không tìm thấy sản phẩm với productId: $productId - $e');
      return productId;
    }
  }

  Future<void> fetchProducts() async {
    try {
      _products = await _productService.getProducts();
      _filteredProducts.clear();
      notifyListeners();
    } catch (e) {
      print('Error: Lỗi khi lấy danh sách sản phẩm - $e');
    }
  }

  Future<void> fetchFavorites(String userId) async {
    try {
      print('Fetching favorites for userId: $userId');
      final favoriteIds = await _productService.getFavoriteIds(userId);
      print('Favorite IDs: $favoriteIds');
      _favoriteProducts = _products.where((product) => favoriteIds.contains(product.id)).toList();
      print('Favorite products count: ${_favoriteProducts.length}');
      for (var product in _products) {
        product.isFavorite = favoriteIds.contains(product.id);
      }
      notifyListeners();
    } catch (e) {
      print('Error: Lỗi khi lấy danh sách yêu thích - $e');
    }
  }

  Future<void> toggleFavorite(String userId, String productId, bool isFavorite) async {
    try {
      if (isFavorite) {
        await _productService.removeFromFavorites(userId, productId);
        _favoriteProducts.removeWhere((product) => product.id == productId);
      } else {
        final product = _products.firstWhere(
          (p) => p.id == productId,
          orElse: () => throw Exception('Sản phẩm không tồn tại với ID: $productId'),
        );
        await _productService.addToFavorites(userId, productId);
        if (!_favoriteProducts.any((p) => p.id == productId)) {
          _favoriteProducts.add(product);
        }
      }
      await fetchFavorites(userId); // Đảm bảo đồng bộ
      notifyListeners();
    } catch (e) {
      print('Error: Lỗi khi cập nhật yêu thích - $e');
      throw Exception('Lỗi khi cập nhật yêu thích: $e');
    }
  }

  Future<void> addToCart(String userId, String productId, dynamic quantity, dynamic size) async {
    try {
      final parsedQuantity = int.tryParse(quantity.toString()) ?? 0;
      final parsedSize = int.tryParse(size.toString()) ?? 0;
      if (parsedQuantity <= 0) {
        throw Exception('Số lượng phải lớn hơn 0');
      }
      await _productService.addToCart(userId, productId, parsedQuantity, parsedSize);
      await fetchCartItems(userId);
    } catch (e) {
      print('Error: Lỗi khi thêm vào giỏ hàng - $e');
      throw Exception('$e');
    }
  }

  Future<void> updateCartItem(String userId, String productId, int newQuantity, int newSize) async {
    try {
      await _productService.removeFromCart(userId, productId);
      await _productService.addToCart(userId, productId, newQuantity, newSize);
      await fetchCartItems(userId);
    } catch (e) {
      print('Error: Lỗi khi cập nhật giỏ hàng - $e');
      throw Exception('Lỗi khi cập nhật giỏ hàng: $e');
    }
  }

  Future<void> removeFromCart(String userId, String productId) async {
    try {
      await _productService.removeFromCart(userId, productId);
      await fetchCartItems(userId);
    } catch (e) {
      print('Error: Lỗi khi xóa khỏi giỏ hàng - $e');
      throw Exception('Lỗi khi xóa khỏi giỏ hàng: $e');
    }
  }

  Future<void> fetchCartItems(String userId) async {
    try {
      _cartItems = await _productService.getCartItems(userId);
      notifyListeners();
    } catch (e) {
      print('Error: Lỗi khi lấy giỏ hàng - $e');
    }
  }

  Future<List<Map<String, dynamic>>> fetchNotifications(String userId) async {
    try {
      _notifications = await _productService.getNotifications(userId);
      notifyListeners();
      return _notifications;
    } catch (e) {
      print('Error: Lỗi khi lấy thông báo - $e');
      throw Exception('Lỗi khi lấy thông báo: $e');
    }
  }

  Future<void> fetchReviews(String productId) async {
    try {
      print('Info: Fetching reviews for productId: $productId');
      _reviews = await _productService.getReviews(productId);
      notifyListeners();
    } catch (e) {
      print('Error: Lỗi khi lấy danh sách đánh giá - $e');
    }
  }

  Future<void> addReview(String productId, String userId, String comment, double rating) async {
    try {
      print('Info: Bắt đầu thêm đánh giá - productId: $productId, userId: $userId, rating: $rating, comment: $comment');
      await _productService.addReview(productId, userId, comment, rating);
      print('Success: Đánh giá gửi thành công');
    } catch (e) {
      print('Error: Lỗi khi thêm đánh giá - $e');
      throw Exception('Lỗi khi thêm đánh giá: $e');
    } finally {
      await fetchReviews(productId);
      await fetchProductById(productId);
      notifyListeners();
    }
  }

  Future<void> fetchProductById(String productId) async {
    try {
      print('Info: Fetching product by ID: $productId');
      final product = await _productService.getProductById(productId);
      _selectedProduct = product;
      if (_selectedProduct != null) {
        await fetchReviews(productId);
      }
      notifyListeners();
    } catch (e) {
      print('Error fetching product by ID: $e');
      _selectedProduct = null;
      notifyListeners();
    }
  }

  Product? getProductById(String id) {
    try {
      return _products.firstWhere((product) => product.id == id);
    } catch (e) {
      return null;
    }
  }

  void filterProducts(String query) {
    if (query.isEmpty) {
      _filteredProducts.clear();
    } else {
      _filteredProducts = _products
          .where((product) =>
              product.name.toLowerCase().contains(query.toLowerCase()) ||
              product.description.toLowerCase().contains(query.toLowerCase()) ||
              product.category.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
    notifyListeners();
  }

  void filterProductsAdvanced(String category, double minPrice, double maxPrice, int? size) {
    _filteredProducts = _products.where((product) {
      bool matchesCategory = category == 'All' || product.category == category;
      bool matchesPrice = product.price >= minPrice && product.price <= maxPrice;
      bool matchesSize = size == null || product.sizes.contains(size);
      return matchesCategory && matchesPrice && matchesSize;
    }).toList();
    notifyListeners();
  }
}