class WalletModel {
  final String id;
  final String userId;
  final String userName;
  final String userRole;
  final String trackId;
  final String trackName;
  final String trackType;
  final double principalBalance;
  final double totalProfitsEarned;
  final String phone; // 🚀 الحقل الجديد لربط محفظة شام كاش

  WalletModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userRole,
    required this.trackId,
    required this.trackName,
    required this.trackType,
    required this.principalBalance,
    required this.totalProfitsEarned,
    required this.phone,
  });

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    // تفكيك الكائنات المتداخلة (Populated fields) القادمة من السيرفر
    final userJson = json['userId'] as Map<String, dynamic>? ?? {};
    final trackJson = json['trackId'] as Map<String, dynamic>? ?? {};

    return WalletModel(
      id: json['_id'] ?? '',
      userId: userJson['_id'] ?? '',
      userName: userJson['name'] ?? 'مستثمر غير معروف',
      userRole: userJson['role'] ?? 'CLIENT',
      trackId: trackJson['_id'] ?? '',
      trackName: trackJson['name'] ?? '',
      trackType: trackJson['type'] ?? '',

      // تحويل الأرقام بشكل آمن لمنع تعليق التطبيق (Cast Error)
      principalBalance: (json['principalBalance'] as num?)?.toDouble() ?? 0.0,
      totalProfitsEarned:
          (json['totalProfitsEarned'] as num?)?.toDouble() ?? 0.0,

      // 🚀 الإصلاح: قراءة الهاتف من كائن المستخدم المتداخل وليس من المحفظة مباشرة
      phone: userJson['phone'] ?? '',
    );
  }
}
