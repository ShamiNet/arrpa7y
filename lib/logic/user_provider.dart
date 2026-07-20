import 'dart:convert'; // 👈 استيراد دالة jsonDecode
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http; // 👈 استيراد مكتبة الاتصال بالشبكة
import '../data/repositories/user_repository.dart';
import '../data/models/wallet_model.dart';

enum WalletSortType { name, principal, newest }

class UserProvider with ChangeNotifier {
  // 1️⃣ أضف هذه المتغيرات ومسترداتها (Getters) داخل كلاس UserProvider:
  double _loadingProgress = 0.0;
  String _loadingMessage = '';

  double get loadingProgress => _loadingProgress;
  String get loadingMessage => _loadingMessage;

  final UserRepository _repository = UserRepository();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Map<String, dynamic>? _shamCashInfo;
  Map<String, dynamic>? get shamCashInfo => _shamCashInfo;

  List<WalletModel> _wallets = [];
  bool _isLoading = false;
  String? _errorMessage;
  WalletSortType _currentSort = WalletSortType.newest;

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

  bool _isFetchingWallets = false;
  bool _isFetchingShamCash = false;

  // 2️⃣ تحديث دالة loadShamCashBalances لتسجيل التقدم:
  Future<void> loadShamCashBalances() async {
    if (_isFetchingShamCash) return;
    _isFetchingShamCash = true;

    _loadingProgress = 0.5;
    _loadingMessage = '🔌 جاري الاتصال بسيرفر ShamCash...';
    notifyListeners();

    debugPrint('🔌 [ShamCash]: جاري جلب الأرصدة الحقيقية سحابياً...');

    final String apiToken = "89qpjCn71t7XzuKI3rw07x8aO5-St_IMmJTtxmzlbpo";
    final String baseUrl = "https://api.shamcash-api.com/v1";

    try {
      _loadingProgress = 0.7;
      _loadingMessage = '🔑 جاري التحقق من معرف الحساب...';
      notifyListeners();

      final accountsResponse = await http
          .get(
            Uri.parse('$baseUrl/accounts'),
            headers: {
              'Authorization': 'Bearer $apiToken',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 15));

      if (accountsResponse.statusCode != 200) {
        throw Exception(
          'فشل الاتصال بالحسابات: رمز الحالة ${accountsResponse.statusCode}',
        );
      }

      final accountsData = jsonDecode(accountsResponse.body);
      if (accountsData['code'] != "SUCCESS" ||
          accountsData['data'] == null ||
          accountsData['data'].isEmpty) {
        throw Exception('لم يتم العثور على حسابات نشطة في شام كاش.');
      }

      final String accountId = accountsData['data'][0]['id'].toString();

      _loadingProgress = 0.85;
      _loadingMessage = '💰 جاري جلب أرصدة العملات الحقيقية...';
      notifyListeners();

      final balancesResponse = await http
          .get(
            Uri.parse('$baseUrl/balances?account_id=$accountId'),
            headers: {
              'Authorization': 'Bearer $apiToken',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 15));

      if (balancesResponse.statusCode != 200) {
        throw Exception(
          'فشل جلب الأرصدة: رمز الحالة ${balancesResponse.statusCode}',
        );
      }

      final balancesData = jsonDecode(balancesResponse.body);
      debugPrint('🕵️‍♂️ [ShamCash Raw Data]: ${balancesResponse.body}');

      if (balancesData['code'] == "SUCCESS") {
        final List rawBalances = balancesData['data']?['balances'] ?? [];
        List<Map<String, dynamic>> balancesList = [];

        for (var bal in rawBalances) {
          final currencyObj = bal['currency'] ?? {};
          final double amount =
              (bal['available'] ?? bal['balance'] ?? bal['amount'] ?? 0.0)
                  .toDouble();
          balancesList.add({
            'currency': currencyObj['code'] ?? 'SYP',
            'amount': amount,
          });
        }

        _shamCashInfo = {
          'success': true,
          'merchantName': 'عامر عبدالقادر حلبي',
          'balances': balancesList,
        };

        _loadingProgress = 1.0;
        _loadingMessage = '✅ اكتمل جلب البيانات بنجاح.';
        notifyListeners();
        debugPrint('✅ [ShamCash]: تم جلب وتحديث الأرصدة الحقيقية بنجاح.');
      } else {
        throw Exception('رمز الخطأ من بوابة شام كاش: ${balancesData['code']}');
      }
    } catch (e) {
      debugPrint(
        '🚨 [ShamCash Error]: حدث خطأ أثناء الاتصال المباشر بـ شام كاش: $e',
      );

      _shamCashInfo = {
        'success': true,
        'merchantName': 'عامر عبدالقادر حلبي (محاكاة الاحتياط)',
        'balances': [
          {'currency': 'SYP', 'amount': 00000.0},
          {'currency': 'USD', 'amount': 0000.0},
          {'currency': 'EUR', 'amount': 0000.0},
        ],
      };
      _loadingProgress = 1.0;
      _loadingMessage =
          '⚠️ تعذر الربط الحقيقي، تم استخدام البيانات الاحتياطية.';
      notifyListeners();
    } finally {
      _isFetchingShamCash = false;
    }
  }

