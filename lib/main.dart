import 'package:flutter/material.dart';
import 'package:hydratrack/presentation/screens/user_goals_screen.dart';
import 'package:hydratrack/presentation/screens/user_settings_screen.dart';
import 'presentation/screens/test_database_screen.dart';
import 'presentation/theme/app_theme.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HydraTrack Test',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,

      // Use named routes
      routes: {
        '/': (context) => TestDatabaseScreen(),
        '/settings': (context) => SettingsScreen(),
        '/goals': (context) => const UserGoalsScreen(),
      },
    );
  }
}