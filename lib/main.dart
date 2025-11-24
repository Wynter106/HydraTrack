import 'package:flutter/material.dart';
import 'presentation/theme/app_theme.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/log_screen.dart';
import 'presentation/screens/drink_library_screen.dart';
import 'presentation/screens/user_goals_screen.dart';
import 'presentation/screens/user_settings_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HydraTrack',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const HomeScreen(),
      routes: {
        '/library': (context) => DrinkLibraryScreen(),
        '/log': (context) => LogScreen(),
        '/settings': (context) => SettingsScreen(),
        '/goals': (context) => const UserGoalsScreen(),
      },
    );
  }
}