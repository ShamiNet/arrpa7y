class TransactionModel {
  final String id;
  final String walletId;
  final String userName;
  final String trackType;
  final String type; // DEPOSIT أو WITHDRAW
  final double amount;
  final String description;
  final DateTime date;

  TransactionModel({
    required this.id,
    required this.walletId,
    required this.userName,
    required this.trackType,
    required this.type,
    required this.amount,
    required this.description,
    required this.date,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    String walletIdStr = '';
    Map<String, dynamic> userJson = {};
    Map<String, dynamic> trackJson = {};

    // فحص حقل walletId إذا كان كائناً مفككاً أم مجرد نص ID
    if (json['walletId'] is Map<String, dynamic>) {
      final walletJson = json['walletId'] as Map<String, dynamic>;
      walletIdStr = walletJson['_id'] ?? '';
      userJson = walletJson['userId'] is Map<String, dynamic>
          ? walletJson['userId'] as Map<String, dynamic>
          : {};
      trackJson = walletJson['trackId'] is Map<String, dynamic>
          ? walletJson['trackId'] as Map<String, dynamic>
          : {};
    } else if (json['walletId'] is String) {
      walletIdStr = json['walletId'];
    }

    return TransactionModel(
      id: json['_id'] ?? '',
      walletId: walletIdStr,
      userName: userJson['name'] ?? 'مستثمر (قيد قديم)',
      trackType: trackJson['type'] ?? 'عام',
      type: json['type'] ?? 'DEPOSIT',
      amount: (json['amount'] ?? 0).toDouble(),
      description: json['description'] ?? '',
      date: json['date'] != null
          ? DateTime.parse(json['date'])
          : DateTime.now(),
    );
  }
}
