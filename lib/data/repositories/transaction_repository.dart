import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/transaction_model.dart';

class TransactionRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // جلب كافة الحركات والسندات من Firestore بسرعة فائقة (بدون N+1 Query)
  Future<List<TransactionModel>> fetchTransactions() async {
    try {
      final txsSnap = await _db
          .collection('Transactions')
          .orderBy('date', descending: true)
          .get();

      // 👈 جلب كلي دفعة واحدة للحد من قراءات الفايربيس وتحسين السرعة
      final walletsSnap = await _db.collection('Wallets').get();
      final Map<String, Map<String, dynamic>> walletsMap = {
        for (var doc in walletsSnap.docs) doc.id: doc.data(),
      };

      final usersSnap = await _db.collection('Users').get();
      final Map<String, Map<String, dynamic>> usersMap = {
        for (var doc in usersSnap.docs) doc.id: doc.data(),
      };

      final tracksSnap = await _db.collection('InvestmentTracks').get();
      final Map<String, Map<String, dynamic>> tracksMap = {
        for (var doc in tracksSnap.docs) doc.id: doc.data(),
      };

      List<TransactionModel> list = [];

      for (var txDoc in txsSnap.docs) {
        final txData = txDoc.data();
        String walletId = txData['walletId'] ?? '';
        String name = txData['userName'] ?? 'مستثمر (قيد قديم)';
        String trackType = txData['trackType'] ?? 'عام';

        // مطابقة البيانات في الذاكرة بدون استعلامات إضافية إذا لم تكن مخزنة سابقاً
        if ((txData['userName'] == null || txData['trackType'] == null) &&
            walletId.isNotEmpty) {
          final walletData = walletsMap[walletId];
          if (walletData != null) {
            final userId = walletData['userId'];
            final trackId = walletData['trackId'];

            if (userId != null && usersMap.containsKey(userId)) {
              name = usersMap[userId]?['name'] ?? name;
            }

            if (trackId != null && tracksMap.containsKey(trackId)) {
              trackType = tracksMap[trackId]?['type'] ?? trackType;
            }
          }
        }

        list.add(
          TransactionModel(
            id: txDoc.id,
            walletId: walletId,
            userName: name,
            trackType: trackType,
            type: txData['type'] ?? 'DEPOSIT',
            amount: (txData['amount'] as num?)?.toDouble() ?? 0.0,
            description: txData['description'] ?? '',
            date: txData['date'] != null
                ? DateTime.parse(txData['date'])
                : DateTime.now(),
          ),
        );
      }
      return list;
    } catch (e) {
      throw Exception('فشل جلب السندات المالية: $e');
    }
  }

  // قيد سند مالي جديد وتعديل رصيد المحفظة مع تخزين الاسم والمسار مباشرة
  Future<void> createTransaction({
    required String walletId,
    required String type,
    required double amount,
    required String description,
  }) async {
    final batch = _db.batch();
    try {
      final walletRef = _db.collection('Wallets').doc(walletId);
      final walletDoc = await walletRef.get();
      if (!walletDoc.exists) throw Exception('المحفظة المستهدفة غير موجودة.');

      final walletData = walletDoc.data() ?? {};
      final double currentPrincipal =
          (walletData['principalBalance'] as num?)?.toDouble() ?? 0.0;
      double updatedPrincipal = currentPrincipal;

      if (type == 'DEPOSIT') {
        updatedPrincipal += amount;
      } else if (type == 'WITHDRAW' || type == 'WITHDRAWAL') {
        if (currentPrincipal < amount) {
          throw Exception('الرصيد المتاح غير كافٍ لإتمام عملية السحب.');
        }
        updatedPrincipal -= amount;
      } else {
        throw Exception('نوع الحركة المالية غير صالح.');
      }

      // جلب اسم المستثمر والمسار لتدوينهما مباشرة في مستند السند
      String userName = 'مستثمر';
      String trackType = 'عام';

      final userId = walletData['userId'];
      final trackId = walletData['trackId'];

      if (userId != null) {
        final userDoc = await _db.collection('Users').doc(userId).get();
        userName = userDoc.data()?['name'] ?? userName;
      }

      if (trackId != null) {
        final trackDoc = await _db
            .collection('InvestmentTracks')
            .doc(trackId)
            .get();
        trackType = trackDoc.data()?['type'] ?? trackType;
      }

      // تحديث رصيد المحفظة
      batch.update(walletRef, {'principalBalance': updatedPrincipal});

      // كتابة مستند السند المالي مفصلاً
      final txRef = _db.collection('Transactions').doc();
      batch.set(txRef, {
        'walletId': walletId,
        'userName': userName,
        'trackType': trackType,
        'type': type,
        'amount': amount,
        'description': description.isEmpty
            ? (type == 'DEPOSIT' ? 'إيداع إضافي' : 'سحب مالي')
            : description,
        'date': DateTime.now().toIso8601String(),
      });

      await batch.commit();
    } catch (e) {
      throw Exception('فشل إتمام السند المالي: $e');
    }
  }

  // حذف حركة مالية فردية
  Future<void> deleteTransaction(String transactionId) async {
    try {
      await _db.collection('Transactions').doc(transactionId).delete();
    } catch (e) {
      throw Exception('فشل حذف الحركة المالية: $e');
    }
  }

  // مسح كافة السندات من السيرفر
  Future<void> clearAllTransactions() async {
    try {
      final snap = await _db.collection('Transactions').get();
      final batch = _db.batch();
      for (var doc in snap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      throw Exception('فشل تصفية سجل السندات: $e');
    }
  }
}
