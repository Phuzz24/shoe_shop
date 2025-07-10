import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '/providers/auth_provider.dart';
import '/widgets/custom_app_bar.dart';

class NewsScreen extends StatelessWidget {
  const NewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isDarkMode = authProvider.isDarkMode;

    // Dữ liệu tin tức ảo
    final List<Map<String, dynamic>> sneakerNews = [
      {
        'id': '1',
        'title': 'Nike Air Max 2025 Ra Mắt Với Thiết Kế Đột Phá',
        'date': '07/07/2025',
        'image': 'https://via.placeholder.com/300?text=Nike+Air+Max',
        'description': 'Nike vừa ra mắt Air Max 2025 với công nghệ đệm khí tiên tiến, mang lại trải nghiệm thoải mái chưa từng có. Thiết kế mới này hứa hẹn sẽ làm mưa làm gió trên thị trường sneaker toàn cầu.',
      },
      {
        'id': '2',
        'title': 'Adidas Yeezy Boost 350 Quay Trở Lại',
        'date': '06/07/2025',
        'image': 'https://via.placeholder.com/300?text=Yeezy+Boost',
        'description': 'Adidas công bố phiên bản mới của Yeezy Boost 350 với phối màu độc đáo, kết hợp giữa phong cách hiện đại và cổ điển, thu hút sự chú ý của các tín đồ sneaker.',
      },
      {
        'id': '3',
        'title': 'Puma Future Rider Sáng Tạo Mới',
        'date': '05/07/2025',
        'image': 'https://via.placeholder.com/300?text=Puma+Future',
        'description': 'Puma giới thiệu Future Rider với thiết kế hiện đại và sử dụng chất liệu bền vững, phù hợp cho cả thời trang đường phố và các hoạt động thể thao.',
      },
      {
        'id': '4',
        'title': 'New Balance 550 Phiên Bản Hạn Chế',
        'date': '04/07/2025',
        'image': 'https://via.placeholder.com/300?text=New+Balance+550',
        'description': 'New Balance ra mắt phiên bản 550 giới hạn với phối màu độc quyền, mang đến sự kết hợp hoàn hảo giữa phong cách retro và hiện đại.',
      },
      {
        'id': '5',
        'title': 'Reebok Nano X3 Cho Phái Nữ',
        'date': '03/07/2025',
        'image': 'https://via.placeholder.com/300?text=Reebok+Nano+X3',
        'description': 'Reebok Nano X3 được thiết kế đặc biệt cho phụ nữ với hiệu suất cao, phù hợp cho các bài tập gym và phong cách năng động.',
      },
    ];

    return Scaffold(
      appBar: const CustomAppBar(showBackButton: true),
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
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tin Tức Sneaker',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: sneakerNews.length,
                itemBuilder: (context, index) {
                  final news = sneakerNews[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    color: isDarkMode ? Colors.grey[850] : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 4,
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => NewsDetailScreen(news: news),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                            child: CachedNetworkImage(
                              imageUrl: news['image'] as String,
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Center(
                                child: SpinKitFadingCircle(
                                  color: isDarkMode ? const Color(0xFF1E90FF) : Colors.blue[600],
                                  size: 30,
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                height: 200,
                                color: isDarkMode ? Colors.grey[800] : Colors.grey[300],
                                child: const Icon(Icons.error, color: Colors.red),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  news['title'] as String,
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: isDarkMode ? Colors.white : Colors.black87,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Ngày: ${news['date']}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  news['description'] as String,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isDarkMode ? Colors.white70 : Colors.black54,
                                  ),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
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
        ),
      ),
    );
  }
}

class NewsDetailScreen extends StatelessWidget {
  final Map<String, dynamic> news;

  const NewsDetailScreen({super.key, required this.news});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isDarkMode = authProvider.isDarkMode;

    return Scaffold(
      appBar: const CustomAppBar(showBackButton: true),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                child: CachedNetworkImage(
                  imageUrl: news['image'] as String,
                  height: 300,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Center(
                    child: SpinKitFadingCircle(
                      color: isDarkMode ? const Color(0xFF1E90FF) : Colors.blue[600],
                      size: 40,
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: 300,
                    color: isDarkMode ? Colors.grey[800] : Colors.grey[300],
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
                      news['title'] as String,
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Ngày: ${news['date']}',
                      style: TextStyle(
                        fontSize: 16,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      news['description'] as String,
                      style: TextStyle(
                        fontSize: 16,
                        color: isDarkMode ? Colors.white70 : Colors.black87,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Chia sẻ tin tức: ${news['title']}')),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDarkMode ? const Color(0xFF1E90FF) : Colors.blue[600],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      child: const Text('Chia sẻ'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}