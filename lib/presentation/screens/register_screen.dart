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
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _principalController = TextEditingController();

  String _selectedTrack = 'BITCOIN';
  bool _obscurePassword = true;

  final List<Map<String, String>> _tracks = [
    {'value': 'BITCOIN', 'label': 'تداول البتكوين'},
    {'value': 'ORGANIZATIONS', 'label': 'استثمار المنظمات (أبو جميل)'},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
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
                                'سيتم إنشاء حساب مستخدم وفتح محفظة استثمارية له في قاعدة البيانات مباشرة.',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 24),

                              // الاسم الكامل
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

                              // البريد الإلكتروني
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                textDirection: TextDirection.ltr,
                                decoration: const InputDecoration(
                                  labelText: 'البريد الإلكتروني للمستثمر',
                                  prefixIcon: Icon(Icons.mail_outline_rounded),
                                  hintText: 'example@mail.com',
                                ),
                                validator: (val) =>
                                    val == null || val.trim().isEmpty
                                    ? 'الرجاء إدخال البريد الإلكتروني'
                                    : null,
                              ),
                              const SizedBox(height: 12),

                              // رقم الهاتف
                              TextFormField(
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                textDirection: TextDirection.ltr,
                                decoration: const InputDecoration(
                                  labelText: 'رقم محفظة شام كاش / الهاتف',
                                  prefixIcon: Icon(Icons.phone_outlined),
                                  hintText: '09xxxxxxxx',
                                ),
                                validator: (val) =>
                                    val == null || val.trim().isEmpty
                                    ? 'الرجاء إدخال رقم الهاتف'
                                    : null,
                              ),
                              const SizedBox(height: 12),

                              // كلمة المرور
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                decoration: InputDecoration(
                                  labelText: 'كلمة مرور الحساب',
                                  prefixIcon: const Icon(
                                    Icons.lock_outline_rounded,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                    ),
                                    onPressed: () => setState(
                                      () =>
                                          _obscurePassword = !_obscurePassword,
                                    ),
                                  ),
                                ),
                                validator: (val) =>
                                    val == null || val.trim().length < 6
                                    ? 'كلمة المرور يجب أن تكون 6 خانات على الأقل'
                                    : null,
                              ),
                              const SizedBox(height: 16),
                              const Divider(),
                              const SizedBox(height: 16),

                              // اختيار مسار الاستثمار لتأسيس المحفظة
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

                              // رأس المال الأولي
                              TextFormField(
                                controller: _principalController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                decoration: const InputDecoration(
                                  labelText: 'رأس المال الأولي للشحن (\$)',
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
                                    : const Text('تأسيس وقيد الحساب سحابياً'),
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
      email: _emailController.text.trim(),
      password: _passwordController.text,
      phone: _phoneController.text.trim(),
      trackType: _selectedTrack,
      initialPrincipal: double.parse(_principalController.text.trim()),
    );

    if (!mounted) return;

    if (success) {
      // تحديث قائمة المحافظ محلياً فور النجاح
      userProvider.loadWallets();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 تم إنشاء حساب المستثمر وقيد محفظته بنجاح!'),
        ),
      );
      Navigator.pop(context); // العودة للشاشة السابقة
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'تعذر إنشاء الحساب'),
        ),
      );
    }
  }
}
