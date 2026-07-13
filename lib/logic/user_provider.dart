import 'dart:convert';
import 'package:flutter/material.dart';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../data/models/wallet_model.dart';

enum WalletSortType { name, principal, newest }

class UserProvider with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  Map<String, dynamic>? _shamCashInfo;
  Map<String, dynamic>? get shamCashInfo => _shamCashInfo;

  // جلب معلومات وأرصدة شام كاش من السيرفر
  // جلب معلومات وأرصدة شام كاش من السيرفر مع طباعة سجلات التتبع الحية للـ Debugging
  Future<void> loadShamCashBalances() async {
    debugPrint(
      '🔌 [ShamCash Debug]: جاري بدء طلب جلب أرصدة شام كاش من السيرفر المالي...',
    );

    try {
      final response = await _apiClient.get(ApiConstants.getShamCashBalances);

      debugPrint(
        '📥 [ShamCash Debug]: استجابة السيرفر المالي وصلت - رمز الحالة: ${response.statusCode}',
      );
      debugPrint(
        '📄 [ShamCash Debug]: البيانات الخام (Raw Body): ${response.body}',
      );

      if (response.statusCode == 200) {
        _shamCashInfo = jsonDecode(response.body);

        // طباعة تفصيلية للتأكد من بنية البيانات التي تم فك تشفيرها
        debugPrint('✅ [ShamCash Debug]: تم فك تشفير البيانات بنجاح!');
        debugPrint(
          '🏢 [ShamCash Debug]: اسم التاجر المسجل: ${_shamCashInfo?['merchantName']}',
        );
        debugPrint(
          '💰 [ShamCash Debug]: الأرصدة المستلمة: ${_shamCashInfo?['balances']}',
        );

        notifyListeners();
      } else {
        debugPrint(
          '⚠️ [ShamCash Debug]: السيرفر أعاد رمز حالة غير ناجح (ليس 200). محتوى الخطأ: ${response.body}',
        );
      }
    } catch (e, stacktrace) {
      debugPrint(
        '🚨 [ShamCash Debug]: حدث خطأ فادح أثناء الاتصال بالشبكة أو معالجة البيانات!',
      );
      debugPrint('🚨 [ShamCash Debug]: تفاصيل الاستثناء: $e');
      debugPrint('🚨 [ShamCash Debug]: مسار التتبع (StackTrace):\n$stacktrace');
    }
  }

  List<WalletModel> _wallets = [];
  bool _isLoading = false;
  String? _errorMessage;
  WalletSortType _currentSort = WalletSortType.newest; // الترتيب الافتراضي

  List<WalletModel> get wallets {
    List<WalletModel> sortedList = List.from(_wallets);
    if (_currentSort == WalletSortType.name) {
      sortedList.sort((a, b) => a.userName.compareTo(b.userName));
    } else if (_currentSort == WalletSortType.principal) {
      sortedList.sort(
        (a, b) => b.principalBalance.compareTo(a.principalBalance),
      );
    } else if (_currentSort == WalletSortType.newest) {
      sortedList.sort((a, b) => b.id.compareTo(a.id));
    }
    return sortedList;
  }

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  WalletSortType get currentSort => _currentSort;

  void changeSortType(WalletSortType sortType) {
    _currentSort = sortType;
    notifyListeners();
  }

  // 🚀 التعديل: استدعاء جلب أرصدة شام كاش تلقائياً بالتزامن مع جلب المحافظ
  Future<void> loadWallets() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      // 1. جلب المحافظ الاستثمارية
      final response = await _apiClient.get(
        '${ApiConstants.baseUrl}/users/wallets',
      );
      final List jsonResponse = jsonDecode(response.body);
      _wallets = jsonResponse.map((w) => WalletModel.fromJson(w)).toList();

      // 2. جلب وتحديث السيولة في شام كاش تلقائياً
      await loadShamCashBalances();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateUser(String userId, String newName, String newRole) async {
    try {
      final response = await _apiClient.put(
        '${ApiConstants.baseUrl}/users/update/$userId',
        body: {'name': newName, 'role': newRole},
      );
      if (response.statusCode == 200) {
        await loadWallets();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteUser(String userId) async {
    try {
      final response = await _apiClient.delete(
        '${ApiConstants.baseUrl}/users/delete/$userId',
      );
      if (response.statusCode == 200) {
        await loadWallets();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  double get totalSystemPrincipal {
    return _wallets.fold(0.0, (sum, wallet) => sum + wallet.principalBalance);
  }

  double get totalSystemProfitsEarned {
    return _wallets.fold(0.0, (sum, wallet) => sum + wallet.totalProfitsEarned);
  }

  Map<String, double> get trackLiquidityDistribution {
    Map<String, double> distribution = {};
    double total = totalSystemPrincipal;

    if (total == 0) return distribution;

    for (var wallet in _wallets) {
      final track = wallet.trackType;
      distribution[track] =
          (distribution[track] ?? 0.0) + wallet.principalBalance;
    }

    distribution.forEach((key, value) {
      distribution[key] = (value / total) * 100;
    });

    return distribution;
  }
}
