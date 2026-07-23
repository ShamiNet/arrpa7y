import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/wallet_model.dart';
import '../../logic/transaction_provider.dart';
import '../../logic/user_provider.dart';
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

  String _selectedTrack = 'BITCOIN';
  String _operationType = 'DEPOSIT';
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedTrack = widget.wallet.trackType.isNotEmpty
        ? widget.wallet.trackType
        : 'BITCOIN';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<TransactionProvider>();
      if (provider.transactions.isEmpty) provider.loadTransactions();
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final txProvider = Provider.of<TransactionProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);

    final currentWallet = userProvider.wallets.firstWhere(
      (w) => w.id == widget.wallet.id,
      orElse: () => widget.wallet,
    );

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
              // 👈 كارت التحكم الموحد بالنِسب الخاصة بالعميل (بونص + خصم إداري)
              _RatesManagementCard(wallet: currentWallet),
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
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              backgroundColor: AppColors.emerald,
            ),
            onPressed: () =>
                _showUnifiedTransactionBottomSheet(context, currentWallet),
            icon: const Icon(Icons.swap_horiz_rounded),
            label: const Text(
              'إجراء حركة مالية موحدة (إيداع / سحب / توجيه مسار)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ),
      ),
    );
  }

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
                      style: Theme.of(
                        context,
                      ).textTheme.titleLarge?.copyWith(color: Colors.white),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
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

  Widget _buildClientTxList(
    List transactions,
    bool isLoading,
    WalletModel currentWallet,
  ) {
    if (isLoading) return const AppStateView(kind: AppStateKind.loading);
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

_تم توليد هذا السند تلقائياً عبر نظام الشامي المالي._
''';
            await Share.share(
              receiptText,
              subject: 'سند مالي - ${currentWallet.userName}',
            );
          },
        );
      },
    );
  }

  void _showUnifiedTransactionBottomSheet(
    BuildContext context,
    WalletModel wallet,
  ) {
    _amountController.clear();
    _descController.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(dialogCtx).viewInsets.bottom,
                top: 20,
                left: 18,
                right: 18,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'إدارة الحركة المالية لـ ${wallet.userName}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 14),

                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(
                            value: 'DEPOSIT',
                            label: Text('إيداع شحن'),
                            icon: Icon(Icons.add_circle_outline_rounded),
                          ),
                          ButtonSegment(
                            value: 'WITHDRAWAL',
                            label: Text('سحب رصيد'),
                            icon: Icon(Icons.remove_circle_outline_rounded),
                          ),
                        ],
                        selected: {_operationType},
                        onSelectionChanged: (val) {
                          setModalState(() => _operationType = val.first);
                        },
                      ),
                      const SizedBox(height: 14),

                      DropdownButtonFormField<String>(
                        value: _selectedTrack,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'توجيه الميزانية للمسار',
                          prefixIcon: Icon(Icons.show_chart_rounded),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'BITCOIN',
                            child: Text('تداول البيتكوين / العملات'),
                          ),
                          DropdownMenuItem(
                            value: 'ORGANIZATIONS',
                            child: Text('استثمار المنظمات (أبو جميل)'),
                          ),
                        ],
                        onChanged: (val) =>
                            setModalState(() => _selectedTrack = val!),
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'المبلغ المستهدف (\$)',
                          prefixIcon: Icon(Icons.attach_money_rounded),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty)
                            return 'الرجاء إدخال المبلغ';
                          final num = double.tryParse(val.trim());
                          if (num == null || num <= 0) return 'مبلغ غير صالح';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _descController,
                        decoration: const InputDecoration(
                          labelText: 'ملاحظات / بيان السند (اختياري)',
                          prefixIcon: Icon(Icons.notes_rounded),
                        ),
                      ),
                      const SizedBox(height: 18),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _operationType == 'DEPOSIT'
                                ? AppColors.success
                                : AppColors.danger,
                          ),
                          onPressed: _isSubmitting
                              ? null
                              : () async {
                                  if (_formKey.currentState!.validate()) {
                                    setModalState(() => _isSubmitting = true);
                                    final userProvider =
                                        Provider.of<UserProvider>(
                                          context,
                                          listen: false,
                                        );

                                    final amount = double.parse(
                                      _amountController.text.trim(),
                                    );
                                    final desc = _descController.text.trim();
                                    bool success = false;

                                    if (_operationType == 'DEPOSIT') {
                                      success = await userProvider
                                          .depositToWallet(
                                            userId: wallet.userId,
                                            trackType: _selectedTrack,
                                            amount: amount,
                                            description: desc,
                                          );
                                    } else {
                                      success = await userProvider
                                          .withdrawFromWallet(
                                            userId: wallet.userId,
                                            trackType: _selectedTrack,
                                            amount: amount,
                                            description: desc,
                                          );
                                    }

                                    if (!mounted) return;
                                    setModalState(() => _isSubmitting = false);

                                    if (success) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            '🎉 تم قيد عملية ${_operationType == 'DEPOSIT' ? "الإيداع" : "السحب"} وتحديث المحفظة بنجاح!',
                                          ),
                                        ),
                                      );
                                      if (ctx.mounted) Navigator.pop(ctx);
                                    } else {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'تعذر إتمام العملية، يرجى التأكد من رصيد المحفظة.',
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                },
                          icon: _isSubmitting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Icon(
                                  _operationType == 'DEPOSIT'
                                      ? Icons.download_rounded
                                      : Icons.upload_rounded,
                                ),
                          label: Text(
                            _isSubmitting
                                ? 'جارٍ المعالجة والقيد...'
                                : (_operationType == 'DEPOSIT'
                                      ? 'تأكيد وشحن الحساب'
                                      : 'تأكيد وسحب المبلغ'),
                            style: const TextStyle(fontWeight: FontWeight.bold),
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
      },
    );
  }
}

// 👈 ويدجت إدارة النسب الخاصة بالعميل (بونص الإحالة + الخصم الإداري الفردي)
class _RatesManagementCard extends StatefulWidget {
  final WalletModel wallet;

  const _RatesManagementCard({required this.wallet});

  @override
  State<_RatesManagementCard> createState() => _RatesManagementCardState();
}

class _RatesManagementCardState extends State<_RatesManagementCard> {
  final _bonusController = TextEditingController();
  final _deductionController = TextEditingController();

  bool _isLoaded = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadUserRates();
  }

  Future<void> _loadUserRates() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(widget.wallet.userId)
          .get();

      if (doc.exists && mounted) {
        final data = doc.data() ?? {};
        _bonusController.text = (data['referralBonusRate'] ?? 0.0).toString();
        _deductionController.text = (data['customDeductionRate'] ?? 0.0)
            .toString();
        setState(() => _isLoaded = true);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoaded = true);
    }
  }

  @override
  void dispose() {
    _bonusController.dispose();
    _deductionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!_isLoaded) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.tune_rounded, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                const Text(
                  'إدارة النسب الخاصة بالعميل',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              children: [
                // 1. نسبة البونص
                Expanded(
                  child: TextFormField(
                    controller: _bonusController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'بونص الإحالة (%)',
                      hintText: 'مثال: 0.25',
                      prefixIcon: Icon(Icons.content_cut_rounded, size: 18),

                      // 1. تصغير حجم خط العنوان ليتناسب مع المساحة
                      labelStyle: TextStyle(fontSize: 13),

                      // 2. التحكم بالحجم عند صعود النص للأعلى (مهم للحقول الصغيرة)
                      floatingLabelStyle: TextStyle(fontSize: 12),

                      // 3. إضافة مساحات داخلية تمنع النص من الاصطدام بالحواف
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // 2. نسبة الخصم الفردي
                Expanded(
                  child: TextFormField(
                    controller: _deductionController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'الخصم الخاص (%)',
                      hintText: 'مثال: 2.0',
                      prefixIcon: Icon(Icons.content_cut_rounded, size: 18),

                      // 1. تصغير حجم خط العنوان ليتناسب مع المساحة
                      labelStyle: TextStyle(fontSize: 13),

                      // 2. التحكم بالحجم عند صعود النص للأعلى (مهم للحقول الصغيرة)
                      floatingLabelStyle: TextStyle(fontSize: 12),

                      // 3. إضافة مساحات داخلية تمنع النص من الاصطدام بالحواف
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSaving
                    ? null
                    : () async {
                        final double? bonus = double.tryParse(
                          _bonusController.text.trim(),
                        );
                        final double? deduction = double.tryParse(
                          _deductionController.text.trim(),
                        );

                        if (bonus == null || deduction == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('الرجاء إدخال أرقام صحيحة'),
                            ),
                          );
                          return;
                        }

                        setState(() => _isSaving = true);
                        try {
                          await FirebaseFirestore.instance
                              .collection('Users')
                              .doc(widget.wallet.userId)
                              .update({
                                'referralBonusRate': bonus,
                                'customDeductionRate': deduction,
                              });

                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  '✅ تم حفظ وتحديث النسب المخصصة للعميل سحابياً.',
                                ),
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('تعذر الحفظ: $e')),
                            );
                          }
                        } finally {
                          if (mounted) setState(() => _isSaving = false);
                        }
                      },
                icon: _isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save_rounded, size: 18),
                label: Text(
                  _isSaving ? 'جارٍ الحفظ...' : 'حفظ وتحديث النسب الفردية',
                ),
              ),
            ),
          ],
        ),
      ),
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
