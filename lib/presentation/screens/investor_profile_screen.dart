import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../data/models/wallet_model.dart';
import '../../logic/transaction_provider.dart';
import '../../logic/user_provider.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme/app_colors.dart';
import '../widgets/app_ui.dart';

class InvestorProfileScreen extends StatefulWidget {
  final WalletModel wallet;

  const InvestorProfileScreen({super.key, required this.wallet});

  @override
  State<InvestorProfileScreen> createState() => _InvestorProfileScreenState();
}

class _InvestorProfileScreenState extends State<InvestorProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descController = TextEditingController();
  final _shamCashAmountController =
      TextEditingController(); // متحكم مستقل لمبلغ شام كاش
  bool _isShamCashLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<TransactionProvider>();
      if (provider.transactions.isEmpty) provider.loadTransactions();
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descController.dispose();
    _shamCashAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final txProvider = Provider.of<TransactionProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);

    // العثور على المحفظة المحدثة من الـ Provider لضمان عرض الأرصدة بدقة بعد كل عملية
    final currentWallet = userProvider.wallets.firstWhere(
      (w) => w.id == widget.wallet.id,
      orElse: () => widget.wallet,
    );

    // فلترة السندات العامة لتعرض فقط السندات التابعة لهذه المحفظة
    final clientTransactions = txProvider.transactions
        .where((tx) => tx.walletId == currentWallet.id)
        .toList();

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(currentWallet.userName),
            Text(
              currentWallet.trackName.isEmpty
                  ? currentWallet.trackType
                  : currentWallet.trackName,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
      body: AppPage(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildFinancialSummaryCard(currentWallet),
              const SizedBox(height: 12),
              _buildShamCashPortal(context, currentWallet),
              const Padding(
                padding: EdgeInsets.only(top: 18, bottom: 10),
                child: AppSectionHeader(
                  title: 'كشف الحساب الشخصي',
                  subtitle: 'الحركات المرتبطة بهذه المحفظة',
                  icon: Icons.receipt_long_outlined,
                ),
              ),
              _buildClientTxList(
                clientTransactions,
                txProvider.isLoading,
                currentWallet,
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),

      // 4. أزرار الإجراءات السريعة الإدارية التقليدية (إيداع / سحب) بأسفل الشاشة
      bottomNavigationBar: _buildActionButtons(context, currentWallet),
    );
  }

  // بطاقة الملخص المالي
  Widget _buildFinancialSummaryCard(WalletModel wallet) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient(Theme.of(context).brightness),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.emerald.withValues(alpha: .22),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const AppBrandMark(size: 48, onDark: true),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      wallet.userName,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '${wallet.trackName} • ${wallet.trackType}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .11),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  wallet.userRole == 'ADMIN' ? 'مدير' : 'مستثمر',
                  style: const TextStyle(
                    color: AppColors.goldSoft,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: _HeroAmount(
                  label: 'رأس المال الحالي',
                  value: '\$${wallet.principalBalance.toStringAsFixed(2)}',
                ),
              ),
              Container(
                width: 1,
                height: 42,
                color: Colors.white.withValues(alpha: .18),
              ),
              Expanded(
                child: _HeroAmount(
                  label: 'إجمالي الأرباح',
                  value: '\$${wallet.totalProfitsEarned.toStringAsFixed(2)}',
                  accent: AppColors.goldSoft,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ويدجت بوابة مدفوعات شام كاش الذكية
  Widget _buildShamCashPortal(BuildContext context, WalletModel wallet) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.account_balance_wallet_outlined,
                    color: theme.colorScheme.primary,
                    size: 21,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'بوابة ShamCash',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        wallet.phone.isEmpty
                            ? 'لا يوجد رقم محفظة مسجل'
                            : wallet.phone,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'متصل',
                    style: TextStyle(
                      color: AppColors.success,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 570;
                final field = TextFormField(
                      controller: _shamCashAmountController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'المبلغ المطلوب',
                        prefixIcon: Icon(Icons.payments_outlined),
                      ),
                    );
                final depositButton = ElevatedButton.icon(
                  onPressed: _isShamCashLoading
                      ? null
                      : () => _requestShamCashDeposit(wallet, userProvider),
                  icon: _isShamCashLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.add_card_rounded, size: 18),
                  label: Text(
                    _isShamCashLoading ? 'جارٍ الإرسال' : 'شحن آلي',
                  ),
                );
                final payoutButton = OutlinedButton.icon(
                  onPressed: _isShamCashLoading
                      ? null
                      : () => _confirmShamCashPayout(wallet),
                  icon: const Icon(Icons.send_outlined, size: 18),
                  label: const Text('صرف فوري'),
                );
                if (isCompact) {
                  return Column(
                    children: [
                      field,
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(child: depositButton),
                          const SizedBox(width: 8),
                          Expanded(child: payoutButton),
                        ],
                      ),
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: field),
                    const SizedBox(width: 10),
                    depositButton,
                    const SizedBox(width: 8),
                    payoutButton,
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _requestShamCashDeposit(
    WalletModel wallet,
    UserProvider userProvider,
  ) async {
    final amount = double.tryParse(_shamCashAmountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أدخل مبلغاً صالحاً أولاً.')),
      );
      return;
    }
    setState(() => _isShamCashLoading = true);
    try {
      final response = await ApiClient().post(
        '${ApiConstants.baseUrl}/users/shamcash/deposit',
        body: {'walletId': wallet.id, 'amount': amount, 'phone': wallet.phone},
      );
      if (!mounted) return;
      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إنشاء طلب الإيداع وإرسال الفاتورة.')),
        );
        _shamCashAmountController.clear();
        userProvider.loadWallets();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر إنشاء طلب الإيداع عبر ShamCash.')),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تعذر الاتصال بخدمة ShamCash. تحقق من الشبكة.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isShamCashLoading = false);
    }
  }

  Future<void> _confirmShamCashPayout(WalletModel wallet) async {
    final amount = double.tryParse(_shamCashAmountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أدخل مبلغاً صالحاً أولاً.')),
      );
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(
          Icons.warning_amber_rounded,
          color: AppColors.warning,
          size: 34,
        ),
        title: const Text('تأكيد الصرف المباشر'),
        content: Text(
          'سيتم تحويل \$${amount.toStringAsFixed(2)} مباشرة إلى محفظة ${wallet.userName}. هل تريد المتابعة؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('جارٍ معالجة الحوالة الفورية...')),
              );
            },
            child: const Text('تأكيد التحويل'),
          ),
        ],
      ),
    );
  }

  // قائمة المعاملات المفلترة لعميل محدد
  Widget _buildClientTxList(
    List transactions,
    bool isLoading,
    WalletModel currentWallet,
  ) {
    if (isLoading) {
      return const AppStateView(kind: AppStateKind.loading);
    }
    if (transactions.isEmpty) {
      return const AppStateView(
        kind: AppStateKind.empty,
        title: 'لا توجد حركات لهذه المحفظة',
        message: 'ستظهر عمليات الإيداع والسحب هنا فور تسجيلها.',
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final tx = transactions[index];
        return TransactionCard(
          transaction: tx,
          compact: true,
          onShare: () async {
            final isDeposit = tx.type == 'DEPOSIT';
            final receiptText =
                '''
🧾 *سند مالي رسمي - شركة الشامي*
----------------------------------
👤 *المستثمر:* ${currentWallet.userName}
📂 *المسار الاستثماري:* ${currentWallet.trackName}
----------------------------------
📌 *نوع العملية:* ${isDeposit ? "إيداع (زيادة رأس مال)" : "سحب مالي (تخفيض حساب)"}
💰 *المبلغ المستهدف:* \$${tx.amount.toStringAsFixed(2)}
📝 *البيان:* ${tx.description.isEmpty ? "قيد مالي دوري" : tx.description}
📅 *التاريخ:* ${DateFormat('yyyy/MM/dd hh:mm a').format(tx.date)}
----------------------------------
💼 *رأس المال الحالي للمحفظة:* \$${currentWallet.principalBalance.toStringAsFixed(2)}

_تم توليد هذا السند تلقائياً عبر نظام الشامي نت لإدارة الأرباح والمحافظ الحية._
''';

            await SharePlus.instance.share(
              ShareParams(
                text: receiptText,
                subject: 'سند مالي - ${currentWallet.userName}',
              ),
            );
          },
        );
      },
    );
  }

  // أزرار الإيداع والسحب في الأسفل
  Widget _buildActionButtons(BuildContext context, WalletModel wallet) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                ),
                onPressed: () =>
                    _showTransactionBottomSheet(context, wallet, 'DEPOSIT'),
                icon: const Icon(Icons.add_circle_outline),
                label: const Text(
                  'إيداع أموال',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.danger,
                ),
                onPressed: () =>
                    _showTransactionBottomSheet(context, wallet, 'WITHDRAW'),
                icon: const Icon(Icons.remove_circle_outline),
                label: const Text(
                  'سحب أموال',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // نافذة إدخال الحركة المالية السريعة
  void _showTransactionBottomSheet(
    BuildContext context,
    WalletModel wallet,
    String type,
  ) {
    _amountController.clear();
    _descController.clear();
    final isDeposit = type == 'DEPOSIT';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            top: 20,
            left: 16,
            right: 16,
          ),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isDeposit ? 'قيد سند إيداع جديد' : 'قيد سند سحب مالي',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'المبلغ المطلوب (\$)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty)
                      return 'الرجاء إدخال المبلغ';
                    if (double.tryParse(val) == null || double.parse(val) <= 0)
                      return 'مبلغ غير صالح';
                    if (!isDeposit &&
                        double.parse(val) > wallet.principalBalance)
                      return 'رصيد المحفظة التأسيسي غير كافٍ';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descController,
                  decoration: const InputDecoration(
                    labelText: 'بيان العملية (اختياري)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isDeposit ? AppColors.success : AppColors.danger,
                    ),
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        final success =
                            await Provider.of<TransactionProvider>(
                              context,
                              listen: false,
                            ).executeTransaction(
                              walletId: wallet.id,
                              type: type,
                              amount: double.parse(_amountController.text),
                              description: _descController.text.trim(),
                            );

                        if (!mounted) return;
                        if (success) {
                          Provider.of<UserProvider>(
                            context,
                            listen: false,
                          ).loadWallets();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('تم تسجيل وتوثيق السند بنجاح.'),
                            ),
                          );
                          if (ctx.mounted) Navigator.pop(ctx);
                        }
                      }
                    },
                    child: const Text(
                      'تأكيد وترحيل السند المالي',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HeroAmount extends StatelessWidget {
  const _HeroAmount({
    required this.label,
    required this.value,
    this.accent = Colors.white,
  });

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white60, fontSize: 11),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.fade,
          style: TextStyle(
            color: accent,
            fontSize: 19,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}
