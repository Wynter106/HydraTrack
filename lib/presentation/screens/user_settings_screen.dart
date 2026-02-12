import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../application/providers/auth_provider.dart';
import '../../business/managers/notification_manager.dart';
import 'profile_setup_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';


class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  
  static const _kNotiEnabledKey = 'noti_enabled';
  static const _kNotiHourKey = 'noti_hour';
  static const _kNotiMinuteKey = 'noti_minute';
  bool _notificationsEnabled = false;

  TimeOfDay _reminderTime = const TimeOfDay(hour: 15, minute: 30);



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

      if (!mounted) return;
      setState(() {
        _notificationsEnabled = enabled;
        if (hour != null && minute != null) {
          _reminderTime = TimeOfDay(hour: hour, minute: minute);
        }
      });
    }

    Future<void> _savePrefs() async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kNotiEnabledKey, _notificationsEnabled);
      await prefs.setInt(_kNotiHourKey, _reminderTime.hour);
      await prefs.setInt(_kNotiMinuteKey, _reminderTime.minute);
    }

  Future<void> _pickReminderTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
    );

    if (picked == null) return;

    setState(() => _reminderTime = picked);
    await _savePrefs();

    // If notifications are ON, refresh the schedule immediately after changing the time
    if (_notificationsEnabled) {
      await NotificationManager.instance.scheduleDailyHydrationReminder(_reminderTime);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Reminder time updated: ${_reminderTime.format(context)}')),
      );
    }
  }

  Future<void> _toggleNotifications(bool val) async {
    setState(() => _notificationsEnabled = val);
    await _savePrefs();

    if (val) {
      await NotificationManager.instance.showTestNotification();
      await NotificationManager.instance.scheduleDailyHydrationReminder(_reminderTime);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Daily reminder scheduled: ${_reminderTime.format(context)}')),
      );
    } else {
      await NotificationManager.instance.cancelHydrationReminder();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Daily reminder cancelled')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Profile',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),

          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Edit Profile'),
            subtitle: const Text('Birthdate, goal, unit preferences'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfileSetupScreen(isFirstTime: false),
                ),
              );
            },
          ),

          const Divider(),

          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Notifications',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),

          SwitchListTile(
            title: const Text('Remind me to drink water'),
            subtitle: Text('Daily at ${_reminderTime.format(context)}'),
            value: _notificationsEnabled,
            onChanged: (val) => _toggleNotifications(val),
          ),

          ListTile(
            leading: const Icon(Icons.access_time),
            title: const Text('Reminder time'),
            subtitle: Text(_reminderTime.format(context)),
            trailing: const Icon(Icons.chevron_right),
            onTap: _pickReminderTime,
          ),

          const Divider(),

          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Account',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),

          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () async {
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
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                final authProvider = context.read<AuthProvider>();
                await authProvider.signOut();

                if (!mounted) return;
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                );
              }
            },
          ),

          const Divider(),

          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'About',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),

          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Version'),
            subtitle: Text('1.0.0 (Alpha)'),
          ),
        ],
      ),
    );
  }
}
