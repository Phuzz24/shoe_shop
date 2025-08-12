import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '/providers/auth_provider.dart';
import '/providers/product_provider.dart';
import '/models/product.dart';
import '/widgets/custom_app_bar.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product? product;
  final String? productId;

  const ProductDetailScreen({super.key, this.product, this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _selectedSize = 0;
  int _quantity = 1;
  bool _isFavorite = false;
  String? _userId;
  Product? _loadedProduct;
  String _currentImageUrl = '';
  final _reviewController = TextEditingController();
  double _rating = 0.0;
  bool _isSubmittingReview = false;

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _userId = authProvider.user?.uid;
    _loadProductAndFavoriteStatus();
  }

  @override
  void didUpdateWidget(covariant ProductDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.productId != oldWidget.productId || widget.product != oldWidget.product) {
      _loadProductAndFavoriteStatus();
    }
  }

  void _loadProductAndFavoriteStatus() async {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);

    if (widget.product != null) {
      _loadedProduct = widget.product;
      _currentImageUrl = _loadedProduct!.imageUrl;
      _isFavorite = _loadedProduct!.isFavorite;
    } else if (widget.productId != null) {
      await productProvider.fetchProductById(widget.productId!);
      _loadedProduct = productProvider.selectedProduct; // Sử dụng getter selectedProduct
      if (_loadedProduct != null) {
        _currentImageUrl = _loadedProduct!.imageUrl;
        _isFavorite = _loadedProduct!.isFavorite;
      }
    }

    if (_userId != null && _loadedProduct != null && mounted) {
      await productProvider.fetchFavorites(_userId!);
      if (mounted) {
        setState(() {
          _isFavorite = productProvider.favoriteIds.contains(_loadedProduct!.id); // Sử dụng favoriteIds thay vì favoriteProducts
          _loadedProduct!.isFavorite = _isFavorite;
        });
      }
    }
    if (_loadedProduct != null && mounted) {
      await productProvider.fetchReviews(_loadedProduct!.id);
    }
  }

  void _toggleFavorite() async {
    if (_userId == null || _loadedProduct == null || !mounted) return;

    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    try {
      await productProvider.toggleFavorite(_userId!, _loadedProduct!.id); // Chỉ truyền 2 tham số
      if (mounted) {
        setState(() {
          _isFavorite = !_isFavorite;
          _loadedProduct!.isFavorite = _isFavorite;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi cập nhật yêu thích: $e')),
        );
      }
    }
  }

  void _addToCart() async {
    if (_userId != null && _selectedSize != 0 && _loadedProduct != null && mounted) {
      try {
        final productProvider = Provider.of<ProductProvider>(context, listen: false);
        final parsedQuantity = _quantity;
        final parsedSize = _selectedSize;
        await productProvider.addToCart(_userId!, _loadedProduct!.id, parsedQuantity, parsedSize);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã thêm vào giỏ hàng!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: $e')),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng chọn kích cỡ!')),
        );
      }
    }
  }

  void _buyNow() async {
    if (_userId != null && _selectedSize != 0 && _loadedProduct != null && mounted) {
      try {
        final productProvider = Provider.of<ProductProvider>(context, listen: false);
        final parsedQuantity = _quantity;
        final parsedSize = _selectedSize;
        await productProvider.addToCart(_userId!, _loadedProduct!.id, parsedQuantity, parsedSize);
        if (mounted) {
          Navigator.pushNamed(context, '/cart');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: $e')),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng chọn kích cỡ!')),
        );
      }
    }
  }

  void _selectImage(String imageUrl) {
    if (mounted) {
      setState(() {
        _currentImageUrl = imageUrl;
      });
    }
  }

  void _submitReview() async {
    if (_userId == null || _loadedProduct == null || _reviewController.text.trim().isEmpty || _rating <= 0 || !mounted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng kiểm tra đăng nhập, nội dung hoặc số sao!')),
        );
      }
      return;
    }

    setState(() {
      _isSubmittingReview = true;
    });

    try {
      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      await productProvider.addReview(
        _loadedProduct!.id,
        _userId!,
        _reviewController.text.trim(),
        _rating,
      );
      if (mounted) {
        _reviewController.clear();
        setState(() {
          _rating = 0.0;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đánh giá đã được gửi!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi gửi đánh giá: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmittingReview = false;
        });
      }
    }
  }

  Future<String> _getUserName(String userId) async {
    if (_userId == userId && _userId != null) {
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
        return doc.data()?['name'] ?? 'Anonymous';
      } catch (e) {
        return 'Anonymous';
      }
    }
    return 'Anonymous';
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final isDarkMode = authProvider.isDarkMode;

    if (_loadedProduct == null) {
      return Scaffold(
        body: Center(
          child: SpinKitFadingCircle(
            color: Theme.of(context).primaryColor,
            size: 50,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: CustomAppBar(
        title: _loadedProduct!.name,
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
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                        child: CachedNetworkImage(
                          imageUrl: _currentImageUrl,
                          fit: BoxFit.cover,
                          height: 350,
                          width: double.infinity,
                          placeholder: (context, url) => SpinKitFadingCircle(
                            color: Theme.of(context).primaryColor,
                            size: 50,
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: isDarkMode ? Colors.grey[800] : Colors.grey[300],
                            child: const Icon(Icons.error, color: Colors.red),
                          ),
                        ),
                      ),
                      if (_loadedProduct!.additionalImages.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: SizedBox(
                            height: 100,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _loadedProduct!.additionalImages.length,
                              itemBuilder: (context, index) {
                                final imageUrl = _loadedProduct!.additionalImages[index];
                                return Padding(
                                  padding: const EdgeInsets.only(right: 10),
                                  child: GestureDetector(
                                    onTap: () => _selectImage(imageUrl),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: CachedNetworkImage(
                                        imageUrl: imageUrl,
                                        fit: BoxFit.cover,
                                        width: 100,
                                        height: 100,
                                        placeholder: (context, url) => SpinKitFadingCircle(
                                          color: Theme.of(context).primaryColor,
                                          size: 30,
                                        ),
                                        errorWidget: (context, url, error) => Container(
                                          color: isDarkMode ? Colors.grey[800] : Colors.grey[300],
                                          child: const Icon(Icons.error, color: Colors.red),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  color: isDarkMode ? Colors.grey[800] : Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _loadedProduct!.name,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            if (_loadedProduct!.isOnSale ?? false)
                              Text(
                                NumberFormat('#,###').format(_loadedProduct!.price) + ' VNĐ',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            if (_loadedProduct!.isOnSale ?? false) const SizedBox(width: 10),
                            Text(
                              (_loadedProduct!.isOnSale ?? false)
                                  ? NumberFormat('#,###').format(_loadedProduct!.salePrice) + ' VNĐ'
                                  : NumberFormat('#,###').format(_loadedProduct!.price) + ' VNĐ',
                              style: TextStyle(
                                fontSize: 20,
                                color: isDarkMode ? const Color(0xFF1E90FF) : Colors.blue[600],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (_loadedProduct!.stock == 0)
                          Text(
                            'Hết hàng',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.red,
                            ),
                          ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            RatingBarIndicator(
                              rating: _loadedProduct!.averageRating ?? 0.0,
                              itemBuilder: (context, _) => const Icon(
                                Icons.star,
                                color: Colors.amber,
                              ),
                              itemCount: 5,
                              itemSize: 20.0,
                              direction: Axis.horizontal,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              _loadedProduct!.averageRating != null
                                  ? '${_loadedProduct!.averageRating!.toStringAsFixed(1)} (${productProvider.reviews.length} đánh giá)'
                                  : '0.0 (0 đánh giá)',
                              style: TextStyle(
                                fontSize: 16,
                                color: isDarkMode ? Colors.white70 : Colors.black54,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: Icon(
                                _isFavorite ? Icons.favorite : Icons.favorite_border,
                                color: _isFavorite ? Colors.red : (isDarkMode ? Colors.white70 : Colors.grey),
                              ),
                              onPressed: _toggleFavorite,
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Mô tả:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          _loadedProduct!.description,
                          style: TextStyle(
                            fontSize: 16,
                            color: isDarkMode ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  color: isDarkMode ? Colors.grey[800] : Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kích cỡ:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 10,
                          children: _loadedProduct!.sizes.map((size) {
                            return ChoiceChip(
                              label: Text(size.toString()),
                              selected: _selectedSize == size,
                              onSelected: (selected) {
                                if (mounted) {
                                  setState(() {
                                    _selectedSize = selected ? size : 0;
                                  });
                                }
                              },
                              selectedColor: const Color(0xFF4A90E2),
                              labelStyle: TextStyle(
                                color: _selectedSize == size ? Colors.white : (isDarkMode ? Colors.white70 : Colors.black87),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Số lượng:',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDarkMode ? Colors.white : Colors.black87,
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove),
                                  onPressed: _quantity > 1
                                      ? () {
                                          if (mounted) {
                                            setState(() => _quantity--);
                                          }
                                        }
                                      : null,
                                  color: isDarkMode ? Colors.white70 : Colors.black87,
                                ),
                                Text(
                                  _quantity.toString(),
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: isDarkMode ? Colors.white : Colors.black87,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add),
                                  onPressed: _quantity < _loadedProduct!.stock
                                      ? () {
                                          if (mounted) {
                                            setState(() => _quantity++);
                                          }
                                        }
                                      : null,
                                  color: isDarkMode ? Colors.white70 : Colors.black87,
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _addToCart,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF4A90E2),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 15),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                child: const Text('Thêm vào giỏ hàng'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _buyNow,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green[600],
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 15),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                child: const Text('Mua ngay'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  color: isDarkMode ? Colors.grey[800] : Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Đánh giá:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (productProvider.reviews.isNotEmpty)
                          Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Tổng quan đánh giá:',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: isDarkMode ? Colors.white70 : Colors.black54,
                                    ),
                                  ),
                                  Text(
                                    '${_loadedProduct!.averageRating?.toStringAsFixed(1) ?? '0.0'}/5 (${productProvider.reviews.length} đánh giá)',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: isDarkMode ? Colors.white70 : Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: productProvider.reviews.length,
                                itemBuilder: (context, index) {
                                  final review = productProvider.reviews[index];
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    color: isDarkMode ? Colors.grey[700] : Colors.white,
                                    child: ListTile(
                                      leading: const Icon(Icons.person, color: Color(0xFF4A90E2)),
                                      title: Text(
                                        review.userName,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: isDarkMode ? Colors.white : Colors.black87,
                                        ),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                review.comment,
                                                style: TextStyle(
                                                  color: isDarkMode ? Colors.white70 : Colors.black54,
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Text(
                                                '(${review.rating.toStringAsFixed(1)}/5)',
                                                style: TextStyle(
                                                  color: isDarkMode ? Colors.amber[200] : Colors.amber,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Text(
                                            'Ngày: ${DateFormat('dd/MM/yyyy HH:mm').format(review.createdAt.toUtc().add(const Duration(hours: 7)))}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        if (productProvider.reviews.isEmpty)
                          Text(
                            'Chưa có đánh giá nào.',
                            style: TextStyle(
                              fontSize: 16,
                              color: isDarkMode ? Colors.white70 : Colors.black54,
                            ),
                          ),
                        const SizedBox(height: 10),
                        if (_userId != null)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Đánh giá của bạn:',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isDarkMode ? Colors.white : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Row(
                                children: [
                                  RatingBar.builder(
                                    initialRating: _rating,
                                    minRating: 0,
                                    direction: Axis.horizontal,
                                    allowHalfRating: true,
                                    itemCount: 5,
                                    itemSize: 30,
                                    itemBuilder: (context, _) => const Icon(
                                      Icons.star,
                                      color: Colors.amber,
                                    ),
                                    onRatingUpdate: (rating) {
                                      if (mounted) {
                                        setState(() {
                                          _rating = rating;
                                        });
                                      }
                                    },
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    '${_rating.toStringAsFixed(1)}/5',
                                    style: TextStyle(
                                      color: isDarkMode ? Colors.white70 : Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              TextField(
                                controller: _reviewController,
                                decoration: InputDecoration(
                                  hintText: 'Viết đánh giá của bạn...',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  filled: true,
                                  fillColor: isDarkMode ? Colors.grey[700] : Colors.grey[200],
                                ),
                                maxLines: 3,
                              ),
                              const SizedBox(height: 10),
                              ElevatedButton(
                                onPressed: _isSubmittingReview ? null : _submitReview,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF4A90E2),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                child: _isSubmittingReview
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                      )
                                    : const Text('Gửi đánh giá'),
                              ),
                            ],
                          ),
                        if (_userId == null)
                          TextButton(
                            onPressed: () {
                              if (mounted) {
                                Navigator.pushNamed(context, '/login');
                              }
                            },
                            child: const Text(
                              'Đăng nhập để viết đánh giá',
                              style: TextStyle(color: Color(0xFF4A90E2)),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  color: isDarkMode ? Colors.grey[800] : Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sản phẩm liên quan:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 150,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: productProvider.products.length > 3 ? 3 : productProvider.products.length,
                            itemBuilder: (context, index) {
                              final relatedProduct = productProvider.products[index];
                              if (relatedProduct.category == _loadedProduct!.category && relatedProduct.id != _loadedProduct!.id) {
                                return Padding(
                                  padding: const EdgeInsets.only(right: 10),
                                  child: GestureDetector(
                                    onTap: () {
                                      if (mounted) {
                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => ProductDetailScreen(productId: relatedProduct.id),
                                          ),
                                        );
                                      }
                                    },
                                    child: Card(
                                      elevation: 2,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      child: Column(
                                        children: [
                                          ClipRRect(
                                            borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                                            child: CachedNetworkImage(
                                              imageUrl: relatedProduct.imageUrl,
                                              height: 100,
                                              width: 100,
                                              fit: BoxFit.cover,
                                              placeholder: (context, url) => SpinKitFadingCircle(
                                                color: Theme.of(context).primaryColor,
                                                size: 20,
                                              ),
                                              errorWidget: (context, url, error) => Container(
                                                color: isDarkMode ? Colors.grey[700] : Colors.grey[200],
                                                child: const Icon(Icons.error, color: Colors.red),
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(4.0),
                                            child: Text(
                                              relatedProduct.name,
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: isDarkMode ? Colors.white : Colors.black87,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              maxLines: 1,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                      ],
                    ),
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
    _reviewController.dispose();
    super.dispose();
  }
}