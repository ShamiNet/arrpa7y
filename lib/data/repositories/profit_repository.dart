import 'dart:convert';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../models/profit_simulation_model.dart';

class ProfitRepository {
  final ApiClient _apiClient = ApiClient();

  /**
   * طلب إجراء محاكاة أرباح (What-If Analysis) من السيرفر
   * [trackType] نوع المسار (BITCOIN أو ORGANIZATIONS)
   * [grossProfitRate] النسبة المئوية العشرية (مثلاً 0.10 لـ 10%)
   */
  Future<ProfitSimulationModel> fetchSimulation({
    required String trackType,
    required double grossProfitRate,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.simulateProfit,
        body: {'trackType': trackType, 'grossProfitRate': grossProfitRate},
      );

      final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
      return ProfitSimulationModel.fromJson(jsonResponse);
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  /**
   * طلب اعتماد التوزيع الفعلي وضخ الأرباح في المحافظ
   */
  Future<ProfitSimulationModel> executeActualDistribution({
    required String trackType,
    required double grossProfitRate,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.distributeProfit,
        body: {'trackType': trackType, 'grossProfitRate': grossProfitRate},
      );

      final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
      // السيرفر يرجع كائن نجاح يحتوي على رسالة وبداخلها كائن البيانات النظيف في حقل 'data'
      final Map<String, dynamic> data = jsonResponse['data'];
      return ProfitSimulationModel.fromJson(data);
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }
}
