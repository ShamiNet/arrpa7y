import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/wallet_model.dart';

class UserRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // جلب كافة المحافظ والبيانات المشتركة يدوياً من Firestore
  Future<List<WalletModel>> fetchAllWallets() async {
    try {
      debugPrint(
        '📥 [UserRepository]: جاري جلب جميع المحافظ والمستخدمين من Firestore...',
      );
      final walletsSnap = await _db.collection('Wallets').get();
      List<WalletModel> list = [];

      for (var walletDoc in walletsSnap.docs) {
        final walletData = walletDoc.data();

        final userDoc = await _db
            .collection('Users')
            .doc(walletData['userId'])
            .get();
        final userData = userDoc.data() ?? {};

        final trackDoc = await _db
            .collection('InvestmentTracks')
            .doc(walletData['trackId'])
            .get();
        final trackData = trackDoc.data() ?? {};

        list.add(
          WalletModel(
            id: walletDoc.id,
            userId: walletData['userId'] ?? '',
            userName: userData['name'] ?? 'مستثمر غير معروف',
            userRole: userData['role'] ?? 'CLIENT',
            trackId: walletData['trackId'] ?? '',
            trackName: trackData['name'] ?? '',
            trackType: trackData['type'] ?? '',
            principalBalance:
                (walletData['principalBalance'] as num?)?.toDouble() ?? 0.0,
            totalProfitsEarned:
                (walletData['totalProfitsEarned'] as num?)?.toDouble() ?? 0.0,
            phone: userData['phone'] ?? '',
            isActive: userData['isActive'] ?? true, // 👈 تمرير حالة النشاط هنا
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
      // 1. إنشاء حساب المستخدم أولاً
      final userRef = _db.collection('Users').doc();
      await userRef.set({
        'name': name,
        'role': 'CLIENT',
        'email': 'client_${DateTime.now().millisecondsSinceEpoch}@al-itqan.com',
        'phone': '',
        'isActive': true, // 👈 تحديد أن الحساب الجديد نشط افتراضياً
        'createdAt': DateTime.now().toIso8601String(),
      });

      // 2. جلب ID المسار المختار
      final trackQuery = await _db
          .collection('InvestmentTracks')
          .where('type', isEqualTo: trackType)
          .limit(1)
          .get();
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
