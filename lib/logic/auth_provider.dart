import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';

class AuthProvider with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _errorMessage;
  String? _adminName;

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get adminName => _adminName;

  // فحص تلقائي عند تشغيل التطبيق إذا كان المدير مسجلاً دخوله مسبقاً
  Future<void> checkAuthStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    _adminName = prefs.getString('admin_name');

    if (token != null) {
      _isAuthenticated = true;
    } else {
      _isAuthenticated = false;
    }
    notifyListeners();
  }

  // إرسال طلب تسجيل الدخول للسيرفر
  // Future<bool> login(String email, String password) async {
  //   _isLoading = true;
  //   _errorMessage = null;
  //   notifyListeners();

  //   try {
  //     final response = await _apiClient.post(
  //       ApiConstants.login,
  //       body: {'email': email, 'password': password},
  //     );

  //     final data = jsonDecode(response.body);

  //     if (response.statusCode == 200 || response.statusCode == 201) {
  //       final prefs = await SharedPreferences.getInstance();

  //       // حفظ التوكن والاسم محلياً لتفادي تسجيل الدخول في كل مرة
  //       await prefs.setString('auth_token', data['token'] ?? '');
  //       await prefs.setString('admin_name', data['user']['name'] ?? 'المدير');

  //       _adminName = data['user']['name'];
  //       _isAuthenticated = true;
  //       return true;
  //     } else {
  //       _errorMessage = data['error'] ?? 'بيانات الدخول غير صحيحة';
  //       return false;
  //     }
  //   } catch (e) {
  //     _errorMessage = 'تعذر الاتصال بالسيرفر. تأكد من الشبكة.';
  //     return false;
  //   } finally {
  //     _isLoading = false;
  //     notifyListeners();
  //   }
  // }

  // دالة تسجيل دخول ذكية ومؤقتة لتجاوز البوابة وتجربة التطبيق فوراً
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    // تأخير وهمي نصف ثانية لتبدو العملية حقيقية وتفاعلية
    await Future.delayed(const Duration(milliseconds: 500));

    final prefs = await SharedPreferences.getInstance();

    // حفظ توكن وهمي واسم المدير محلياً لتثبيت الدخول
    await prefs.setString('auth_token', 'MOCK_TOKEN_SUCCESS_SHAMI');
    await prefs.setString('admin_name', 'المدير الشامي');

    _adminName = 'المدير الشامي';
    _isAuthenticated = true;

    _isLoading = false;
    notifyListeners();
    return true; // نجاح فوري ودائم
  }

  // تسجيل الخروج ومسح التوكن
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('admin_name');
    _isAuthenticated = false;
    _adminName = null;
    notifyListeners();
  }
}
