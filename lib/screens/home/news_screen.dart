import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';
import '/providers/auth_provider.dart';
import '/providers/product_provider.dart';
import '/widgets/custom_app_bar.dart';

class NewsScreen extends StatefulWidget {
  final Map<String, dynamic>? initialNews;

  const NewsScreen({super.key, this.initialNews});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user?.uid != null && mounted) {
      Provider.of<ProductProvider>(context, listen: false).fetchCartItems(authProvider.user!.uid);
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isDarkMode = authProvider.isDarkMode;

    if (widget.initialNews == null) {
      return Scaffold(
        backgroundColor: isDarkMode ? const Color(0xFF2E2E48) : const Color(0xFFE0E0E0),
        appBar: CustomAppBar(
          title: 'Tin tức Sneaker',
          showUserName: false,
        ),
        body: const Center(
          child: Text('Không có tin tức để hiển thị'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF2E2E48) : const Color(0xFFE0E0E0),
      appBar: CustomAppBar(
        title: 'Chi tiết tin tức',
        showUserName: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildNewsDetail(widget.initialNews!),
          ],
        ),
      ),
    );
  }

  Widget _buildNewsDetail(Map<String, dynamic> news) {
    final isDarkMode = Provider.of<AuthProvider>(context, listen: false).isDarkMode;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      color: isDarkMode ? Colors.grey[800] : Colors.white,
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            child: CachedNetworkImage(
              imageUrl: news['image'],
              height: 250,
              width: double.infinity,
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
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  news['title'],
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Ngày phát hành: ${news['date']}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isDarkMode ? Colors.white70 : Colors.grey,
                      ),
                ),
                const SizedBox(height: 15),
                Text(
                  'Mô tả chi tiết:',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                ),
                const SizedBox(height: 5),
                Text(
                  news['description'],
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isDarkMode ? Colors.white70 : Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 15),
                Text(
                  'Thông tin thương hiệu:',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                ),
                const SizedBox(height: 5),
                _buildBrandInfo(news['title']),
                const SizedBox(height: 15),
                Text(
                  'Đặc điểm nổi bật:',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                ),
                const SizedBox(height: 5),
                _buildHighlights(news['title']),
                const SizedBox(height: 15),
                Text(
                  'Câu hỏi thường gặp:',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                ),
                const SizedBox(height: 5),
                _buildFAQ(news['title']),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrandInfo(String title) {
    final isDarkMode = Provider.of<AuthProvider>(context, listen: false).isDarkMode;
    String brandInfo;

    switch (title) {
      case 'Nike Air Max 2025 Ra Mắt Với Thiết Kế Đột Phá':
        brandInfo = 'Nike, thương hiệu thể thao hàng đầu từ Mỹ, được thành lập vào năm 1964. Air Max 2025 là sản phẩm mới nhất trong dòng Air Max nổi tiếng với công nghệ đệm khí độc quyền.';
        break;
      case 'Adidas Yeezy Boost 350 Quay Trở Lại':
        brandInfo = 'Adidas, thương hiệu Đức với lịch sử từ năm 1949, hợp tác cùng Kanye West để ra mắt Yeezy Boost 350, nổi tiếng với thiết kế thời trang và công nghệ Boost.';
        break;
      case 'Puma Future Rider Sáng Tạo Mới':
        brandInfo = 'Puma, thương hiệu Đức thành lập năm 1948, tập trung vào thiết kế hiện đại và bền vững. Future Rider là dòng giày kết hợp phong cách và công nghệ thân thiện môi trường.';
        break;
      case 'New Balance 550 Phiên Bản Hạn Chế':
        brandInfo = 'New Balance, thương hiệu Mỹ từ năm 1906, nổi tiếng với giày chạy bộ và phong cách retro. Phiên bản 550 giới hạn mang đậm dấu ấn cổ điển.';
        break;
      case 'Reebok Nano X3 Cho Phái Nữ':
        brandInfo = 'Reebok, thương hiệu Anh thành lập năm 1958, tập trung vào giày tập luyện. Nano X3 được thiết kế đặc biệt cho phụ nữ với hiệu suất cao.';
        break;
      default:
        brandInfo = 'Thông tin thương hiệu chưa được cập nhật.';
    }

    return Text(
      brandInfo,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: isDarkMode ? Colors.white70 : Colors.grey[600],
          ),
    );
  }

  Widget _buildHighlights(String title) {
    final isDarkMode = Provider.of<AuthProvider>(context, listen: false).isDarkMode;
    String highlights;

    switch (title) {
      case 'Nike Air Max 2025 Ra Mắt Với Thiết Kế Đột Phá':
        highlights = '- Công nghệ đệm khí Air Max tiên tiến.\n- Thiết kế nhẹ nhàng, phù hợp cho chạy bộ.\n- Phối màu đa dạng, phong cách hiện đại.';
        break;
      case 'Adidas Yeezy Boost 350 Quay Trở Lại':
        highlights = '- Công nghệ Boost êm ái.\n- Thiết kế tối giản, dễ phối đồ.\n- Phiên bản giới hạn với màu sắc độc quyền.';
        break;
      case 'Puma Future Rider Sáng Tạo Mới':
        highlights = '- Chất liệu tái chế thân thiện môi trường.\n- Thiết kế thời trang, phù hợp đường phố.\n- Đệm cao su bền bỉ.';
        break;
      case 'New Balance 550 Phiên Bản Hạn Chế':
        highlights = '- Phong cách retro kết hợp hiện đại.\n- Phối màu giới hạn, số lượng có hạn.\n- Đệm ENCAP hỗ trợ tối ưu.';
        break;
      case 'Reebok Nano X3 Cho Phái Nữ':
        highlights = '- Thiết kế dành riêng cho phụ nữ.\n- Hỗ trợ tốt cho các bài tập gym.\n- Chất liệu thoáng khí, nhẹ nhàng.';
        break;
      default:
        highlights = 'Đặc điểm nổi bật chưa được cập nhật.';
    }

    return Text(
      highlights,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: isDarkMode ? Colors.white70 : Colors.grey[600],
          ),
    );
  }

  Widget _buildFAQ(String title) {
    final isDarkMode = Provider.of<AuthProvider>(context, listen: false).isDarkMode;
    List<String> faq;

    switch (title) {
      case 'Nike Air Max 2025 Ra Mắt Với Thiết Kế Đột Phá':
        faq = [
          'Q: Giày có chống nước không?\nA: Có, lớp phủ đặc biệt giúp chống nước nhẹ.',
          'Q: Kích cỡ nào phổ biến nhất?\nA: Kích cỡ 40-42 được ưa chuộng nhất.',
          'Q: Giá bán là bao nhiêu?\nA: Khoảng 3.500.000 VNĐ tùy phiên bản.',
        ];
        break;
      case 'Adidas Yeezy Boost 350 Quay Trở Lại':
        faq = [
          'Q: Yeezy Boost có dễ mua không?\nA: Phiên bản giới hạn, cần đặt trước.',
          'Q: Giày có hỗ trợ chạy bộ không?\nA: Phù hợp hơn cho thời trang hơn là chạy bộ.',
          'Q: Giá hiện tại là bao nhiêu?\nA: Khoảng 4.000.000 VNĐ.',
        ];
        break;
      case 'Puma Future Rider Sáng Tạo Mới':
        faq = [
          'Q: Giày có bền không?\nA: Có, chất liệu tái chế rất bền bỉ.',
          'Q: Có kích cỡ lớn không?\nA: Có, lên đến kích cỡ 45.',
          'Q: Giá bao nhiêu?\nA: Khoảng 2.500.000 VNĐ.',
        ];
        break;
      case 'New Balance 550 Phiên Bản Hạn Chế':
        faq = [
          'Q: Phiên bản hạn chế còn hàng không?\nA: Rất ít, nên mua sớm.',
          'Q: Giày nặng không?\nA: Không, chỉ khoảng 300g.',
          'Q: Giá bán là bao nhiêu?\nA: Khoảng 3.200.000 VNĐ.',
        ];
        break;
      case 'Reebok Nano X3 Cho Phái Nữ':
        faq = [
          'Q: Giày phù hợp với bài tập nào?\nA: Phù hợp gym và cardio.',
          'Q: Có size nhỏ không?\nA: Có, từ size 35.',
          'Q: Giá bán ra sao?\nA: Khoảng 2.800.000 VNĐ.',
        ];
        break;
      default:
        faq = ['Câu hỏi thường gặp chưa được cập nhật.'];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: faq.map((q) => Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              q,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDarkMode ? Colors.white70 : Colors.grey[600],
                  ),
            ),
          )).toList(),
    );
  }
}