import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/user_model.dart';
import '../views/screens/admin/admin_main_screen.dart';
import '../views/screens/user/landlord/landlord_main_screen.dart';
import '../views/screens/main_screen.dart';

class AuthController extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  UserModel? _currentUser;
  bool _isLoading = false;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;
  bool get isAdmin => _currentUser?.isAdmin ?? false;
  bool get isLandlord => _currentUser?.isLandlord ?? false;

  AuthController() {
    _initializeAuth();
  }

  void _initializeAuth() {
    _auth.authStateChanges().listen((User? user) async {
      if (user == null) {
        _currentUser = null;
        notifyListeners();
      } else {
        await _loadUserData(user.uid);
      }
    });
  }

  Future<void> _loadUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        _currentUser = UserModel.fromJson({
          'id': uid,
          ...doc.data()!,
        });
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Lỗi khi tải thông tin người dùng: $e');
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String name,
    required BuildContext context,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Kiểm tra email đã tồn tại
      final methods = await _auth.fetchSignInMethodsForEmail(email);
      if (methods.isNotEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Email đã được sử dụng')),
          );
        }
        return;
      }

      // Tạo tài khoản Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Tạo user model
      final newUser = UserModel(
        id: userCredential.user!.uid,
        email: email.trim(),
        fullName: name.trim(),
        isAdmin: false,
        createdAt: DateTime.now(),
      );

      // Lưu vào Firestore
      await _firestore
          .collection('users')
          .doc(newUser.id)
          .set(newUser.toJson());

      // Cập nhật current user
      _currentUser = newUser;
      notifyListeners();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đăng ký thành công')),
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> login({
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      await _loadUserData(userCredential.user!.uid);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đăng nhập thành công')),
        );

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
              builder: (context) => _currentUser!.isAdmin
                  ? const AdminMainScreen()
                  : const MainScreen()),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = _getAuthErrorMessage(e.code);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Không tìm thấy tài khoản';
      case 'wrong-password':
        return 'Sai mật khẩu';
      case 'invalid-email':
        return 'Email không hợp lệ';
      case 'user-disabled':
        return 'Tài khoản bị vô hiệu hóa';
      default:
        return 'Đăng nhập thất bại: $code';
    }
  }

  Future<void> logout({BuildContext? context}) async {
    try {
      await _auth.signOut();
      _currentUser = null;
      notifyListeners();

      // Nếu có context thì điều hướng về MainScreen
      if (context != null && context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint('Lỗi đăng xuất: $e');
    }
  }

  Future<void> setLandlordRole({
    required String userId,
    required bool isLandlord,
    required BuildContext context,
  }) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isLandlord': isLandlord,
      });

      if (_currentUser != null) {
        _currentUser = UserModel(
          id: _currentUser!.id,
          email: _currentUser!.email,
          fullName: _currentUser!.fullName,
          isAdmin: _currentUser!.isAdmin,
          isLandlord: isLandlord,
          createdAt: _currentUser!.createdAt,
        );
        notifyListeners();
      }

      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) =>
                isLandlord ? const LandlordMainScreen() : const MainScreen(),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint('Lỗi khi cập nhật vai trò: $e');
    }
  }

  Future<UserModel?> getUserById(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return UserModel.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error getting user: $e');
      return null;
    }
  }

  Future<void> updateUserProfile({
    required String userId,
    required String fullName,
    required String phone,
    File? avatarFile,
  }) async {
    try {
      String? avatarUrl;
      if (avatarFile != null) {
        // Upload ảnh mới
        final ref = _storage.ref().child('avatars/$userId');
        await ref.putFile(avatarFile);
        avatarUrl = await ref.getDownloadURL();
      }

      // Cập nhật thông tin user
      await _firestore.collection('users').doc(userId).update({
        'fullName': fullName,
        'phone': phone,
        if (avatarUrl != null) 'avatar': avatarUrl,
      });

      // Cập nhật state local
      _currentUser = _currentUser?.copyWith(
        fullName: fullName,
        phone: phone,
        avatar: avatarUrl ?? _currentUser?.avatar,
      );
      notifyListeners();
    } catch (e) {
      print('Error updating profile: $e');
      rethrow;
    }
  }
}
