import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:shop_shop/config/firebase_options.dart';
import 'package:shop_shop/models/product.dart';
import 'package:shop_shop/providers/auth_provider.dart';
import 'package:shop_shop/providers/product_provider.dart';
import 'package:shop_shop/screens/auth/register_screen.dart';
import 'package:shop_shop/screens/cart_screen.dart';
import 'package:shop_shop/screens/auth/login_screen.dart';
import 'package:shop_shop/screens/notification_screen.dart';
import 'package:shop_shop/screens/product/product_detail_screen.dart';
import 'package:shop_shop/screens/profile/edit_profile_screen.dart';
import 'package:shop_shop/screens/profile/favorite_screen.dart';
import 'package:shop_shop/screens/checkout_screen.dart';
import 'package:shop_shop/screens/order_success_screen.dart';
import 'package:shop_shop/screens/profile/order_history_screen.dart';
import 'package:shop_shop/screens/home/news_screen.dart';
import 'package:shop_shop/screens/home_navigation_screen.dart';
import 'package:shop_shop/screens/admin/admin_dashboard_screen.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:crypto/crypto.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    debugPrint('Info: Firebase initialized successfully at ${DateTime.now()}');

    final messaging = FirebaseMessaging.instance;
    final settings = await messaging.requestPermission();
    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      final fcmToken = await messaging.getToken();
      debugPrint('FCM Token: $fcmToken');
    } else {
      debugPrint('Info: Quyền thông báo bị từ chối hoặc chặn, bỏ qua thông báo đẩy.');
    }

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (navigatorKey.currentState != null && navigatorKey.currentState!.context != null) {
        debugPrint('Got a message whilst in the foreground!');
        debugPrint('Message data: ${message.data}');
        if (message.notification != null) {
          debugPrint('Message also contained a notification: ${message.notification}');
          Fluttertoast.showToast(
            msg: message.notification?.body ?? 'Có thông báo mới!',
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.TOP,
            backgroundColor: Colors.black87,
            textColor: Colors.white,
          );
        }
      }
    });

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  } catch (e, stackTrace) {
    debugPrint('Error: Failed to initialize Firebase - $e\nStackTrace: $stackTrace');
  }
  runApp(MyApp(navigatorKey: navigatorKey));
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('Handling a background message: ${message.messageId}');
}

class MyApp extends StatefulWidget {
  final GlobalKey<NavigatorState> navigatorKey;
  const MyApp({super.key, required this.navigatorKey});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      // Chỉ khởi tạo deep link trên Android/iOS
      _handleIncomingLinks();
    }
  }

  void _handleIncomingLinks() {
    // Không cần StreamSubscription trên web, chỉ dùng cho Android/iOS
  }

  Future<Map<String, dynamic>?> _queryZaloPayOrder(String appTransId) async {
    try {
      final params = {
        'app_id': '2553',
        'app_trans_id': appTransId,
        'mac': '',
      };
      final dataToSign = '${params['app_id']}|${params['app_trans_id']}|PcY4iZIKFCIdgZvA6ueMcMHHUbRLYjPL';
      final hmac = Hmac(sha256, utf8.encode('PcY4iZIKFCIdgZvA6ueMcMHHUbRLYjPL'));
      final mac = hmac.convert(utf8.encode(dataToSign)).toString();
      params['mac'] = mac;

      final response = await http.post(
        Uri.parse('https://sb-openapi.zalopay.vn/v2/query'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: params.map((k, v) => MapEntry(k, v.toString())),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Lỗi kiểm tra trạng thái: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('Lỗi kiểm tra trạng thái ZaloPay: $e');
      return null;
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..initialize()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return MaterialApp(
            navigatorKey: widget.navigatorKey,
            title: 'ShoeTrend',
            theme: ThemeData(primarySwatch: Colors.blue),
            darkTheme: ThemeData.dark(),
            themeMode: authProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: const HomeNavigationScreen(),
            routes: {
              '/login': (context) => const LoginScreen(),
              '/register': (context) => const RegisterScreen(),
              '/edit_profile': (context) => const EditProfileScreen(),
              '/product': (context) {
                final arguments = ModalRoute.of(context)!.settings.arguments;
                if (arguments is Product) {
                  return ProductDetailScreen(product: arguments);
                } else if (arguments is String) {
                  return ProductDetailScreen(productId: arguments);
                }
                debugPrint('Error: Invalid product argument - $arguments');
                return const Scaffold(
                  body: Center(child: Text('Lỗi: Không tìm thấy sản phẩm hoặc tham số không hợp lệ')),
                );
              },
              '/cart': (context) => const CartScreen(),
              '/favorites': (context) => const FavoriteScreen(),
              '/notifications': (context) => const NotificationScreen(),
              '/main': (context) => const HomeNavigationScreen(),
              '/checkout': (context) => const CheckoutScreen(),
              '/order_success': (context) => const OrderSuccessScreen(),
              '/order_history': (context) => const OrderHistoryScreen(),
              '/all_news': (context) => const NewsScreen(),
              '/admin': (context) => FutureBuilder<bool>(
                    future: authProvider.isAdmin(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Scaffold(body: Center(child: CircularProgressIndicator()));
                      }
                      if (snapshot.hasError) {
                        debugPrint('Error: Checking admin status - ${snapshot.error}');
                        return const Scaffold(body: Center(child: Text('Lỗi: Không thể kiểm tra quyền truy cập')));
                      }
                      if (snapshot.hasData && snapshot.data == true) {
                        return const AdminDashboardScreen();
                      }
                      return const Scaffold(
                        body: Center(child: Text('Bạn không có quyền truy cập!')),
                      );
                    },
                  ),
            },
          );
        },
      ),
    );
  }
}