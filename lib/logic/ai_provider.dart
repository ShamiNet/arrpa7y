import 'dart:convert';
import 'package:flutter/material.dart';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';

class AiChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  AiChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

class AiProvider with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  final List<AiChatMessage> _messages = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<AiChatMessage> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> sendPrompt(String prompt) async {
    final cleanPrompt = prompt.trim();
    if (cleanPrompt.isEmpty || _isLoading) return;

    _messages.add(
      AiChatMessage(text: cleanPrompt, isUser: true, timestamp: DateTime.now()),
    );

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    debugPrint('🤖 [AiProvider Step 1]: بدء إرسال الطلب: "$cleanPrompt"');
    debugPrint(
      '🌐 [AiProvider Step 2]: الرابط المستهدف: ${ApiConstants.baseUrl}/ai/query',
    );

    final stopwatch = Stopwatch()..start();

    try {
      final response = await _apiClient
          .post(
            '${ApiConstants.baseUrl}/ai/query',
            body: {'prompt': cleanPrompt},
          )
          .timeout(
            const Duration(seconds: 20),
            onTimeout: () {
              debugPrint(
                '⏰ [AiProvider Error]: انقضت مهلة 20 ثانية ولم يستجب السيرفر!',
              );
              throw Exception('تأخر رد السيرفر عن الوقت المحدد (Timeout).');
            },
          );

      debugPrint(
        '📩 [AiProvider Step 3]: استجابة السيرفر وصل في ${stopwatch.elapsedMilliseconds}ms - رمز الحالة: ${response.statusCode}',
      );
      debugPrint('📄 [AiProvider Step 4]: محتوى الرد: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final String aiReply = data['reply'] ?? 'لا يوجد رد.';

        _messages.add(
          AiChatMessage(
            text: aiReply,
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
        debugPrint(
          '✅ [AiProvider Step 5]: تم إضافة رد الذكاء الاصطناعي بنجاح.',
        );
      } else {
        _errorMessage = data['error'] ?? 'تعذر الحصول على رد من السيرفر.';
        _addErrorMessage(_errorMessage!);
      }
    } catch (e) {
      debugPrint('🚨 [AiProvider Error]: فشل العملية: $e');
      _errorMessage = 'خطأ اتصال: تعذر الوصول إلى سيرفر الذكاء الاصطناعي.';
      _addErrorMessage(_errorMessage!);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _addErrorMessage(String errorText) {
    _messages.add(
      AiChatMessage(
        text: '⚠️ $errorText',
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
  }

  void clearChat() {
    _messages.clear();
    _errorMessage = null;
    notifyListeners();
  }
}
