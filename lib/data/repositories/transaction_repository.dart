import 'dart:convert';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../models/transaction_model.dart';

class TransactionRepository {
  final ApiClient _apiClient = ApiClient();

  // جلب كافة السندات المالية من السيرفر
  Future<List<TransactionModel>> fetchTransactions() async {
    try {
      final response = await _apiClient.get(ApiConstants.getAllTransactions);
      final List jsonResponse = jsonDecode(response.body);
      return jsonResponse.map((tx) => TransactionModel.fromJson(tx)).toList();
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // إرسال طلب إنشاء سند مالي جديد (إيداع أو سحب)
  Future<void> createTransaction({
    required String walletId,
    required String type,
    required double amount,
    required String description,
  }) async {
    try {
      await _apiClient.post(
        ApiConstants.createTransaction,
        body: {
          'walletId': walletId,
          'type': type,
          'amount': amount,
          'description': description,
        },
      );
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }
}
