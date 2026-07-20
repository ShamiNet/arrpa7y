import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/models/profit_simulation_model.dart'; // ستحتاج لتحديث الـ Model لاحقاً لعرض البنود المنفصلة

class ProfitProvider with ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // هيكل مرن لحفظ تفاصيل أرباح المدير لعرضها في الشاشة
  Map<String, double> _managerProfitStats = {
    'trackBaseProfit': 0.0,
    'managerExtraEarned': 0.0,
    'totalDistributedBonus': 0.0,
    'managerNetProfit': 0.0,
  };
  Map<String, double> get managerProfitStats => _managerProfitStats;

  Future<void> distributeProfitsWithBonus({
    required String trackType,
    required double
    baseProfitRate, // نسبة الربح الأساسية للجميع (مثال: 0.05 لـ 5%)
    required double
    managerExtraRate, // النسبة الإضافية المتغيرة للمدير (مثال: 0.005 لـ 0.5%)
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. جلب المسار وتحديث نسبته الإضافية المتغيرة لهذا الشهر
      final trackQuery = await _db
          .collection('InvestmentTracks')
          .where('type', isEqualTo: trackType)
          .limit(1)
          .get();

      if (trackQuery.docs.isEmpty)
        throw Exception('المسار الاستثماري غير موجود.');
      final trackDoc = trackQuery.docs.first;

      // حفظ النسبة المتغيرة في قاعدة البيانات لتوثيقها
      await trackDoc.reference.update({'additionalRate': managerExtraRate});

      // 2. جلب جميع محافظ هذا المسار
      final walletsQuery = await _db
          .collection('Wallets')
          .where('trackId', isEqualTo: trackDoc.id)
          .get();

      double totalTrackPrincipal = 0.0;
      double totalBaseDistributed = 0.0;
      double totalBonusDistributed = 0.0;
      double totalManagerExtraEarned = 0.0;

      WriteBatch batch = _db.batch();
      final String executedAtStr = DateTime.now().toIso8601String();

      // 3. معالجة كل محفظة ومستثمر
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

        // أ) حساب الربح الأساسي للمستثمر (5%)
        double baseProfit = principal * baseProfitRate;

        // ب) حساب البونص الإضافي المخصص لهذا العميل من نسبة المدير (مثلاً 0.25%)
        double bonusRate = 0.0;
        if (userData['referralBonusRate'] != null) {
          bonusRate =
              (userData['referralBonusRate'] as num).toDouble() /
              100; // تحويل 0.25 إلى 0.0025
        }
        double bonusProfit = principal * bonusRate;

        // ج) حساب النسبة الإضافية الإجمالية التي تدرها هذه المحفظة للمدير (0.5%)
        double managerExtraFromThisWallet = principal * managerExtraRate;
        totalManagerExtraEarned += managerExtraFromThisWallet;

        // د) القيد السحابي وتحديث الأرصدة في المحفظة
        double totalNewProfits = baseProfit + bonusProfit;
        double currentEarned =
            (walletData['totalProfitsEarned'] as num?)?.toDouble() ?? 0.0;

        batch.update(walletDoc.reference, {
          'totalProfitsEarned': currentEarned + totalNewProfits,
        });

        // هـ) قيد المستند المالي كبندين منفصلين تماماً في السندات السحابية

        // 1. سند الربح الأساسي
        final baseTxRef = _db.collection('Transactions').doc();
        batch.set(baseTxRef, {
          'walletId': walletDoc.id,
          'type': 'PROFIT',
          'amount': baseProfit,
          'description':
              'أرباح استثمار أساسية بنسبة ${(baseProfitRate * 100).toStringAsFixed(1)}%',
          'date': executedAtStr,
        });

        // 2. سند بونص الإحالة المنفصل (إذا كان له بونص مخصص أكبر من 0)
        if (bonusProfit > 0) {
          totalBonusDistributed += bonusProfit;
          final bonusTxRef = _db.collection('Transactions').doc();
          batch.set(bonusTxRef, {
            'walletId': walletDoc.id,
            'type': 'BONUS', // نوع جديد للسندات
            'amount': bonusProfit,
            'description':
                'بونص إحالة إضافي بنسبة ${(bonusRate * 100).toStringAsFixed(2)}%',
            'date': executedAtStr,
          });
        }

        if (role != 'ADMIN') {
          totalBaseDistributed += baseProfit;
        }
      }

      // 4. احتساب إحصائيات المدير وحفظها لعرضها في الشاشة
      _managerProfitStats = {
        'trackBaseProfit':
            totalTrackPrincipal * baseProfitRate, // إجمالي أرباح المسار 5%
        'managerExtraEarned':
            totalManagerExtraEarned, // إجمالي الـ 0.5% التي حصلت عليها
        'totalDistributedBonus': totalBonusDistributed, // كم وزعت منها (البونص)
        'managerNetProfit':
            totalManagerExtraEarned - totalBonusDistributed, // المتبقي لك صافي
      };

      // 5. حفظ هذه العملية الإدارية في سجل التوزيع السحابي
      final logRef = _db.collection('ProfitDistributionLogs').doc();
      batch.set(logRef, {
        'trackId': trackDoc.id,
        'baseProfitRate': baseProfitRate,
        'managerExtraRate': managerExtraRate,
        'totalTrackPrincipal': totalTrackPrincipal,
        'managerExtraEarned': totalManagerExtraEarned,
        'totalDistributedBonus': totalBonusDistributed,
        'managerNetProfit': totalManagerExtraEarned - totalBonusDistributed,
        'executedAt': executedAtStr,
      });

      await batch.commit();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }
}
