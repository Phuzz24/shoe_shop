import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';
import '../models/review.dart';

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

    // Chuyển đổi quantity và size từ dynamic sang num
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
  print('Adding to favorites - userId: $userId, productId: $productId');
  await _usersCollection
      .doc(userId)
      .collection('favorites')
      .doc(productId)
      .set({
        'productId': productId,
        'addedAt': FieldValue.serverTimestamp(),
      });
  print('Added to favorites successfully');
}

Future<void> removeFromFavorites(String userId, String productId) async {
  print('Removing from favorites - userId: $userId, productId: $productId');
  await _usersCollection.doc(userId).collection('favorites').doc(productId).delete();
  print('Removed from favorites successfully');
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
      print('Error: Lỗi khi lấy danh sách đánh giá - $e');
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
    } catch (e) {
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
}