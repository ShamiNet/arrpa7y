import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

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
      // جلب اسم المدير من Firestore
      final doc = await _db.collection('users').doc(user.uid).get();
      _adminName = doc.data()?['name'] ?? 'المدير الشامي';
    } else {
      _isAuthenticated = false;
    }
    notifyListeners();
  }

  // تسجيل الدخول المباشر عبر Firebase Authentication
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
          .collection('users')
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
        // إذا كان الحساب مسجل لكنه ليس مديراً
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
  // أضف هذه الدالة داخل كلاس AuthProvider في ملف logic/auth_provider.dart

  Future<bool> signUp({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String trackType, // 'BITCOIN' أو 'ORGANIZATIONS'
    required double initialPrincipal,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. إنشاء الحساب في Firebase Authentication
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final String uid = credential.user!.uid;
      final String createdAtStr = DateTime.now().toIso8601String();

      // 2. تدوين بيانات المستخدم في Firestore
      await _db.collection('users').doc(uid).set({
        'name': name,
        'email': email,
        'phone': phone,
        'role': 'CLIENT', // افتراضي للمستثمرين الجدد
        'createdAt': createdAtStr,
      });

      // 3. جلب ID المسار المختار من الـ Firestore
      final trackQuery = await _db
          .collection('InvestmentTracks')
          .where('type', isEqualTo: trackType)
          .limit(1)
          .get();

      if (trackQuery.docs.isEmpty) {
        throw Exception('مسار الاستثمار المحدد غير موجود في النظام.');
      }
      final String trackId = trackQuery.docs.first.id;

      // 4. إنشاء المحفظة الاستثمارية المرتبطة به
      final walletRef = _db.collection('Wallets').doc();
      await walletRef.set({
        'userId': uid,
        'trackId': trackId,
        'principalBalance': initialPrincipal,
        'totalProfitsEarned': 0.0,
        'createdAt': createdAtStr,
      });

      // 5. قيد حركة ماليّة أولية (إيداع تأسيسي) لتوثيق رأس المال
      await _db.collection('Transactions').add({
        'walletId': walletRef.id,
        'type': 'DEPOSIT',
        'amount': initialPrincipal,
        'description': 'رأس المال التأسيسي الأول للمحفظة',
        'date': createdAtStr,
      });

      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        _errorMessage = 'البريد الإلكتروني مستخدم بالفعل.';
      } else if (e.code == 'weak-password') {
        _errorMessage = 'كلمة المرور ضعيفة جداً.';
      } else {
        _errorMessage = e.message ?? 'حدث خطأ أثناء إنشاء الحساب.';
      }
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

  // تسجيل الخروج المباشر
  Future<void> logout() async {
    await _auth.signOut();
    _isAuthenticated = false;
    _adminName = null;
    notifyListeners();
  }
}
