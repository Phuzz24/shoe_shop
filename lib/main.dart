import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:shop_shop/config/firebase_options.dart';
import 'package:shop_shop/models/product.dart';
import 'package:shop_shop/providers/auth_provider.dart';
import 'package:shop_shop/providers/product_provider.dart';
import 'package:shop_shop/screens/auth/register_screen.dart';
import 'package:shop_shop/screens/cart_screen.dart';
import 'package:shop_shop/screens/main_screen.dart';
import 'package:shop_shop/screens/auth/login_screen.dart';
import 'package:shop_shop/screens/notification_screen.dart';
import 'package:shop_shop/screens/product/product_detail_screen.dart';
import 'package:shop_shop/screens/profile/edit_profile_screen.dart';
import 'package:shop_shop/screens/profile/favorite_screen.dart';
import 'package:shop_shop/screens/checkout_screen.dart';
import 'package:shop_shop/screens/order_success_screen.dart';
import 'package:shop_shop/screens/profile/order_history_screen.dart';
import 'package:shop_shop/screens/home/news_screen.dart'; // Cập nhật import cho NewsScreen

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    print('Info: Firebase initialized successfully');
  } catch (e) {
    print('Error: Failed to initialize Firebase - $e');
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
            title: 'ShoeTrend',
            theme: ThemeData(
              primarySwatch: Colors.blue,
              visualDensity: VisualDensity.adaptivePlatformDensity,
            ),
            darkTheme: ThemeData.dark(),
            themeMode: authProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: const MainScreen(),
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
                print('Error: Invalid product argument - $arguments');
                return const Scaffold(
                  body: Center(child: Text('Lỗi: Không tìm thấy sản phẩm hoặc tham số không hợp lệ')),
                );
              },
              '/cart': (context) => const CartScreen(),
              '/favorites': (context) => const FavoriteScreen(),
              '/notifications': (context) => const NotificationScreen(),
              '/main': (context) => const MainScreen(),
              '/checkout': (context) => const CheckoutScreen(),
              '/order_success': (context) => const OrderSuccessScreen(),
              '/order_history': (context) => const OrderHistoryScreen(),
              '/all_news': (context) => const NewsScreen(), // Route cho NewsScreen
            },
            onGenerateRoute: (settings) {
              print('Info: Navigating to route: ${settings.name}, arguments: ${settings.arguments}');
              return null;
            },
            onUnknownRoute: (settings) {
              print('Error: Unknown route - ${settings.name}');
              return MaterialPageRoute(
                builder: (context) => const Scaffold(
                  body: Center(child: Text('Lỗi: Trang không tồn tại')),
                ),
              );
            },
          );
        },
      ),
    );
  }
}