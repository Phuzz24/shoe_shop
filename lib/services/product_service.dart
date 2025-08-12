import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import '../models/product.dart';
import '../models/review.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ProductService {
  final CollectionReference _productsCollection = FirebaseFirestore.instance.collection('products');
  final CollectionReference _usersCollection = FirebaseFirestore.instance.collection('users');

  Future<List<Product>> getProducts() async {
    final snapshot = await _productsCollection.get();
    return snapshot.docs
        .map((doc) => Product.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }

  Future<Product?> getProductById(String productId) async {
    final doc = await _productsCollection.doc(productId).get();
    if (doc.exists) {
      return Product.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }
    return null;
  }

  Future<void> addProduct(Map<String, dynamic> productData) async {
    try {
      await _productsCollection.add({
        'name': productData['name'],
        'price': double.parse(productData['price'].toString()),
        'salePrice': double.parse(productData['salePrice'].toString()),
        'imageUrl': productData['imageUrl'],
        'isOnSale': productData['isOnSale'] ?? false,
        'stock': productData['stock'] ?? 100,
        'sizes': productData['sizes'] ?? [],
      });
      debugPrint('Success: Product added');
    } catch (e) {
      debugPrint('Error: Lỗi khi thêm sản phẩm - $e');
      throw Exception('Lỗi khi thêm sản phẩm: $e');
    }
  }

  Future<void> updateProduct(String productId, Map<String, dynamic> productData) async {
    try {
      await _productsCollection.doc(productId).update({
        'name': productData['name'],
        'price': double.parse(productData['price'].toString()),
        'salePrice': double.parse(productData['salePrice'].toString()),
        'imageUrl': productData['imageUrl'],
        'isOnSale': productData['isOnSale'],
        'stock': productData['stock'],
        'sizes': productData['sizes'],
      });
      debugPrint('Success: Product updated with ID: $productId');
    } catch (e) {
      debugPrint('Error: Lỗi khi cập nhật sản phẩm - $e');
      throw Exception('Lỗi khi cập nhật sản phẩm: $e');
    }
  }

  Future<void> deleteProduct(String productId) async {
    try {
      await _productsCollection.doc(productId).delete();
      debugPrint('Success: Product deleted with ID: $productId');
    } catch (e) {
      debugPrint('Error: Lỗi khi xóa sản phẩm - $e');
      throw Exception('Lỗi khi xóa sản phẩm: $e');
    }
  }

  Future<void> addToCart(String userId, String productId, dynamic quantity, dynamic size) async {
    final cartRef = _usersCollection.doc(userId).collection('cart').doc(productId);
    final productRef = _productsCollection.doc(productId);
    final productDoc = await productRef.get();
    if (!productDoc.exists) {
      throw Exception('Sản phẩm không tồn tại');
    }
    final productData = productDoc.data() as Map<String, dynamic>;
    final stock = (productData['stock'] as num?)?.toInt() ?? 0;
    final sizes = productData['sizes'] is String
        ? productData['sizes'].split(',').map((s) => int.tryParse(s.trim()) ?? 0).toList()
        : List<int>.from(productData['sizes'] ?? []);

    final parsedQuantity = int.tryParse(quantity.toString()) ?? 0;
    final parsedSize = int.tryParse(size.toString()) ?? 0;

    if (parsedQuantity <= 0) {
      throw Exception('Số lượng phải lớn hơn 0');
    }
    if (!sizes.contains(parsedSize)) {
      throw Exception('Kích cỡ không hợp lệ');
    }

    final doc = await cartRef.get();
    final currentQuantity = doc.exists ? (doc.data() as Map<String, dynamic>)['quantity'] as num? ?? 0 : 0;
    final newQuantity = currentQuantity.toInt() + parsedQuantity;

    if (newQuantity > stock) {
      throw Exception('Số lượng vượt quá tồn kho (${stock} sản phẩm)');
    }

    if (newQuantity <= 0) {
      await cartRef.delete();
    } else {
      await cartRef.set({
        'productId': productId,
        'quantity': newQuantity,
        'size': parsedSize,
        'addedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  Future<void> removeFromCart(String userId, String productId) async {
    await _usersCollection.doc(userId).collection('cart').doc(productId).delete();
  }

  Future<List<Map<String, dynamic>>> getCartItems(String userId) async {
    final snapshot = await _usersCollection.doc(userId).collection('cart').get();
    return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
  }

  Future<void> addToFavorites(String userId, String productId) async {
    debugPrint('Adding to favorites - userId: $userId, productId: $productId');
    await _usersCollection
        .doc(userId)
        .collection('favorites')
        .doc(productId)
        .set({
          'productId': productId,
          'addedAt': FieldValue.serverTimestamp(),
        });
    debugPrint('Added to favorites successfully');
  }

  Future<void> removeFromFavorites(String userId, String productId) async {
    debugPrint('Removing from favorites - userId: $userId, productId: $productId');
    await _usersCollection.doc(userId).collection('favorites').doc(productId).delete();
    debugPrint('Removed from favorites successfully');
  }

  Future<List<String>> getFavoriteIds(String userId) async {
    final snapshot = await _usersCollection.doc(userId).collection('favorites').get();
    return snapshot.docs.map((doc) => doc.id).toList();
  }

  Future<List<Review>> getReviews(String productId) async {
    try {
      final snapshot = await _productsCollection
          .doc(productId)
          .collection('reviews')
          .orderBy('timestamp', descending: true)
          .get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Review.fromMap(data, doc.id);
      }).toList();
    } catch (e) {
      debugPrint('Error: Lỗi khi lấy danh sách đánh giá - $e');
      return [];
    }
  }

  Future<void> addReview(String productId, String userId, String comment, double rating) async {
    try {
      final productDoc = await _productsCollection.doc(productId).get();
      if (!productDoc.exists) {
        throw Exception('Sản phẩm không tồn tại');
      }

      final userDoc = await _usersCollection.doc(userId).get();
      final userData = userDoc.data() as Map<String, dynamic>?;
      if (userData == null) {
        throw Exception('No user data found for userId: $userId');
      }
      final userName = userData['name'] as String? ?? 'Unknown';

      final reviewRef = await _productsCollection.doc(productId).collection('reviews').add({
        'userId': userId,
        'userName': userName,
        'comment': comment,
        'rating': rating,
        'timestamp': FieldValue.serverTimestamp(),
      });

      final reviewsSnapshot = await _productsCollection.doc(productId).collection('reviews').get();
      double totalRating = 0.0;
      int reviewCount = reviewsSnapshot.docs.length;

      for (var doc in reviewsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        totalRating += (data['rating'] as num?)?.toDouble() ?? 0.0;
      }

      double averageRating = reviewCount > 0 ? totalRating / reviewCount : 0.0;
      await _productsCollection.doc(productId).update({
        'averageRating': averageRating,
      });
      debugPrint('Success: Review added and average rating updated');
    } catch (e) {
      debugPrint('Error: Lỗi khi thêm đánh giá - $e');
      throw Exception('Lỗi khi thêm đánh giá: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getNotifications(String userId) async {
    try {
      final snapshot = await _usersCollection
          .doc(userId)
          .collection('notifications')
          .orderBy('timestamp', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => {
                ...doc.data() as Map<String, dynamic>,
                'id': doc.id,
              })
          .toList();
    } catch (e) {
      debugPrint('Error: Lỗi khi lấy thông báo - $e');
      throw Exception('Lỗi khi lấy thông báo: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getOrders(String userId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
  }

  Future<void> addNotification(String userId, Map<String, dynamic> notification) async {
    try {
      await _usersCollection
          .doc(userId)
          .collection('notifications')
          .add({
            ...notification,
            'timestamp': FieldValue.serverTimestamp(),
          });
      debugPrint('Success: Notification added for userId: $userId');
    } catch (e) {
      debugPrint('Error: Lỗi khi thêm thông báo - $e');
      throw Exception('Lỗi khi thêm thông báo: $e');
    }
  }

  Future<void> sendPushNotification(String userId, String title, String message) async {
  try {
    final userDoc = await _usersCollection.doc(userId).get();
    final userData = userDoc.data() as Map<String, dynamic>?;
    final fcmToken = userData?['fcmToken'] as String?;
    if (fcmToken == null) {
      debugPrint('Error: Không tìm thấy FCM token cho userId: $userId');
      throw Exception('Không tìm thấy FCM token');
    }

    const serverKey = 'YOUR_FCM_SERVER_KEY'; // Thay bằng server key thực tế
    final url = Uri.parse('https://fcm.googleapis.com/fcm/send');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'key=$serverKey',
    };
    final body = jsonEncode({
      'to': fcmToken,
      'notification': {
        'title': title,
        'body': message,
        'click_action': 'FLUTTER_NOTIFICATION_CLICK',
      },
      'data': {
        'userId': userId,
      },
    });

    final response = await http.post(url, headers: headers, body: body);
    if (response.statusCode == 200) {
      debugPrint('Success: Push notification sent to userId: $userId');
    } else {
      debugPrint('Error: Failed to send push notification - ${response.body}');
      throw Exception('Failed to send push notification: ${response.statusCode}');
    }
  } catch (e) {
    debugPrint('Error: Lỗi khi gửi thông báo đẩy - $e');
    // Có thể thông báo cho người dùng hoặc admin nếu cần
  }
}
}