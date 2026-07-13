import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../logic/transaction_provider.dart';
import '../../logic/user_provider.dart';
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
    // جلب سجل السندات فور فتح الواجهة
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
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('السندات المالية'),
            Text(
              'سجل موحّد لجميع الحركات',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'إضافة حركة مالية',
            icon: const Icon(Icons.add_card_outlined),
            onPressed: () => _showActionDialog(context),
          ),
          const SizedBox(width: 50),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showActionDialog(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('سند جديد'),
      ),
      body: AppPage(
        child: _buildTxList(txProvider),
      ),
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
    if (provider.transactions.isEmpty) {
      return const AppStateView(
        kind: AppStateKind.empty,
        title: 'لا توجد سندات مالية',
        message: 'أنشئ أول حركة إيداع أو سحب لتظهر هنا.',
      );
    }

    final deposits = provider.transactions
        .where((transaction) => transaction.type == 'DEPOSIT')
        .fold<double>(0, (sum, transaction) => sum + transaction.amount);
    final withdrawals = provider.transactions
        .where((transaction) => transaction.type != 'DEPOSIT')
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
                AppSectionHeader(
                  title: 'أحدث الحركات',
                  subtitle: '${provider.transactions.length} سنداً مسجلاً',
                  icon: Icons.history_rounded,
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
          SliverList.builder(
            itemCount: provider.transactions.length,
            itemBuilder: (context, index) => FadeSlideIn(
              delay: Duration(milliseconds: index * 25),
              child: TransactionCard(
                transaction: provider.transactions[index],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 84)),
        ],
      ),
    );
  }

  // نافذة تنفيذ عملية (إيداع / سحب) جديدة
  Future<void> _showActionDialog(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    final amountController = TextEditingController();
    final descController = TextEditingController();

    String selectedType = 'DEPOSIT';
    String? selectedWalletId;
    bool isSubmitting = false;

    // جلب قائمة المحافظ المتاحة من الـ UserProvider لتغذية الـ Dropdown
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
                      // 1. اختيار العميل / المحفظة المستهدفة
                      DropdownButtonFormField<String>(
                        value: selectedWalletId,
                        decoration: const InputDecoration(
                          labelText: 'اختر حساب المستثمر',
                          border: OutlineInputBorder(),
                        ),
                        items: userProvider.wallets.map((w) {
                          return DropdownMenuItem(
                            value: w.id,
                            child: Text('${w.userName} (${w.trackType})'),
                          );
                        }).toList(),
                        onChanged: (val) =>
                            setDialogState(() => selectedWalletId = val),
                        validator: (val) =>
                            val == null ? 'الرجاء اختيار المستثمر' : null,
                      ),
                      const SizedBox(height: 12),
                      // 2. نوع الحركة (إيداع أم سحب)
                      DropdownButtonFormField<String>(
                        value: selectedType,
                        decoration: const InputDecoration(
                          labelText: 'نوع العملية الماليّة',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'DEPOSIT',
                            child: Text('إيداع (زيادة رأس المال)'),
                          ),
                          DropdownMenuItem(
                            value: 'WITHDRAW',
                            child: Text('سحب (تخفيض أو تصفية أرباح)'),
                          ),
                        ],
                        onChanged: (val) =>
                            setDialogState(() => selectedType = val!),
                      ),
                      const SizedBox(height: 12),
                      // 3. قيمة المبلغ
                      TextFormField(
                        controller: amountController,
                        keyboardType: TextInputType.number,
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
                      // 4. البيان / الوصف
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
                        // تحديث أرصدة شاشة إدارة المستخدمين بالتزامن
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
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'فشل التنفيذ: ${transactionProvider.errorMessage}',
                            ),
                          ),
                        );
                        if (ctx.mounted) {
                          setDialogState(() => isSubmitting = false);
                        }
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
    amountController.dispose();
    descController.dispose();
  }
}
