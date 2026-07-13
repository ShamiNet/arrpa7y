import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../logic/profit_provider.dart';
import '../../data/models/profit_simulation_model.dart';
import '../../logic/user_provider.dart';

class ProfitSimulationScreen extends StatefulWidget {
  const ProfitSimulationScreen({super.key});

  @override
  State<ProfitSimulationScreen> createState() => _ProfitSimulationScreenState();
}

class _ProfitSimulationScreenState extends State<ProfitSimulationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _rateController = TextEditingController();

  String _selectedTrack = 'BITCOIN';

  final List<Map<String, String>> _tracks = [
    {'value': 'BITCOIN', 'label': 'تداول البتكوين'},
    {'value': 'ORGANIZATIONS', 'label': 'استثمار المنظمات (أبو جميل)'},
  ];

  @override
  void initState() {
    super.initState();
    // 🚀 جلب البيانات والأرصدة عند إقلاع الواجهة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UserProvider>(context, listen: false).loadWallets();
    });
  }

  @override
  void dispose() {
    _rateController.dispose();
    super.dispose();
  }

  String _formatCurrency(double amount) {
    return '\$${amount.toStringAsFixed(2)}';
  }

  String _formatPercent(double rate) {
    return '${(rate * 100).toStringAsFixed(0)}%';
  }

  // 🚀 ويدجت بناء كرت سيولة شام كاش لمؤسسة الشامي
  Widget _buildShamCashStatusCard(UserProvider userProvider) {
    final info = userProvider.shamCashInfo;
    if (info == null) return const SizedBox.shrink();

    final balances = info['balances'] as List? ?? [];
    final merchantName = info['merchantName'] ?? 'مؤسسة الشامي';

    return Card(
      color: const Color(0xFF0F1E36), // لون إنديغو داكن عميق
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: const [
                    Icon(
                      Icons.account_balance_wallet,
                      color: Colors.greenAccent,
                      size: 22,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'السيولة الحية (ShamCash)',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.greenAccent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    merchantName,
                    style: const TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(color: Colors.white24, height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: balances.map<Widget>((bal) {
                final String currency = bal['currency'] ?? '';
                final double amount =
                    (bal['amount'] as num?)?.toDouble() ?? 0.0;

                // تحديد اسم العملة ورمز التنسيق المالي المخصص
                String currencyLabel = 'أخرى';
                String formattedValue = amount.toStringAsFixed(2);

                if (currency == 'SYP') {
                  currencyLabel = 'الليرة السورية';
                  formattedValue = '${amount.toStringAsFixed(0)} ل.س';
                } else if (currency == 'USD') {
                  currencyLabel = 'الدولار الأمريكي';
                  formattedValue = '\$${amount.toStringAsFixed(2)}';
                } else if (currency == 'EUR') {
                  currencyLabel = 'اليورو الأوروبي';
                  formattedValue = '€${amount.toStringAsFixed(2)}';
                }

                // تغيير اللون لتمييز العملة بصرياً
                Color valueColor = Colors.greenAccent;
                if (currency == 'SYP') {
                  valueColor = Colors.amberAccent;
                } else if (currency == 'EUR') {
                  valueColor = Colors.lightBlueAccent;
                }

                return Column(
                  children: [
                    Text(
                      currencyLabel,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formattedValue,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: valueColor,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profitProvider = Provider.of<ProfitProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'محرك محاكاة وتوزيع الأرباح',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            userProvider.loadWallets(), // يحدث المحافظ وشام كاش معاً
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🚀 عرض كرت السيولة المالي الجديد في المقدمة
                _buildShamCashStatusCard(userProvider),

                const Text(
                  '📊 التقرير المالي العام للمؤسسة',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        title: 'إجمالي رؤوس الأموال',
                        value:
                            '\$${userProvider.totalSystemPrincipal.toStringAsFixed(2)}',
                        color: Colors.blue.shade700,
                        icon: Icons.account_balance_wallet_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        title: 'إجمالي الأرباح الموزعة',
                        value:
                            '\$${userProvider.totalSystemProfitsEarned.toStringAsFixed(2)}',
                        color: Colors.green.shade700,
                        icon: Icons.trending_up_rounded,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                _buildDistributionSection(
                  context,
                  userProvider.trackLiquidityDistribution,
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: Divider(),
                ),

                const Text(
                  '🎛️ محاكي ضخ وتوزيع الأرباح الدورية',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        DropdownButtonFormField<String>(
                          value: _selectedTrack,
                          decoration: const InputDecoration(
                            labelText: 'اختر مسار الاستثمار',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.trending_up),
                          ),
                          items: _tracks.map((track) {
                            return DropdownMenuItem(
                              value: track['value'],
                              child: Text(track['label']!),
                            );
                          }).toList(),
                          onChanged: (val) =>
                              setState(() => _selectedTrack = val!),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _rateController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText:
                                'نسبة الربح الإجمالية للمسار (مثال: 10 تعني 10%)',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.percent),
                            hintText: 'أدخل الرقم بدون رمز %',
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty)
                              return 'الرجاء إدخال نسبة الربح';
                            if (double.tryParse(val) == null)
                              return 'الرجاء إدخال رقم صحيح';
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: profitProvider.isLoading
                                    ? null
                                    : _handleSimulation,
                                icon: const Icon(Icons.analytics_outlined),
                                label: const Text('تشغيل المحاكاة'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(
                                    context,
                                  ).colorScheme.secondary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: profitProvider.isLoading
                                    ? null
                                    : _handleDistribution,
                                icon: const Icon(Icons.account_balance_wallet),
                                label: const Text('اعتماد وضخ فعلي'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(
                                    context,
                                  ).primaryColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                if (profitProvider.isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (profitProvider.errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            profitProvider.errorMessage!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  )
                else if (profitProvider.simulationResult != null)
                  _buildFinancialResults(profitProvider.simulationResult!),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDistributionSection(
    BuildContext context,
    Map<String, double> distribution,
  ) {
    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.pie_chart_outline_rounded,
                  color: Theme.of(context).primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  '🎯 نسبة توزيع السيولة حسب مسارات الاستثمار',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ],
            ),
            const Divider(height: 24),
            if (distribution.isEmpty)
              const Text(
                'لا توجد بيانات سيولة كافية لعرض التوزيع الكلي.',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              )
            else
              ...distribution.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'مسار: ${entry.key}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '${entry.value.toStringAsFixed(1)}%',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: entry.value / 100,
                        backgroundColor: Colors.grey.shade200,
                        color: Theme.of(context).primaryColor,
                        minHeight: 6,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                );
              }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialResults(ProfitSimulationModel res) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ملخص نتائج توزيع الأرباح الإجمالية:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'أرباحك كمدير (العمولة)',
                _formatCurrency(res.myTotalCommissionEarned),
                Colors.orange.shade800,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildSummaryCard(
                'أرباح محفظتك الشخصية',
                _formatCurrency(res.myPersonalWalletProfit),
                Colors.green.shade800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildSummaryCard(
          'إجمالي رأس مال المسار النشط',
          _formatCurrency(res.totalTrackPrincipal),
          Colors.blueGrey,
        ),
        const SizedBox(height: 20),
        const Text(
          'كشف الحساب الافتراضي لكل مشترك:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Card(
          elevation: 2,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(
                  label: Text(
                    'المستثمر',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'رأس المال',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'الربح الإجمالي',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'العمولة المستقطعة',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'الصافي المستحق',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
              rows: res.breakdown.map((user) {
                final isAdmin = user.role == 'ADMIN';
                return DataRow(
                  color: MaterialStateProperty.resolveWith<Color?>((states) {
                    if (isAdmin) return Colors.green.shade50;
                    return null;
                  }),
                  cells: [
                    DataCell(
                      Text(
                        isAdmin ? '${user.userName} (أنت)' : user.userName,
                        style: TextStyle(
                          fontWeight: isAdmin
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                    DataCell(Text(_formatCurrency(user.principalBalance))),
                    DataCell(Text(_formatCurrency(user.grossProfit))),
                    DataCell(
                      Text(
                        _formatCurrency(user.commissionDeducted),
                        style: TextStyle(
                          color: user.commissionDeducted > 0
                              ? Colors.red
                              : Colors.grey,
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        _formatCurrency(user.netProfitAdded),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, Color color) {
    return Card(
      color: color,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _getProviderAndRun(bool isActual) {
    if (_formKey.currentState!.validate()) {
      final inputRate = double.parse(_rateController.text);
      final decimalRate = inputRate / 100;

      final provider = Provider.of<ProfitProvider>(context, listen: false);
      if (isActual) {
        _showConfirmDialog(provider, decimalRate);
      } else {
        provider.runSimulation(
          trackType: _selectedTrack,
          grossProfitRate: decimalRate,
        );
      }
    }
  }

  void _handleSimulation() => _getProviderAndRun(false);
  void _handleDistribution() => _getProviderAndRun(true);

  void _showConfirmDialog(ProfitProvider provider, double rate) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('⚠️ تأكيد الضخ المالي الفعلي'),
        content: Text(
          'هل أنت متأكد من اعتماد ونشر هذه الأرباح بنسبة ${_formatPercent(rate)} للمسار المحدد؟ سيتم تحديث أرصدة المحافظ الفعلية وتوليد سندات مالية فوراً ولا يمكن التراجع!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await provider.runActualDistribution(
                trackType: _selectedTrack,
                grossProfitRate: rate,
              );
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      '🚀 تم ترحيل وضخ الأرباح للمحفظات وتوليد السندات بنجاح تام!',
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
                provider.resetData();
                _rateController.clear();
                // تحديث البيانات الإحصائية وشام كاش بعد الضخ مباشرة
                Provider.of<UserProvider>(context, listen: false).loadWallets();
              }
            },
            child: const Text('نعم، اضخ الأرباح الآن'),
          ),
        ],
      ),
    );
  }
}
