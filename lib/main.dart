import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'presentation/theme/app_theme.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/login_screen.dart';
import 'presentation/screens/log_screen.dart';
import 'presentation/screens/drink_library_screen.dart';
import 'presentation/screens/user_goals_screen.dart';
import 'presentation/screens/user_settings_screen.dart';
import 'presentation/screens/weekly_stats_screen.dart';
import 'presentation/screens/monthly_stats_screen.dart';
import 'presentation/screens/manage_quick_add_screen.dart';
import 'presentation/screens/alcohol_home_screen.dart';
import 'presentation/screens/alcohol_drink_library_screen.dart';
import 'application/providers/hydration_provider.dart';
import 'application/providers/auth_provider.dart';
import 'business/managers/notification_manager.dart';
import 'application/providers/profile_provider.dart';
import 'application/providers/favorite_drinks_provider.dart';
import 'application/providers/theme_provider.dart';
import 'business/services/connectivity_service.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Edge-to-edge: 시스템 네비게이션 바 영역까지 앱이 그려지도록 설정
  // Scaffold의 bottomNavigationBar가 자동으로 inset 처리함
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  await Supabase.initialize(
    url: 'https://gzpqnwhfkemioshwycul.supabase.co',
    anonKey: 'sb_publishable_7-U1uPbBIu6d_UBe6JR37A_qZuigKj6'
  );

  await NotificationManager.instance.init();
  // 알림 권한 요청은 설정 화면에서 알림을 켤 때 요청 (앱 시작 시 X)

  final prefs = await SharedPreferences.getInstance();
  final hasLaunchedBefore = prefs.getBool('has_launched_before') ?? false;
  if (!hasLaunchedBefore) {
    await prefs.setBool('has_launched_before', true);
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => HydrationProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => FavoriteDrinksProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => ConnectivityService()),
      ],
      child: MyApp(isFirstLaunch: !hasLaunchedBefore),
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool isFirstLaunch;
  const MyApp({super.key, required this.isFirstLaunch});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      title: 'HydraTrack',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,

      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          if (auth.isLoggedIn) return const HomeScreen();
          return LoginScreen(startWithSignUp: isFirstLaunch);
        },
      ),
      
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/library': (context) => const DrinkLibraryScreen(),
        '/log': (context) => const LogScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/goals': (context) => const UserGoalsScreen(),
        '/weekly-stats': (context) => const WeeklyStatsScreen(),
        '/monthly-stats': (context) => const MonthlyStatsScreen(),
        '/manage-quick-add': (context) => const ManageQuickAddScreen(),
        '/alchome': (context) => const AlcoholHomeScreen(),
        '/alclib': (context) => const AlcoholDrinkLibraryScreen(),
      },
    );
  }
}