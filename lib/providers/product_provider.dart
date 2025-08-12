import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shop_shop/main.dart';
import '/models/product.dart';
import '/models/review.dart';
import '/services/product_service.dart';

class ProductProvider with ChangeNotifier {
  final ProductService _productService = ProductService();
  List<Product> _products = [];
  List<Map<String, dynamic>> _cartItems = [];
  List<String> _favoriteIds = [];
  List<Map<String, dynamic>> _notifications = [];
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = false;
  List<Product> _filteredProducts = [];
  Product? _selectedProduct;
  List<Review> _reviews = [];

  List<Product> get products => _filteredProducts.isNotEmpty ? _filteredProducts : _products;
  List<Map<String, dynamic>> get cartItems => _cartItems;
  List<String> get favoriteIds => _favoriteIds;
  List<Map<String, dynamic>> get notifications => _notifications;
  List<Map<String, dynamic>> get orders => _orders;
  bool get isLoading => _isLoading;
  ProductService get productService => _productService;
  Product? get selectedProduct => _selectedProduct;
  List<Review> get reviews => _reviews;
  List<Product> get favoriteProducts => _products.where((product) => _favoriteIds.contains(product.id)).toList();

  ProductProvider() {
    debugPrint('ProductProvider initialized');
  }

  Future<void> fetchProductById(String productId) async {
    try {
      _isLoading = true;
      notifyListeners();
      _selectedProduct = await _productService.getProductById(productId);
      debugPrint('Fetched product with ID: $productId');
    } catch (e) {
      debugPrint('Error fetching product by ID: $e');
      _selectedProduct = null;
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchReviews(String productId) async {
    try {
      _isLoading = true;
      notifyListeners();
      _reviews = await _productService.getReviews(productId);
      debugPrint('Fetched ${_reviews.length} reviews for product ID: $productId');
    } catch (e) {
      debugPrint('Error fetching reviews: $e');
      _reviews = [];
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchProducts() async {
    _isLoading = true;
    notifyListeners();
    try {
      _products = await _productService.getProducts();
      _filteredProducts = _products;
      debugPrint('Fetched ${_products.length} products');
    } catch (e) {
      debugPrint('Error fetching products: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  void filterProducts(String query) {
    if (query.isEmpty) {
      _filteredProducts = _products;
    } else {
      _filteredProducts = _products
          .where((product) =>
              product.name.toLowerCase().contains(query.toLowerCase()) ||
              product.id.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
    notifyListeners();
  }

  void filterProductsAdvanced(String category, double minPrice, double maxPrice, int? size) {
    _filteredProducts = _products.where((product) {
      bool matchesCategory = category == 'All' || product.category == category;
      bool matchesPrice = product.price >= minPrice && product.price <= maxPrice;
      bool matchesSize = size == null || (product.sizes?.contains(size) ?? false);
      return matchesCategory && matchesPrice && matchesSize;
    }).toList();
    notifyListeners();
  }

  Product? getProductById(String productId) {
    try {
      return _products.firstWhere((product) => product.id == productId);
    } catch (e) {
      debugPrint('Product not found for ID: $productId');
      return null;
    }
  }

  String getProductName(String productId) {
    final product = getProductById(productId);
    return product?.name ?? 'Unknown';
  }

  Future<void> addToCart(String userId, String productId, dynamic quantity, dynamic size) async {
    try {
      await _productService.addToCart(userId, productId, quantity, size);
      await _addNotification(
        userId,
        'Thêm vào giỏ hàng',
        'Sản phẩm ${getProductName(productId)} đã được thêm vào giỏ hàng.',
        'Khác',
      );
      try {
        await _productService.sendPushNotification(
          userId,
          'Thêm vào giỏ hàng',
          'Sản phẩm ${getProductName(productId)} đã được thêm vào giỏ hàng.',
        );
      } catch (e) {
        debugPrint('Lỗi gửi thông báo đẩy: $e, bỏ qua.');
      }
      await fetchCartItems(userId);
    } catch (e) {
      debugPrint('Error adding to cart: $e');
      throw e;
    }
  }

  Future<void> removeFromCart(String userId, String productId) async {
    try {
      await _productService.removeFromCart(userId, productId);
      await _addNotification(
        userId,
        'Xóa khỏi giỏ hàng',
        'Sản phẩm ${getProductName(productId)} đã được xóa khỏi giỏ hàng.',
        'Khác',
      );
      try {
        await _productService.sendPushNotification(
          userId,
          'Xóa khỏi giỏ hàng',
          'Sản phẩm ${getProductName(productId)} đã được xóa khỏi giỏ hàng.',
        );
      } catch (e) {
        debugPrint('Lỗi gửi thông báo đẩy: $e, bỏ qua.');
      }
      await fetchCartItems(userId);
    } catch (e) {
      debugPrint('Error removing from cart: $e');
      throw e;
    }
  }

  Future<void> fetchCartItems(String userId) async {
    try {
      _cartItems = await _productService.getCartItems(userId);
      debugPrint('Fetched ${_cartItems.length} cart items for userId: $userId');
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching cart items: $e');
    }
  }

  Future<void> toggleFavorite(String userId, String productId) async {
    try {
      if (_favoriteIds.contains(productId)) {
        await _productService.removeFromFavorites(userId, productId);
        await _addNotification(
          userId,
          'Xóa khỏi yêu thích',
          'Sản phẩm ${getProductName(productId)} đã được xóa khỏi danh sách yêu thích.',
          'Yêu thích',
        );
      } else {
        await _productService.addToFavorites(userId, productId);
        await _addNotification(
          userId,
          'Thêm vào yêu thích',
          'Sản phẩm ${getProductName(productId)} đã được thêm vào danh sách yêu thích.',
          'Yêu thích',
        );
      }
      try {
        await _productService.sendPushNotification(
          userId,
          _favoriteIds.contains(productId) ? 'Xóa khỏi yêu thích' : 'Thêm vào yêu thích',
          'Sản phẩm ${getProductName(productId)} đã được ${_favoriteIds.contains(productId) ? 'xóa' : 'thêm'} khỏi danh sách yêu thích.',
        );
      } catch (e) {
        debugPrint('Lỗi gửi thông báo đẩy: $e, bỏ qua.');
      }
      await fetchFavorites(userId);
    } catch (e) {
      debugPrint('Error toggling favorite: $e');
      throw e;
    }
  }

  Future<void> fetchFavorites(String userId) async {
    try {
      _favoriteIds = await _productService.getFavoriteIds(userId);
      debugPrint('Fetched ${_favoriteIds.length} favorite IDs for userId: $userId');
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching favorites: $e');
    }
  }

  Future<List<Review>> getReviews(String productId) async {
    try {
      return await _productService.getReviews(productId);
    } catch (e) {
      debugPrint('Error getting reviews: $e');
      return [];
    }
  }

  Future<void> addReview(String productId, String userId, String comment, double rating) async {
    try {
      await _productService.addReview(productId, userId, comment, rating);
      await _addNotification(
        userId,
        'Đánh giá sản phẩm',
        'Bạn đã gửi đánh giá cho sản phẩm ${getProductName(productId)}.',
        'Khác',
      );
      try {
        await _productService.sendPushNotification(
          userId,
          'Đánh giá sản phẩm',
          'Bạn đã gửi đánh giá cho sản phẩm ${getProductName(productId)}.',
        );
      } catch (e) {
        debugPrint('Lỗi gửi thông báo đẩy: $e, bỏ qua.');
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding review: $e');
      throw e;
    }
  }

  Future<void> addProduct(Map<String, dynamic> productData) async {
    try {
      await _productService.addProduct(productData);
      await fetchProducts();
    } catch (e) {
      debugPrint('Error adding product: $e');
      throw e;
    }
  }

  Future<void> updateProduct(String productId, Map<String, dynamic> productData) async {
    try {
      await _productService.updateProduct(productId, productData);
      await fetchProducts();
    } catch (e) {
      debugPrint('Error updating product: $e');
      throw e;
    }
  }

  Future<void> deleteProduct(String productId) async {
    try {
      await _productService.deleteProduct(productId);
      await fetchProducts();
    } catch (e) {
      debugPrint('Error deleting product: $e');
      throw e;
    }
  }

  Future<void> fetchNotifications(String userId) async {
    try {
      _notifications = await _productService.getNotifications(userId);
      debugPrint('Fetched ${_notifications.length} notifications for userId: $userId');
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
    }
  }

  Future<void> _addNotification(String userId, String title, String message, String type) async {
    try {
      final notification = {
        'title': title,
        'message': message,
        'type': type,
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      };
      await _productService.addNotification(userId, notification);
      await fetchNotifications(userId);
      if (navigatorKey.currentState != null && navigatorKey.currentState!.context != null) {
        ScaffoldMessenger.of(navigatorKey.currentState!.context!).showSnackBar(
          SnackBar(content: Text('$title: $message')),
        );
      }
    } catch (e) {
      debugPrint('Error adding notification: $e');
    }
  }

  Future<void> fetchOrders(String userId) async {
    try {
      _orders = await _productService.getOrders(userId);
      debugPrint('Fetched ${_orders.length} orders for userId: $userId');
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching orders: $e');
    }
  }
}