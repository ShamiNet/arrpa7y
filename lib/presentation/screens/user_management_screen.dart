import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../logic/user_provider.dart';
import '../../data/models/wallet_model.dart';
import 'investor_profile_screen.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UserProvider>(context, listen: false).loadWallets();
    });
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'إدارة المستثمرين والصلاحيات',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
        actions: [
          // قائمة منبثقة لاختيار طريقة ترتيب عرض الحسابات
          PopupMenuButton<WalletSortType>(
            icon: const Icon(Icons.sort_rounded, color: Colors.white),
            onSelected: (type) => userProvider.changeSortType(type),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: WalletSortType.newest,
                child: Text('⏳ ترتيب حسب: الأحدث أولاً'),
              ),
              const PopupMenuItem(
                value: WalletSortType.name,
                child: Text('🔤 ترتيب حسب: الاسم أبجدياً'),
              ),
              const PopupMenuItem(
                value: WalletSortType.principal,
                child: Text('💰 ترتيب حسب: رأس المال الأعلى'),
              ),
            ],
          ),
        ],
      ),
      // استبدل جزء الـ body في ملف user_management_screen.dart بهذا الجزء:
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            color: Colors.grey.shade200,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'إجمالي الحسابات: ${userProvider.wallets.length}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  userProvider.currentSort == WalletSortType.newest
                      ? 'الترتيب: الأحدث'
                      : userProvider.currentSort == WalletSortType.name
                      ? 'الترتيب: أبجدي'
                      : 'الترتيب: رأس المال الأعلى',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: userProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : userProvider.errorMessage != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        '✗ خطأ اتصال: ${userProvider.errorMessage}\nتأكد من صلاحيات الـ Token بالسيرفر.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  )
                : userProvider.wallets.isEmpty
                ? const Center(child: Text('لا يوجد مستثمرون مسجلون حالياً.'))
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: userProvider.wallets.length,
                    itemBuilder: (context, index) {
                      final wallet = userProvider.wallets[index];
                      return _buildInvestorCard(wallet, userProvider);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvestorCard(WalletModel wallet, UserProvider provider) {
    final bool isAdmin = wallet.userRole == 'ADMIN';

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => InvestorProfileScreen(wallet: wallet),
            ),
          );
        },
        leading: CircleAvatar(
          backgroundColor: isAdmin
              ? Colors.amber.shade700
              : Theme.of(context).primaryColor,
          child: Icon(
            isAdmin ? Icons.admin_panel_settings : Icons.person,
            color: Colors.white,
          ),
        ),
        title: Row(
          children: [
            Text(
              wallet.userName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (isAdmin)
              Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'مدير',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.amber.shade900,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Text(
          'رأس المال: \$${wallet.principalBalance.toStringAsFixed(2)}\nالمسار: ${wallet.trackType}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // زر التعديل والتحكم بالصلاحيات
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Colors.blue),
              onPressed: () => _showEditDialog(wallet, provider),
            ),
            // زر الحذف النهائي والتصفية
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
              onPressed: () => _confirmDelete(wallet, provider),
            ),
          ],
        ),
      ),
    );
  }

  // نافذة تعديل الاسم وتغيير الصلاحيات
  void _showEditDialog(WalletModel wallet, UserProvider provider) {
    final nameController = TextEditingController(text: wallet.userName);
    String selectedRole = wallet.userRole;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('⚙️ تعديل بيانات وصلاحيات المستثمر'),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final success = await provider.updateUser(
                wallet.userId,
                nameController.text.trim(),
                selectedRole,
              );
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('🚀 تم حفظ التعديلات بنجاح!'),
                    backgroundColor: Colors.green,
                  ),
                );
                Navigator.pop(ctx);
              }
            },
            child: const Text('حفظ التعديلات'),
          ),
        ],
      ),
    );
  }

  // تأكيد الحذف النهائي لحماية الحسابات من الضغط العفوي
  void _confirmDelete(WalletModel wallet, UserProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('⚠️ تنبيه أمني حساس جداً'),
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
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('🗑️ تم تصفية الحساب وحذفه تماماً.'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
                Navigator.pop(ctx);
              }
            },
            child: const Text('نعم، احذف نهائياً'),
          ),
        ],
      ),
    );
  }
}
