import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

// 👈 استخدام المسارات النسبية حصراً يمنع أخطاء الـ Provider
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'logic/ai_provider.dart';
import 'logic/auth_provider.dart';
import 'logic/profit_provider.dart';
import 'logic/theme_provider.dart';
import 'logic/transaction_provider.dart';
import 'logic/user_provider.dart';
import 'presentation/screens/admin_dashboard_screen.dart';
import 'presentation/screens/login_screen.dart';
import 'presentation/screens/profit_simulation_screen.dart';
import 'presentation/screens/transaction_history_screen.dart';
import 'presentation/screens/user_management_screen.dart';
import 'presentation/widgets/app_ui.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(); // تهيئة الفيربيس مباشرة
  // 👈 تفعيل التخزين المحلي المؤقت لبيانات التطبيق
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );
  runApp(const FinancialApp());
}

class FinancialApp extends StatelessWidget {
  const FinancialApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider()..checkAuthStatus(),
        ),
        ChangeNotifierProvider(create: (_) => ThemeProvider()..loadTheme()),
        ChangeNotifierProvider(create: (_) => ProfitProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider(create: (_) => AiProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) => MaterialApp(
          title: 'نظام إدارة الأرباح الشامي',
          debugShowCheckedModeBanner: false,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('ar', 'SY'), Locale('ar', '')],
          locale: const Locale('ar', 'SY'),
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeProvider.themeMode,
          home: Consumer<AuthProvider>(
            builder: (context, auth, _) => AnimatedSwitcher(
              duration: const Duration(milliseconds: 380),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: auth.isAuthenticated
                  ? const MainNavigationScreen(key: ValueKey('main'))
                  : const LoginScreen(key: ValueKey('login')),
            ),
          ),
        ),
      ),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // 🛠️ فحص وتصحيح مسارات الفايربيس (بيتكوين / منظمات) فور فتح التطبيق
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<UserProvider>().fixAndInitializeTracks();
      }
    });
  }

  void _selectDestination(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    final screens = <Widget>[
      AdminDashboardScreen(onNavigateToTab: _selectDestination),
      const ProfitSimulationScreen(),
      const UserManagementScreen(),
      const TransactionHistoryScreen(),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 840;
        final body = IndexedStack(index: _selectedIndex, children: screens);
        return Scaffold(
          body: isWide
              ? Row(
                  children: [
                    _NavigationRail(
                      selectedIndex: _selectedIndex,
                      onDestinationSelected: _selectDestination,
                    ),
                    const VerticalDivider(width: 1),
                    Expanded(child: body),
                  ],
                )
              : Stack(
                  children: [
                    body,
                    Positioned.directional(
                      textDirection: Directionality.of(context),
                      top: MediaQuery.paddingOf(context).top + 7,
                      end: 8,
                      child: _AccountMenu(onAction: _handleMenuAction),
                    ),
                  ],
                ),
          bottomNavigationBar: isWide
              ? null
              : NavigationBar(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: _selectDestination,
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.dashboard_outlined),
                      selectedIcon: Icon(Icons.dashboard_rounded),
                      label: 'الرئيسية',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.query_stats_outlined),
                      selectedIcon: Icon(Icons.query_stats_rounded),
                      label: 'الأرباح',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.groups_2_outlined),
                      selectedIcon: Icon(Icons.groups_2_rounded),
                      label: 'المستثمرون',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.receipt_long_outlined),
                      selectedIcon: Icon(Icons.receipt_long_rounded),
                      label: 'السندات',
                    ),
                  ],
                ),
        );
      },
    );
  }

  Future<void> _handleMenuAction(_MenuAction action) async {
    switch (action) {
      case _MenuAction.theme:
        await _showThemePicker(context);
        break;
      case _MenuAction.logout:
        if (!mounted) return;
        await context.read<AuthProvider>().logout();
        break;
    }
  }
}

enum _MenuAction { theme, logout }

class _AccountMenu extends StatelessWidget {
  const _AccountMenu({required this.onAction});

  final ValueChanged<_MenuAction> onAction;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_MenuAction>(
      tooltip: 'الحساب والإعدادات',
      onSelected: onAction,
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: _MenuAction.theme,
          child: ListTile(
            leading: Icon(Icons.contrast_rounded),
            title: Text('المظهر والثيم'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        PopupMenuDivider(),
        PopupMenuItem(
          value: _MenuAction.logout,
          child: ListTile(
            leading: Icon(Icons.logout_rounded, color: AppColors.danger),
            title: Text('تسجيل الخروج'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
      child: Material(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: .9),
        shape: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(
            Icons.person_outline_rounded,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }
}

class _NavigationRail extends StatelessWidget {
  const _NavigationRail({
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Container(
      width: 238,
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(18, 16, 18, 24),
              child: Row(
                children: [
                  AppBrandMark(size: 45),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'الشامي المالية',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: NavigationRail(
                extended: true,
                minExtendedWidth: 238,
                selectedIndex: selectedIndex,
                onDestinationSelected: onDestinationSelected,
                labelType: NavigationRailLabelType.none,
                destinations: const [
                  NavigationRailDestination(
                    icon: Icon(Icons.dashboard_outlined),
                    selectedIcon: Icon(Icons.dashboard_rounded),
                    label: Text('لوحة القيادة'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.query_stats_outlined),
                    selectedIcon: Icon(Icons.query_stats_rounded),
                    label: Text('محرك الأرباح'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.groups_2_outlined),
                    selectedIcon: Icon(Icons.groups_2_rounded),
                    label: Text('إدارة المستثمرين'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.receipt_long_outlined),
                    selectedIcon: Icon(Icons.receipt_long_rounded),
                    label: Text('كشف الحساب'),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.contrast_rounded),
                    title: const Text('المظهر'),
                    onTap: () => _showThemePicker(context),
                  ),
                  const Divider(),
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.primaryContainer,
                      child: const Icon(Icons.person_outline_rounded),
                    ),
                    title: Text(auth.adminName ?? 'المدير'),
                    subtitle: const Text('حساب الإدارة'),
                    trailing: IconButton(
                      tooltip: 'تسجيل الخروج',
                      onPressed: auth.logout,
                      icon: const Icon(Icons.logout_rounded),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _showThemePicker(BuildContext context) {
  final provider = context.read<ThemeProvider>();
  return showModalBottomSheet<void>(
    context: context,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'اختر مظهر التطبيق',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            RadioGroup<ThemeMode>(
              groupValue: provider.themeMode,
              onChanged: (mode) {
                if (mode == null) return;
                provider.setThemeMode(mode);
                Navigator.pop(context);
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...[
                    (
                      ThemeMode.system,
                      Icons.brightness_auto_rounded,
                      'حسب الجهاز',
                    ),
                    (ThemeMode.light, Icons.light_mode_rounded, 'الوضع الفاتح'),
                    (ThemeMode.dark, Icons.dark_mode_rounded, 'الوضع الداكن'),
                  ].map(
                    (item) => RadioListTile<ThemeMode>(
                      value: item.$1,
                      secondary: Icon(item.$2),
                      title: Text(item.$3),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
