import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final ApiClient _apiClient = ApiClient();

  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _errorMessage;
  String? _adminName;

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get adminName => _adminName;

  // فحص حالة الدخول تلقائياً عند فتح التطبيق
  Future<void> checkAuthStatus() async {
    final user = _auth.currentUser;
    if (user != null) {
      _isAuthenticated = true;
      final doc = await _db.collection('Users').doc(user.uid).get();
      _adminName = doc.data()?['name'] ?? 'المدير الشامي';
    } else {
      _isAuthenticated = false;
    }
    notifyListeners();
  }

  // تسجيل الدخول المباشر للمدير
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final userDoc = await _db
          .collection('Users')
          .doc(credential.user!.uid)
          .get();
      final userData = userDoc.data();

      if (userData != null &&
          (userData['role'] == 'admin' ||
              userData['role'] == 'ADMIN' ||
              userData['role'] == 'owner')) {
        _adminName = userData['name'] ?? 'المدير الشامي';
        _isAuthenticated = true;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        await _auth.signOut();
        _errorMessage = 'عذراً، هذا الحساب لا يملك صلاحيات إدارية.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        _errorMessage = 'البريد الإلكتروني غير مسجل.';
      } else if (e.code == 'wrong-password') {
        _errorMessage = 'كلمة المرور غير صحيحة.';
      } else {
        _errorMessage = e.message ?? 'حدث خطأ أثناء تسجيل الدخول.';
      }
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'حدث خطأ غير متوقع.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// 🎯 إنشاء حساب مستثمر جديد آمن تماماً (دون تسجيل خروج المدير)
  Future<bool> signUp({
    required String name,
    required String phone,
    required String trackType,
    required double initialPrincipal,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1️⃣ المحاولة الأولى: الإنشاء عبر السيرفر الخلفي إذا كان متاحاً
      final response = await _apiClient.post(
        ApiConstants.createClient,
        body: {
          'name': name,
          'phone': phone,
          'trackType': trackType,
          'initialPrincipal': initialPrincipal,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _isLoading = false;
        notifyListeners();
        return true;
      }

      // 2️⃣ الحل المباشر في الفلاتر (FirebaseApp معزول ثانوي)
      // يمنع تعديل جلسة المدير الحالية في FirebaseAuth.instance الرئيسي
      FirebaseApp secondaryApp;
      try {
        secondaryApp = Firebase.app('SecondaryAuthApp');
      } catch (_) {
        secondaryApp = await Firebase.initializeApp(
          name: 'SecondaryAuthApp',
          options: Firebase.app().options,
        );
      }

      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String generatedUsername =
          'user_${timestamp.substring(timestamp.length - 6)}';
      final String generatedEmail = '$generatedUsername@shami-app.com';
      final String generatedPassword =
          'ShamiPass_${timestamp.substring(timestamp.length - 6)}!';

      // إنشاء المستخدم داخل التطبيق الثانوي دون المساس بـ _auth الخاص بالمدير
      final credential = await secondaryAuth.createUserWithEmailAndPassword(
        email: generatedEmail,
        password: generatedPassword,
      );

      final String uid = credential.user!.uid;
      final String createdAtStr = DateTime.now().toIso8601String();

      // تدوين البيانات في Firestore
      await _db.collection('Users').doc(uid).set({
        'name': name,
        'username': generatedUsername,
        'email': generatedEmail,
        'phone': phone,
        'role': 'CLIENT',
        'isActive': true,
        'createdAt': createdAtStr,
      });

      // جلب المسار وتأسيس المحفظة
      final trackQuery = await _db
          .collection('InvestmentTracks')
          .where('type', isEqualTo: trackType)
          .limit(1)
          .get();

      if (trackQuery.docs.isEmpty) {
        throw Exception('مسار الاستثمار المحدد غير موجود في النظام.');
      }
      final String trackId = trackQuery.docs.first.id;

      final walletRef = _db.collection('Wallets').doc();
      await walletRef.set({
        'userId': uid,
        'trackId': trackId,
        'principalBalance': initialPrincipal,
        'totalProfitsEarned': 0.0,
        'createdAt': createdAtStr,
      });

      if (initialPrincipal > 0) {
        await _db.collection('Transactions').add({
          'walletId': walletRef.id,
          'type': 'DEPOSIT',
          'amount': initialPrincipal,
          'description': 'رأس المال التأسيسي الأول للمحفظة',
          'date': createdAtStr,
        });
      }

      // تسجيل الخروج المباشر من التطبيق الثانوي وتنظيف الجلسة الفرعية
      await secondaryAuth.signOut();

      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = e.message ?? 'حدث خطأ أثناء إنشاء الحساب.';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // تسجيل خروج المدير
  Future<void> logout() async {
    await _auth.signOut();
    _isAuthenticated = false;
    _adminName = null;
    notifyListeners();
  }
}
