import 'package:flutter/material.dart';

/// Shared bottom navigation bar used across all main screens.
/// [currentIndex]: 0=Home, 1=Log, 2=Goals, 3=Alcohol, 4=Settings
class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  const AppBottomNav({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: currentIndex,
      onTap: (index) {
        if (index == currentIndex) return;
        switch (index) {
          case 0:
            Navigator.pushNamed(context, '/home');
            break;
          case 1:
            Navigator.pushNamed(context, '/log');
            break;
          case 2:
            Navigator.pushNamed(context, '/goals');
            break;
          case 3:
            Navigator.pushNamed(context, '/alchome');
            break;
          case 4:
            Navigator.pushNamed(context, '/settings');
            break;
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Log'),
        BottomNavigationBarItem(icon: Icon(Icons.emoji_events), label: 'Goals'),
        BottomNavigationBarItem(icon: Icon(Icons.local_bar), label: 'Alcohol'),
        BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
      ],
    );
  }
}
