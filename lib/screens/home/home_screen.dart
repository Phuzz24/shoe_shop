import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shop_shop/screens/home/news_screen.dart';
import '/providers/auth_provider.dart';
import '/providers/product_provider.dart';
import '/models/product.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '/widgets/custom_app_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  String _selectedFilter = 'All';
  double _minPrice = 0;
  double _maxPrice = 100000000;
  int? _selectedSize;
  int _visibleProducts = 4;
  int _visibleNews = 3;
  String _searchQuery = '';
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      productProvider.fetchProducts().then((_) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final userId = authProvider.user?.uid;
        if (userId != null && mounted) {
          productProvider.fetchFavorites(userId).then((_) {
            if (mounted) setState(() {});
          });
        }
      });
    });
    _searchController.addListener(() {
      if (mounted) {
        setState(() {
          _searchQuery = _searchController.text;
        });
        _applyFilters();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        String tempCategory = _selectedCategory;
        String tempFilter = _selectedFilter;
        double tempMinPrice = _minPrice;
        double tempMaxPrice = _maxPrice;
        int? tempSelectedSize = _selectedSize;

        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Lọc sản phẩm',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF4A90E2)),
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  value: tempCategory,
                  decoration: InputDecoration(
                    labelText: 'Danh mục',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  items: ['All', 'Nike', 'Adidas', 'Running', 'Casual']
                      .map((category) => DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          ))
                      .toList(),
                  onChanged: (value) {
                    tempCategory = value!;
                  },
                ),
                const SizedBox(height: 15),
                DropdownButtonFormField<String>(
                  value: tempFilter,
                  decoration: InputDecoration(
                    labelText: 'Bộ lọc',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  items: ['All', 'Best Seller', 'Sale']
                      .map((filter) => DropdownMenuItem(
                            value: filter,
                            child: Text(filter),
                          ))
                      .toList(),
                  onChanged: (value) {
                    tempFilter = value!;
                  },
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          labelText: 'Giá tối thiểu',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          filled: true,
                          fillColor: Colors.grey[100],
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          tempMinPrice = double.tryParse(value) ?? 0;
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          labelText: 'Giá tối đa',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          filled: true,
                          fillColor: Colors.grey[100],
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          tempMaxPrice = double.tryParse(value) ?? 100000000;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                DropdownButtonFormField<int?>(
                  value: tempSelectedSize,
                  decoration: InputDecoration(
                    labelText: 'Kích cỡ',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  items: [null, 38, 39, 40, 41, 42]
                      .map((size) => DropdownMenuItem(
                            value: size,
                            child: Text(size?.toString() ?? 'Any Size'),
                          ))
                      .toList(),
                  onChanged: (value) {
                    tempSelectedSize = value;
                  },
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      ),
                      child: const Text('Hủy'),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () {
                        if (mounted) {
                          setState(() {
                            _selectedCategory = tempCategory;
                            _selectedFilter = tempFilter;
                            _minPrice = tempMinPrice;
                            _maxPrice = tempMaxPrice;
                            _selectedSize = tempSelectedSize;
                          });
                          _applyFilters();
                          Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4A90E2),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Áp dụng'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _loadMoreProducts() {
    if (mounted) {
      setState(() {
        _visibleProducts = _visibleProducts + 4 <= 8 ? _visibleProducts + 4 : 8;
      });
    }
  }

  void _loadMoreNews() {
    if (mounted) {
      setState(() {
        _visibleNews = _visibleNews + 2 <= 5 ? _visibleNews + 2 : 5;
      });
    }
  }

  void _viewAllProducts() {
    if (mounted) {
      Navigator.pushNamed(context, '/all_products');
    }
  }

  void _viewAllNews() {
    if (mounted) {
      Navigator.pushNamed(context, '/all_news');
    }
  }

  void _selectCategory(String category) {
    if (mounted) {
      setState(() {
        _selectedCategory = category;
      });
      _applyFilters();
    }
  }

  void _applyFilters() {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    if (mounted) {
      if (_selectedFilter == 'Sale') {
        productProvider.filterProductsAdvanced(
          _selectedCategory,
          _minPrice,
          _maxPrice,
          _selectedSize,
        );
        productProvider.filterProducts(_searchQuery);
        final filtered = productProvider.products.where((product) => product.isOnSale ?? false).toList();
        productProvider.products.clear();
        productProvider.products.addAll(filtered);
      } else {
        productProvider.filterProductsAdvanced(
          _selectedCategory,
          _minPrice,
          _maxPrice,
          _selectedSize,
        );
        if (_searchQuery.isNotEmpty) {
          productProvider.filterProducts(_searchQuery);
        }
      }
      productProvider.notifyListeners();
    }
  }

  void _toggleFavorite(String productId) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.uid;
    if (userId != null && mounted) {
      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      try {
        await productProvider.toggleFavorite(userId, productId, false); // Giả định false để thêm
        if (mounted) {
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã cập nhật yêu thích!')),
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
          const SnackBar(content: Text('Vui lòng đăng nhập để thêm vào yêu thích!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final productProvider = Provider.of<ProductProvider>(context);
    final isDarkMode = authProvider.isDarkMode;
    final products = productProvider.products;

    final List<String> bannerImages = [
      'https://img01.ztat.net/banner/4fcb357ada0f4a2b8fcb5e6edd4c7931/6d7a7e36711c4babb09d03ae1e4682ea.jpg?imwidth=1200',
      'https://ignewsimg.s3.ap-northeast-1.wasabisys.com/CyMzZvBPCBi',
      'https://img.mytheresa.com/media/static/raw/cms/l/SM_Monetate_Images/19_Gecco/PocketBannerAssets/ww/WW-Gucci-Shoes-Pre-Fall-2025_PB_20250702094106.jpg',
    ];

    final List<Map<String, dynamic>> sneakerNews = [
      {
        'title': 'Nike Air Max 2025 Ra Mắt Với Thiết Kế Đột Phá',
        'date': '07/07/2025',
        'image': 'https://via.placeholder.com/150?text=Nike+Air+Max',
        'description': 'Nike vừa ra mắt Air Max 2025 với công nghệ đệm khí tiên tiến...',
      },
      {
        'title': 'Adidas Yeezy Boost 350 Quay Trở Lại',
        'date': '06/07/2025',
        'image': 'https://via.placeholder.com/150?text=Yeezy+Boost',
        'description': 'Adidas công bố phiên bản mới của Yeezy Boost 350 với màu sắc độc đáo...',
      },
      {
        'title': 'Puma Future Rider Sáng Tạo Mới',
        'date': '05/07/2025',
        'image': 'https://via.placeholder.com/150?text=Puma+Future',
        'description': 'Puma giới thiệu Future Rider với thiết kế hiện đại và bền vững...',
      },
      {
        'title': 'New Balance 550 Phiên Bản Hạn Chế',
        'date': '04/07/2025',
        'image': 'https://via.placeholder.com/150?text=New+Balance+550',
        'description': 'New Balance ra mắt phiên bản 550 giới hạn với phối màu độc quyền...',
      },
      {
        'title': 'Reebok Nano X3 Cho Phái Nữ',
        'date': '03/07/2025',
        'image': 'https://via.placeholder.com/150?text=Reebok+Nano+X3',
        'description': 'Reebok Nano X3 được thiết kế đặc biệt cho phụ nữ với hiệu suất cao...',
      },
    ];

    final DateTime now = DateTime.now();
    final DateTime offerEnd = now.add(const Duration(days: 2, hours: 3));
    final String countdown = '${offerEnd.difference(now).inDays} ngày ${offerEnd.difference(now).inHours.remainder(24)} giờ';

    return Scaffold(
      appBar: const CustomAppBar(showBackButton: false),
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
                CarouselSlider(
                  options: CarouselOptions(
                    height: 200,
                    enlargeCenterPage: true,
                    autoPlay: true,
                    autoPlayInterval: const Duration(seconds: 3),
                    aspectRatio: 16 / 9,
                    viewportFraction: 1.0,
                    enableInfiniteScroll: true,
                    onPageChanged: (index, reason) {
                      if (mounted) {
                        setState(() {
                          _currentIndex = index;
                        });
                      }
                    },
                  ),
                  items: bannerImages.map((imageUrl) {
                    return Builder(
                      builder: (BuildContext context) {
                        return Container(
                          width: MediaQuery.of(context).size.width,
                          margin: const EdgeInsets.symmetric(horizontal: 5.0),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            gradient: LinearGradient(
                              colors: isDarkMode
                                  ? [Colors.grey[800]!, Colors.grey[900]!]
                                  : [Colors.white, Colors.grey[200]!],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: CachedNetworkImage(
                              imageUrl: imageUrl,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => SpinKitFadingCircle(
                                color: isDarkMode ? const Color(0xFF1E90FF) : Colors.blue[600],
                                size: 30,
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: isDarkMode ? Colors.grey[800] : Colors.grey[300],
                                child: const Icon(Icons.error, color: Colors.red),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  }).toList(),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(bannerImages.length, (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentIndex == index ? Colors.blue : Colors.grey,
                    ),
                  )),
                ),
                const SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(
                    color: isDarkMode ? const Color(0xFF2E2E48) : const Color(0xFFF0F0F0),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
                          decoration: InputDecoration(
                            hintText: 'Tìm kiếm sản phẩm...',
                            hintStyle: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54),
                            prefixIcon: const Icon(Icons.search, color: Color(0xFF4A90E2)),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, color: Color(0xFF4A90E2)),
                                    onPressed: () {
                                      if (mounted) {
                                        _searchController.clear();
                                        setState(() {
                                          _searchQuery = '';
                                        });
                                        _applyFilters();
                                      }
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.filter_list, color: Color(0xFF4A90E2)),
                        onPressed: _showFilterDialog,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ...['All', 'Nike', 'Adidas', 'Running', 'Casual'].map((category) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: ElevatedButton(
                            onPressed: () => _selectCategory(category),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _selectedCategory == category ? const Color(0xFF4A90E2) : Colors.grey[300],
                              foregroundColor: _selectedCategory == category ? Colors.white : Colors.black87,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            ),
                            child: Text(category),
                          ),
                        );
                      }).toList(),
                      Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: ElevatedButton(
                          onPressed: () {
                            if (mounted) {
                              setState(() {
                                _selectedFilter = 'Best Seller';
                              });
                              _applyFilters();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _selectedFilter == 'Best Seller' ? const Color(0xFF4A90E2) : Colors.grey[300],
                            foregroundColor: _selectedFilter == 'Best Seller' ? Colors.white : Colors.black87,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                          child: const Text('Phổ biến'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Sản phẩm nổi bật',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 10),
                products.isEmpty
                    ? Center(
                        child: SpinKitFadingCircle(
                          color: isDarkMode ? const Color(0xFF1E90FF) : Colors.blue[600],
                          size: 50,
                        ),
                      )
                    : Column(
                        children: [
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.only(top: 10),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                              childAspectRatio: 0.7,
                            ),
                            itemCount: _visibleProducts < products.length ? _visibleProducts : products.length,
                            itemBuilder: (context, index) {
                              final product = products[index];
                              return AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                transitionBuilder: (Widget child, Animation<double> animation) {
                                  return FadeTransition(opacity: animation, child: child);
                                },
                                child: GestureDetector(
                                  key: ValueKey(product.id),
                                  onTap: () {
                                    if (mounted) {
                                      Navigator.pushNamed(context, '/product', arguments: product);
                                    }
                                  },
                                  child: Card(
                                    elevation: 6,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    color: isDarkMode ? Colors.grey[900] : Colors.white,
                                    child: Stack(
                                      children: [
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: ClipRRect(
                                                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                                                child: CachedNetworkImage(
                                                  imageUrl: product.imageUrl,
                                                  fit: BoxFit.cover,
                                                  placeholder: (context, url) => SpinKitFadingCircle(
                                                    color: isDarkMode ? const Color(0xFF1E90FF) : Colors.blue[600],
                                                    size: 30,
                                                  ),
                                                  errorWidget: (context, url, error) => Container(
                                                    color: isDarkMode ? Colors.grey[800] : Colors.grey[300],
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.all(8.0),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    product.name,
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 16,
                                                      color: isDarkMode ? Colors.white : Colors.black87,
                                                    ),
                                                    maxLines: 1,
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
                                                            color: isDarkMode ? const Color(0xFF1E90FF) : Colors.blue[600],
                                                          ),
                                                        ),
                                                      ],
                                                    )
                                                  else
                                                    Text(
                                                      NumberFormat('#,###').format(product.price) + ' VNĐ',
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        color: isDarkMode ? const Color(0xFF1E90FF) : Colors.blue[600],
                                                      ),
                                                    ),
                                                  if (product.stock == 0)
                                                    Text(
                                                      'Hết hàng',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.red,
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (product.isOnSale ?? false)
                                          Positioned(
                                            top: 10,
                                            left: 10,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Colors.red[600],
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: const Text(
                                                'Sale',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          ),
                                        Positioned(
                                          top: 10,
                                          right: 10,
                                          child: IconButton(
                                            icon: Icon(
                                              product.isFavorite ? Icons.favorite : Icons.favorite_border,
                                              color: product.isFavorite ? Colors.red : (isDarkMode ? Colors.white70 : Colors.grey),
                                            ),
                                            onPressed: () => _toggleFavorite(product.id),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          if (_visibleProducts < products.length)
                            Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Center(
                                child: ElevatedButton(
                                  onPressed: _loadMoreProducts,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isDarkMode ? const Color(0xFF1E90FF) : Colors.blue[600],
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: const Text('Xem thêm'),
                                ),
                              ),
                            ),
                          if (_visibleProducts < 8 && products.length > 8)
                            Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Center(
                                child: TextButton(
                                  onPressed: _viewAllProducts,
                                  child: const Text(
                                    'Xem tất cả',
                                    style: TextStyle(
                                      color: Color(0xFF4A90E2),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDarkMode
                          ? [const Color(0xFF1E90FF), const Color(0xFF0F3460)]
                          : [Colors.blue[600]!, Colors.blue[800]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ưu đãi đặc biệt',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: isDarkMode ? Colors.white : Colors.white,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'Kết thúc trong: $countdown',
                              style: TextStyle(
                                fontSize: 14,
                                color: isDarkMode ? Colors.white70 : Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Chức năng đang phát triển!')),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: isDarkMode ? const Color(0xFF1E90E2) : Colors.blue[600],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('Xem ngay'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Tin tức về Sneaker',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 10),
               ListView.builder(
  shrinkWrap: true,
  physics: const NeverScrollableScrollPhysics(),
  itemCount: _visibleNews < sneakerNews.length ? _visibleNews : sneakerNews.length,
  itemBuilder: (context, index) {
    final news = sneakerNews[index];
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: isDarkMode ? Colors.grey[800] : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: () {
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => NewsDetailScreen(news: news),
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(15),
        child: ListTile(
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: CachedNetworkImage(
              imageUrl: news['image'] as String,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              placeholder: (context, url) => SpinKitFadingCircle(
                color: isDarkMode ? const Color(0xFF1E90FF) : Colors.blue[600],
                size: 20,
              ),
              errorWidget: (context, url, error) => Container(
                color: isDarkMode ? Colors.grey[800] : Colors.grey[300],
                child: const Icon(Icons.error, color: Colors.red),
              ),
            ),
          ),
          title: Text(
            news['title'] as String,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                news['description'] as String,
                style: TextStyle(
                  fontSize: 14,
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 5),
              Text(
                'Ngày: ${news['date']}',
                style: TextStyle(
                  fontSize: 12,
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  },
),
                if (_visibleNews < sneakerNews.length)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Center(
                      child: ElevatedButton(
                        onPressed: _loadMoreNews,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDarkMode ? const Color(0xFF1E90FF) : Colors.blue[600],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('Xem thêm'),
                      ),
                    ),
                  ),
                if (_visibleNews < 5 && sneakerNews.length > 5)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Center(
                      child: TextButton(
                        onPressed: _viewAllNews,
                        child: const Text(
                          'Xem tất cả',
                          style: TextStyle(
                            color: Color(0xFF4A90E2),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}