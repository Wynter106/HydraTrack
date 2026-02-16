import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../application/providers/auth_provider.dart';
import '../../application/providers/theme_provider.dart';
import 'profile_setup_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // ===== APPEARANCE SECTION =====
          _SectionHeader(title: 'Appearance', icon: Icons.palette_outlined),
          const _ThemeSection(),
          
          const SizedBox(height: 8),
          
          // ===== PROFILE SECTION =====
          _SectionHeader(title: 'Profile', icon: Icons.person_outline),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ListTile(
              leading: Icon(Icons.edit_outlined, color: colors.primary),
              title: const Text('Edit Profile'),
              subtitle: const Text('Birthdate, goal, unit preferences'),
              trailing: Icon(Icons.chevron_right, color: colors.onSurface.withOpacity(0.5)),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfileSetupScreen(isFirstTime: false),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 8),

          // ===== ACCOUNT SECTION =====
          _SectionHeader(title: 'Account', icon: Icons.account_circle_outlined),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ListTile(
              leading: Icon(Icons.logout, color: colors.error),
              title: Text('Logout', style: TextStyle(color: colors.error)),
              onTap: () => _showLogoutDialog(context),
            ),
          ),

          const SizedBox(height: 8),

          // ===== ABOUT SECTION =====
          _SectionHeader(title: 'About', icon: Icons.info_outline),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ListTile(
              leading: Icon(Icons.water_drop_outlined, color: colors.primary),
              title: const Text('HydraTrack'),
              subtitle: const Text('Version 1.0.0 (Alpha)'),
            ),
          ),
          
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Future<void> _showLogoutDialog(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Logout',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      final authProvider = context.read<AuthProvider>();
      await authProvider.signOut();
      
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/login',
        (route) => false,
      );
    }
  }
}

// ===== SECTION HEADER =====
class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: colors.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colors.primary,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ===== THEME SECTION =====
class _ThemeSection extends StatelessWidget {
  const _ThemeSection();

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            _ThemeOption(
              title: 'Light',
              subtitle: 'Fresh & Clean',
              icon: Icons.wb_sunny_outlined,
              isSelected: themeProvider.isLightMode,
              onTap: () => themeProvider.setLightMode(),
            ),
            const SizedBox(height: 8),
            _ThemeOption(
              title: 'Dark',
              subtitle: 'Sleek & Premium',
              icon: Icons.nightlight_outlined,
              isSelected: themeProvider.isDarkMode,
              onTap: () => themeProvider.setDarkMode(),
            ),
            const SizedBox(height: 8),
            _ThemeOption(
              title: 'System',
              subtitle: 'Match device settings',
              icon: Icons.settings_suggest_outlined,
              isSelected: themeProvider.isSystemMode,
              onTap: () => themeProvider.setSystemMode(),
            ),
          ],
        ),
      ),
    );
  }
}

// ===== THEME OPTION TILE =====
class _ThemeOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? colors.primary.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? colors.primary : colors.outline.withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected 
                    ? colors.primary.withOpacity(0.2) 
                    : colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 20,
                color: isSelected ? colors.primary : colors.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected ? colors.primary : colors.onSurface,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: isSelected ? 1.0 : 0.0,
              child: Icon(
                Icons.check_circle,
                color: colors.primary,
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }
}