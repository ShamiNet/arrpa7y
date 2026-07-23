import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../logic/auth_provider.dart';
import '../../logic/user_provider.dart';
import '../widgets/app_ui.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _principalController = TextEditingController();

  String _selectedTrack = 'BITCOIN';

  final List<Map<String, String>> _tracks = [
    {'value': 'BITCOIN', 'label': 'تداول البتكوين'},
    {'value': 'ORGANIZATIONS', 'label': 'استثمار المنظمات'},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _principalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('إنشاء حساب مستثمر جديد'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: AppColors.pageGlow(theme.brightness),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: FadeSlideIn(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Center(child: AppBrandMark(size: 56)),
                              const SizedBox(height: 16),
                              Text(
                                'تسجيل مستثمر جديد',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.titleLarge,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'سيتم إنشاء بيانات الدعم والمحفظة الاستثمارية تلقائياً وآلياً عبر النظام.',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 24),

                              // 1. الاسم الكامل
                              TextFormField(
                                controller: _nameController,
                                decoration: const InputDecoration(
                                  labelText: 'الاسم الكامل للمستثمر',
                                  prefixIcon: Icon(
                                    Icons.person_outline_rounded,
                                  ),
                                ),
                                validator: (val) =>
                                    val == null || val.trim().isEmpty
                                    ? 'الرجاء إدخال الاسم'
                                    : null,
                              ),
                              const SizedBox(height: 12),

                              // 2. حساب شام كاش / الهاتف
                              TextFormField(
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                textDirection: TextDirection.ltr,
                                decoration: const InputDecoration(
                                  labelText: 'حساب شام كاش / رقم الهاتف',
                                  prefixIcon: Icon(
                                    Icons.account_balance_wallet_outlined,
                                  ),
                                  hintText: '09xxxxxxxx',
                                ),
                                validator: (val) =>
                                    val == null || val.trim().isEmpty
                                    ? 'الرجاء إدخال حساب شام كاش'
                                    : null,
                              ),
                              const SizedBox(height: 12),

                              // 3. مسار الاستثمار
                              DropdownButtonFormField<String>(
                                value: _selectedTrack,
                                decoration: const InputDecoration(
                                  labelText: 'مسار الاستثمار التأسيسي',
                                  prefixIcon: Icon(Icons.trending_up),
                                ),
                                items: _tracks.map((track) {
                                  return DropdownMenuItem(
                                    value: track['value'],
                                    child: Text(track['label']!),
                                  );
                                }).toList(),
                                onChanged: (val) =>
                                    setState(() => _selectedTrack = val!),
                              ),
                              const SizedBox(height: 12),

                              // 4. رأس المال الأولي
                              TextFormField(
                                controller: _principalController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                decoration: const InputDecoration(
                                  labelText: 'رأس المال الأولي (\$)',
                                  prefixIcon: Icon(
                                    Icons.monetization_on_outlined,
                                  ),
                                  hintText: '0.00',
                                ),
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty)
                                    return 'الرجاء تحديد رأس المال';
                                  final num = double.tryParse(val);
                                  if (num == null || num < 0)
                                    return 'قيمة مالية غير صالحة';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 24),

                              // زر الإرسال والحفظ
                              FilledButton(
                                onPressed: authProvider.isLoading
                                    ? null
                                    : _submitRegister,
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size.fromHeight(54),
                                ),
                                child: authProvider.isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text('تأسيس وقيد الحساب آلياً'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final userProvider = context.read<UserProvider>();

    final success = await authProvider.signUp(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      trackType: _selectedTrack,
      initialPrincipal: double.parse(_principalController.text.trim()),
    );

    if (!mounted) return;

    if (success) {
      userProvider.loadWallets();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 تم إنشاء حساب المستثمر وقيد محفظته بنجاح!'),
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'تعذر إنشاء الحساب'),
        ),
      );
    }
  }
}
