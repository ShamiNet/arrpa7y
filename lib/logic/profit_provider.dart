import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/repositories/profit_repository.dart';

class ProfitProvider with ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final ProfitRepository _repository = ProfitRepository();

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Map<String, double> _managerProfitStats = {
    'trackBaseProfit': 0.0,
    'managerExtraEarned': 0.0,
    'totalDeductionsEarned': 0.0,
    'totalDistributedBonus': 0.0,
    'managerNetProfit': 0.0,
  };
  Map<String, double> get managerProfitStats => _managerProfitStats;

  /// 🎯 حساب محاكاة وتوزيع الأرباح والخصومات
  Future<void> distributeProfitsWithBonus({
    required String trackType,
    required double baseProfitRate,
    double managerExtraRate = 0.0,
    double managerDeductionRate = 0.0,
    required String targetUserId,
    bool isSimulation = false, // 👈 لمنع الحفظ السحابي أثناء المحاكاة
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. جلب بيانات المسار
      final trackQuery = await _db
          .collection('InvestmentTracks')
          .where('type', isEqualTo: trackType)
          .limit(1)
          .get();

      if (trackQuery.docs.isEmpty) {
        throw Exception('المسار الاستثماري غير موجود.');
      }
      final trackDoc = trackQuery.docs.first;

      if (!isSimulation) {
        await trackDoc.reference.update({'additionalRate': managerExtraRate});
      }

      // 2. جلب محافظ المسار
      final walletsQuery = await _db
          .collection('Wallets')
          .where('trackId', isEqualTo: trackDoc.id)
          .get();

      double totalTrackPrincipal = 0.0;
      double totalBonusDistributed = 0.0;
      double totalManagerExtraEarned = 0.0;
      double totalDeductionsEarned = 0.0;

      Map<String, double> walletProfitsToAdd = {};
      Map<String, double> walletBaseNetProfits = {};
      Map<String, double> walletBonusProfits = {};
      Map<String, double> walletBonusRates = {};

      String? targetAdminWalletId;

      // 3. حساب الأرباح والعمولات والخصومات بالذاكرة
      for (var walletDoc in walletsQuery.docs) {
        final walletData = walletDoc.data();
        final double principal = (walletData['principalBalance'] as num)
            .toDouble();
        totalTrackPrincipal += principal;

        final String walletUserId = walletData['userId'] ?? '';

        if (walletUserId == targetUserId) {
          targetAdminWalletId = walletDoc.id;
        }

        final userDoc = await _db.collection('Users').doc(walletUserId).get();
        final userData = userDoc.data() ?? {};

        double appliedDeductionRate = managerDeductionRate;
        if (userData['customDeductionRate'] != null) {
          appliedDeductionRate =
              (userData['customDeductionRate'] as num).toDouble() / 100;
        }

        double grossBaseProfit = principal * baseProfitRate;
        double managerDeduction = principal * appliedDeductionRate;
        double netBaseProfit = grossBaseProfit - managerDeduction;

        double bonusRate = 0.0;
        if (userData['referralBonusRate'] != null) {
          bonusRate = (userData['referralBonusRate'] as num).toDouble() / 100;
        }
        double bonusProfit = principal * bonusRate;

        double managerExtraFromThisWallet = principal * managerExtraRate;
        totalManagerExtraEarned += managerExtraFromThisWallet;
        totalDeductionsEarned += managerDeduction;
        totalBonusDistributed += bonusProfit;

        walletBaseNetProfits[walletDoc.id] = netBaseProfit;
        walletBonusProfits[walletDoc.id] = bonusProfit;
        walletBonusRates[walletDoc.id] = bonusRate;
        walletProfitsToAdd[walletDoc.id] = netBaseProfit + bonusProfit;
      }

      // 4. احتساب الصافي المتبقي لعمولة وخصومات المدير
      double managerNetProfit =
          (totalManagerExtraEarned + totalDeductionsEarned) -
          totalBonusDistributed;

      // 5. حفظ الإحصائيات لعرضها بالواجهة
      _managerProfitStats = {
        'trackBaseProfit': totalTrackPrincipal * baseProfitRate,
        'managerExtraEarned': totalManagerExtraEarned,
        'totalDeductionsEarned': totalDeductionsEarned,
        'totalDistributedBonus': totalBonusDistributed,
        'managerNetProfit': managerNetProfit,
      };

      // إذا كانت العملية محاكاة افتراضية، ننهي الدالة هنا ولا نعدل قاعدة البيانات
      if (isSimulation) {
        _isLoading = false;
        notifyListeners();
        return;
      }

      // إضافة صافي أرباح المدير للحساب المختار
      if (managerNetProfit > 0 && targetAdminWalletId != null) {
        walletProfitsToAdd[targetAdminWalletId] =
            (walletProfitsToAdd[targetAdminWalletId] ?? 0.0) + managerNetProfit;
      }

      // 6. استدعاء الـ Repository المطور لإجراء الضخ الفعلي في الفايربيس
      await _repository.executeProfitDistribution(
        trackDocId: trackDoc.id,
        trackType: trackType,
        baseProfitRate: baseProfitRate,
        managerExtraRate: managerExtraRate,
        managerDeductionRate: managerDeductionRate,
        targetUserId: targetUserId,
        walletProfitsToAdd: walletProfitsToAdd,
        walletBaseNetProfits: walletBaseNetProfits,
        walletBonusProfits: walletBonusProfits,
        walletBonusRates: walletBonusRates,
        walletDocs: walletsQuery.docs,
      );

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// 🔄 مسح وتصفير كافة الأرباح المسجلة مسبقاً عبر الـ Repository
  Future<bool> resetAllProfits() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.resetAllProfitsData();

      _managerProfitStats = {
        'trackBaseProfit': 0.0,
        'managerExtraEarned': 0.0,
        'totalDeductionsEarned': 0.0,
        'totalDistributedBonus': 0.0,
        'managerNetProfit': 0.0,
      };

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}
