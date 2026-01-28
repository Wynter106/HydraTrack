import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'presentation/theme/app_theme.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/log_screen.dart';
import 'presentation/screens/drink_library_screen.dart';
import 'presentation/screens/user_goals_screen.dart';
import 'presentation/screens/user_settings_screen.dart';
import 'application/providers/hydration_provider.dart';
import 'presentation/screens/weekly_stats_screen.dart';
import 'presentation/screens/monthly_stats_screen.dart';
import 'business/managers/notification_manager.dart';

Future<void> main() async {
  // Flutter가 네이티브 플러그인(알림 등) 초기화할 수 있게 준비
  WidgetsFlutterBinding.ensureInitialized();

  // 알림 플러그인 초기화 + (Android 13+) 권한 요청
  await NotificationManager.instance.init();
  await NotificationManager.instance.requestPermissionIfNeeded();

  runApp(
    ChangeNotifierProvider(
      create: (context) => HydrationProvider(),
      child: const MyApp(),
    ),
  );
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
        '/library': (context) => const DrinkLibraryScreen(),
        '/log': (context) => const LogScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/goals': (context) => const UserGoalsScreen(),
        '/weekly-stats': (context) => const WeeklyStatsScreen(),
        '/monthly-stats': (context) => const MonthlyStatsScreen(),
      },
    );
  }
}