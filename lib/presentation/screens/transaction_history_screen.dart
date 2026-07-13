import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // لتنسيق التواريخ بشكل مقروء
import '../../logic/transaction_provider.dart';
import '../../logic/user_provider.dart';

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
    });
  }

  @override
  Widget build(BuildContext context) {
    final txProvider = Provider.of<TransactionProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'كشف الحساب والسندات الماليّة',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
        actions: [
          // زر سريع لإنشاء حركة مالية جديدة من أعلى البار
          IconButton(
            icon: const Icon(Icons.add_card, color: Colors.white),
            onPressed: () => _showActionDialog(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => txProvider.loadTransactions(),
        child: _buildTxList(txProvider),
      ),
    );
  }

  Widget _buildTxList(TransactionProvider provider) {
    if (provider.isLoading && provider.transactions.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.errorMessage != null && provider.transactions.isEmpty) {
      // السطر الجديد لمراقبة الخطأ في الكونسول
      debugPrint('🚨 [Transaction Error]: ${provider.errorMessage}');
      return Center(
        child: Text('✗ خطأ أثناء جلب السجلات: ${provider.errorMessage}'),
      );
    }
    if (provider.transactions.isEmpty) {
      return const Center(child: Text('لا توجد عمليات ماليّة مسجلة حالياً.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: provider.transactions.length,
      itemBuilder: (context, index) {
        final tx = provider.transactions[index];
        final isDeposit = tx.type == 'DEPOSIT';

        return Card(
          elevation: 1.5,
          margin: const EdgeInsets.symmetric(vertical: 5),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isDeposit
                  ? Colors.green.shade50
                  : Colors.red.shade50,
              child: Icon(
                isDeposit ? Icons.arrow_downward : Icons.arrow_upward,
                color: isDeposit ? Colors.green.shade700 : Colors.red.shade700,
              ),
            ),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  tx.userName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${isDeposit ? "+" : "-"}\$${tx.amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDeposit
                        ? Colors.green.shade700
                        : Colors.red.shade700,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  tx.description,
                  style: const TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'المسار: ${tx.trackType}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.blueGrey,
                      ),
                    ),
                    Text(
                      DateFormat('yyyy/MM/dd hh:mm a').format(tx.date),
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // نافذة تنفيذ عملية (إيداع / سحب) جديدة
  void _showActionDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final amountController = TextEditingController();
    final descController = TextEditingController();

    String selectedType = 'DEPOSIT';
    String? selectedWalletId;

    // جلب قائمة المحافظ المتاحة من الـ UserProvider لتغذية الـ Dropdown
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text(
                '🧾 تسجيل حركة مالية بقيد',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
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
                          labelText:
                              'البيان (مثال: إيداع دفعة إضافية مع أبو جميل)',
                          border: OutlineInputBorder(),
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      final success =
                          await Provider.of<TransactionProvider>(
                            context,
                            listen: false,
                          ).executeTransaction(
                            walletId: selectedWalletId!,
                            type: selectedType,
                            amount: double.parse(amountController.text),
                            description: descController.text.trim(),
                          );

                      if (success && mounted) {
                        // تحديث أرصدة شاشة إدارة المستخدمين بالتزامن
                        userProvider.loadWallets();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              '🚀 تم قيد السند وتحديث الرصيد التأسيسي بنجاح!',
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );
                        Navigator.pop(ctx);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '✗ فشل: ${Provider.of<TransactionProvider>(context, listen: false).errorMessage}',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('قيد وترحيل السند'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
