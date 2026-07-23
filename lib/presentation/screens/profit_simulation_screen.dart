import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../logic/profit_provider.dart';
import '../../data/models/profit_simulation_model.dart';
import '../../data/models/wallet_model.dart';
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
  final _baseRateController = TextEditingController();
  final _managerExtraRateController = TextEditingController();
  final _managerDeductionRateController = TextEditingController();

  String _selectedTrack = 'BITCOIN';
  String? _selectedRecipientUserId;

  final List<Map<String, String>> _tracks = [
    {'value': 'BITCOIN', 'label': 'تداول البتكوين'},
    {'value': 'ORGANIZATIONS', 'label': 'استثمار المنظمات (أبو جميل)'},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        userProvider.loadWallets();
        userProvider.loadShamCashBalances();
      }
    });
  }

  @override
  void dispose() {
    _baseRateController.dispose();
    _managerExtraRateController.dispose();
    _managerDeductionRateController.dispose();
    super.dispose();
  }

  String _formatCurrency(double amount) {
    return '\$${amount.toStringAsFixed(2)}';
  }

  String _formatPercent(double rate) {
    return '${(rate * 100).toStringAsFixed(2)}%';
  }

  // 👑 دالة جلب معرف الأدمن الافتراضي من المحافظ
  String? _getDefaultAdminUserId(List<WalletModel> wallets) {
    if (wallets.isEmpty) return null;
    final adminWallet = wallets.cast<WalletModel?>().firstWhere(
      (w) => w?.userRole == 'ADMIN',
      orElse: () => wallets.first,
    );
    return adminWallet?.userId;
  }

  Widget _buildShamCashStatusCard(UserProvider userProvider) {
    final info = userProvider.shamCashInfo;

    if (info == null || userProvider.isShamCashLoading) {
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
                  value: progress > 0 ? progress : null,
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
                  'ملخص أرباح وعمولات الإدارة',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildStatRow(
              'إجمالي أرباح المسار الخام:',
              _formatCurrency(stats['trackBaseProfit'] ?? 0.0),
              Colors.white,
            ),
            _buildStatRow(
              'إجمالي الخصومات المقتطعة للإدارة:',
              '+${_formatCurrency(stats['totalDeductionsEarned'] ?? 0.0)}',
              Colors.greenAccent,
            ),
            _buildStatRow(
              'إجمالي العمولة الإضافية الإدارية:',
              '+${_formatCurrency(stats['managerExtraEarned'] ?? 0.0)}',
              Colors.lightBlueAccent,
            ),
            _buildStatRow(
              'بونص الإحالة المستقطع والموزع للناس:',
              '-\$${(stats['totalDistributedBonus'] ?? 0.0).toStringAsFixed(2)}',
              Colors.redAccent,
            ),
            const Divider(color: Colors.white30, height: 20),
            _buildStatRow(
              'صافي الأرباح والعمولات المتبقية للحساب المختار:',
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
        automaticallyImplyLeading: false,
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
        actions: [
          PopupMenuButton<String>(
            tooltip: 'خيارات الإدارة',
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (val) {
              if (val == 'reset') _showResetProfitsDialog(context);
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'reset',
                child: ListTile(
                  leading: Icon(
                    Icons.restart_alt_rounded,
                    color: AppColors.danger,
                  ),
                  title: Text(
                    'تصفير كافة الأرباح السابقة',
                    style: TextStyle(
                      color: AppColors.danger,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: AppPage(
        padding: EdgeInsets.zero,
        child: RefreshIndicator(
          onRefresh: () async {
            await userProvider.refreshAllData();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    color: AppColors.danger.withValues(alpha: 0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: AppColors.danger.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: AppColors.danger,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'تصفية وإعادة ضبط الأرباح',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: AppColors.danger,
                                ),
                              ),
                            ],
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.danger,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            onPressed: () => _showResetProfitsDialog(context),
                            icon: const Icon(
                              Icons.restart_alt_rounded,
                              size: 18,
                            ),
                            label: const Text(
                              'تصفير الأرباح',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

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
                    title: 'محرك توزيع الأرباح والعمولات',
                    subtitle: 'اضبط نسب أرباح المسار والخصم والعمولة الإضافية',
                    icon: Icons.tune_rounded,
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        children: [
                          DropdownButtonFormField<String>(
                            value: _selectedTrack,
                            isExpanded: true,
                            style: const TextStyle(fontSize: 13),
                            decoration: const InputDecoration(
                              labelText: 'اختر مسار الاستثمار المستهدف',
                              labelStyle: TextStyle(fontSize: 12),
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.trending_up, size: 20),
                            ),
                            items: _tracks.map((track) {
                              return DropdownMenuItem(
                                value: track['value'],
                                child: Text(
                                  track['label']!,
                                  style: const TextStyle(fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (val) =>
                                setState(() => _selectedTrack = val!),
                          ),
                          const SizedBox(height: 16),

                          // 2. 👈 القائمة المنسدلة لاختيار الحساب المستفيد (تحديد الأدمن كافتراضي تلقائي)
                          // 2. 👈 القائمة المنسدلة لاختيار الحساب المستفيد (تحديد الأدمن كافتراضي تلقائي)
                          Builder(
                            builder: (context) {
                              final Map<String, WalletModel> uniqueUsersMap =
                                  {};
                              for (var w in userProvider.wallets) {
                                if (!uniqueUsersMap.containsKey(w.userId)) {
                                  uniqueUsersMap[w.userId] = w;
                                }
                              }
                              final uniqueUsers = uniqueUsersMap.values
                                  .toList();

                              // 1. تحديد القيمة التي نريد استخدامها
                              String? targetId =
                                  _selectedRecipientUserId ??
                                  _getDefaultAdminUserId(uniqueUsers);

                              // 2. التحقق: هل القيمة المختارة موجودة فعلياً في القائمة؟
                              bool isValidValue =
                                  targetId != null &&
                                  uniqueUsers.any((u) => u.userId == targetId);

                              // 3. إذا لم تكن موجودة، نستخدم null لمنع الانهيار
                              final String? finalValue = isValidValue
                                  ? targetId
                                  : null;

                              return DropdownButtonFormField<String>(
                                value: finalValue, // 👈 القيمة الآمنة
                                isExpanded: true,
                                style: const TextStyle(fontSize: 13),
                                decoration: const InputDecoration(
                                  labelText:
                                      'الحساب المستفيد من الصافي المتبقي',
                                  labelStyle: TextStyle(fontSize: 12),
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(
                                    Icons.person_pin_rounded,
                                    size: 20,
                                    color: AppColors.gold,
                                  ),
                                ),
                                items: uniqueUsers.map((w) {
                                  return DropdownMenuItem<String>(
                                    value: w.userId,
                                    child: Text(
                                      '${w.userName} ${w.userRole == 'ADMIN' ? '(مدير)' : ''}',
                                      style: const TextStyle(fontSize: 13),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) => setState(
                                  () => _selectedRecipientUserId = val,
                                ),
                                validator: (val) => val == null
                                    ? 'الرجاء اختيار الحساب المستفيد'
                                    : null,
                              );
                            },
                          ),
                          const SizedBox(height: 16),

                          TextFormField(
                            controller: _baseRateController,
                            style: const TextStyle(fontSize: 13),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText:
                                  'الربح العام الوارد للجميع (%) [إجباري]',
                              labelStyle: TextStyle(fontSize: 11),
                              hintText: 'مثال: 16',
                              hintStyle: TextStyle(fontSize: 11),
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.percent, size: 18),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'أدخل النسبة العامة';
                              }
                              final rate = double.tryParse(val);
                              if (rate == null || rate <= 0 || rate > 100) {
                                return 'نسبة غير صالحة';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),

                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _managerDeductionRateController,
                                  style: const TextStyle(fontSize: 12),
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  decoration: const InputDecoration(
                                    labelText:
                                        'خصمك من الربح العام (%) [اختياري]',
                                    labelStyle: TextStyle(fontSize: 10),
                                    hintText: 'مثال: 2 (اختياري)',
                                    hintStyle: TextStyle(fontSize: 10),
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(
                                      Icons.content_cut_rounded,
                                      size: 18,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextFormField(
                                  controller: _managerExtraRateController,
                                  style: const TextStyle(fontSize: 12),
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  decoration: const InputDecoration(
                                    labelText: 'عمولتك الإضافية (%) [اختياري]',
                                    labelStyle: TextStyle(fontSize: 10),
                                    hintText: 'مثال: 0.5 (اختياري)',
                                    hintStyle: TextStyle(fontSize: 10),
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(
                                      Icons.add_chart_rounded,
                                      size: 18,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

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
    final globalDeductionRate =
        double.tryParse(_managerDeductionRateController.text) ?? 0.0;
    final stats = provider.managerProfitStats;
    final double netAdminProfit = stats['managerNetProfit'] ?? 0.0;

    final filteredWallets = userProvider.wallets
        .where((w) => w.trackType == _selectedTrack)
        .toList();

    // 👈 المعرف المستهدف (المختار أو الأدمن الافتراضي)
    final effectiveTargetUserId =
        _selectedRecipientUserId ??
        _getDefaultAdminUserId(userProvider.wallets);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'كشف تفاصيل الأرباح والخصومات والبونصات للمشتركين:',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
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
                    'الربح العام',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'اقتطاع الإدارة',
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
              rows: filteredWallets.map((wallet) {
                final bool isSelectedTarget =
                    wallet.userId == effectiveTargetUserId;
                final double grossProfit =
                    wallet.principalBalance * (baseRate / 100);

                return DataRow(
                  color: WidgetStateProperty.resolveWith<Color?>((states) {
                    if (isSelectedTarget) {
                      return AppColors.goldSoft.withValues(alpha: 0.6);
                    }
                    return null;
                  }),
                  cells: [
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isSelectedTarget) ...[
                            const Icon(
                              Icons.stars_rounded,
                              color: AppColors.gold,
                              size: 18,
                            ),
                            const SizedBox(width: 4),
                          ],
                          Text(
                            isSelectedTarget
                                ? '${wallet.userName} (المستفيد الإداري)'
                                : wallet.userName,
                            style: TextStyle(
                              fontWeight: isSelectedTarget
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                    DataCell(Text(_formatCurrency(wallet.principalBalance))),
                    DataCell(Text(_formatCurrency(grossProfit))),
                    DataCell(
                      FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('Users')
                            .doc(wallet.userId)
                            .get(),
                        builder: (context, snapshot) {
                          double deductionRate = globalDeductionRate;
                          if (snapshot.hasData) {
                            final userData =
                                snapshot.data!.data()
                                    as Map<String, dynamic>? ??
                                {};
                            if (userData['customDeductionRate'] != null) {
                              deductionRate =
                                  (userData['customDeductionRate'] as num)
                                      .toDouble();
                            }
                          }
                          final double deductionAmount =
                              wallet.principalBalance * (deductionRate / 100);

                          return Text(
                            '-${_formatCurrency(deductionAmount)}',
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        },
                      ),
                    ),
                    DataCell(
                      FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('Users')
                            .doc(wallet.userId)
                            .get(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) return const Text('\$0.00');
                          final userData =
                              snapshot.data!.data() as Map<String, dynamic>? ??
                              {};
                          final double bonusRate =
                              (userData['referralBonusRate'] as num?)
                                  ?.toDouble() ??
                              0.0;
                          final double bonusAmount =
                              wallet.principalBalance * (bonusRate / 100);

                          return Text(
                            '+${_formatCurrency(bonusAmount)}',
                            style: const TextStyle(
                              color: Colors.teal,
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        },
                      ),
                    ),
                    DataCell(
                      FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('Users')
                            .doc(wallet.userId)
                            .get(),
                        builder: (context, snapshot) {
                          double bonusAmount = 0.0;
                          double deductionRate = globalDeductionRate;

                          if (snapshot.hasData) {
                            final userData =
                                snapshot.data!.data()
                                    as Map<String, dynamic>? ??
                                {};
                            final double bonusRate =
                                (userData['referralBonusRate'] as num?)
                                    ?.toDouble() ??
                                0.0;
                            bonusAmount =
                                wallet.principalBalance * (bonusRate / 100);

                            if (userData['customDeductionRate'] != null) {
                              deductionRate =
                                  (userData['customDeductionRate'] as num)
                                      .toDouble();
                            }
                          }

                          final double deductionAmount =
                              wallet.principalBalance * (deductionRate / 100);
                          final double netBaseProfit =
                              grossProfit - deductionAmount;

                          final double extraNet = isSelectedTarget
                              ? netAdminProfit
                              : 0.0;
                          final double totalDue =
                              netBaseProfit + bonusAmount + extraNet;

                          return Text(
                            _formatCurrency(totalDue),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isSelectedTarget
                                  ? AppColors.emerald
                                  : Colors.green,
                            ),
                          );
                        },
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

  void _getProviderAndRun(bool isActual) {
    if (_formKey.currentState!.validate()) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      // 👈 اختيار الأدمن الافتراضي تلقائياً إن لم يُحدد حساب
      final targetUserId =
          _selectedRecipientUserId ??
          _getDefaultAdminUserId(userProvider.wallets);

      if (targetUserId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر العثور على حساب إداري مستفيد.')),
        );
        return;
      }

      final baseRate = double.parse(_baseRateController.text) / 100;
      final managerExtraRate =
          (double.tryParse(_managerExtraRateController.text.trim()) ?? 0.0) /
          100;
      final managerDeductionRate =
          (double.tryParse(_managerDeductionRateController.text.trim()) ??
              0.0) /
          100;

      final provider = Provider.of<ProfitProvider>(context, listen: false);
      if (isActual) {
        _showConfirmDialog(
          provider,
          baseRate,
          managerExtraRate,
          managerDeductionRate,
          targetUserId,
        );
      } else {
        provider.distributeProfitsWithBonus(
          trackType: _selectedTrack,
          baseProfitRate: baseRate,
          managerExtraRate: managerExtraRate,
          managerDeductionRate: managerDeductionRate,
          targetUserId: targetUserId,
          isSimulation: true,
        );
      }
    }
  }

  void _handleSimulation() => _getProviderAndRun(false);
  void _handleDistribution() => _getProviderAndRun(true);

  void _showResetProfitsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(
          Icons.warning_amber_rounded,
          color: AppColors.danger,
          size: 36,
        ),
        title: const Text('تصفير ومسح الأرباح السابقة؟'),
        content: const Text(
          'سيتم إعادة رصيد أرباح جميع المحافظ والمستثمرين إلى \$0.00، وحذف كافة سندات الأرباح والبونصات المسجلة. هل أنت متأكد؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final profitProvider = Provider.of<ProfitProvider>(
                context,
                listen: false,
              );
              final userProvider = Provider.of<UserProvider>(
                context,
                listen: false,
              );

              final success = await profitProvider.resetAllProfits();

              if (context.mounted && success) {
                await userProvider.loadWallets();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      '🎉 تم مسح وإعادة تصفير جميع الأرباح والبونصات بنجاح.',
                    ),
                  ),
                );
              }
            },
            child: const Text('نعم، صفّر جميع الأرباح الآن'),
          ),
        ],
      ),
    );
  }

  void _showConfirmDialog(
    ProfitProvider provider,
    double baseRate,
    double extraRate,
    double deductionRate,
    String targetUserId,
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
          'هل أنت متأكد من اعتماد ونشر الأرباح بنسبة ${_formatPercent(baseRate)}، مع خصم إداري ${_formatPercent(deductionRate)} وعمولة إضافية ${_formatPercent(extraRate)}؟ سيتم شحن المحافظ وتحويل الصافي للحساب المختار فوراً ولا يمكن التراجع!',
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
                managerDeductionRate: deductionRate,
                targetUserId: targetUserId,
                isSimulation: false,
              );

              if (provider.errorMessage == null && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      '🎉 تم ترحيل الأرباح والخصومات والبونصات والصافي للحساب المختار سحابياً بنجاح.',
                    ),
                  ),
                );
                _baseRateController.clear();
                _managerExtraRateController.clear();
                _managerDeductionRateController.clear();
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
