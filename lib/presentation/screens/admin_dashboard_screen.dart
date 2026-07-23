import 'package:arrpa7y/presentation/screens/sham_cash_gateway_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// 👈 استيرادات نسبية سليمة 100%
import '../../logic/user_provider.dart';
import '../../logic/auth_provider.dart';
import '../../core/theme/app_colors.dart';
import '../widgets/app_ui.dart';
import 'ai_assistant_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  final Function(int) onNavigateToTab;

  const AdminDashboardScreen({super.key, required this.onNavigateToTab});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProvider>().loadWallets();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final userProvider = context.watch<UserProvider>();
    final theme = Theme.of(context);

    final totalWallets = userProvider.wallets.length;
    final totalPrincipal = userProvider.totalSystemPrincipal;
    final totalProfits = userProvider.totalSystemProfitsEarned;
    final shamInfo = userProvider.shamCashInfo;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('مركز القيادة والإدارة'),
            Text(
              'مرحباً بك، ${auth.adminName ?? "المدير"} • تحكم كامل بالنظام',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
      body: AppPage(
        child: RefreshIndicator(
          onRefresh: () => userProvider.loadWallets(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1️⃣ كارت الترحيب والحالة العامة
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: AppColors.heroGradient(theme.brightness),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      const AppBrandMark(size: 50, onDark: true),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'نظام الشامي المالي',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'البوابة المالية: $totalWallets محفظة نشطة',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 2️⃣ قسم الإحصائيات
                const AppSectionHeader(
                  title: 'المؤشرات الإحصائية المباشرة',
                  subtitle: 'متابعة لحظية لرؤوس الأموال والأرباح',
                  icon: Icons.insights_rounded,
                ),
                const SizedBox(height: 12),

                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _buildHalfWidthCard(
                      context,
                      title: 'إجمالي المستثمرين',
                      value: '$totalWallets مستثمر',
                      icon: Icons.groups_rounded,
                      accent: AppColors.info,
                    ),
                    _buildHalfWidthCard(
                      context,
                      title: 'رؤوس الأموال',
                      value: '\$${totalPrincipal.toStringAsFixed(2)}',
                      icon: Icons.account_balance_wallet_rounded,
                      accent: AppColors.emerald,
                    ),
                    _buildHalfWidthCard(
                      context,
                      title: 'الأرباح الموزعة',
                      value: '\$${totalProfits.toStringAsFixed(2)}',
                      icon: Icons.trending_up_rounded,
                      accent: AppColors.gold,
                    ),
                    _buildHalfWidthCard(
                      context,
                      title: 'سيولة ShamCash',
                      value: shamInfo != null ? 'متصل ومحدث' : 'جاري التحقق...',
                      icon: Icons.payments_rounded,
                      accent: AppColors.success,
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // 3️⃣ أدوات التحكم السريع
                const AppSectionHeader(
                  title: 'أدوات التحكم السريع بالنظام',
                  subtitle: 'وصول مباشر لكافة الميزات والأقسام',
                  icon: Icons.grid_view_rounded,
                ),
                const SizedBox(height: 12),

                GridView.count(
                  crossAxisCount: MediaQuery.of(context).size.width > 600
                      ? 3
                      : 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.3,
                  children: [
                    _buildActionTile(
                      context,
                      title: 'بوابة الشامي المالية',
                      subtitle: 'إيداع وسحب وتوجيه الرصيد',
                      icon: Icons.account_balance_wallet_rounded,
                      color: AppColors.emerald,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ShamCashGatewayScreen(),
                          ),
                        );
                      },
                    ),
                    _buildActionTile(
                      context,
                      title: 'المساعد الذكي (AI)',
                      subtitle: 'تحليل البيانات وإجراء الحسابات',
                      icon: Icons.auto_awesome_rounded,
                      color: AppColors.gold,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AiAssistantScreen(),
                          ),
                        );
                      },
                    ),
                    _buildActionTile(
                      context,
                      title: 'محرك الأرباح',
                      subtitle: 'توزيع وضخ الأرباح',
                      icon: Icons.query_stats_rounded,
                      color: AppColors.emerald,
                      onTap: () => widget.onNavigateToTab(1),
                    ),
                    _buildActionTile(
                      context,
                      title: 'إدارة المستثمرين',
                      subtitle: 'الحسابات والمحافظ',
                      icon: Icons.people_alt_rounded,
                      color: AppColors.info,
                      onTap: () => widget.onNavigateToTab(2),
                    ),
                    _buildActionTile(
                      context,
                      title: 'كشف السندات',
                      subtitle: 'سجل الإيداع والسحب',
                      icon: Icons.receipt_long_rounded,
                      color: AppColors.gold,
                      onTap: () => widget.onNavigateToTab(3),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHalfWidthCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color accent,
  }) {
    final width = MediaQuery.of(context).size.width;
    final cardWidth = (width - 44) / 2;
    return SizedBox(
      width: cardWidth,
      child: AppMetricCard(
        title: title,
        value: value,
        icon: icon,
        accent: accent,
      ),
    );
  }

  Widget _buildActionTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const Spacer(),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
