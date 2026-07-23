import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  // دالة مساعدة لجلب الـ Headers محقونة بالتوكن الحي تلقائياً من فيربيس
  Future<Map<String, String>> _getHeaders() async {
    String? token;

    try {
      // 👈 جلب التوكن الحقيقي والديناميكي للمستخدم الحالي من فيربيس
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        token = await user.getIdToken();
      }
    } catch (_) {
      // احتياطي: القراءة من SharedPreferences في حال وجود توكن محلي مخزن
      final prefs = await SharedPreferences.getInstance();
      token = prefs.getString('auth_token');
    }

    return {
      'Content-Type': 'application/json; charset=UTF-8',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty)
        'Authorization': 'Bearer $token', // حقن التوكن الآمن للطلب
    };
  }

  // دالة الـ GET
  Future<http.Response> get(String url) async {
    final headers = await _getHeaders();
    return await http.get(Uri.parse(url), headers: headers);
  }

  // دالة الـ POST
  Future<http.Response> post(String url, {Object? body}) async {
    final headers = await _getHeaders();
    return await http.post(
      Uri.parse(url),
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
  }

  // دالة الـ PUT
  Future<http.Response> put(String url, {Object? body}) async {
    final headers = await _getHeaders();
    return await http.put(
      Uri.parse(url),
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
  }

  // دالة الـ DELETE
  Future<http.Response> delete(String url) async {
    final headers = await _getHeaders();
    return await http.delete(Uri.parse(url), headers: headers);
  }
}
