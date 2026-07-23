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
  String _selectedTrackFilter =
      'ALL'; // 👈 حالة الفلتر المختارة ('ALL', 'BITCOIN', 'ORGANIZATIONS')

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

    // 🎯 دالة الفلترة المزدوجة (حسب البحث + حسب المسار المختار)
    final wallets = userProvider.wallets.where((wallet) {
      final matchesQuery =
          wallet.userName.toLowerCase().contains(_query.toLowerCase()) ||
          wallet.trackName.toLowerCase().contains(_query.toLowerCase());

      final matchesTrack =
          _selectedTrackFilter == 'ALL' ||
          wallet.trackType == _selectedTrackFilter;

      return matchesQuery && matchesTrack;
    }).toList();

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
            // 1️⃣ حقل البحث
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
            const SizedBox(height: 10),

            // 2️⃣ 🔍 أزرار الفلترة حسب المسار الاستثماري (الكل / بيتكوين / منظمات)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('الكل 🌐'),
                    selected: _selectedTrackFilter == 'ALL',
                    onSelected: (selected) {
                      if (selected)
                        setState(() => _selectedTrackFilter = 'ALL');
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('تداول البيتكوين ₿'),
                    selected: _selectedTrackFilter == 'BITCOIN',
                    selectedColor: const Color(
                      0xFFF7931A,
                    ).withValues(alpha: 0.25),
                    labelStyle: TextStyle(
                      color: _selectedTrackFilter == 'BITCOIN'
                          ? const Color(0xFFF7931A)
                          : null,
                      fontWeight: _selectedTrackFilter == 'BITCOIN'
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedTrackFilter = 'BITCOIN');
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('استثمار المنظمات 🏢'),
                    selected: _selectedTrackFilter == 'ORGANIZATIONS',
                    selectedColor: const Color(
                      0xFF0088CC,
                    ).withValues(alpha: 0.25),
                    labelStyle: TextStyle(
                      color: _selectedTrackFilter == 'ORGANIZATIONS'
                          ? const Color(0xFF0088CC)
                          : null,
                      fontWeight: _selectedTrackFilter == 'ORGANIZATIONS'
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedTrackFilter = 'ORGANIZATIONS');
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 3️⃣ كارت الملخص وحساب النتايج
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
                            '${wallets.length} مستثمر مستعرض',
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
                    if (_selectedTrackFilter != 'ALL' || _query.isNotEmpty)
                      Chip(label: Text('${wallets.length} نتيجة')),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // 4️⃣ قائمة الحسابات
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
                      title: 'لا توجد نتائج مطابقة',
                      message: 'جرّب تغيير الفلتر أو البحث عن اسم آخر.',
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
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'user_management_fab',
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
    final phoneController = TextEditingController();
    final principalController = TextEditingController();
    String selectedTrack = 'BITCOIN';
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          return AlertDialog(
            title: const Text('إضافة مستثمر جديد'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 1. اسم المستثمر
                  TextField(
                    controller: nameController,
                    enabled: !isSubmitting,
                    decoration: const InputDecoration(
                      labelText: 'اسم المستثمر الكامل',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 2. حساب شام كاش / الهاتف
                  TextField(
                    controller: phoneController,
                    enabled: !isSubmitting,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'حساب شام كاش / الهاتف',
                      prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 3. رأس المال الأولي
                  TextField(
                    controller: principalController,
                    enabled: !isSubmitting,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'رأس المال الأولي (\$)',
                      prefixIcon: Icon(Icons.attach_money_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 4. المسار الاستثماري
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
                        child: Text('البيتكوين / العملات الرقمية'),
                      ),
                      DropdownMenuItem(
                        value: 'ORGANIZATIONS',
                        child: Text('استثمار المنظمات / المشاريع'),
                      ),
                    ],
                    onChanged: isSubmitting
                        ? null
                        : (val) => setDialogState(() => selectedTrack = val!),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        final name = nameController.text.trim();
                        final phone = phoneController.text.trim();
                        final principal =
                            double.tryParse(principalController.text.trim()) ??
                            0.0;

                        if (name.isEmpty || phone.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('الرجاء إدخال الاسم وحساب شام كاش'),
                            ),
                          );
                          return;
                        }

                        // تفعيل حالة التحميل داخل النافذة المنبثقة
                        setDialogState(() => isSubmitting = true);

                        try {
                          final authProvider = Provider.of<AuthProvider>(
                            context,
                            listen: false,
                          );

                          final success = await authProvider.signUp(
                            name: name,
                            phone: phone,
                            trackType: selectedTrack,
                            initialPrincipal: principal,
                          );

                          if (ctx.mounted) {
                            if (success) {
                              Navigator.pop(ctx); // إغلاق الدايلوج عند النجاح
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    '🎉 تم إنشاء حساب المستثمر ومحفظته تلقائياً!',
                                  ),
                                ),
                              );
                              if (context.mounted) {
                                Provider.of<UserProvider>(
                                  context,
                                  listen: false,
                                ).loadWallets();
                              }
                            } else {
                              setDialogState(() => isSubmitting = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    authProvider.errorMessage ??
                                        'فشل إنشاء الحساب، يرجى المحاولة لاحقاً',
                                  ),
                                ),
                              );
                            }
                          }
                        } catch (e) {
                          if (ctx.mounted) {
                            setDialogState(() => isSubmitting = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('حدث خطأ غير متوقع: $e')),
                            );
                          }
                        }
                      },
                child: isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('إضافة وقيد المستثمر'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showQuickGatewayDialog(BuildContext context, WalletModel wallet) {
    final formKey = GlobalKey<FormState>();
    final amountController = TextEditingController();
    final descController = TextEditingController();

    String selectedTrack = wallet.trackType.isNotEmpty
        ? wallet.trackType
        : 'BITCOIN';
    String operationType = 'DEPOSIT';
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          return AlertDialog(
            icon: const Icon(Icons.swap_horiz_rounded, size: 28),
            title: Text('حركة مالية لـ ${wallet.userName}'),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                          value: 'DEPOSIT',
                          label: Text('إيداع'),
                          icon: Icon(Icons.add_circle_outline_rounded),
                        ),
                        ButtonSegment(
                          value: 'WITHDRAWAL',
                          label: Text('سحب'),
                          icon: Icon(Icons.remove_circle_outline_rounded),
                        ),
                      ],
                      selected: {operationType},
                      onSelectionChanged: (val) {
                        setDialogState(() => operationType = val.first);
                      },
                    ),
                    const SizedBox(height: 12),

                    DropdownButtonFormField<String>(
                      value: selectedTrack,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'توجيه الميزانية إلى المسار',
                        prefixIcon: Icon(Icons.show_chart_rounded),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'BITCOIN',
                          child: Text('تداول البيتكوين / العملات'),
                        ),
                        DropdownMenuItem(
                          value: 'ORGANIZATIONS',
                          child: Text('استثمار المنظمات / المشاريع'),
                        ),
                      ],
                      onChanged: (val) =>
                          setDialogState(() => selectedTrack = val!),
                    ),
                    const SizedBox(height: 10),

                    TextFormField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'المبلغ المستهدف (\$)',
                        prefixIcon: Icon(Icons.attach_money_rounded),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'أدخل المبلغ';
                        }
                        final num = double.tryParse(val.trim());
                        if (num == null || num <= 0) return 'غير صالح';
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),

                    TextFormField(
                      controller: descController,
                      decoration: const InputDecoration(
                        labelText: 'بيان / ملاحظات (اختياري)',
                        prefixIcon: Icon(Icons.notes_rounded),
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
                  backgroundColor: operationType == 'DEPOSIT'
                      ? AppColors.success
                      : AppColors.danger,
                ),
                onPressed: isSubmitting
                    ? null
                    : () async {
                        if (formKey.currentState!.validate()) {
                          setDialogState(() => isSubmitting = true);
                          final userProvider = Provider.of<UserProvider>(
                            context,
                            listen: false,
                          );

                          final amount = double.parse(
                            amountController.text.trim(),
                          );
                          final desc = descController.text.trim();
                          bool success = false;

                          if (operationType == 'DEPOSIT') {
                            success = await userProvider.depositToWallet(
                              userId: wallet.userId,
                              trackType: selectedTrack,
                              amount: amount,
                              description: desc,
                            );
                          } else {
                            success = await userProvider.withdrawFromWallet(
                              userId: wallet.userId,
                              trackType: selectedTrack,
                              amount: amount,
                              description: desc,
                            );
                          }

                          if (context.mounted) {
                            if (success) {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '🎉 تم إتمام ${operationType == 'DEPOSIT' ? "الإيداع" : "السحب"} وتوجيه المحفظة بنجاح!',
                                  ),
                                ),
                              );
                            } else {
                              setDialogState(() => isSubmitting = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'تعذر إتمام العملية، يرجى التحقق من الرصيد.',
                                  ),
                                ),
                              );
                            }
                          }
                        }
                      },
                child: isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        operationType == 'DEPOSIT'
                            ? 'تأكيد الإيداع'
                            : 'تأكيد السحب',
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInvestorCard(WalletModel wallet, UserProvider provider) {
    final isAdmin = wallet.userRole == 'ADMIN';
    final theme = Theme.of(context);

    final bool isBitcoin = wallet.trackType == 'BITCOIN';
    final Color trackColor = isBitcoin
        ? const Color(0xFFF7931A)
        : const Color(0xFF0088CC);
    final IconData trackIcon = isBitcoin
        ? Icons.currency_bitcoin_rounded
        : Icons.corporate_fare_rounded;
    final String trackLabel = wallet.trackName.isNotEmpty
        ? wallet.trackName
        : (isBitcoin ? 'تداول البيتكوين' : 'استثمار المنظمات');

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      wallet.userName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: trackColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: trackColor.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(trackIcon, size: 13, color: trackColor),
                              const SizedBox(width: 4),
                              Text(
                                trackLabel,
                                style: TextStyle(
                                  color: trackColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),

                        if (isAdmin)
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

                        if (!wallet.isActive)
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
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        tooltip: 'بوابة الحركة المالية السريعة',
                        onPressed: () =>
                            _showQuickGatewayDialog(context, wallet),
                        icon: const Icon(
                          Icons.swap_horiz_rounded,
                          size: 20,
                          color: AppColors.emerald,
                        ),
                      ),
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

  Future<void> _showEditDialog(
    WalletModel wallet,
    UserProvider provider,
  ) async {
    final nameController = TextEditingController(text: wallet.userName);
    final phoneController = TextEditingController(text: wallet.phone);
    final bonusController = TextEditingController();
    final deductionController = TextEditingController();

    String selectedRole = wallet.userRole;

    final userDoc = await FirebaseFirestore.instance
        .collection('Users')
        .doc(wallet.userId)
        .get();
    final userData = userDoc.data() ?? {};
    bonusController.text = (userData['referralBonusRate'] ?? 0.0).toString();
    deductionController.text = (userData['customDeductionRate'] ?? 0.0)
        .toString();

    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.manage_accounts_outlined),
        title: const Text('تعديل بيانات المستثمر ونسبه'),
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
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: bonusController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'نسبة البونص (%)',
                        prefixIcon: Icon(Icons.card_giftcard_rounded),
                        hintText: '0.25',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: deductionController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'نسبة الخصم الخاصة (%)',
                        prefixIcon: Icon(Icons.content_cut_rounded),
                        hintText: '2.0',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedRole,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'صلاحية الحساب',
                  prefixIcon: Icon(Icons.admin_panel_settings_outlined),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'CLIENT',
                    child: Text(
                      'مستثمر عادي (CLIENT)',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'ADMIN',
                    child: Text(
                      'مدير (ADMIN)',
                      overflow: TextOverflow.ellipsis,
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
              final double? deductionRate = double.tryParse(
                deductionController.text.trim(),
              );

              await FirebaseFirestore.instance
                  .collection('Users')
                  .doc(wallet.userId)
                  .update({
                    'name': nameController.text.trim(),
                    'role': selectedRole,
                    'phone': phoneController.text.trim(),
                    'referralBonusRate': bonusRate ?? 0.0,
                    'customDeductionRate': deductionRate ?? 0.0,
                  });

              if (!mounted) return;
              provider.loadWallets();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('تم حفظ وتحديث البيانات والنسب المخصصة بنجاح.'),
                ),
              );
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('حفظ التعديلات'),
          ),
        ],
      ),
    );
  }

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
