import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../data/models/wallet_model.dart';

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
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final List<AiChatMessage> _messages = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<AiChatMessage> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // 📌 1️⃣ دالة حفظ تقرير/إجابة الذكاء الاصطناعي في الفايربيس
  Future<bool> saveAiReport({
    required String prompt,
    required String replyText,
  }) async {
    try {
      await _db.collection('SavedAiReports').add({
        'prompt': prompt,
        'reply': replyText,
        'savedAt': DateTime.now().toIso8601String(),
      });
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('🚨 [AiProvider Save Error]: $e');
      return false;
    }
  }

  // 🗑️ 2️⃣ دالة حذف تقرير محفوظ من الأرشيف السحابي
  Future<bool> deleteSavedReport(String docId) async {
    try {
      await _db.collection('SavedAiReports').doc(docId).delete();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('🚨 [AiProvider Delete Error]: $e');
      return false;
    }
  }

  // 🎯 3️⃣ إرسال السؤال مع دمج سياق تفصيلي دقيق للمسارات (بيتكوين vs منظمات)
  Future<void> sendPrompt(String prompt, List<WalletModel> wallets) async {
    final cleanPrompt = prompt.trim();
    if (cleanPrompt.isEmpty || _isLoading) return;

    _messages.add(
      AiChatMessage(text: cleanPrompt, isUser: true, timestamp: DateTime.now()),
    );

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    debugPrint('🤖 [AiProvider Step 1]: بدء إرسال الطلب مع السياق المالي...');

    // أ) تجميع وتحليل إحصائيات مسار البيتكوين
    final btcWallets = wallets.where((w) => w.trackType == 'BITCOIN').toList();
    final double btcPrincipal = btcWallets.fold(
      0.0,
      (s, w) => s + w.principalBalance,
    );
    final double btcProfits = btcWallets.fold(
      0.0,
      (s, w) => s + w.totalProfitsEarned,
    );

    // ب) تجميع وتحليل إحصائيات مسار المنظمات
    final orgWallets = wallets
        .where((w) => w.trackType == 'ORGANIZATIONS')
        .toList();
    final double orgPrincipal = orgWallets.fold(
      0.0,
      (s, w) => s + w.principalBalance,
    );
    final double orgProfits = orgWallets.fold(
      0.0,
      (s, w) => s + w.totalProfitsEarned,
    );

    // ج) بناء هيكل البيانات المالي الموجه للذكاء الاصطناعي
    final systemContext = {
      'totalSystem': {
        'totalWalletsCount': wallets.length,
        'totalPrincipal': wallets.fold(0.0, (s, w) => s + w.principalBalance),
        'totalProfits': wallets.fold(0.0, (s, w) => s + w.totalProfitsEarned),
      },
      'bitcoinTrack': {
        'name': 'تداول البيتكوين ₿',
        'walletsCount': btcWallets.length,
        'totalPrincipal': btcPrincipal,
        'totalProfits': btcProfits,
      },
      'organizationsTrack': {
        'name': 'استثمار المنظمات 🏢',
        'walletsCount': orgWallets.length,
        'totalPrincipal': orgPrincipal,
        'totalProfits': orgProfits,
      },
      'investorsList': wallets
          .map(
            (w) => {
              'name': w.userName,
              'track': w.trackType,
              'principal': w.principalBalance,
              'profits': w.totalProfitsEarned,
              'role': w.userRole,
              'isActive': w.isActive,
            },
          )
          .toList(),
    };

    final stopwatch = Stopwatch()..start();

    try {
      final response = await _apiClient
          .post(
            '${ApiConstants.baseUrl}/ai/query',
            body: {
              'prompt': cleanPrompt,
              'systemContext':
                  systemContext, // 👈 إرسال البيانات المفصلة للمسارات للسيرفر
            },
          )
          .timeout(
            const Duration(seconds: 20),
            onTimeout: () {
              throw Exception('تأخر رد السيرفر عن الوقت المحدد (Timeout).');
            },
          );

      debugPrint(
        '📩 [AiProvider]: استجابة السيرفر في ${stopwatch.elapsedMilliseconds}ms',
      );

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
