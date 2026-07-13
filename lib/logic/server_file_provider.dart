import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';

class ServerFileProvider with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  List<dynamic> _fileTree = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<dynamic> get fileTree => _fileTree;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // 1. جلب شجرة الملفات من السيرفر
  Future<void> fetchServerFiles() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // سنقوم بطلب الرابط المباشر من السيرفر الحي
      final response = await _apiClient.get(
        '${ApiConstants.baseUrl}/users/server-files',
      );
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        _fileTree = data['tree'] ?? [];
      } else {
        _errorMessage = data['error'] ?? 'فشل جلب ملفات السيرفر';
      }
    } catch (e) {
      _errorMessage = 'خطأ اتصال: تعذر جلب قائمة الملفات.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 2. قراءة محتوى ملف محدد
  Future<String?> readFileContent(String relativePath) async {
    try {
      final response = await _apiClient.post(
        '${ApiConstants.baseUrl}/users/edit-file',
        body: {'filePath': relativePath, 'action': 'READ'},
      );
      final data = jsonDecode(response.body);
      return data['content'];
    } catch (e) {
      return null;
    }
  }

  // 3. حفظ وتحديث كود الملف على السيرفر الحي
  Future<bool> saveFileContent(String relativePath, String content) async {
    try {
      final response = await _apiClient.post(
        '${ApiConstants.baseUrl}/users/edit-file',
        body: {'filePath': relativePath, 'action': 'WRITE', 'content': content},
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
