import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

class AuthProvider with ChangeNotifier {
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  firebase_auth.User? _user;
  Map<String, dynamic>? _userData;
  bool _isDarkMode = false;
  bool _hasUnreadNotifications = false;

  firebase_auth.User? get user => _user;
  Map<String, dynamic>? get userData => _userData;
  bool get isDarkMode => _isDarkMode;
  bool get hasUnreadNotifications => _hasUnreadNotifications;

  AuthProvider() {
    _initializeAuthState();
    _checkThemePreference();
  }

  Future<void> _initializeAuthState() async {
    _auth.authStateChanges().listen((firebase_auth.User? user) {
      if (_user != user) {
        _user = user;
        _loadUserData();
        notifyListeners();
      }
    });
  }

  Future<void> _loadUserData() async {
    if (_user != null) {
      try {
        final doc = await _firestore.collection('users').doc(_user!.uid).get();
        _userData = doc.data();
        if (_userData == null) {
          await _firestore.collection('users').doc(_user!.uid).set({
            'email': _user!.email,
            'createdAt': FieldValue.serverTimestamp(),
          });
          final newDoc = await _firestore.collection('users').doc(_user!.uid).get();
          _userData = newDoc.data();
        }
      } catch (e) {
        print('Lỗi tải dữ liệu người dùng: $e');
        _userData = null;
      }
      notifyListeners();
    } else {
      _userData = null;
      notifyListeners();
    }
  }

  Future<String> signIn(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      _user = userCredential.user;
      await _loadUserData();
      notifyListeners();
      return 'success';
    } on firebase_auth.FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'wrong-password':
          return 'Mật khẩu sai. Vui lòng thử lại!';
        case 'user-not-found':
          return 'Email không tồn tại. Vui lòng kiểm tra lại hoặc đăng ký!';
        case 'invalid-email':
          return 'Email không hợp lệ. Vui lòng nhập lại!';
        case 'too-many-requests':
          return 'Quá nhiều yêu cầu. Vui lòng thử lại sau!';
        default:
          return 'Đăng nhập thất bại: ${e.message}';
      }
    } catch (e) {
      print('Lỗi đăng nhập: $e');
      return 'Đăng nhập thất bại: Đã xảy ra lỗi không xác định.';
    }
  }

  Future<void> signInWithCredential(firebase_auth.AuthCredential credential) async {
    try {
      final userCredential = await _auth.signInWithCredential(credential);
      _user = userCredential.user;
      await _loadUserData();
      notifyListeners();
    } catch (e) {
      print('Lỗi đăng nhập bằng credential: $e');
      rethrow;
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
        const String defaultAvatar = 'https://via.placeholder.com/150';
        await _firestore.collection('users').doc(_user!.uid).set({
          'name': name,
          'email': email,
          'phone': phone,
          'photoURL': defaultAvatar,
          'createdAt': FieldValue.serverTimestamp(),
        });
        await _loadUserData();
      }
      notifyListeners();
      return 'success';
    } on firebase_auth.FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
          return 'Email đã được sử dụng. Vui lòng chọn email khác!';
        case 'invalid-email':
          return 'Email không hợp lệ. Vui lòng nhập lại!';
        case 'weak-password':
          return 'Mật khẩu quá yếu. Vui lòng sử dụng mật khẩu mạnh hơn (ít nhất 6 ký tự)!';
        default:
          return 'Đăng ký thất bại: ${e.message}';
      }
    } catch (e) {
      print('Lỗi đăng ký: $e');
      return 'Đăng ký thất bại: Đã xảy ra lỗi không xác định.';
    }
  }

  Future<void> fetchUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        _userData = doc.data() as Map<String, dynamic>?;
      } else {
        _userData = {'name': _user?.email?.split('@')[0] ?? 'Unknown'};
      }
      notifyListeners();
    } catch (e) {
      print('Error fetching user data: $e');
      _userData = {'name': _user?.email?.split('@')[0] ?? 'Unknown'};
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
      print('Lỗi lưu ảnh cục bộ: $e');
      return null;
    }
  }

  Future<void> updateProfile(String uid, {
    String? name,
    String? phone,
    File? imageFile,
    String? photoUrl,
    String? bio,
    String? address,
    DateTime? birthDate,
    String? gender,
  }) async {
    final updates = <String, dynamic>{};
    final currentUserData = await _firestore.collection('users').doc(uid).get();
    final currentName = currentUserData.data()?['name'] as String?;

    if (name != null) updates['name'] = name;
    if (phone != null) updates['phone'] = phone;
    if (bio != null) updates['bio'] = bio;
    if (address != null) updates['address'] = address;
    if (birthDate != null) updates['birthDate'] = Timestamp.fromDate(birthDate);
    if (gender != null) updates['gender'] = gender;
    updates['updatedAt'] = FieldValue.serverTimestamp();

    if (imageFile != null) {
      final localPath = await saveImageLocally(imageFile);
      if (localPath != null) updates['photoURL'] = localPath;
    } else if (photoUrl != null) {
      updates['photoURL'] = photoUrl;
    }

    await _firestore.collection('users').doc(uid).update(updates);
    if (name != null && currentName != name) {
      await updateUserReviews(uid, name);
    }
    await fetchUserData(uid);
    notifyListeners();
  }

  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).delete();
      await user.delete();
      _user = null;
      _userData = null;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      _user = null;
      _userData = null;
      notifyListeners();
    } catch (e) {
      print('Lỗi đăng xuất: $e');
      rethrow;
    }
  }

  Future<void> updateUserReviews(String uid, String newName) async {
    try {
      final products = await _firestore.collection('products').get();
      for (var productDoc in products.docs) {
        final reviews = await productDoc.reference.collection('reviews')
            .where('userId', isEqualTo: uid).get();
        for (var reviewDoc in reviews.docs) {
          await reviewDoc.reference.update({'userName': newName});
        }
      }
    } catch (e) {
      print('Error updating user reviews: $e');
      throw Exception('Lỗi khi cập nhật tên trong đánh giá: $e');
    }
  }

  void toggleDarkMode() {
    _isDarkMode = !_isDarkMode;
    _saveThemePreference();
    notifyListeners();
  }

  Future<void> checkNotifications() async {
    if (user != null) {
      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: user!.uid)
          .where('isRead', isEqualTo: false)
          .get();
      _hasUnreadNotifications = snapshot.docs.isNotEmpty;
      notifyListeners();
    }
  }

  void setHasUnreadNotifications(bool value) {
    _hasUnreadNotifications = value;
    notifyListeners();
  }

  Future<void> _checkThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
  }

  Future<void> _saveThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);
  }

  Future<void> initialize() async {
    await _initializeAuthState();
    await _checkThemePreference();
  }
}