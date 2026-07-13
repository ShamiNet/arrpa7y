import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../data/models/wallet_model.dart';
import '../../logic/transaction_provider.dart';
import '../../logic/user_provider.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import 'package:share_plus/share_plus.dart';

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
        title: Text(
          currentWallet.userName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0,
      ),
      body: Column(
        children: [
          // 1. لوحة الملخص المالي للمستثمر
          _buildFinancialSummaryCard(currentWallet),

          // 2. بوابة مدفوعات شام كاش الذكية والمدمجة
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 14.0,
              vertical: 4.0,
            ),
            child: _buildShamCashPortal(context, currentWallet),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                '📝 كشف الحساب الشخصي',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
          ),

          // 3. قائمة الحركات الشخصية للمستثمر
          Expanded(
            child: _buildClientTxList(
              clientTransactions,
              txProvider.isLoading,
              currentWallet,
            ),
          ),
        ],
      ),

      // 4. أزرار الإجراءات السريعة الإدارية التقليدية (إيداع / سحب) بأسفل الشاشة
      bottomNavigationBar: _buildActionButtons(context, currentWallet),
    );
  }

  // بطاقة الملخص المالي
  Widget _buildFinancialSummaryCard(WalletModel wallet) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(
                'مسار الاستثمار: ${wallet.trackName} (${wallet.trackType})',
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const Divider(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      const Text(
                        'رأس المال الحالي',
                        style: TextStyle(color: Colors.black54, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '\$${wallet.principalBalance.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey,
                        ),
                      ),
                    ],
                  ),
                  Container(width: 1, height: 40, color: Colors.grey.shade300),
                  Column(
                    children: [
                      const Text(
                        'إجمالي الأرباح المنزلة',
                        style: TextStyle(color: Colors.black54, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '\$${wallet.totalProfitsEarned.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ويدجت بوابة مدفوعات شام كاش الذكية
  Widget _buildShamCashPortal(BuildContext context, WalletModel wallet) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    return Card(
      color: Colors.indigo.shade50,
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.account_balance_wallet,
                  color: Colors.indigo,
                  size: 22,
                ),
                const SizedBox(width: 8),
                const Text(
                  'بوابة مدفوعات شام كاش (ShamCash الآلية)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.indigo,
                  ),
                ),
              ],
            ),
            const Divider(height: 16),
            Text(
              '📱 رقم المحفظة المسجل: ${wallet.phone.isEmpty ? "غير مدرج" : wallet.phone}',
              style: const TextStyle(fontSize: 12, color: Colors.black87),
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 45,
                    child: TextFormField(
                      controller: _shamCashAmountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'المبلغ المطلوب',
                        prefixIcon: Icon(Icons.money, size: 20),
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(vertical: 8),
                        fillColor: Colors.white,
                        filled: true,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () async {
                    if (_shamCashAmountController.text.trim().isEmpty) return;

                    final apiClient = ApiClient();
                    final response = await apiClient.post(
                      '${ApiConstants.baseUrl}/users/shamcash/deposit',
                      body: {
                        'walletId': wallet.id,
                        'amount': double.parse(
                          _shamCashAmountController.text.trim(),
                        ),
                        'phone': wallet.phone,
                      },
                    );

                    if (response.statusCode == 200 && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            '⚡ تم إنشاء طلب الإيداع وإرسال الفاتورة بنجاح عبر ShamCash!',
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );
                      _shamCashAmountController.clear();
                      userProvider.loadWallets();
                    }
                  },
                  child: const Text(
                    'شحن آلي',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 4),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () async {
                    if (_shamCashAmountController.text.trim().isEmpty) return;

                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('⚠️ تأكيد الصرف المباشر'),
                        content: Text(
                          'هل أنت متأكد من تحويل مالي فوري بقيمة \$${_shamCashAmountController.text} مباشرة من محفظة شركتك لشام كاش الخاصة بالعميل؟',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('إلغاء'),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            onPressed: () async {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    '🚀 جاري معالجة صرف الحوالة الفورية للعميل...',
                                  ),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                            },
                            child: const Text('نعم، حوّل الآن'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: const Text(
                    'صرف فوري',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
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
      return const Center(child: CircularProgressIndicator());
    }
    if (transactions.isEmpty) {
      return const Center(
        child: Text('لا توجد عمليات ماليّة مسجلة لهذا الحساب حتى الآن.'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final tx = transactions[index];
        final isDeposit = tx.type == 'DEPOSIT';

        return Card(
          elevation: 1,
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isDeposit
                  ? Colors.green.shade50
                  : Colors.red.shade50,
              child: Icon(
                isDeposit ? Icons.arrow_downward : Icons.arrow_upward,
                color: isDeposit ? Colors.green.shade700 : Colors.red.shade700,
                size: 20,
              ),
            ),
            title: Text(
              tx.description.isEmpty
                  ? (isDeposit ? 'إيداع رأس مال' : 'سحب مالي')
                  : tx.description,
            ),
            subtitle: Text(
              DateFormat('yyyy/MM/dd hh:mm a').format(tx.date),
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${isDeposit ? "+" : "-"}\$${tx.amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDeposit
                        ? Colors.green.shade700
                        : Colors.red.shade700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(
                    Icons.share_outlined,
                    color: Colors.blueGrey,
                    size: 20,
                  ),
                  onPressed: () {
                    final String receiptText =
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

                    Share.share(
                      receiptText,
                      subject: 'سند مالي - ${currentWallet.userName}',
                    );
                  },
                ),
              ],
            ),
          ),
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
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
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
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
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
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isDeposit ? '📥 قيد سند إيداع جديد' : '📤 قيد سند سحب مالي',
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
                      backgroundColor: isDeposit
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
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

                        if (success && mounted) {
                          Provider.of<UserProvider>(
                            context,
                            listen: false,
                          ).loadWallets();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('🚀 تم تسجيل وتوثيق السند بنجاح!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                          Navigator.pop(ctx);
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
        );
      },
    );
  }
}
