import 'package:cloud_firestore/cloud_firestore.dart';

class ProfitRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// 🎯 توزيع وضخ الأرباح والبونصات سحابياً للفايربيس
  Future<void> executeProfitDistribution({
    required String trackDocId,
    required String trackType,
    required double baseProfitRate,
    required double managerExtraRate,
    required double managerDeductionRate,
    required String targetUserId,
    required Map<String, double> walletProfitsToAdd,
    required Map<String, double> walletBaseNetProfits,
    required Map<String, double> walletBonusProfits,
    required Map<String, double> walletBonusRates,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> walletDocs,
  }) async {
    WriteBatch batch = _db.batch();
    final String executedAtStr = DateTime.now().toIso8601String();

    // جلب خريطة الأسماء لتضمينها مباشرة في السندات Denormalization
    final usersSnap = await _db.collection('Users').get();
    final Map<String, String> userNamesMap = {
      for (var doc in usersSnap.docs) doc.id: doc.data()['name'] ?? 'مستثمر',
    };

    for (var walletDoc in walletDocs) {
      final walletId = walletDoc.id;
      final walletData = walletDoc.data();
      final String userId = walletData['userId'] ?? '';
      final String userName = userNamesMap[userId] ?? 'مستثمر';

      final double currentEarned =
          (walletData['totalProfitsEarned'] as num?)?.toDouble() ?? 0.0;
      final double addedProfit = walletProfitsToAdd[walletId] ?? 0.0;

      // 1. تحديث رصيد الأرباح الكلي للمحفظة
      batch.update(walletDoc.reference, {
        'totalProfitsEarned': currentEarned + addedProfit,
      });

      // 2. قيد سند أرباح أساسي محقون باسم المستثمر والمسار مباشرة
      final double netBaseProfit = walletBaseNetProfits[walletId] ?? 0.0;
      if (netBaseProfit > 0) {
        final baseTxRef = _db.collection('Transactions').doc();
        batch.set(baseTxRef, {
          'walletId': walletId,
          'userName': userName,
          'trackType': trackType,
          'type': 'PROFIT',
          'amount': netBaseProfit,
          'description':
              'أرباح استثمار صافية بنسبة ${((baseProfitRate - managerDeductionRate) * 100).toStringAsFixed(2)}%',
          'date': executedAtStr,
        });
      }

      // 3. قيد سند بونص إحالة إن وجد
      final double bonusProfit = walletBonusProfits[walletId] ?? 0.0;
      final double bonusRate = walletBonusRates[walletId] ?? 0.0;
      if (bonusProfit > 0) {
        final bonusTxRef = _db.collection('Transactions').doc();
        batch.set(bonusTxRef, {
          'walletId': walletId,
          'userName': userName,
          'trackType': trackType,
          'type': 'BONUS',
          'amount': bonusProfit,
          'description':
              'بونص إحالة إضافي بنسبة ${(bonusRate * 100).toStringAsFixed(2)}%',
          'date': executedAtStr,
        });
      }
    }

    // 4. حفظ سجل التوزيع الإجمالي Log
    final logRef = _db.collection('ProfitDistributionLogs').doc();
    batch.set(logRef, {
      'trackId': trackDocId,
      'trackType': trackType,
      'baseProfitRate': baseProfitRate,
      'managerExtraRate': managerExtraRate,
      'managerDeductionRate': managerDeductionRate,
      'targetUserId': targetUserId,
      'executedAt': executedAtStr,
    });

    await batch.commit();
  }

  /// 🔄 تصفير ومسح كافة الأرباح والبونصات وسجلاتها نهائياً
  Future<void> resetAllProfitsData() async {
    // أ) إعادة تصفير رصيد الأرباح في المحافظ
    final walletsSnap = await _db.collection('Wallets').get();
    WriteBatch walletBatch = _db.batch();
    for (var doc in walletsSnap.docs) {
      walletBatch.update(doc.reference, {'totalProfitsEarned': 0.0});
    }
    await walletBatch.commit();

    // ب) حذف سندات الأرباح والبونصات
    final txsSnap = await _db
        .collection('Transactions')
        .where('type', whereIn: ['PROFIT', 'BONUS'])
        .get();

    WriteBatch txBatch = _db.batch();
    int count = 0;
    for (var doc in txsSnap.docs) {
      txBatch.delete(doc.reference);
      count++;
      if (count % 400 == 0) {
        await txBatch.commit();
        txBatch = _db.batch();
      }
    }
    if (count % 400 != 0) {
      await txBatch.commit();
    }

    // ج) حذف سجلات التوزيع
    final logsSnap = await _db.collection('ProfitDistributionLogs').get();
    WriteBatch logBatch = _db.batch();
    for (var doc in logsSnap.docs) {
      logBatch.delete(doc.reference);
    }
    await logBatch.commit();
  }
}
