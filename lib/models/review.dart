import 'package:cloud_firestore/cloud_firestore.dart';

class Review {
  final String userId;
  final String userName;
  final String comment;
  final double rating;
  final DateTime createdAt;

  Review({
    required this.userId,
    required this.userName,
    required this.comment,
    required this.rating,
    required this.createdAt,
  });

  factory Review.fromMap(Map<String, dynamic> map, String userId) {
    print('Info: Mapping review - userId: $userId, userName: ${map['userName']}'); // Log để debug
    return Review(
      userId: userId,
      userName: map['userName'] as String? ?? 'Unknown', // Lấy userName từ Firestore
      comment: map['comment'] as String? ?? '',
      rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
      createdAt: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}