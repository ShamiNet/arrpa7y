import 'package:flutter/material.dart';
import '../data/models/profit_simulation_model.dart';
import '../data/repositories/profit_repository.dart';

class ProfitProvider with ChangeNotifier {
  final ProfitRepository _profitRepository = ProfitRepository();

  bool _isLoading = false;
  String? _errorMessage;
  ProfitSimulationModel? _simulationResult;

  // مسيرات الحصول على البيانات (Getters) لتزويد الواجهات بالمعلومات الحاليّة
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  ProfitSimulationModel? get simulationResult => _simulationResult;

  /**
   * تنفيذ محاكاة الأرباح وتنبيه الشاشات لتحديث البيانات رسومياً
   */
  Future<void> runSimulation({
    required String trackType,
    required double grossProfitRate,
  }) async {
    _setLoading(true);
    _clearError();
    _simulationResult = null; // تنظيف النتائج السابقة قبل جلب الجديدة

    try {
      _simulationResult = await _profitRepository.fetchSimulation(
        trackType: trackType,
        grossProfitRate: grossProfitRate,
      );
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  /**
   * تنفيذ التوزيع الفعلي والضخ النهائي للأرباح في السيرفر
   */
  Future<bool> runActualDistribution({
    required String trackType,
    required double grossProfitRate,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      await _profitRepository.executeActualDistribution(
        trackType: trackType,
        grossProfitRate: grossProfitRate,
      );
      return true; // تعبير عن نجاح العملية بالكامل للـ UI
    } catch (e) {
      _errorMessage = e.toString();
      return false; // فشل الضخ
    } finally {
      _setLoading(false);
    }
  }

  // دوال مساعدة داخلية للتحكم وتنبيه الواجهات
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners(); // هذه الدالة السحرية هي من تعيد بناء شاشات فلاتر فوراً
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // دالة لتصفير البيانات عند مغادرة الشاشة
  void resetData() {
    _simulationResult = null;
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }
}
