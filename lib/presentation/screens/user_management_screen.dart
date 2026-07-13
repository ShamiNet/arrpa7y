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
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
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
    String selectedRole = wallet.userRole;

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.manage_accounts_outlined),
        title: const Text('تعديل بيانات المستثمر'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'اسم المستثمر المحدث',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: selectedRole,
              decoration: const InputDecoration(
                labelText: 'صلاحية الحساب في النظام',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'CLIENT',
                  child: Text('مستثمر عادي (CLIENT)'),
                ),
                DropdownMenuItem(
                  value: 'ADMIN',
                  child: Text('مدير كامل الصلاحيات (ADMIN)'),
                ),
              ],
              onChanged: (val) => selectedRole = val!,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              final success = await provider.updateUser(
                wallet.userId,
                nameController.text.trim(),
                selectedRole,
              );
              if (!mounted) return;
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم حفظ التعديلات بنجاح.')),
                );
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('حفظ التعديلات'),
          ),
        ],
      ),
    );
    nameController.dispose();
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
