import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '/providers/auth_provider.dart';
import '/providers/product_provider.dart';
import '/models/product.dart';
import '/screens/home/news_screen.dart';
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
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) {
        final isDarkMode = Provider.of<AuthProvider>(context).isDarkMode;
        String tempCategory = _selectedCategory;
        String tempFilter = _selectedFilter;
        double tempMinPrice = _minPrice;
        double maxPrice = 100000000;
        int? tempSelectedSize = _selectedSize;

        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          backgroundColor: isDarkMode ? const Color(0xFF2E2E48) : Colors.white,
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lọc sản phẩm',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: isDarkMode ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  value: tempCategory,
                  decoration: InputDecoration(
                    labelText: 'Danh mục',
                    labelStyle: TextStyle(color: isDarkMode ? Colors.white70 : Colors.grey),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[100],
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
                    labelStyle: TextStyle(color: isDarkMode ? Colors.white70 : Colors.grey),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[100],
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
                          labelStyle: TextStyle(color: isDarkMode ? Colors.white70 : Colors.grey),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[100],
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
                          labelStyle: TextStyle(color: isDarkMode ? Colors.white70 : Colors.grey),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          maxPrice = double.tryParse(value) ?? 100000000;
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
                    labelStyle: TextStyle(color: isDarkMode ? Colors.white70 : Colors.grey),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[100],
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
                      child: Text(
                        'Hủy',
                        style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.grey),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () {
                        if (mounted) {
                          setState(() {
                            _selectedCategory = tempCategory;
                            _selectedFilter = tempFilter;
                            _minPrice = tempMinPrice;
                            _maxPrice = maxPrice;
                            _selectedSize = tempSelectedSize;
                          });
                          _applyFilters();
                          Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        shadowColor: Colors.transparent,
                        elevation: 0,
                      ).copyWith(
                        backgroundColor: MaterialStateProperty.resolveWith((states) {
                          return const Color(0xFF4A90E2);
                        }),
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
    if (!mounted) return;
    setState(() {
      _visibleProducts = _visibleProducts + 4 <= 8 ? _visibleProducts + 4 : 8;
    });
  }

  void _loadMoreNews() {
    if (!mounted) return;
    setState(() {
      _visibleNews = _visibleNews + 2 <= 5 ? _visibleNews + 2 : 5;
    });
  }

  void _viewAllProducts() {
    if (!mounted) return;
    Navigator.pushNamed(context, '/all_products');
  }

  void _viewAllNews() {
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NewsScreen()),
    );
  }

  void _selectCategory(String category) {
    if (!mounted) return;
    setState(() {
      _selectedCategory = category;
    });
    _applyFilters();
  }

  void _applyFilters() {
    if (!mounted) return;
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
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

  void _toggleFavorite(String productId) async {
  if (!mounted) return;
  final authProvider = Provider.of<AuthProvider>(context, listen: false);
  final userId = authProvider.user?.uid;
  if (userId != null) {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    try {
      await productProvider.toggleFavorite(userId, productId); // Xóa tham số isFavorite
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Đã cập nhật yêu thích!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  } else {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Vui lòng đăng nhập để thêm vào yêu thích!'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isDarkMode = authProvider.isDarkMode;
    final productProvider = Provider.of<ProductProvider>(context);
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
        'image': 'https://static.nike.com/a/images/t_PDP_1728_v1/f_auto,q_auto:eco/4b8e0c6c-4e8c-4c7d-a0b1-7f2d8a9f8a5e/air-max-2025-shoes-4kZ6m2.png',
        'description': 'Nike vừa ra mắt Air Max 2025 với công nghệ đệm khí tiên tiến...',
      },
      {
        'title': 'Adidas Yeezy Boost 350 Quay Trở Lại',
        'date': '06/07/2025',
        'image': 'https://assets.adidas.com/images/h_840,f_auto,q_auto:sensitive,fl_lossy,c_fill,g_auto/2f0f2f8e3c8c4e4b9e1e8d8e8e8e8e8e/adidas-yeezy-boost-350-v2-mono-cinder-fy5158-01-standard.jpg',
        'description': 'Adidas công bố phiên bản mới của Yeezy Boost 350 với màu sắc độc đáo...',
      },
      {
        'title': 'Puma Future Rider Sáng Tạo Mới',
        'date': '05/07/2025',
        'image': 'https://images.puma.com/image/upload/f_auto,q_auto,b_rgb:fafafa,w_600,h_600/global/377897/01/sv01/fnd/PNA/fmt/png',
        'description': 'Puma giới thiệu Future Rider với thiết kế hiện đại và bền vững...',
      },
      {
        'title': 'New Balance 550 Phiên Bản Hạn Chế',
        'date': '04/07/2025',
        'image': 'https://newbalance.vn/cdn/shop/files/550-AW23-2_1200x1200.jpg?v=1696834138',
        'description': 'New Balance ra mắt phiên bản 550 giới hạn với phối màu độc quyền...',
      },
      {
        'title': 'Reebok Nano X3 Cho Phái Nữ',
        'date': '03/07/2025',
        'image': 'https://www.reebok.com/dw/image/v2/AAYP_PRD/on/demandware.static/-/Sites-reebok-products/default/dw0d3f4e6b/zoom/H68737_01_standard.jpg',
        'description': 'Reebok Nano X3 được thiết kế đặc biệt cho phụ nữ với hiệu suất cao...',
      },
    ];

    final DateTime now = DateTime.now();
    final DateTime offerEnd = now.add(const Duration(days: 2, hours: 3));
    final String countdown = '${offerEnd.difference(now).inDays} ngày ${offerEnd.difference(now).inHours.remainder(24)} giờ';

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF2E2E48) : const Color(0xFFE0E0E0),
      appBar: CustomAppBar(
        title: 'Trang chủ',
      ),
      body: SingleChildScrollView(
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
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(isDarkMode ? 0.4 : 0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const SpinKitFadingCircle(
                            color: Color(0xFF4A90E2),
                            size: 30,
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
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
                  color: _currentIndex == index ? const Color(0xFF4A90E2) : (isDarkMode ? Colors.grey[600] : Colors.grey[400]),
                ),
              )),
            ),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[800] : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDarkMode ? 0.4 : 0.2),
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
                        hintStyle: TextStyle(color: isDarkMode ? Colors.white70 : Colors.grey),
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
                          backgroundColor: _selectedCategory == category
                              ? const Color(0xFF4A90E2)
                              : (isDarkMode ? Colors.grey[700] : Colors.grey[300]),
                          foregroundColor: _selectedCategory == category
                              ? Colors.white
                              : (isDarkMode ? Colors.white70 : Colors.black87),
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
                        backgroundColor: _selectedFilter == 'Best Seller'
                            ? const Color(0xFF4A90E2)
                            : (isDarkMode ? Colors.grey[700] : Colors.grey[300]),
                        foregroundColor: _selectedFilter == 'Best Seller'
                            ? Colors.white
                            : (isDarkMode ? Colors.white70 : Colors.black87),
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
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: isDarkMode ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 10),
            products.isEmpty
                ? const Center(
                    child: SpinKitFadingCircle(
                      color: Color(0xFF4A90E2),
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
                              return ScaleTransition(scale: animation, child: child);
                            },
                            child: GestureDetector(
                              key: ValueKey(product.id),
                              onTap: () {
                                if (mounted) {
                                  Navigator.pushNamed(context, '/product', arguments: product);
                                }
                              },
                              child: Card(
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                color: isDarkMode ? Colors.grey[800] : Colors.white,
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
                                              placeholder: (context, url) => const SpinKitFadingCircle(
                                                color: Color(0xFF4A90E2),
                                                size: 30,
                                              ),
                                              errorWidget: (context, url, error) => Container(
                                                color: isDarkMode ? Colors.grey[700] : Colors.grey[200],
                                                child: const Icon(Icons.error, color: Colors.red),
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
                                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                      fontWeight: FontWeight.bold,
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
                                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                            color: isDarkMode ? Colors.grey[400] : Colors.grey,
                                                            decoration: TextDecoration.lineThrough,
                                                          ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      NumberFormat('#,###').format(product.salePrice) + ' VNĐ',
                                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                            color: const Color(0xFF4A90E2),
                                                          ),
                                                    ),
                                                  ],
                                                )
                                              else
                                                Text(
                                                  NumberFormat('#,###').format(product.price) + ' VNĐ',
                                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                        color: const Color(0xFF4A90E2),
                                                      ),
                                                ),
                                              if (product.stock == 0)
                                                Text(
                                                  'Hết hàng',
                                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
                                          child: Text(
                                            'Sale',
                                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
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
                                          color: product.isFavorite ? Colors.red : (isDarkMode ? Colors.grey[400] : Colors.grey),
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
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF4A90E2), Color(0xFF50C9C3)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(isDarkMode ? 0.4 : 0.2),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: _loadMoreProducts,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  shadowColor: Colors.transparent,
                                ),
                                child: const Text('Xem thêm'),
                              ),
                            ),
                          ),
                        ),
                      if (_visibleProducts < 8 && products.length > 8)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Center(
                            child: TextButton(
                              onPressed: _viewAllProducts,
                              child: Text(
                                'Xem tất cả',
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: const Color(0xFF4A90E2),
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
                gradient: const LinearGradient(
                  colors: [Color(0xFF4A90E2), Color(0xFF50C9C3)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDarkMode ? 0.4 : 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
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
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Kết thúc trong: $countdown',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.white70,
                              ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (mounted) {
                        setState(() {
                          _selectedFilter = 'Sale';
                        });
                        _applyFilters();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF4A90E2),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Mua ngay'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tin tức sneaker',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: isDarkMode ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                TextButton(
                  onPressed: _viewAllNews,
                  child: Text(
                    'Xem tất cả',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: const Color(0xFF4A90E2),
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _visibleNews < sneakerNews.length ? _visibleNews : sneakerNews.length,
              itemBuilder: (context, index) {
                final news = sneakerNews[index];
                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                  child: GestureDetector(
                    key: ValueKey(news['title']),
                    onTap: () {
                      if (mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => NewsScreen(initialNews: news),
                          ),
                        );
                      }
                    },
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      color: isDarkMode ? Colors.grey[800] : Colors.white,
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.horizontal(left: Radius.circular(15)),
                            child: CachedNetworkImage(
                              imageUrl: news['image'],
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => const SpinKitFadingCircle(
                                color: Color(0xFF4A90E2),
                                size: 30,
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: isDarkMode ? Colors.grey[700] : Colors.grey[200],
                                child: const Icon(Icons.error, color: Colors.red),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    news['title'],
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: isDarkMode ? Colors.white : Colors.black87,
                                        ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    news['date'],
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: isDarkMode ? Colors.white70 : Colors.grey,
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
                );
              },
            ),
            if (_visibleNews < sneakerNews.length)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4A90E2), Color(0xFF50C9C3)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDarkMode ? 0.4 : 0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _loadMoreNews,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        shadowColor: Colors.transparent,
                      ),
                      child: const Text('Xem thêm'),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}