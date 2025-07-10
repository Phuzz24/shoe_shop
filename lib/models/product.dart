class Product {
  final String id;
  final String name;
  final double price; // Giá gốc
  final double salePrice; // Giá sale
  final String imageUrl;
  final String description;
  final String category;
  final List<int> sizes;
  final int stock;
  final List<String> additionalImages;
  final bool? isOnSale;
  final double? averageRating; // Thêm thuộc tính averageRating
  bool isFavorite; // Thêm trường này

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.salePrice,
    required this.imageUrl,
    this.description = '',
    required this.category,
    required this.sizes,
    required this.stock,
    this.additionalImages = const [],
    this.isOnSale = false,
    this.isFavorite = false, // Khởi tạo mặc định là false
    this.averageRating, // Thêm vào constructor
  });

  factory Product.fromMap(Map<String, dynamic> map, String id) {
    return Product(
      id: id,
      name: map['name'] as String? ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0, // Giá gốc
      salePrice: (map['salePrice'] as num?)?.toDouble() ?? 0.0, // Giá sale
      imageUrl: map['imageUrl'] as String? ?? '',
      description: map['description'] as String? ?? '',
      category: map['category'] as String? ?? '',
      sizes: (map['sizes'] as List<dynamic>?)?.map((s) => s as int).toList() ?? [],
      stock: int.tryParse(map['stock']?.toString() ?? '0') ?? 0,
      additionalImages: (map['additionalImages'] as List<dynamic>?)?.map((i) => i as String).toList() ?? [],
      isOnSale: map['isOnSale'] as bool? ?? false,
      averageRating: (map['averageRating'] as num?)?.toDouble(), // Lấy averageRating từ Firestore
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price, // Giá gốc
      'salePrice': salePrice, // Giá sale
      'imageUrl': imageUrl,
      'description': description,
      'category': category,
      'sizes': sizes,
      'stock': stock,
      'additionalImages': additionalImages,
      'isOnSale': isOnSale,
      'averageRating': averageRating, // Lưu averageRating vào Firestore
    };
  }
}