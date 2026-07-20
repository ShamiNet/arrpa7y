import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/profit_simulation_model.dart';

class ProfitRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // إجراء حسابات المحاكاة برمجياً عبر سحب المستندات وحسابها في التطبيق
  Future<ProfitSimulationModel> fetchSimulation({
    required String trackType,
    required double grossProfitRate,
  }) async {
    try {
      // 1. جلب بيانات المسار
      final trackQuery = await _db
          .collection('InvestmentTracks')
          .where('type', isEqualTo: trackType)
          .limit(1)
          .get();

      if (trackQuery.docs.isEmpty)
        throw Exception('المسار الاستثماري المحدد غير موجود.');
      final trackDoc = trackQuery.docs.first;
      final double trackCommission =
          (trackDoc.data()['myCommissionRate'] as num).toDouble();

      // 2. جلب المحافظ والعملاء المربوطين بها
      final walletsQuery = await _db
          .collection('Wallets')
          .where('trackId', isEqualTo: trackDoc.id)
          .get();

      double totalTrackPrincipal = 0.0;
      double totalDistributedToClients = 0.0;
      double myTotalCommissionEarned = 0.0;
      double myPersonalWalletProfit = 0.0;
      double clientPrincipalTotal = 0.0;

      List<UserProfitBreakdown> breakdown = [];

      for (var walletDoc in walletsQuery.docs) {
        final walletData = walletDoc.data();
        final double principal = (walletData['principalBalance'] as num)
            .toDouble();
        totalTrackPrincipal += principal;

        final userDoc = await _db
            .collection('Users')
            .doc(walletData['userId'])
            .get();
        final userData = userDoc.data() ?? {};
        final String role = userData['role'] ?? 'CLIENT';
        final String name = userData['name'] ?? 'مستثمر';

        double grossProfit = principal * grossProfitRate;
        double commissionDeducted = 0.0;
        double netProfitAdded = grossProfit;

        if (role == 'ADMIN') {
          myPersonalWalletProfit += grossProfit;
        } else {
          clientPrincipalTotal += principal;
          double appliedCommission = trackCommission;
          if (userData['customCommissionRate'] != null) {
            appliedCommission =
                (userData['customCommissionRate'] as num).toDouble() / 100;
          }
          commissionDeducted = grossProfit * appliedCommission;
          netProfitAdded = grossProfit - commissionDeducted;

          myTotalCommissionEarned += commissionDeducted;
          totalDistributedToClients += netProfitAdded;
        }

        breakdown.add(
          UserProfitBreakdown(
            userId: userDoc.id,
            userName: name,
            role: role,
            principalBalance: principal,
            grossProfit: grossProfit,
            commissionDeducted: commissionDeducted,
            netProfitAdded: netProfitAdded,
          ),
        );
      }

      double netProfitRateDistributed = clientPrincipalTotal > 0
          ? (totalDistributedToClients / clientPrincipalTotal)
          : (grossProfitRate * (1 - trackCommission));

      return ProfitSimulationModel(
        trackName: trackDoc.data()['name'] ?? '',
        totalTrackPrincipal: totalTrackPrincipal,
        grossProfitRate: grossProfitRate,
        netProfitRateDistributed: netProfitRateDistributed,
        totalDistributedToClients: totalDistributedToClients,
        myTotalCommissionEarned: myTotalCommissionEarned,
        myPersonalWalletProfit: myPersonalWalletProfit,
        breakdown: breakdown,
      );
    } catch (e) {
      throw Exception('فشل حساب المحاكاة: $e');
    }
  }

  // تنفيذ التوزيع الحقيقي وضخ الأرباح لـ Firestore
  Future<void> executeActualDistribution({
    required String trackType,
    required double grossProfitRate,
    required ProfitSimulationModel results,
  }) async {
    final batch = _db.batch();
    final executedAtStr = DateTime.now().toIso8601String();

    try {
      final trackQuery = await _db
          .collection('InvestmentTracks')
          .where('type', isEqualTo: trackType)
          .limit(1)
          .get();
      final trackId = trackQuery.docs.first.id;

      // 1. إنشاء مستند سجل التوزيع الإجمالي
      final logRef = _db.collection('ProfitDistributionLogs').doc();
      batch.set(logRef, {
        'trackId': trackId,
        'grossProfitRate': results.grossProfitRate,
        'netProfitRateDistributed': results.netProfitRateDistributed,
        'totalTrackPrincipal': results.totalTrackPrincipal,
        'totalDistributedAmount': results.totalDistributedToClients,
        'myTotalCommissionEarned': results.myTotalCommissionEarned,
        'status': 'APPROVED',
        'executedAt': executedAtStr,
      });

      // 2. تحديث المحافظ وحقن السندات لكل مستثمر
      final walletsQuery = await _db
          .collection('Wallets')
          .where('trackId', isEqualTo: trackId)
          .get();

      for (var walletDoc in walletsQuery.docs) {
        final walletData = walletDoc.data();
        final userId = walletData['userId'];

        final clientRes = results.breakdown.firstWhere(
          (b) => b.userId == userId,
        );
        final currentEarned =
            (walletData['totalProfitsEarned'] as num?)?.toDouble() ?? 0.0;

        batch.update(walletDoc.reference, {
          'totalProfitsEarned': currentEarned + clientRes.netProfitAdded,
        });

        final txRef = _db.collection('Transactions').doc();
        batch.set(txRef, {
          'walletId': walletDoc.id,
          'type': 'PROFIT',
          'amount': clientRes.netProfitAdded,
          'description':
              'توزيع أرباح دورية - نسبة المسار الإجمالية ${(grossProfitRate * 100).toStringAsFixed(1)}%',
          'referenceDistributionId': logRef.id,
          'date': executedAtStr,
        });
      }

      await batch.commit();
    } catch (e) {
      throw Exception('فشل ضخ الأرباح سحابياً: $e');
    }
  }
}
