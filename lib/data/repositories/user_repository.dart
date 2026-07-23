import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/wallet_model.dart';

class UserRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // جلب كافة المحافظ والبيانات المشتركة دفعة واحدة وبسرعة عالية (Bulk Fetching)
  Future<List<WalletModel>> fetchAllWallets() async {
    try {
      debugPrint(
        '📥 [UserRepository]: جاري جلب جميع المحافظ والمستخدمين دفعة واحدة...',
      );

      // 👈 جلب البيانات دفعة واحدة بدلاً من الاستعلام المكرر داخل الحلقة
      final walletsSnap = await _db.collection('Wallets').get();
      final usersSnap = await _db.collection('Users').get();
      final tracksSnap = await _db.collection('InvestmentTracks').get();

      // خريطة سريعة للوصول للبيانات بالذاكرة In-Memory Lookup
      final Map<String, Map<String, dynamic>> usersMap = {
        for (var doc in usersSnap.docs) doc.id: doc.data(),
      };

      final Map<String, Map<String, dynamic>> tracksMap = {
        for (var doc in tracksSnap.docs) doc.id: doc.data(),
      };

      List<WalletModel> list = [];

      for (var walletDoc in walletsSnap.docs) {
        final walletData = walletDoc.data();
        final String userId = walletData['userId'] ?? '';
        final String trackId = walletData['trackId'] ?? '';

        final userData = usersMap[userId] ?? {};
        final trackData = tracksMap[trackId] ?? {};

        list.add(
          WalletModel(
            id: walletDoc.id,
            userId: userId,
            userName: userData['name'] ?? 'مستثمر غير معروف',
            userRole: userData['role'] ?? 'CLIENT',
            trackId: trackId,
            trackName: trackData['name'] ?? '',
            trackType: trackData['type'] ?? '',
            principalBalance:
                (walletData['principalBalance'] as num?)?.toDouble() ?? 0.0,
            totalProfitsEarned:
                (walletData['totalProfitsEarned'] as num?)?.toDouble() ?? 0.0,
            phone: userData['phone'] ?? '',
            isActive: userData['isActive'] ?? true,
          ),
        );
      }

      debugPrint('✅ [UserRepository]: تم جلب ${list.length} محفظة بنجاح.');
      return list;
    } catch (e) {
      debugPrint('🚨 [UserRepository Error]: فشل جلب المحافظ: $e');
      throw Exception('فشل جلب المحافظ: $e');
    }
  }

  // إضافة مستثمر جديد وتأسيس محفظته
  Future<void> createNewClient({
    required String name,
    required String trackType,
    required double initialPrincipal,
  }) async {
    try {
      // 1. إنشاء حساب المستخدم
      final userRef = _db.collection('Users').doc();
      await userRef.set({
        'name': name,
        'role': 'CLIENT',
        'email':
            'client_${DateTime.now().millisecondsSinceEpoch}@shami-app.com',
        'phone': '',
        'isActive': true,
        'createdAt': DateTime.now().toIso8601String(),
      });

      // 2. جلب ID المسار المختار
      final trackQuery = await _db
          .collection('InvestmentTracks')
          .where('type', isEqualTo: trackType)
          .limit(1)
          .get();

      if (trackQuery.docs.isEmpty) {
        throw Exception('مسار الاستثمار المحدد غير موجود.');
      }
      final trackId = trackQuery.docs.first.id;

      // 3. إنشاء المحفظة المقرنة به
      final walletRef = _db.collection('Wallets').doc();
      await walletRef.set({
        'userId': userRef.id,
        'trackId': trackId,
        'principalBalance': initialPrincipal,
        'totalProfitsEarned': 0.0,
        'createdAt': DateTime.now().toIso8601String(),
      });

      // 4. تدوين الإيداع الأولي كحركة مالية تأسيسية
      await _db.collection('Transactions').add({
        'walletId': walletRef.id,
        'userName': name,
        'trackType': trackType,
        'type': 'DEPOSIT',
        'amount': initialPrincipal,
        'description': 'رأس المال التأسيسي الأول للمحفظة',
        'date': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('فشل تأسيس الحساب والمحفظة: $e');
    }
  }
}
