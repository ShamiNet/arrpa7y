class ApiConstants {
  // رابط السيرفر الحي الخاص بك
  static const String baseUrl = 'http://qaaz.live:3005/api';

  // نقاط الاتصال (Endpoints)
  static const String login = '$baseUrl/auth/login';
  static const String simulateProfit = '$baseUrl/profits/simulate';
  static const String distributeProfit = '$baseUrl/profits/distribute';

  // النقاط الجديدة للإدارة والإضافة
  static const String createClient = '$baseUrl/users/create';
  static const String getAllWallets = '$baseUrl/users/wallets';

  // النقاط الجديدة للسندات المالية والوصولات
  static const String createTransaction = '$baseUrl/transactions/create';
  static const String getAllTransactions = '$baseUrl/transactions/all';

  static const String getShamCashBalances = '$baseUrl/users/shamcash/balances';
}
