import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../logic/profit_provider.dart';
import '../../data/models/profit_simulation_model.dart';
import '../../logic/user_provider.dart';
import '../../core/theme/app_colors.dart';
import '../widgets/app_ui.dart';

class ProfitSimulationScreen extends StatefulWidget {
  const ProfitSimulationScreen({super.key});

  @override
  State<ProfitSimulationScreen> createState() => _ProfitSimulationScreenState();
}

class _ProfitSimulationScreenState extends State<ProfitSimulationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _baseRateController =
      TextEditingController(); // متحكم نسبة الأرباح الأساسية
  final _managerExtraRateController =
      TextEditingController(); // متحكم النسبة الإضافية المتغيرة للمدير

  String _selectedTrack = 'BITCOIN';

  final List<Map<String, String>> _tracks = [
    {'value': 'BITCOIN', 'label': 'تداول البتكوين'},
    {'value': 'ORGANIZATIONS', 'label': 'استثمار المنظمات (أبو جميل)'},
  ];

  @override
  void initState() {
    super.initState();
    // استدعاء آمن لمرة واحدة عند الإقلاع لتجنب الـ Infinite Loop
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        userProvider.loadWallets();
      }
    });
  }

  @override
  void dispose() {
    _baseRateController.dispose();
    _managerExtraRateController.dispose();
    super.dispose();
  }

  String _formatCurrency(double amount) {
    return '\$${amount.toStringAsFixed(2)}';
  }

  String _formatPercent(double rate) {
    return '${(rate * 100).toStringAsFixed(2)}%';
  }

  // ويدجت بناء كرت سيولة شام كاش الحية لمؤسسة الشامي
  Widget _buildShamCashStatusCard(UserProvider userProvider) {
    final info = userProvider.shamCashInfo;

    if (info == null || userProvider.isLoading) {
      final progress = userProvider.loadingProgress;
      final percentage = (progress * 100).toInt();

      return Card(
        color: const Color(0xFF0B433C),
        margin: const EdgeInsets.only(bottom: 20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    userProvider.loadingMessage.isEmpty
                        ? '🔌 جاري الاتصال...'
                        : userProvider.loadingMessage,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    '%$percentage',
                    style: const TextStyle(
                      color: Colors.greenAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress > 0
                      ? progress
                      : null, // يتحول إلى شريط محدد النسبة تلقائياً
                  minHeight: 8,
                  backgroundColor: Colors.white12,
                  color: Colors.greenAccent,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final balances = info['balances'] as List? ?? [];
    final merchantName = info['merchantName'] ?? 'مؤسسة الشامي';

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [AppColors.shamCash, Color(0xFF0B433C)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white12),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: .2),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.account_balance_wallet,
                        color: Colors.greenAccent,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'السيولة الحية (ShamCash)',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  constraints: const BoxConstraints(maxWidth: 120),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    merchantName.toString(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
            Wrap(
              spacing: 24,
              runSpacing: 14,
              children: balances.map<Widget>((bal) {
                final String currency = bal['currency'] ?? '';
                final double amount =
                    (bal['amount'] as num?)?.toDouble() ?? 0.0;

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

                Color valueColor = Colors.greenAccent;
                if (currency == 'SYP') {
                  valueColor = Colors.amberAccent;
                } else if (currency == 'EUR') {
                  valueColor = Colors.lightBlueAccent;
                }

                return ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 112),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // لوحة أرباح وعمولات المدير الصافية بعد توزيع البونصات
  Widget _buildManagerProfitDashboard(ProfitProvider profitProvider) {
    final stats = profitProvider.managerProfitStats;
    return Card(
      margin: const EdgeInsets.only(top: 16, bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.analytics_rounded, color: Colors.amber),
                SizedBox(width: 8),
                Text(
                  'جدول أرباح المدير والعمولات الإضافية',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildStatRow(
              'إجمالي أرباح المسار (الربح العام):',
              _formatCurrency(stats['trackBaseProfit'] ?? 0.0),
              Colors.white,
            ),
            _buildStatRow(
              'إجمالي العمولة الإضافية الواردة لك (المتغيرة):',
              _formatCurrency(stats['managerExtraEarned'] ?? 0.0),
              Colors.greenAccent,
            ),
            _buildStatRow(
              'بونص الإحالة المستقطع والموزع للناس:',
              '-\$${(stats['totalDistributedBonus'] ?? 0.0).toStringAsFixed(2)}',
              Colors.redAccent,
            ),
            const Divider(color: Colors.white30, height: 20),
            _buildStatRow(
              'صافي أرباح المدير المحفوظة (المتبقي لك):',
              _formatCurrency(stats['managerNetProfit'] ?? 0.0),
              Colors.amberAccent,
              isBold: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(
    String label,
    String value,
    Color valueColor, {
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade300),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profitProvider = Provider.of<ProfitProvider>(context);
    final userProvider = Provider.of<UserProvider>(context, listen: true);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('لوحة الأرباح'),
            Text(
              'مراقبة السيولة ومحاكاة التوزيع الحية',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
      body: AppPage(
        padding: EdgeInsets.zero,
        child: RefreshIndicator(
          onRefresh: () async {
            await userProvider.loadWallets();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildShamCashStatusCard(userProvider),

                  const AppSectionHeader(
                    title: 'المشهد المالي العام',
                    subtitle: 'نظرة مباشرة على أداء المؤسسة',
                    icon: Icons.dashboard_customize_outlined,
                  ),
                  const SizedBox(height: 14),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;
                      final cardWidth = width >= 700 ? (width - 12) / 2 : width;
                      return Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          SizedBox(
                            width: cardWidth,
                            child: _buildStatCard(
                              title: 'إجمالي رؤوس الأموال',
                              value:
                                  '\$${userProvider.totalSystemPrincipal.toStringAsFixed(2)}',
                              color: AppColors.info,
                              icon: Icons.account_balance_wallet_rounded,
                            ),
                          ),
                          SizedBox(
                            width: cardWidth,
                            child: _buildStatCard(
                              title: 'إجمالي الأرباح الموزعة',
                              value:
                                  '\$${userProvider.totalSystemProfitsEarned.toStringAsFixed(2)}',
                              color: AppColors.success,
                              icon: Icons.trending_up_rounded,
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  _buildDistributionSection(
                    context,
                    userProvider.trackLiquidityDistribution,
                  ),

                  const SizedBox(height: 24),
                  const AppSectionHeader(
                    title: 'محرك توزيع الأرباح والبونص',
                    subtitle: 'اضبط نسب أرباح المسار والعمولة الإضافية',
                    icon: Icons.tune_rounded,
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        children: [
                          // 1. القائمة المنسدلة لاختيار المسار
                          DropdownButtonFormField<String>(
                            value: _selectedTrack,
                            isExpanded: true,
                            style: const TextStyle(
                              fontSize: 13,
                            ), // 👈 تصغير خط النص المختار
                            decoration: const InputDecoration(
                              labelText: 'اختر مسار الاستثمار المستهدف',
                              labelStyle: TextStyle(
                                fontSize: 12,
                              ), // 👈 تصغير خط العنوان
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.trending_up, size: 20),
                            ),
                            items: _tracks.map((track) {
                              return DropdownMenuItem(
                                value: track['value'],
                                child: Text(
                                  track['label']!,
                                  style: const TextStyle(
                                    fontSize: 13,
                                  ), // 👈 تصغير خط الخيارات
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (val) =>
                                setState(() => _selectedTrack = val!),
                          ),
                          const SizedBox(height: 16),

                          // 2. حقول إدخال النسب المالية
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _baseRateController,
                                  style: const TextStyle(
                                    fontSize: 13,
                                  ), // 👈 تصغير خط الإدخال
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  decoration: const InputDecoration(
                                    labelText: 'الربح العام للجميع (%)',
                                    labelStyle: TextStyle(
                                      fontSize: 11,
                                    ), // 👈 تصغير خط العنوان
                                    hintText: 'مثال: 5',
                                    hintStyle: TextStyle(fontSize: 11),
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.percent, size: 18),
                                  ),
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty)
                                      return 'أدخل النسبة';
                                    final rate = double.tryParse(val);
                                    if (rate == null || rate <= 0 || rate > 100)
                                      return 'غير صالح';
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _managerExtraRateController,
                                  style: const TextStyle(
                                    fontSize: 10,
                                  ), // 👈 تصغير خط الإدخال
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  decoration: const InputDecoration(
                                    labelText: 'عمولتك الإضافية (%)',
                                    labelStyle: TextStyle(
                                      fontSize: 10,
                                    ), // 👈 تصغير خط العنوان
                                    hintText: 'مثال: 0.5',
                                    hintStyle: TextStyle(fontSize: 10),
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(
                                      Icons.add_chart_rounded,
                                      size: 18,
                                    ),
                                  ),
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty)
                                      return 'أدخل النسبة';
                                    final rate = double.tryParse(val);
                                    if (rate == null || rate < 0 || rate > 100)
                                      return 'غير صالح';
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // 3. أزرار المحاكاة والضخ
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final simulationButton = OutlinedButton.icon(
                                onPressed: profitProvider.isLoading
                                    ? null
                                    : _handleSimulation,
                                icon: const Icon(
                                  Icons.analytics_outlined,
                                  size: 18,
                                ),
                                label: const Text(
                                  'تشغيل المحاكاة',
                                  style: TextStyle(fontSize: 15),
                                ),
                              );
                              final distributionButton = ElevatedButton.icon(
                                onPressed: profitProvider.isLoading
                                    ? null
                                    : _handleDistribution,
                                icon: const Icon(
                                  Icons.account_balance_wallet,
                                  size: 18,
                                ),
                                label: const Text(
                                  'اعتماد وضخ فعلي',
                                  style: TextStyle(fontSize: 15),
                                ),
                              );
                              if (constraints.maxWidth < 430) {
                                return Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    simulationButton,
                                    const SizedBox(height: 10),
                                    distributionButton,
                                  ],
                                );
                              }
                              return Row(
                                children: [
                                  Expanded(child: simulationButton),
                                  const SizedBox(width: 12),
                                  Expanded(child: distributionButton),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  if (!profitProvider.isLoading)
                    _buildManagerProfitDashboard(profitProvider),

                  if (profitProvider.isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (profitProvider.errorMessage != null)
                    AppStateView(
                      kind: AppStateKind.error,
                      message: profitProvider.errorMessage,
                    )
                  else if (profitProvider
                          .managerProfitStats['trackBaseProfit']! >
                      0)
                    _buildFinancialResults(profitProvider),
                ],
              ),
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
    return AppMetricCard(title: title, value: value, icon: icon, accent: color);
  }

  Widget _buildDistributionSection(
    BuildContext context,
    Map<String, double> distribution,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.pie_chart_outline_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'توزيع السيولة حسب المسار',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
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
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        color: Theme.of(context).colorScheme.primary,
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(8),
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

  Widget _buildFinancialResults(ProfitProvider provider) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final baseRate = double.tryParse(_baseRateController.text) ?? 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'كشف أرباح وبونصات المشتركين الافتراضي:',
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
                    'الربح الأساسي',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'بونص الإحالة',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'إجمالي المستحق',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
              rows: userProvider.wallets
                  .where((w) => w.trackType == _selectedTrack)
                  .map((wallet) {
                    final isAdmin = wallet.userRole == 'ADMIN';

                    final double grossProfit =
                        wallet.principalBalance * (baseRate / 100);
                    double bonusRate =
                        0.0; // سيقرأ البونص التابع له تلقائياً بحسب هيكليتك الجديدة
                    double bonusProfit = wallet.principalBalance * bonusRate;
                    double netProfitAdded = grossProfit + bonusProfit;

                    return DataRow(
                      color: WidgetStateProperty.resolveWith<Color?>((states) {
                        if (isAdmin) {
                          return Theme.of(
                            context,
                          ).colorScheme.primaryContainer.withValues(alpha: .35);
                        }
                        return null;
                      }),
                      cells: [
                        DataCell(
                          Text(
                            isAdmin
                                ? '${wallet.userName} (أنت)'
                                : wallet.userName,
                            style: TextStyle(
                              fontWeight: isAdmin
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                        DataCell(
                          Text(_formatCurrency(wallet.principalBalance)),
                        ),
                        DataCell(Text(_formatCurrency(grossProfit))),
                        DataCell(
                          Text(
                            _formatCurrency(bonusProfit),
                            style: const TextStyle(
                              color: Colors.teal,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            _formatCurrency(netProfitAdded),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ),
                      ],
                    );
                  })
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }

  void _getProviderAndRun(bool isActual) {
    if (_formKey.currentState!.validate()) {
      final baseRate = double.parse(_baseRateController.text) / 100;
      final managerExtraRate =
          double.parse(_managerExtraRateController.text) / 100;

      final provider = Provider.of<ProfitProvider>(context, listen: false);
      if (isActual) {
        _showConfirmDialog(provider, baseRate, managerExtraRate);
      } else {
        provider.distributeProfitsWithBonus(
          trackType: _selectedTrack,
          baseProfitRate: baseRate,
          managerExtraRate: managerExtraRate,
        );
      }
    }
  }

  void _handleSimulation() => _getProviderAndRun(false);
  void _handleDistribution() => _getProviderAndRun(true);

  void _showConfirmDialog(
    ProfitProvider provider,
    double baseRate,
    double extraRate,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(
          Icons.warning_amber_rounded,
          color: AppColors.warning,
          size: 34,
        ),
        title: const Text('تأكيد الضخ المالي الفعلي'),
        content: Text(
          'هل أنت متأكد من اعتماد ونشر الأرباح بنسبة ${_formatPercent(baseRate)} مع عمولة متغيرة ${_formatPercent(extraRate)}؟ سيتم شحن محافظ المشتركين وتوليد السندات والبونصات فوراً في فيربيس ولا يمكن التراجع!',
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

              await provider.distributeProfitsWithBonus(
                trackType: _selectedTrack,
                baseProfitRate: baseRate,
                managerExtraRate: extraRate,
              );

              if (provider.errorMessage == null && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      '🎉 تم ترحيل الأرباح الأساسية والبونصات للمحافظ سحابياً بنجاح.',
                    ),
                  ),
                );
                _baseRateController.clear();
                _managerExtraRateController.clear();
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
