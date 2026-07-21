import 'package:arrpa7y/logic/auth_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../logic/user_provider.dart';
import '../../data/models/wallet_model.dart';
import '../../core/theme/app_colors.dart';
import '../widgets/app_ui.dart';
import 'investor_profile_screen.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UserProvider>(context, listen: false).loadWallets();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final wallets = userProvider.wallets
        .where(
          (wallet) =>
              wallet.userName.toLowerCase().contains(_query.toLowerCase()) ||
              wallet.trackName.toLowerCase().contains(_query.toLowerCase()),
        )
        .toList();

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('المستثمرون'),
            Text(
              'إدارة الحسابات والصلاحيات',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<WalletSortType>(
            tooltip: 'ترتيب المستثمرين',
            icon: const Icon(Icons.sort_rounded),
            onSelected: (type) => userProvider.changeSortType(type),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: WalletSortType.newest,
                child: ListTile(
                  leading: Icon(Icons.schedule_rounded),
                  title: Text('الأحدث أولاً'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: WalletSortType.name,
                child: ListTile(
                  leading: Icon(Icons.sort_by_alpha_rounded),
                  title: Text('الاسم أبجدياً'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: WalletSortType.principal,
                child: ListTile(
                  leading: Icon(Icons.trending_up_rounded),
                  title: Text('رأس المال الأعلى'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
          const SizedBox(width: 50),
        ],
      ),
      body: AppPage(
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _query = value.trim()),
              decoration: InputDecoration(
                hintText: 'ابحث باسم المستثمر أو المسار...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'مسح البحث',
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
              ),
            ),
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.groups_2_rounded,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${userProvider.wallets.length} حساباً استثمارياً',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            _sortLabel(userProvider.currentSort),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                    if (_query.isNotEmpty)
                      Chip(label: Text('${wallets.length} نتيجة')),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: userProvider.isLoading
                  ? const AppStateView(kind: AppStateKind.loading)
                  : userProvider.errorMessage != null
                  ? AppStateView(
                      kind: AppStateKind.error,
                      message: userProvider.errorMessage,
                      onRetry: userProvider.loadWallets,
                    )
                  : wallets.isEmpty
                  ? AppStateView(
                      kind: AppStateKind.empty,
                      title: _query.isEmpty
                          ? 'لا يوجد مستثمرون مسجلون'
                          : 'لا توجد نتائج مطابقة',
                      message: _query.isEmpty
                          ? 'ستظهر حسابات المستثمرين هنا عند إضافتها.'
                          : 'جرّب اسماً أو مساراً مختلفاً.',
                    )
                  : RefreshIndicator(
                      onRefresh: userProvider.loadWallets,
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.only(bottom: 16),
                        itemCount: wallets.length,
                        itemBuilder: (context, index) => FadeSlideIn(
                          delay: Duration(milliseconds: index * 35),
                          child: _buildInvestorCard(
                            wallets[index],
                            userProvider,
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
      // 👈 أضف هذا الجزء هنا قبل نهاية Scaffold
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddInvestorDialog(context),
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('إضافة مستثمر'),
      ),
    );
  }

  String _sortLabel(WalletSortType type) {
    switch (type) {
      case WalletSortType.newest:
        return 'مرتب حسب أحدث الحسابات';
      case WalletSortType.name:
        return 'مرتب أبجدياً حسب الاسم';
      case WalletSortType.principal:
        return 'مرتب حسب رأس المال الأعلى';
    }
  }

  void _showAddInvestorDialog(BuildContext context) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final phoneController = TextEditingController();
    final principalController = TextEditingController();
    String selectedTrack = 'BITCOIN';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إضافة مستثمر جديد'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'اسم المستثمر',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'البريد الإلكتروني',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'كلمة المرور',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'رقم الهاتف / الشام كاش',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: principalController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'رأس المال الأولي (\$)',
                  prefixIcon: Icon(Icons.attach_money_rounded),
                ),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: selectedTrack,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'مسار الاستثمار',
                  prefixIcon: Icon(Icons.show_chart_rounded),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'BITCOIN',
                    child: Text(' البيتكوين / العملات '),
                  ),
                  DropdownMenuItem(
                    value: 'ORGANIZATIONS',

                    child: Text('مسار المنظمات / المشاريع'),
                  ),
                ],
                onChanged: (val) => selectedTrack = val!,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final email = emailController.text.trim();
              final password = passwordController.text.trim();
              final phone = phoneController.text.trim();
              final principal =
                  double.tryParse(principalController.text.trim()) ?? 0.0;

              if (name.isEmpty || email.isEmpty || password.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('الرجاء تعبئة الحقول الأساسية')),
                );
                return;
              }

              final authProvider = Provider.of<AuthProvider>(
                context,
                listen: false,
              );
              final success = await authProvider.signUp(
                name: name,
                email: email,
                password: password,
                phone: phone,
                trackType: selectedTrack,
                initialPrincipal: principal,
              );

              if (context.mounted) {
                if (success) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تمت إضافة المستثمر والمحفظة بنجاح'),
                    ),
                  );
                  // إعادة تحميل قائمة المستثمرين
                  Provider.of<UserProvider>(
                    context,
                    listen: false,
                  ).loadWallets();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        authProvider.errorMessage ?? 'فشل إنشاء الحساب',
                      ),
                    ),
                  );
                }
              }
            },
            child: const Text('إنشاء الحساب'),
          ),
        ],
      ),
    );
  }

  Widget _buildInvestorCard(WalletModel wallet, UserProvider provider) {
    final isAdmin = wallet.userRole == 'ADMIN';
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => InvestorProfileScreen(wallet: wallet),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: isAdmin
                    ? AppColors.goldSoft
                    : theme.colorScheme.primaryContainer,
                child: Icon(
                  isAdmin
                      ? Icons.admin_panel_settings_rounded
                      : Icons.person_outline_rounded,
                  color: isAdmin ? AppColors.gold : theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            wallet.userName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium,
                          ),
                        ),
                        if (isAdmin) ...[
                          const SizedBox(width: 7),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.goldSoft,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'مدير',
                              style: TextStyle(
                                color: Color(0xFF805B16),
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                        // 👈 هـــنـــا تُـــضـــاف شارة التجميد الجديدة مباشرة
                        if (!wallet.isActive) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.danger.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'مجمد',
                              style: TextStyle(
                                color: AppColors.danger,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      wallet.trackName.isEmpty
                          ? wallet.trackType
                          : wallet.trackName,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$${wallet.principalBalance.toStringAsFixed(2)}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    'رأس المال',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // زر تجميد / تفعيل الحساب
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        tooltip: wallet.isActive
                            ? 'تجميد الحساب'
                            : 'تفعيل الحساب',
                        onPressed: () async {
                          final success = await provider.toggleUserStatus(
                            wallet.userId,
                            wallet.isActive,
                          );
                          if (context.mounted && success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  wallet.isActive
                                      ? 'تم تجميد حساب ${wallet.userName}'
                                      : 'تم إعادة تفعيل حساب ${wallet.userName}',
                                ),
                              ),
                            );
                          }
                        },
                        icon: Icon(
                          wallet.isActive
                              ? Icons.block_rounded
                              : Icons.check_circle_outline_rounded,
                          size: 19,
                          color: wallet.isActive
                              ? AppColors.warning
                              : AppColors.success,
                        ),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        tooltip: 'تعديل',
                        onPressed: () => _showEditDialog(wallet, provider),
                        icon: const Icon(Icons.edit_outlined, size: 19),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        tooltip: 'حذف',
                        onPressed: () => _confirmDelete(wallet, provider),
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          size: 19,
                          color: AppColors.danger,
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

  // نافذة تعديل الاسم وتغيير الصلاحيات
  Future<void> _showEditDialog(
    WalletModel wallet,
    UserProvider provider,
  ) async {
    final nameController = TextEditingController(text: wallet.userName);
    final phoneController = TextEditingController(text: wallet.phone);
    final bonusController = TextEditingController();

    String selectedRole = wallet.userRole;

    // جلب نسبة البونص الحالية للمستثمر من Firestore لعرضها بالنافذة
    final userDoc = await FirebaseFirestore.instance
        .collection('Users')
        .doc(wallet.userId)
        .get();
    final currentBonus = userDoc.data()?['referralBonusRate'] ?? 0.0;
    bonusController.text = currentBonus.toString();

    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.manage_accounts_outlined),
        title: const Text('تعديل بيانات المستثمر'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'اسم المستثمر',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'رقم المحفظة / الهاتف (ShamCash)',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: bonusController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'نسبة بونص الإحالة الخاصة (%)',
                  prefixIcon: Icon(Icons.percent_rounded),
                  hintText: 'مثال: 0.25',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedRole,
                isExpanded:
                    true, // 👈 يضمن توسع القائمة لتأخذ المساحة المتاحة فقط
                decoration: const InputDecoration(
                  labelText: 'صلاحية الحساب',
                  prefixIcon: Icon(Icons.admin_panel_settings_outlined),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'CLIENT',
                    child: Text(
                      'مستثمر عادي (CLIENT)',
                      overflow: TextOverflow
                          .ellipsis, // 👈 يضع نقاط عند المكونات الطويلة بدلاً من كسر الشاشة
                      maxLines: 1,
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'ADMIN',
                    child: Text(
                      'مدير (ADMIN)', // 👈 اختصار النص قليلاً لمنع طفح الشاشة
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
                onChanged: (val) => selectedRole = val!,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              final double? bonusRate = double.tryParse(
                bonusController.text.trim(),
              );
              final success = await provider.updateUser(
                userId: wallet.userId,
                newName: nameController.text.trim(),
                newRole: selectedRole,
                newPhone: phoneController.text.trim(),
                newBonusRate: bonusRate,
              );
              if (!mounted) return;
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم حفظ وتحديث بيانات المستثمر بنجاح.'),
                  ),
                );
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('حفظ التعديلات'),
          ),
        ],
      ),
    );

    // nameController.dispose();
    // phoneController.dispose();
    // bonusController.dispose();
  }

  // تأكيد الحذف النهائي لحماية الحسابات من الضغط العفوي
  void _confirmDelete(WalletModel wallet, UserProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(
          Icons.warning_amber_rounded,
          color: AppColors.danger,
          size: 34,
        ),
        title: const Text('حذف الحساب نهائياً؟'),
        content: Text(
          'هل أنت متأكد تماماً من حذف المستثمر "${wallet.userName}" وتصفية محفظته الاستثمارية بالكامل من السيرفر نهائياً؟ لا يمكن التراجع عن هذا الإجراء.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء التصفية'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final success = await provider.deleteUser(wallet.userId);
              if (!mounted) return;
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تمت تصفية الحساب وحذفه نهائياً.'),
                  ),
                );
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('نعم، احذف نهائياً'),
          ),
        ],
      ),
    );
  }
}
