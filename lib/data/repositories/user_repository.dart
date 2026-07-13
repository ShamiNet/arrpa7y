import 'dart:convert';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../models/wallet_model.dart';

class UserRepository {
  final ApiClient _apiClient = ApiClient();

  // جلب كافة المستثمرين ومحافظهم الاستثمارية لعرضهم في قائمة الإدارة
  Future<List<WalletModel>> fetchAllWallets() async {
    try {
      final response = await _apiClient.get(ApiConstants.getAllWallets);
      final List jsonResponse = jsonDecode(response.body);
      return jsonResponse
          .map((wallet) => WalletModel.fromJson(wallet))
          .toList();
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // إرسال طلب إنشاء مستثمر جديد وتأسيس محفظته المالية
  Future<void> createNewClient({
    required String name,
    required String trackType,
    required double initialPrincipal,
  }) async {
    try {
      await _apiClient.post(
        ApiConstants.createClient,
        body: {
          'name': name,
          'trackType': trackType,
          'initialPrincipal': initialPrincipal,
          'role': 'CLIENT', // افتراضي للمستثمرين الجدد
        },
      );
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }
}
