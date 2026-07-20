import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/transaction_model.dart';

class TransactionRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // جلب كافة الحركات والسندات من Firestore بالتفصيل
  Future<List<TransactionModel>> fetchTransactions() async {
    try {
      final txsSnap = await _db
          .collection('Transactions')
          .orderBy('date', descending: true)
          .get();
      List<TransactionModel> list = [];

      for (var txDoc in txsSnap.docs) {
        final txData = txDoc.data();
        String walletId = txData['walletId'] ?? '';
        String name = 'مستثمر (قيد قديم)';
        String trackType = 'عام';

        // Populate يدوي لربط السند بصاحبه
        if (walletId.isNotEmpty) {
          final walletDoc = await _db.collection('Wallets').doc(walletId).get();
          if (walletDoc.exists) {
            final walletData = walletDoc.data() ?? {};
            final userDoc = await _db
                .collection('Users')
                .doc(walletData['userId'])
                .get();
            name = userDoc.data()?['name'] ?? name;

            final trackDoc = await _db
                .collection('InvestmentTracks')
                .doc(walletData['trackId'])
                .get();
            trackType = trackDoc.data()?['type'] ?? trackType;
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

  // قيد سند مالي جديد وتعديل رصيد المحفظة المستهدفة مباشرة في Firestore
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

      final double currentPrincipal =
          (walletDoc.data()?['principalBalance'] as num?)?.toDouble() ?? 0.0;
      double updatedPrincipal = currentPrincipal;

      if (type == 'DEPOSIT') {
        updatedPrincipal += amount;
      } else if (type == 'WITHDRAW') {
        if (currentPrincipal < amount)
          throw Exception('الرصيد المتاح غير كافٍ لإتمام عملية السحب.');
        updatedPrincipal -= amount;
      } else {
        throw Exception('نوع الحركة المالية غير صالح.');
      }

      // تحديث رصيد المحفظة
      batch.update(walletRef, {'principalBalance': updatedPrincipal});

      // كتابة مستند السند المالي
      final txRef = _db.collection('Transactions').doc();
      batch.set(txRef, {
        'walletId': walletId,
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
}
