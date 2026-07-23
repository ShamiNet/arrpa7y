import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../logic/transaction_provider.dart';
import '../../logic/user_provider.dart';
import '../../data/models/transaction_model.dart';
import '../../core/theme/app_colors.dart';
import '../widgets/app_ui.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TransactionProvider>(
        context,
        listen: false,
      ).loadTransactions();
      Provider.of<UserProvider>(context, listen: false).loadWallets();
    });
  }

  @override
  Widget build(BuildContext context) {
    final txProvider = context.watch<TransactionProvider>();

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        automaticallyImplyLeading:
            false, // 👈 إلغاء وإخفاء أيقونة الحساب/المظهر في أعلى الشاشة
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('السندات والحركات المالية'),
            Text(
              'سجل موحّد وتقارير تفصيلية',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'توليد تقرير مالي',
            icon: const Icon(Icons.summarize_outlined, color: AppColors.gold),
            onPressed: () => _showReportGeneratorDialog(context),
          ),
          IconButton(
            tooltip: 'تصفية جميع السندات',
            icon: const Icon(
              Icons.delete_sweep_rounded,
              color: AppColors.danger,
            ),
            onPressed: () => _confirmClearAllTransactions(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag:
            'transaction_history_fab', // 👈 أضف هذا السطر لمنع تكرار الـ Hero Tag
        onPressed: () => _showActionDialog(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('سند جديد'),
      ),
      body: AppPage(child: _buildTxList(txProvider)),
    );
  }

  Widget _buildTxList(TransactionProvider provider) {
    if (provider.isLoading && provider.transactions.isEmpty) {
      return const AppStateView(kind: AppStateKind.loading);
    }
    if (provider.errorMessage != null && provider.transactions.isEmpty) {
      return AppStateView(
        kind: AppStateKind.error,
        message: provider.errorMessage,
        onRetry: provider.loadTransactions,
      );
    }

    final deposits = provider.transactions
        .where((transaction) => transaction.type == 'DEPOSIT')
        .fold<double>(0, (sum, transaction) => sum + transaction.amount);
    final withdrawals = provider.transactions
        .where(
          (transaction) =>
              transaction.type == 'WITHDRAW' ||
              transaction.type == 'WITHDRAWAL',
        )
        .fold<double>(0, (sum, transaction) => sum + transaction.amount);

    return RefreshIndicator(
      onRefresh: provider.loadTransactions,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🎯 1. لوحة أزرار التحكم المباشرة والواضحة في الواجهة
                Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.gold,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: () =>
                                _showReportGeneratorDialog(context),
                            icon: const Icon(Icons.summarize_rounded, size: 18),
                            label: const Text(
                              'توليد تقرير',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.danger,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: provider.transactions.isEmpty
                                ? null
                                : () => _confirmClearAllTransactions(context),
                            icon: const Icon(
                              Icons.delete_sweep_rounded,
                              size: 18,
                            ),
                            label: const Text(
                              'مسح السجل بالكامل',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 2. كروت إحصائيات الإيداع والسحب
                LayoutBuilder(
                  builder: (context, constraints) {
                    final cardWidth = constraints.maxWidth >= 650
                        ? (constraints.maxWidth - 12) / 2
                        : constraints.maxWidth;
                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        SizedBox(
                          width: cardWidth,
                          child: AppMetricCard(
                            title: 'إجمالي الإيداعات',
                            value: '\$${deposits.toStringAsFixed(2)}',
                            icon: Icons.south_west_rounded,
                            accent: AppColors.success,
                          ),
                        ),
                        SizedBox(
                          width: cardWidth,
                          child: AppMetricCard(
                            title: 'إجمالي السحوبات',
                            value: '\$${withdrawals.toStringAsFixed(2)}',
                            icon: Icons.north_east_rounded,
                            accent: AppColors.danger,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 22),

                // 3. شريط عنوان القائمة
                AppSectionHeader(
                  title: 'أحدث الحركات المالية',
                  subtitle:
                      '${provider.transactions.length} سنداً مسجلاً • انقر للتفاصيل',
                  icon: Icons.history_rounded,
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),

          if (provider.transactions.isEmpty)
            const SliverToBoxAdapter(
              child: AppStateView(
                kind: AppStateKind.empty,
                title: 'لا توجد سندات مالية',
                message: 'أنشئ أول حركة إيداع أو سحب لتظهر هنا.',
              ),
            )
          else
            SliverList.builder(
              itemCount: provider.transactions.length,
              itemBuilder: (context, index) {
                final tx = provider.transactions[index];
                return FadeSlideIn(
                  delay: Duration(milliseconds: index * 25),
                  child: InkWell(
                    onTap: () => _showTransactionDetails(
                      context,
                      tx,
                    ), // 👈 انقر لعرض التفاصيل
                    borderRadius: BorderRadius.circular(16),
                    child: TransactionCard(
                      transaction: tx,
                      onShare: () => _shareSingleReceipt(tx),
                    ),
                  ),
                );
              },
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 84)),
        ],
      ),
    );
  }

  // 🔍 1. نافذة تفاصيل السند المنفرد وحذفه
  void _showTransactionDetails(BuildContext context, TransactionModel tx) {
    final isDeposit = tx.type == 'DEPOSIT';
    final isBonus = tx.type == 'BONUS';
    final isProfit = tx.type == 'PROFIT';

    Color statusColor = AppColors.success;
    String typeLabel = 'إيداع مالي';

    if (isBonus) {
      statusColor = Colors.teal;
      typeLabel = 'بونص إحالة';
    } else if (isProfit) {
      statusColor = AppColors.gold;
      typeLabel = 'أرباح استثمارية';
    } else if (!isDeposit) {
      statusColor = AppColors.danger;
      typeLabel = 'سحب مالي';
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isDeposit
                    ? Icons.arrow_downward_rounded
                    : Icons.arrow_upward_rounded,
                color: statusColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'تفاصيل السند المالي',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailTile(
                'المستثمر المعني:',
                tx.userName,
                Icons.person_outline,
              ),
              _buildDetailTile(
                'نوع الحركة المالية:',
                typeLabel,
                Icons.category_outlined,
                color: statusColor,
              ),
              _buildDetailTile(
                'المسار الاستثماري:',
                tx.trackType,
                Icons.show_chart_rounded,
              ),
              _buildDetailTile(
                'قيمة المبلغ:',
                '\$${tx.amount.toStringAsFixed(2)}',
                Icons.attach_money_rounded,
                isBold: true,
              ),
              _buildDetailTile(
                'التاريخ والوقت:',
                DateFormat('yyyy/MM/dd • hh:mm a').format(tx.date),
                Icons.schedule_rounded,
              ),
              _buildDetailTile(
                'بيان السند / الوصف:',
                tx.description.isEmpty ? 'لا يوجد بيان مسجل' : tx.description,
                Icons.notes_rounded,
              ),
              _buildDetailTile(
                'معرف السند المرجعي:',
                tx.id.isEmpty ? 'سند سحابي حي' : tx.id,
                Icons.qr_code_rounded,
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'مشاركة السند',
            icon: const Icon(Icons.share_rounded, color: AppColors.info),
            onPressed: () {
              Navigator.pop(ctx);
              _shareSingleReceipt(tx);
            },
          ),
          IconButton(
            tooltip: 'حذف هذا السند',
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: AppColors.danger,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _confirmDeleteSingleTransaction(context, tx);
            },
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailTile(
    String label,
    String value,
    IconData icon, {
    Color? color,
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 📊 2. نافذة إنشاء تقارير مفصلة وشاملة
  void _showReportGeneratorDialog(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final txProvider = Provider.of<TransactionProvider>(context, listen: false);

    String scope = 'ALL';
    String? selectedUserId;
    bool includeBonus = true;
    final deductionController = TextEditingController();
    final bonusOverrideController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setModalState) {
          return AlertDialog(
            icon: const Icon(
              Icons.summarize_rounded,
              color: AppColors.gold,
              size: 30,
            ),
            title: const Text('توليد تقرير مالي كلي / فرعي'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'نطاق التقرير المطلوب:',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'ALL',
                        label: Text('تقرير شامل'),
                        icon: Icon(Icons.dashboard_rounded),
                      ),
                      ButtonSegment(
                        value: 'USER',
                        label: Text('مستثمر محدد'),
                        icon: Icon(Icons.person_rounded),
                      ),
                    ],
                    selected: {scope},
                    onSelectionChanged: (val) =>
                        setModalState(() => scope = val.first),
                  ),
                  const SizedBox(height: 12),

                  if (scope == 'USER') ...[
                    DropdownButtonFormField<String>(
                      value: selectedUserId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'اختر المستثمر',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      items: userProvider.wallets.map((w) {
                        return DropdownMenuItem(
                          value: w.userId,
                          child: Text('${w.userName} (${w.trackType})'),
                        );
                      }).toList(),
                      onChanged: (val) =>
                          setModalState(() => selectedUserId = val),
                    ),
                    const SizedBox(height: 12),
                  ],

                  SwitchListTile(
                    title: const Text(
                      'إدراج البونص في التقرير',
                      style: TextStyle(fontSize: 12),
                    ),
                    value: includeBonus,
                    onChanged: (val) => setModalState(() => includeBonus = val),
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: deductionController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'نسبة الخصم (%)',
                            hintText: 'مثال: 2.0',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: bonusOverrideController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'نسبة البونص (%)',
                            hintText: 'مثال: 0.25',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('إلغاء'),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.ios_share_rounded, size: 18),
                label: const Text('توليد ومشاركة'),
                onPressed: () {
                  if (scope == 'USER' && selectedUserId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('اختر المستثمر أولاً')),
                    );
                    return;
                  }

                  Navigator.pop(ctx);
                  _generateAndShareReport(
                    txProvider: txProvider,
                    userProvider: userProvider,
                    scope: scope,
                    userId: selectedUserId,
                    includeBonus: includeBonus,
                    customDeduction:
                        double.tryParse(deductionController.text.trim()) ?? 0.0,
                    customBonus:
                        double.tryParse(bonusOverrideController.text.trim()) ??
                        0.0,
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  void _generateAndShareReport({
    required TransactionProvider txProvider,
    required UserProvider userProvider,
    required String scope,
    String? userId,
    required bool includeBonus,
    required double customDeduction,
    required double customBonus,
  }) {
    final String dateStr = DateFormat(
      'yyyy/MM/dd - hh:mm a',
    ).format(DateTime.now());
    final buffer = StringBuffer();

    if (scope == 'ALL') {
      buffer.writeln('📊 *تقرير مالي شامل - المؤسسة الشامية*');
      buffer.writeln('🗓️ *تاريخ التقرير:* $dateStr');
      buffer.writeln('────────────────────────');
      buffer.writeln(
        '💼 *إجمالي الحسابات:* ${userProvider.wallets.length} محفظة',
      );
      buffer.writeln(
        '💰 *إجمالي رؤوس الأموال:* \$${userProvider.totalSystemPrincipal.toStringAsFixed(2)}',
      );
      buffer.writeln(
        '📈 *إجمالي الأرباح الموزعة:* \$${userProvider.totalSystemProfitsEarned.toStringAsFixed(2)}',
      );

      if (customDeduction > 0)
        buffer.writeln('✂️ *نسبة الخصم المطبقة:* $customDeduction%');
      if (customBonus > 0 && includeBonus)
        buffer.writeln('🎁 *نسبة البونص المطبقة:* $customBonus%');

      buffer.writeln('────────────────────────');
      buffer.writeln('📋 *سجل أحدث الحركات المالية:*');

      for (var tx in txProvider.transactions.take(15)) {
        if (!includeBonus && tx.type == 'BONUS') continue;
        buffer.writeln(
          '• ${tx.userName} | ${tx.type} | \$${tx.amount.toStringAsFixed(2)} | (${DateFormat('MM/dd').format(tx.date)})',
        );
      }
    } else {
      final userWallets = userProvider.wallets
          .where((w) => w.userId == userId)
          .toList();
      final userName = userWallets.isNotEmpty
          ? userWallets.first.userName
          : 'مستثمر';
      final double totalPrincipal = userWallets.fold(
        0.0,
        (s, w) => s + w.principalBalance,
      );
      final double totalProfits = userWallets.fold(
        0.0,
        (s, w) => s + w.totalProfitsEarned,
      );

      final userTxs = txProvider.transactions.where((tx) {
        if (!includeBonus && tx.type == 'BONUS') return false;
        return userWallets.any((w) => w.id == tx.walletId);
      }).toList();

      buffer.writeln('👤 *كشف حساب مستثمر | شركة الشامي*');
      buffer.writeln('👤 *المستثمر:* $userName');
      buffer.writeln('🗓️ *تاريخ التقرير:* $dateStr');
      buffer.writeln('────────────────────────');
      buffer.writeln(
        '💼 *رأس المال الحالي:* \$${totalPrincipal.toStringAsFixed(2)}',
      );
      buffer.writeln(
        '📈 *إجمالي الأرباح المستلمة:* \$${totalProfits.toStringAsFixed(2)}',
      );

      if (customDeduction > 0)
        buffer.writeln('✂️ *نسبة الخصم الإداري:* $customDeduction%');
      if (customBonus > 0 && includeBonus)
        buffer.writeln('🎁 *نسبة بونص الإحالة:* $customBonus%');

      buffer.writeln('────────────────────────');
      buffer.writeln('📝 *سجل المعاملات:*');

      for (var tx in userTxs) {
        buffer.writeln(
          '• ${tx.description.isEmpty ? tx.type : tx.description}: \$${tx.amount.toStringAsFixed(2)} بتاريخ ${DateFormat('yyyy/MM/dd').format(tx.date)}',
        );
      }
    }

    buffer.writeln('\n────────────────────────');
    buffer.writeln('📱 *تم التصدير آلياً عبر نظام الشامي المالي*');

    Share.share(buffer.toString(), subject: 'تقرير مالي - الشامي');
  }

  // 🗑️ 3. تأكيد حذف حركة مفردة
  void _confirmDeleteSingleTransaction(
    BuildContext context,
    TransactionModel tx,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(
          Icons.warning_amber_rounded,
          color: AppColors.danger,
          size: 32,
        ),
        title: const Text('حذف هذا السند؟'),
        content: Text(
          'هل أنت متأكد من حذف سند "${tx.userName}" بقيمة \$${tx.amount.toStringAsFixed(2)}؟',
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
              final success = await Provider.of<TransactionProvider>(
                context,
                listen: false,
              ).deleteTransaction(tx.id);
              if (context.mounted && success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم حذف السند بنجاح.')),
                );
              }
            },
            child: const Text('نعم، احذف'),
          ),
        ],
      ),
    );
  }

  // 🗑️ 4. تأكيد مسح الكشف بالكامل
  void _confirmClearAllTransactions(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(
          Icons.warning_amber_rounded,
          color: AppColors.danger,
          size: 36,
        ),
        title: const Text('مسح كافة السندات المالية؟'),
        content: const Text(
          'سيتم حذف جميع السندات والحركات المالية المسجلة نهائياً من السيرفر. لا يمكن التراجع عن هذا الإجراء!',
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
              final success = await Provider.of<TransactionProvider>(
                context,
                listen: false,
              ).clearAllTransactions();
              if (context.mounted && success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم مسح كافة السندات بنجاح.')),
                );
              }
            },
            child: const Text('نعم، امسح الكشف بالكامل'),
          ),
        ],
      ),
    );
  }

  void _shareSingleReceipt(TransactionModel tx) {
    final receiptText =
        '''
🧾 *سند مالي رسمي - شركة الشامي*
----------------------------------
👤 *المستثمر:* ${tx.userName}
📂 *المسار:* ${tx.trackType}
📌 *نوع العملية:* ${tx.type}
💰 *المبلغ:* \$${tx.amount.toStringAsFixed(2)}
📝 *البيان:* ${tx.description.isEmpty ? "قيد مالي" : tx.description}
📅 *التاريخ:* ${DateFormat('yyyy/MM/dd hh:mm a').format(tx.date)}
----------------------------------
_تم توليد هذا السند تلقائياً عبر نظام الشامي المالي._
''';
    Share.share(receiptText, subject: 'سند مالي - ${tx.userName}');
  }

  void _showActionDialog(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    final amountController = TextEditingController();
    final descController = TextEditingController();

    String selectedType = 'DEPOSIT';
    String? selectedWalletId;
    bool isSubmitting = false;

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final transactionProvider = Provider.of<TransactionProvider>(
      context,
      listen: false,
    );

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              icon: const Icon(Icons.receipt_long_outlined),
              title: const Text('تسجيل حركة مالية'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        value: selectedWalletId,
                        isExpanded: true, // 👈 تمنع تجاوز الحدود
                        decoration: const InputDecoration(
                          labelText: 'اختر حساب المستثمر',
                          border: OutlineInputBorder(),
                        ),
                        items: userProvider.wallets.map((w) {
                          return DropdownMenuItem(
                            value: w.id,
                            child: Text(
                              '${w.userName} (${w.trackType})',
                              overflow: TextOverflow
                                  .ellipsis, // 👈 تمنع overflow للنص الطويل
                              maxLines: 1,
                            ),
                          );
                        }).toList(),
                        onChanged: (val) =>
                            setDialogState(() => selectedWalletId = val),
                        validator: (val) =>
                            val == null ? 'الرجاء اختيار المستثمر' : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: selectedType,
                        isExpanded: true, // 👈 تمنع تجاوز الحدود
                        decoration: const InputDecoration(
                          labelText: 'نوع العملية الماليّة',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'DEPOSIT',
                            child: Text(
                              'إيداع (زيادة رأس المال)',
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'WITHDRAW',
                            child: Text(
                              'سحب (تخفيض أو تصفية أرباح)',
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                        onChanged: (val) =>
                            setDialogState(() => selectedType = val!),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: amountController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'المبلغ المستهدف (\$)',
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty)
                            return 'الرجاء إدخال قيمة السند';
                          if (double.tryParse(val) == null ||
                              double.parse(val) <= 0)
                            return 'المبلغ غير صالح';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: descController,
                        decoration: const InputDecoration(
                          labelText: 'بيان العملية (اختياري)',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('إلغاء'),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (formKey.currentState!.validate()) {
                            setDialogState(() => isSubmitting = true);
                            final success = await transactionProvider
                                .executeTransaction(
                                  walletId: selectedWalletId!,
                                  type: selectedType,
                                  amount: double.parse(amountController.text),
                                  description: descController.text.trim(),
                                );

                            if (!mounted) return;
                            if (success) {
                              userProvider.loadWallets();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'تم قيد السند وتحديث الرصيد بنجاح.',
                                  ),
                                ),
                              );
                              if (ctx.mounted) Navigator.pop(ctx);
                            } else {
                              if (ctx.mounted)
                                setDialogState(() => isSubmitting = false);
                            }
                          }
                        },
                  child: isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('قيد وترحيل السند'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
