import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '/providers/auth_provider.dart';
import '/providers/product_provider.dart';
import '/screens/product/product_detail_screen.dart';
import '/widgets/custom_app_bar.dart';

class FavoriteScreen extends StatefulWidget {
  const FavoriteScreen({super.key});

  @override
  State<FavoriteScreen> createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> {
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final productProvider = Provider.of<ProductProvider>(context);
    final isDarkMode = authProvider.isDarkMode;
    List favorites = productProvider.favoriteProducts;

    // Áp dụng bộ lọc
    if (_filter == 'priceLowToHigh') {
      favorites.sort((a, b) => a.price.compareTo(b.price));
    } else if (_filter == 'priceHighToLow') {
      favorites.sort((a, b) => b.price.compareTo(a.price));
    }

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Sản phẩm yêu thích',
        showUserName: false,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDarkMode
                ? [const Color(0xFF121212), const Color(0xFF1E1E1E)]
                : [Colors.white, Colors.grey[50]!],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: favorites.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.favorite_border, size: 60, color: isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                    const SizedBox(height: 10),
                    Text(
                      'Chưa có sản phẩm yêu thích',
                      style: TextStyle(fontSize: 18, color: isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: favorites.length,
                itemBuilder: (context, index) {
                  final product = favorites[index];
                  return Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    color: isDarkMode ? Colors.grey[850] : Colors.white,
                    margin: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProductDetailScreen(productId: product.id),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isDarkMode
                                ? [Colors.grey[900]!, Colors.grey[800]!]
                                : [Colors.white, Colors.grey[100]!],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(
                                product.imageUrl,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => const Icon(Icons.error),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product.name,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: isDarkMode ? Colors.white : Colors.black87,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  if (product.isOnSale ?? false)
                                    Row(
                                      children: [
                                        Text(
                                          NumberFormat('#,###').format(product.price) + ' VNĐ',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey,
                                            decoration: TextDecoration.lineThrough,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          NumberFormat('#,###').format(product.salePrice) + ' VNĐ',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: isDarkMode ? const Color(0xFFBB86FC) : Colors.purple[600],
                                          ),
                                        ),
                                      ],
                                    )
                                  else
                                    Text(
                                      NumberFormat('#,###').format(product.price) + ' VNĐ',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: isDarkMode ? const Color(0xFFBB86FC) : Colors.purple[600],
                                      ),
                                    ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Danh mục: ${product.category}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                           IconButton(
                              icon: const Icon(Icons.favorite, color: Colors.red),
                              onPressed: () async {
                                try {
                                  await productProvider.toggleFavorite(authProvider.user!.uid, product.id); // Sửa: chỉ truyền 2 tham số
                                  setState(() {}); // Cập nhật UI
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Đã xóa khỏi yêu thích')),
                                  );
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Lỗi: $e')),
                                  );
                                }
                              },
                              padding: EdgeInsets.zero,
                            ),
                                                      ],
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}