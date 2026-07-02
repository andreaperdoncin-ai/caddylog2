import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'state/app_state.dart';
import 'widgets/add_expense_sheet.dart';
import 'views/settings_view.dart';
import 'views/home_view.dart';
import 'views/electric_view.dart';
import 'views/fuel_view.dart';
import 'views/other_expenses_view.dart';
import 'views/statistics_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const CaddyLogApp());
}

class CaddyLogApp extends StatelessWidget {
  const CaddyLogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        ColorScheme darkScheme = darkDynamic?.harmonized() ?? ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        );

        return MaterialApp(
          title: 'Caddy Log',
          theme: ThemeData(
            colorScheme: darkScheme,
            useMaterial3: true,
          ),
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('it', 'IT')],
          home: const MainScreen(),
        );
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final AppState _appState = AppState();

  @override
  Widget build(BuildContext context) {
    // Pagine temporanee in attesa di essere ricostruite
    final List<Widget> pages = [
      HomeView(appState: _appState),
      ElectricView(appState: _appState),
      FuelView(appState: _appState),
      OtherExpensesView(appState: _appState),
      StatisticsView(appState: _appState),
      SettingsView(appState: _appState),
    ];

    return Scaffold(
      body: pages[_currentIndex],
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        elevation: 4,
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Theme.of(context).colorScheme.surface,
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
            builder: (ctx) => AddExpenseSheet(appState: _appState),
          );
        },
        child: const Icon(Icons.add, size: 32),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.bolt), label: 'Elettrico'),
          BottomNavigationBarItem(icon: Icon(Icons.local_gas_station), label: 'Benzina'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Spese'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Stat.'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Opzioni'),
        ],
      ),
    );
  }
}