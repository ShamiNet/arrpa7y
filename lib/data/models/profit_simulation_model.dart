class ProfitSimulationModel {
  final String trackName;
  final double totalTrackPrincipal;
  final double grossProfitRate;
  final double netProfitRateDistributed;
  final double totalDistributedToClients;
  final double myTotalCommissionEarned;
  final double myPersonalWalletProfit;
  final List<UserProfitBreakdown> breakdown;

  ProfitSimulationModel({
    required this.trackName,
    required this.totalTrackPrincipal,
    required this.grossProfitRate,
    required this.netProfitRateDistributed,
    required this.totalDistributedToClients,
    required this.myTotalCommissionEarned,
    required this.myPersonalWalletProfit,
    required this.breakdown,
  });

  // تحويل الـ JSON القادم من السيرفر إلى كائن Dart (Factory Constructor)
  factory ProfitSimulationModel.fromJson(Map<String, dynamic> json) {
    var list = json['breakdown'] as List;
    List<UserProfitBreakdown> breakdownList = list
        .map((i) => UserProfitBreakdown.fromJson(i))
        .toList();

    return ProfitSimulationModel(
      trackName: json['trackName'] ?? '',
      totalTrackPrincipal: (json['totalTrackPrincipal'] ?? 0).toDouble(),
      grossProfitRate: (json['grossProfitRate'] ?? 0).toDouble(),
      netProfitRateDistributed: (json['netProfitRateDistributed'] ?? 0)
          .toDouble(),
      totalDistributedToClients: (json['totalDistributedToClients'] ?? 0)
          .toDouble(),
      myTotalCommissionEarned: (json['myTotalCommissionEarned'] ?? 0)
          .toDouble(),
      myPersonalWalletProfit: (json['myPersonalWalletProfit'] ?? 0).toDouble(),
      breakdown: breakdownList,
    );
  }
}

class UserProfitBreakdown {
  final String userId;
  final String userName;
  final String role;
  final double principalBalance;
  final double grossProfit;
  final double commissionDeducted;
  final double netProfitAdded;

  UserProfitBreakdown({
    required this.userId,
    required this.userName,
    required this.role,
    required this.principalBalance,
    required this.grossProfit,
    required this.commissionDeducted,
    required this.netProfitAdded,
  });

  factory UserProfitBreakdown.fromJson(Map<String, dynamic> json) {
    return UserProfitBreakdown(
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      role: json['role'] ?? 'CLIENT',
      principalBalance: (json['principalBalance'] ?? 0).toDouble(),
      grossProfit: (json['grossProfit'] ?? 0).toDouble(),
      commissionDeducted: (json['commissionDeducted'] ?? 0).toDouble(),
      netProfitAdded: (json['netProfitAdded'] ?? 0).toDouble(),
    );
  }
}
