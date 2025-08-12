import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthProvider with ChangeNotifier {
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);
  firebase_auth.User? _user;
  Map<String, dynamic>? _userData;
  bool _isDarkMode = false;
  bool _hasUnreadNotifications = false;
  bool _isPasswordVisible = false;
  static const String _rememberedEmailKey = 'remembered_email';
  static const String _rememberedPasswordKey = 'remembered_password';
  static const String _rememberMeKey = 'remember_me';
  bool _rememberMe = false;

  firebase_auth.User? get user => _user;
  Map<String, dynamic>? get userData => _userData;
  bool get isDarkMode => _isDarkMode;
  bool get hasUnreadNotifications => _hasUnreadNotifications;
  bool get isPasswordVisible => _isPasswordVisible;
  bool get rememberMe => _rememberMe;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  TextEditingController get emailController => _emailController;
  TextEditingController get passwordController => _passwordController;

  AuthProvider() {
    _user = FirebaseAuth.instance.currentUser;
    if (_user != null) {
      _fetchUserData();
      _updateFcmToken();
      checkNotifications();
    }
    FirebaseAuth.instance.authStateChanges().listen((user) {
      _user = user;
      if (user != null) {
        _fetchUserData();
        _updateFcmToken();
        checkNotifications();
      } else {
        _userData = null;
        _hasUnreadNotifications = false;
        notifyListeners();
      }
    });
  }

  Future<void> _updateFcmToken() async {
    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken != null && _user != null) {
        await FirebaseFirestore.instance.collection('users').doc(_user!.uid).set(
          {'fcmToken': fcmToken},
          SetOptions(merge: true),
        );
        debugPrint('Success: FCM token updated for userId: ${_user!.uid}');
      }
    } catch (e) {
      debugPrint('Error: Failed to update FCM token: $e');
    }
  }

  void toggleDarkMode() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  Future<void> _fetchUserData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .get();
      _userData = doc.data();
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching user data: $e');
    }
  }

  Future<void> initialize() async {
    await _initializeAuthState();
    await _checkThemePreference();
    await _loadRememberedCredentials();
    await checkNotifications();
    debugPrint('Info: AuthProvider initialized');
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  set rememberMe(bool value) {
    _rememberMe = value;
    notifyListeners();
  }

  Future<void> _initializeAuthState() async {
    _auth.authStateChanges().listen((firebase_auth.User? user) async {
      _user = user;
      await _loadUserData();
      if (user != null) {
        final fcmToken = await FirebaseMessaging.instance.getToken();
        if (fcmToken != null) {
          await _firestore.collection('users').doc(user.uid).update({
            'fcmToken': fcmToken,
            'lastUpdated': FieldValue.serverTimestamp(),
          });
        }
        await checkNotifications();
      }
      notifyListeners();
    }, onError: (e) {
      debugPrint('Auth state error: $e');
    });
  }

  Future<void> _loadUserData() async {
    if (_user != null) {
      try {
        final doc = await _firestore.collection('users').doc(_user!.uid).get();
        if (doc.exists) {
          _userData = doc.data() as Map<String, dynamic>? ?? {};
        } else {
          await _firestore.collection('users').doc(_user!.uid).set({
            'email': _user!.email,
            'createdAt': FieldValue.serverTimestamp(),
            'role': 'user',
            'chatIds': [], // Thêm mảng chatIds mặc định
          }, SetOptions(merge: true));
          final newDoc = await _firestore.collection('users').doc(_user!.uid).get();
          _userData = newDoc.data() as Map<String, dynamic>? ?? {};
        }
      } catch (e) {
        debugPrint('Error loading user data: $e');
        _userData = {'email': _user!.email, 'role': 'user', 'chatIds': []};
      }
    } else {
      _userData = null;
    }
    notifyListeners();
  }

  Future<bool> isAdmin() async {
    if (_user == null) return false;
    try {
      final userDoc = await _firestore.collection('users').doc(_user!.uid).get();
      return userDoc.data()?['role'] == 'admin';
    } catch (e) {
      debugPrint('Error checking admin status: $e');
      return false;
    }
  }

  Future<void> checkNotifications() async {
    if (_user == null) {
      _hasUnreadNotifications = false;
      notifyListeners();
      return;
    }
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_user!.uid)
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .get();
      _hasUnreadNotifications = snapshot.docs.isNotEmpty;
      notifyListeners();
    } catch (e) {
      debugPrint('Error checking notifications: $e');
      _hasUnreadNotifications = false;
      notifyListeners();
    }
  }

  Future<String> signIn(String email, String password, BuildContext context) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      _user = userCredential.user;
      await _loadUserData();
      if (_rememberMe) {
        await _saveRememberedCredentials(email, password);
      } else {
        await _clearRememberedCredentials();
      }
      if (context.mounted) {
        if (await isAdmin()) {
          Navigator.pushReplacementNamed(context, '/admin');
        } else {
          Navigator.pushReplacementNamed(context, '/main');
        }
      }
      await checkNotifications();
      notifyListeners();
      return 'success';
    } on firebase_auth.FirebaseAuthException catch (e) {
      return _handleAuthException(e);
    } catch (e) {
      debugPrint('Error signing in: $e');
      return 'Đăng nhập thất bại: Đã xảy ra lỗi không xác định.';
    }
  }

  Future<String> signUp(String email, String password, String name, String phone) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      _user = userCredential.user;
      if (_user != null) {
        const String defaultAvatar = 'https://tse2.mm.bing.net/th/id/OIP.WMnC3P-wkCPX04vVFQGqKQHaHY?r=0&rs=1&pid=ImgDetMain&o=7&rm=3';
        await _firestore.collection('users').doc(_user!.uid).set({
          'name': name,
          'email': email,
          'phone': phone,
          'photoURL': defaultAvatar,
          'createdAt': FieldValue.serverTimestamp(),
          'role': 'user',
          'chatIds': [], // Thêm mảng chatIds mặc định
        }, SetOptions(merge: true));
        await _loadUserData();
        final fcmToken = await FirebaseMessaging.instance.getToken();
        if (fcmToken != null) {
          await _firestore.collection('users').doc(_user!.uid).update({
            'fcmToken': fcmToken,
            'lastUpdated': FieldValue.serverTimestamp(),
          });
        }
      }
      await checkNotifications();
      notifyListeners();
      return 'success';
    } on firebase_auth.FirebaseAuthException catch (e) {
      return _handleAuthException(e);
    } catch (e) {
      debugPrint('Error signing up: $e');
      return 'Đăng ký thất bại: Đã xảy ra lỗi không xác định.';
    }
  }

  Future<String> signInWithGoogle(BuildContext context) async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return 'Đăng nhập bị hủy bởi người dùng.';
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCredential = await _auth.signInWithCredential(credential);
      _user = userCredential.user;
      if (_user != null) {
        final userDoc = await _firestore.collection('users').doc(_user!.uid).get();
        if (!userDoc.exists) {
          await _firestore.collection('users').doc(_user!.uid).set({
            'name': googleUser.displayName ?? 'Unknown',
            'email': googleUser.email,
            'photoURL': googleUser.photoUrl ?? 'https://tse2.mm.bing.net/th/id/OIP.WMnC3P-wkCPX04vVFQGqKQHaHY?r=0&rs=1&pid=ImgDetMain&o=7&rm=3',
            'createdAt': FieldValue.serverTimestamp(),
            'role': 'user',
            'chatIds': [], // Thêm mảng chatIds mặc định
          }, SetOptions(merge: true));
        }
        final fcmToken = await FirebaseMessaging.instance.getToken();
        if (fcmToken != null) {
          await _firestore.collection('users').doc(_user!.uid).update({
            'fcmToken': fcmToken,
            'lastUpdated': FieldValue.serverTimestamp(),
          });
        }
      }
      await _loadUserData();
      if (context.mounted) {
        if (await isAdmin()) {
          Navigator.pushReplacementNamed(context, '/admin');
        } else {
          Navigator.pushReplacementNamed(context, '/main');
        }
      }
      await checkNotifications();
      notifyListeners();
      return 'success';
    } on firebase_auth.FirebaseAuthException catch (e) {
      debugPrint('Google Sign-In error: $e');
      return 'Đăng nhập bằng Google thất bại: ${e.message}';
    } catch (e) {
      debugPrint('Google Sign-In error: $e');
      return 'Đăng nhập bằng Google thất bại: Đã xảy ra lỗi không xác định.';
    }
  }

  Future<void> fetchUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      _userData = doc.exists ? doc.data() as Map<String, dynamic>? ?? {} : {'name': 'Unknown'};
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching user data: $e');
      _userData = {'name': 'Unknown'};
      notifyListeners();
    }
  }

  Future<String?> saveImageLocally(File image) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final localPath = '${directory.path}/$fileName';
      final savedImage = await image.copy(localPath);
      return savedImage.path;
    } catch (e) {
      debugPrint('Error saving image locally: $e');
      return null;
    }
  }

  Future<void> updateProfile(String uid, {
    String? name,
    String? phone,
    String? photoUrl,
    String? bio,
    String? address,
    DateTime? birthDate,
    String? gender,
    String? city,
    String? district,
    String? ward,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (phone != null) updates['phone'] = phone;
    if (bio != null) updates['bio'] = bio;
    if (address != null) updates['address'] = address;
    if (birthDate != null) updates['birthDate'] = Timestamp.fromDate(birthDate);
    if (gender != null) updates['gender'] = gender;
    if (photoUrl != null) updates['photoURL'] = photoUrl;
    if (city != null) updates['city'] = city;
    if (district != null) updates['district'] = district;
    if (ward != null) updates['ward'] = ward;
    updates['updatedAt'] = FieldValue.serverTimestamp();

    try {
      await _firestore.collection('users').doc(uid).update(updates);
      await fetchUserData(uid);
    } catch (e) {
      debugPrint('Error updating profile: $e');
      throw e;
    }
    notifyListeners();
  }

  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        await _firestore.collection('users').doc(user.uid).delete();
        await user.delete();
        _user = null;
        _userData = null;
        await _clearRememberedCredentials();
        await checkNotifications();
        notifyListeners();
      } catch (e) {
        debugPrint('Error deleting account: $e');
        throw e;
      }
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
      _user = null;
      _userData = null;
      await checkNotifications();
      notifyListeners();
    } catch (e) {
      debugPrint('Error signing out: $e');
      throw e;
    }
  }

  void togglePasswordVisibility() {
    _isPasswordVisible = !_isPasswordVisible;
    notifyListeners();
  }

  Future<void> _checkThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);
    notifyListeners();
  }

  Future<void> _loadRememberedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    _rememberMe = prefs.getBool(_rememberMeKey) ?? false;
    if (_rememberMe) {
      _emailController.text = prefs.getString(_rememberedEmailKey) ?? '';
      _passwordController.text = prefs.getString(_rememberedPasswordKey) ?? '';
    }
    notifyListeners();
  }

  Future<void> _saveRememberedCredentials(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_rememberedEmailKey, email);
    await prefs.setString(_rememberedPasswordKey, password);
    await prefs.setBool(_rememberMeKey, true);
    _rememberMe = true;
    notifyListeners();
  }

  Future<void> _clearRememberedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_rememberedEmailKey);
    await prefs.remove(_rememberedPasswordKey);
    await prefs.setBool(_rememberMeKey, false);
    _rememberMe = false;
    _emailController.clear();
    _passwordController.clear();
    notifyListeners();
  }

  void toggleRememberMe() {
    _rememberMe = !_rememberMe;
    notifyListeners();
  }

  String _handleAuthException(firebase_auth.FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Không tìm thấy người dùng với email này.';
      case 'wrong-password':
        return 'Sai mật khẩu. Vui lòng thử lại.';
      case 'invalid-email':
        return 'Email không hợp lệ. Vui lòng kiểm tra lại.';
      case 'email-already-in-use':
        return 'Email này đã được sử dụng.';
      case 'weak-password':
        return 'Mật khẩu quá yếu. Vui lòng chọn mật khẩu mạnh hơn.';
      default:
        return 'Lỗi: ${e.message}';
    }
  }
}