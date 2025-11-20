import 'package:flutter/material.dart';
import 'presentation/theme/app_theme.dart'; 
import 'presentation/screens/home_screen.dart';

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
      home: const HomeScreen(),    
      
    );
  }
}