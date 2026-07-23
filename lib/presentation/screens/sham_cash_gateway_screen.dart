import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../logic/user_provider.dart';
import '../../data/models/wallet_model.dart';
import '../../core/theme/app_colors.dart';
import '../widgets/app_ui.dart';

class ShamCashGatewayScreen extends StatefulWidget {
  const ShamCashGatewayScreen({super.key});

  @override
  State<ShamCashGatewayScreen> createState() => _ShamCashGatewayScreenState();
}

class _ShamCashGatewayScreenState extends State<ShamCashGatewayScreen> {
  final _formKey = GlobalKey<FormState>();

  WalletModel? _selectedWallet;
  String _operationType = 'DEPOSIT'; // 'DEPOSIT' أو 'WITHDRAWAL'
  String _selectedTrack = 'BITCOIN'; // 'BITCOIN' أو 'ORGANIZATIONS'
  bool _isSubmitting = false;

  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final wallets = userProvider.wallets;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('بوابة الشامي المالية (ShamCash)'),
            Text(
              'إيداع وسحب وتوجيه ميزانية المستثمرين',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
      body: AppPage(
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1️⃣ كارت الترحيب بـ ShamCash والسيولة الحية
                _buildHeaderCard(theme, userProvider),
                const SizedBox(height: 20),

                // 2️⃣ اختيار نوع العملية (إيداع / سحب)
                const AppSectionHeader(
                  title: 'نوع الحركة المالية',
                  subtitle: 'حدد نوع الإجراء المالي المطلوب تنفيذه',
                  icon: Icons.swap_horiz_rounded,
                ),
                const SizedBox(height: 10),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'DEPOSIT',
                      label: Text('إيداع شحن رصيد'),
                      icon: Icon(Icons.add_circle_outline_rounded),
                    ),
                    ButtonSegment(
                      value: 'WITHDRAWAL',
                      label: Text('سحب مالي فوري'),
                      icon: Icon(Icons.remove_circle_outline_rounded),
                    ),
                  ],
                  selected: {_operationType},
                  onSelectionChanged: (val) {
                    setState(() => _operationType = val.first);
                  },
                ),
                const SizedBox(height: 20),

                // 3️⃣ تفاصيل الحركة
                const AppSectionHeader(
                  title: 'تفاصيل المستهدف والمسار',
                  subtitle: 'اختر حساب المستثمر والمسار المطلوب',
                  icon: Icons.account_balance_outlined,
                ),
                const SizedBox(height: 10),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      children: [
                        // أ) اختيار المستثمر
                        DropdownButtonFormField<WalletModel>(
                          value: _selectedWallet,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'اختر المستثمر المستهدف',
                            prefixIcon: Icon(Icons.person_outline_rounded),
                          ),
                          items: wallets.map((w) {
                            return DropdownMenuItem(
                              value: w,
                              child: Text(
                                '${w.userName} (${w.phone.isEmpty ? "بدون هاتف" : w.phone})',
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (val) =>
                              setState(() => _selectedWallet = val),
                          validator: (val) =>
                              val == null ? 'الرجاء اختيار المستثمر' : null,
                        ),
                        const SizedBox(height: 14),

                        // ب) اختيار المسار (بيتكوين أم منظمات)
                        DropdownButtonFormField<String>(
                          value: _selectedTrack,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'توجيه الميزانية إلى مسار',
                            prefixIcon: Icon(Icons.show_chart_rounded),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'BITCOIN',
                              child: Text('مسار البيتكوين / العملات الرقمية'),
                            ),
                            DropdownMenuItem(
                              value: 'ORGANIZATIONS',
                              child: Text('مسار استثمار المنظمات (أبو جميل)'),
                            ),
                          ],
                          onChanged: (val) =>
                              setState(() => _selectedTrack = val!),
                        ),
                        const SizedBox(height: 14),

                        // ج) مبلغ العملية
                        TextFormField(
                          controller: _amountController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'المبلغ المستهدف (\$)',
                            prefixIcon: Icon(Icons.attach_money_rounded),
                            hintText: '0.00',
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty)
                              return 'الرجاء إدخال المبلغ';
                            final amount = double.tryParse(val.trim());
                            if (amount == null || amount <= 0)
                              return 'مبلغ غير صالح';
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        // د) ملاحظات ورقم مرجعي
                        TextFormField(
                          controller: _descriptionController,
                          decoration: const InputDecoration(
                            labelText:
                                'ملاحظات / رقم المرجعية بـ ShamCash (اختياري)',
                            prefixIcon: Icon(Icons.notes_rounded),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // 4️⃣ زر تنفيذ العملية
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(54),
                    backgroundColor: _operationType == 'DEPOSIT'
                        ? AppColors.success
                        : AppColors.danger,
                    foregroundColor: Colors.white,
                  ),
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
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
                        ? 'جارٍ معالجة الحركة وتسجيلها...'
                        : (_operationType == 'DEPOSIT'
                              ? 'تأكيد وشحن حساب المستثمر'
                              : 'تأكيد وسحب المبلغ من المستثمر'),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: _isSubmitting ? null : _submitOperation,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard(ThemeData theme, UserProvider userProvider) {
    final info = userProvider.shamCashInfo;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.shamCash, Color(0xFF0B433C)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.account_balance_wallet_rounded,
              color: Colors.greenAccent,
              size: 30,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'بوابة عمليات الشامي المالية',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  info != null
                      ? 'متصل ببوابة ShamCash • جاهز لإدارة الحركة'
                      : 'جاري التقييم والربط...',
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitOperation() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    final amount = double.parse(_amountController.text.trim());
    final description = _descriptionController.text.trim();
    bool success = false;

    if (_operationType == 'DEPOSIT') {
      success = await userProvider.depositToWallet(
        userId: _selectedWallet!.userId,
        trackType: _selectedTrack,
        amount: amount,
        description: description,
      );
    } else {
      success = await userProvider.withdrawFromWallet(
        userId: _selectedWallet!.userId,
        trackType: _selectedTrack,
        amount: amount,
        description: description,
      );
    }

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      _amountController.clear();
      _descriptionController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '🎉 تمت عملية ${_operationType == 'DEPOSIT' ? "الإيداع" : "السحب"} وتحديث المحفظة بنجاح!',
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'تعذر إتمام العملية، يرجى التأكد من رصيد المحفظة أو اتصال الشبكة.',
          ),
        ),
      );
    }
  }
}
