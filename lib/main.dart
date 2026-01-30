import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'presentation/theme/app_theme.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/log_screen.dart';
import 'presentation/screens/drink_library_screen.dart';
import 'presentation/screens/user_goals_screen.dart';
import 'presentation/screens/user_settings_screen.dart';
import 'application/providers/hydration_provider.dart';
import 'application/providers/auth_provider.dart';
import 'presentation/screens/login_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://gzpqnwhfkemioshwycul.supabase.co',
    anonKey: 'sb_publishable_7-U1uPbBIu6d_UBe6JR37A_qZuigKj6'
  );

  runApp(
  MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => HydrationProvider()),
      ChangeNotifierProvider(create: (_) => AuthProvider()),  
    ],
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
      home: const LoginScreen(),
      routes: {
        '/home': (context) => const HomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/library': (context) => const DrinkLibraryScreen(),
        '/log': (context) => const LogScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/goals': (context) => const UserGoalsScreen(),
      },
    );
  }
}