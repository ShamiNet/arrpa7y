import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:arrpa7y/data/models/transaction_model.dart';
import 'package:arrpa7y/logic/theme_provider.dart';
import 'package:arrpa7y/presentation/widgets/app_ui.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('theme preference is persisted', () async {
    SharedPreferences.setMockInitialValues({});
    final provider = ThemeProvider();
    await provider.setThemeMode(ThemeMode.dark);

    final restoredProvider = ThemeProvider();
    await restoredProvider.loadTheme();

    expect(restoredProvider.themeMode, ThemeMode.dark);
  });

  testWidgets('shared empty state renders Arabic message', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: const Scaffold(
          body: AppStateView(
            kind: AppStateKind.empty,
            title: 'لا توجد بيانات',
          ),
        ),
      ),
    );

    expect(find.text('لا توجد بيانات'), findsOneWidget);
    expect(find.byIcon(Icons.inbox_outlined), findsOneWidget);
  });

  testWidgets('transaction card exposes financial details', (tester) async {
    final transaction = TransactionModel(
      id: 'tx-1',
      walletId: 'wallet-1',
      userName: 'مستثمر تجريبي',
      trackType: 'BITCOIN',
      type: 'DEPOSIT',
      amount: 1200,
      description: 'إيداع رأس مال',
      date: DateTime(2026, 7, 13),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: Scaffold(
          body: TransactionCard(transaction: transaction),
        ),
      ),
    );

    expect(find.text('مستثمر تجريبي'), findsOneWidget);
    expect(find.text('+\$1200.00'), findsOneWidget);
  });
}
