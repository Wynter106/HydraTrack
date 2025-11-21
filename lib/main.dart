import 'package:flutter/material.dart';
import 'presentation/theme/app_theme.dart'; 
import '../presentation/screens/log_screen.dart';
import 'presentation/screens/test_database_screen.dart';

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
      
      routes: {
        '/': (context) => TestDatabaseScreen(),
        '/log': (context) => LogScreen(),
      }
    );
  }
}