  // أضف هذه الدالة داخل كلاس UserProvider
  Future<bool> toggleUserStatus(String userId, bool currentStatus) async {
    try {
      await _db.collection('Users').doc(userId).update({
        'isActive': !currentStatus,
      });
      await loadWallets(); // إعادة تحميل القائمة للتحديث
      return true;
    } catch (e) {
      return false;
    }
  }

  // 3️⃣ تحديث دالة loadWallets لتشمل بداية ونهاية شريط التقدم:
  Future<void> loadWallets() async {
    if (_isFetchingWallets) return;
    _isFetchingWallets = true;
    _isLoading = true;
    _errorMessage = null;

    _loadingProgress = 0.15;
    _loadingMessage = '📥 جاري تحميل المحافظ من Firestore...';
    notifyListeners();

    try {
      _wallets = await _repository.fetchAllWallets();

      _loadingProgress = 0.35;
      _loadingMessage = '✅ تم جلب المحافظ، جاري الانتقال لـ ShamCash...';
      notifyListeners();

      await loadShamCashBalances();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      _isFetchingWallets = false;
      notifyListeners();
    }
  }

  Future<bool> updateUser({
    required String userId,
    required String newName,
    required String newRole,
    required String newPhone,
    required double? newBonusRate,
  }) async {
    debugPrint('🔄 [UserProvider]: جاري تحديث بيانات المستثمر ($userId)...');
    try {
      await _db.collection('Users').doc(userId).update({
        'name': newName,
        'role': newRole,
        'phone': newPhone,
        'referralBonusRate': newBonusRate ?? 0.0,
      });
      debugPrint('✅ [UserProvider]: تم تحديث بيانات المستثمر سحابياً بنجاح.');
      await loadWallets(); // إعادة تحميل القائمة المحدثة
      return true;
    } catch (e) {
      debugPrint('🚨 [UserProvider Error]: تعذر تحديث بيانات المستثمر: $e');
      return false;
    }
  }

  Future<bool> deleteUser(String userId) async {
    try {
      // حذف المحفظة المرتبطة أولاً وسجل السندات المرتبطة بالمستثمر
      final walletQuery = await _db
          .collection('Wallets')
          .where('userId', isEqualTo: userId)
          .get();
      final batch = _db.batch();

      for (var walletDoc in walletQuery.docs) {
        // تصفية وحذف السندات المالية المقيدة للمحفظة
        final txsQuery = await _db
            .collection('Transactions')
            .where('walletId', isEqualTo: walletDoc.id)
            .get();
        for (var txDoc in txsQuery.docs) {
          batch.delete(txDoc.reference);
        }
        batch.delete(walletDoc.reference);
      }

      batch.delete(_db.collection('Users').doc(userId));
      await batch.commit();

      await loadWallets();
      return true;
    } catch (e) {
      return false;
    }
  }

  double get totalSystemPrincipal =>
      _wallets.fold(0.0, (sum, w) => sum + w.principalBalance);
  double get totalSystemProfitsEarned =>
      _wallets.fold(0.0, (sum, w) => sum + w.totalProfitsEarned);

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
