import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../application/providers/auth_provider.dart';
import '../../application/providers/theme_provider.dart';
import '../../business/managers/notification_manager.dart';
import 'profile_setup_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const _kNotiEnabledKey = 'noti_enabled';
  static const _kNotiHourKey = 'noti_hour';
  static const _kNotiMinuteKey = 'noti_minute';

  static const _kMedNotiEnabledKey = 'med_noti_enabled';
  static const _kMedNotiHourKey = 'med_noti_hour';
  static const _kMedNotiMinuteKey = 'med_noti_minute';

  bool _notificationsEnabled = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 15, minute: 30);

  bool _medicationNotificationsEnabled = false;
  TimeOfDay _medicationReminderTime = const TimeOfDay(hour: 21, minute: 0);

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_kNotiEnabledKey) ?? false;
    final hour = prefs.getInt(_kNotiHourKey);
    final minute = prefs.getInt(_kNotiMinuteKey);

    final medEnabled = prefs.getBool(_kMedNotiEnabledKey) ?? false;
    final medHour = prefs.getInt(_kMedNotiHourKey);
    final medMinute = prefs.getInt(_kMedNotiMinuteKey);

    if (!mounted) return;
    setState(() {
      _notificationsEnabled = enabled;
      if (hour != null && minute != null) {
        _reminderTime = TimeOfDay(hour: hour, minute: minute);
      }
      _medicationNotificationsEnabled = medEnabled;
      if (medHour != null && medMinute != null) {
        _medicationReminderTime = TimeOfDay(hour: medHour, minute: medMinute);
      }
    });
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kNotiEnabledKey, _notificationsEnabled);
    await prefs.setInt(_kNotiHourKey, _reminderTime.hour);
    await prefs.setInt(_kNotiMinuteKey, _reminderTime.minute);

    await prefs.setBool(_kMedNotiEnabledKey, _medicationNotificationsEnabled);
    await prefs.setInt(_kMedNotiHourKey, _medicationReminderTime.hour);
    await prefs.setInt(_kMedNotiMinuteKey, _medicationReminderTime.minute);
  }

  Future<void> _toggleNotifications(bool val) async {
    setState(() => _notificationsEnabled = val);
    await _savePrefs();

    if (val) {
      await NotificationManager.instance.requestPermissionIfNeeded();
      await NotificationManager.instance.showTestNotification();
      await NotificationManager.instance.scheduleDailyHydrationReminder(_reminderTime);
    } else {
      await NotificationManager.instance.cancelHydrationReminder();
    }
  }

  Future<void> _pickReminderTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
    );

    if (picked == null) return;

    setState(() => _reminderTime = picked);
    await _savePrefs();

    if (_notificationsEnabled) {
      await NotificationManager.instance.scheduleDailyHydrationReminder(_reminderTime);
    }
  }

  Future<void> _toggleMedicationNotifications(bool val) async {
    setState(() => _medicationNotificationsEnabled = val);
    await _savePrefs();

    if (val) {
      await NotificationManager.instance.requestPermissionIfNeeded();
      await NotificationManager.instance.scheduleDailyMedicationReminder(_medicationReminderTime);
    } else {
      await NotificationManager.instance.cancelMedicationReminder();
    }
  }

  Future<void> _pickMedicationReminderTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _medicationReminderTime,
    );
    if (picked == null) return;
    setState(() => _medicationReminderTime = picked);
    await _savePrefs();
    if (_medicationNotificationsEnabled) {
      await NotificationManager.instance.scheduleDailyMedicationReminder(_medicationReminderTime);
    }
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

      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // ===== APPEARANCE =====
          _SectionHeader(title: 'Appearance', icon: Icons.palette_outlined),
          const _ThemeSection(),

          const SizedBox(height: 8),

          // ===== NOTIFICATIONS =====
          _SectionHeader(title: 'Notifications', icon: Icons.notifications_outlined),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              children: [
                SwitchListTile(
                  secondary: Icon(Icons.notifications_active, color: colors.primary),
                  title: const Text('Remind me to drink water'),
                  subtitle: Text('Daily at ${_reminderTime.format(context)}'),
                  value: _notificationsEnabled,
                  onChanged: _toggleNotifications,
                ),
                if (_notificationsEnabled) ...[
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.access_time, color: colors.primary),
                    title: const Text('Reminder time'),
                    subtitle: Text(_reminderTime.format(context)),
                    trailing: Icon(Icons.chevron_right, color: colors.onSurface.withOpacity(0.5)),
                    onTap: _pickReminderTime,
                  ),
                ],

                const Divider(height: 1),

                SwitchListTile(
                  secondary: Icon(Icons.medication_outlined, color: colors.primary),
                  title: const Text('Medication reminder'),
                  subtitle: Text('Daily at ${_medicationReminderTime.format(context)}'),
                  value: _medicationNotificationsEnabled,
                  onChanged: _toggleMedicationNotifications,
                ),

                if (_medicationNotificationsEnabled) ...[
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.access_time, color: colors.primary),
                    title: const Text('Medication time'),
                    subtitle: Text(_medicationReminderTime.format(context)),
                    trailing: Icon(Icons.chevron_right, color: colors.onSurface.withOpacity(0.5)),
                    onTap: _pickMedicationReminderTime,
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 8),

          // ===== PROFILE =====
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
                    builder: (context) => const ProfileSetupScreen(isFirstTime: false),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 8),

          // ===== ACCOUNT =====
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

          // ===== ABOUT =====
          _SectionHeader(title: 'About', icon: Icons.info_outline),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ListTile(
              leading: Icon(Icons.water_drop_outlined, color: colors.primary),
              title: const Text('HydraTrack'),
              subtitle: const Text('Version 1.2.0'),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
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
              child: Icon(Icons.check_circle, color: colors.primary, size: 22),
            ),
          ],
        ),
      ),
    );
  }
}