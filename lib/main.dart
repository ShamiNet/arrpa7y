import 'package:arrpa7y/logic/auth_provider.dart';
import 'package:arrpa7y/logic/server_file_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'logic/profit_provider.dart';
import 'logic/user_provider.dart';
import 'presentation/screens/profit_simulation_screen.dart';
import 'presentation/screens/user_management_screen.dart';
import 'logic/transaction_provider.dart';
import 'presentation/screens/transaction_history_screen.dart';

// أضف استيراد شاشة اللوجن في الأعلى
import 'presentation/screens/login_screen.dart';

void main() {
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
        ), // استدعاء الفحص التلقائي فوراً
        ChangeNotifierProvider(create: (_) => ProfitProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider(
          create: (_) => ServerFileProvider(),
        ), // المحرك الجديد هنا
      ],
      child: MaterialApp(
        title: 'نظام إدارة الأرباح الشامي',
        debugShowCheckedModeBanner: false,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('ar', 'SY'), Locale('ar', '')],
        locale: const Locale('ar', 'SY'),
        theme: ThemeData(
          fontFamily: 'Cairo',
          primaryColor: const Color(0xFF1B5E20),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1B5E20),
            primary: const Color(0xFF1B5E20),
            secondary: const Color(0xFF00796B),
            background: const Color(0xFFF5F5F5),
          ),
          useMaterial3: true,
        ),
        // بوابات الحماية الذكية
        home: Consumer<AuthProvider>(
          builder: (context, auth, _) {
            if (auth.isAuthenticated) {
              return const MainNavigationScreen(); // مسجل دخول -> افتح لوحة التحكم
            } else {
              return const LoginScreen(); // غير مسجل -> احجبه في شاشة اللوجن
            }
          },
        ),
      ),
    );
  }
}

// شاشة التنقل الرئيسية
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const ProfitSimulationScreen(),
    const UserManagementScreen(),
    const TransactionHistoryScreen(), // الشاشة الثالثة الجديدة
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics_outlined),
            label: 'محرك الأرباح',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_alt_outlined),
            label: 'إدارة المستثمرين',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            label: 'كشف الحساب',
          ),
        ],
      ),
    );
  }
}
