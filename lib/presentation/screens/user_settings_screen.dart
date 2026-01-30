import 'package:flutter/material.dart';
import '../../data/models/user_settings.dart';
import '../../business/managers/notification_manager.dart';

enum WeightUnit { lb, kg }
enum VolumeUnit { oz, ml }

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late UserSettings _settings;

  // Height split into feet + inches for UI
  late TextEditingController _heightFeetController;
  late TextEditingController _heightInchesController;

  late TextEditingController _weightController;
  late TextEditingController _goalController;

  WeightUnit _weightUnit = WeightUnit.lb;
  VolumeUnit _volumeUnit = VolumeUnit.oz;
  bool _notificationsEnabled = false;

  @override
  void initState() {
    super.initState();

    // Start from your default settings
    _settings = UserSettings.defaultSettings();

    _heightFeetController =
        TextEditingController(text: _settings.heightFeet.toString());
    _heightInchesController =
        TextEditingController(text: _settings.heightInchesRemaining.toString());

    _weightController =
        TextEditingController(text: _settings.weightLb.toStringAsFixed(1));
    _goalController =
        TextEditingController(text: _settings.dailyGoalOz.toStringAsFixed(0));

    _notificationsEnabled = _settings.notificationsEnabled;
  }

  @override
  void dispose() {
    _heightFeetController.dispose();
    _heightInchesController.dispose();
    _weightController.dispose();
    _goalController.dispose();
    super.dispose();
  }

  double _lbToKg(double lb) => lb * 0.453592;
  double _kgToLb(double kg) => kg * 2.20462;

  double _ozToMl(double oz) => oz * 29.5735;
  double _mlToOz(double ml) => ml / 29.5735;

  void _onWeightUnitChanged(WeightUnit? newUnit) {
    if (newUnit == null) return;
    final current = double.tryParse(_weightController.text);
    if (current == null) {
      setState(() => _weightUnit = newUnit);
      return;
    }

    setState(() {
      if (_weightUnit == WeightUnit.lb && newUnit == WeightUnit.kg) {
        _weightController.text = _lbToKg(current).toStringAsFixed(1);
      } else if (_weightUnit == WeightUnit.kg && newUnit == WeightUnit.lb) {
        _weightController.text = _kgToLb(current).toStringAsFixed(1);
      }
      _weightUnit = newUnit;
    });
  }

  void _onVolumeUnitChanged(VolumeUnit? newUnit) {
    if (newUnit == null) return;
    final current = double.tryParse(_goalController.text);
    if (current == null) {
      setState(() => _volumeUnit = newUnit);
      return;
    }

    setState(() {
      if (_volumeUnit == VolumeUnit.oz && newUnit == VolumeUnit.ml) {
        _goalController.text = _ozToMl(current).toStringAsFixed(0);
      } else if (_volumeUnit == VolumeUnit.ml && newUnit == VolumeUnit.oz) {
        _goalController.text = _mlToOz(current).toStringAsFixed(0);
      }
      _volumeUnit = newUnit;
    });
  }

  void _saveSettings() {
    final feet = int.tryParse(_heightFeetController.text);
    final inches = int.tryParse(_heightInchesController.text);
    final weightValue = double.tryParse(_weightController.text);
    final goalValue = double.tryParse(_goalController.text);

    if (feet == null ||
        inches == null ||
        weightValue == null ||
        goalValue == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid numbers.')),
      );
      return;
    }

    final heightIn = feet * 12 + inches;

    // Convert back to internal units: inches, lb, oz
    final weightLb =
        _weightUnit == WeightUnit.lb ? weightValue : _kgToLb(weightValue);
    final goalOz =
        _volumeUnit == VolumeUnit.oz ? goalValue : _mlToOz(goalValue);

    _settings = UserSettings(
      id: _settings.id, // stays null for now unless loaded from DB
      heightIn: heightIn.toDouble(),
      weightLb: weightLb,
      dailyGoalOz: goalOz,
      notificationsEnabled: _notificationsEnabled,
      lastModified: DateTime.now(),
    );

    // TODO: hook into UserSettingsDao to actually save:
    // await UserSettingsDao().upsertSettings(_settings);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings saved (not wired to DB yet).')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Profile',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              // Height: feet + inches
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _heightFeetController,
                      decoration: const InputDecoration(
                        labelText: 'Height (ft)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _heightInchesController,
                      decoration: const InputDecoration(
                        labelText: 'Height (in)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Weight + unit
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _weightController,
                      decoration: const InputDecoration(
                        labelText: 'Weight',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  DropdownButton<WeightUnit>(
                    value: _weightUnit,
                    onChanged: _onWeightUnitChanged,
                    items: const [
                      DropdownMenuItem(
                        value: WeightUnit.lb,
                        child: Text('lb'),
                      ),
                      DropdownMenuItem(
                        value: WeightUnit.kg,
                        child: Text('kg'),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 24),
              const Text(
                'Daily Hydration Goal',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _goalController,
                      decoration: const InputDecoration(
                        labelText: 'Daily goal',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  DropdownButton<VolumeUnit>(
                    value: _volumeUnit,
                    onChanged: _onVolumeUnitChanged,
                    items: const [
                      DropdownMenuItem(
                        value: VolumeUnit.oz,
                        child: Text('oz'),
                      ),
                      DropdownMenuItem(
                        value: VolumeUnit.ml,
                        child: Text('ml'),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 24),
              const Text(
                'Analytics',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              ListTile(
                leading: const Icon(Icons.bar_chart),
                title: const Text('Weekly Stats'),
                subtitle: const Text('View this week’s hydration & caffeine'),
                onTap: () => Navigator.pushNamed(context, '/weekly-stats'),
              ),

              ListTile(
                leading: const Icon(Icons.calendar_month),
                title: const Text('Monthly Stats'),
                subtitle: const Text('View this month’s hydration & caffeine'),
                onTap: () => Navigator.pushNamed(context, '/monthly-stats'),
              ),

              const SizedBox(height: 24),
              const Text(
                'Notifications',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              
              SwitchListTile(
                  title: const Text('Remind me to drink water'),
                  value: _notificationsEnabled,

//테스트 잠깐
onChanged: (val) async {
  setState(() => _notificationsEnabled = val);

  if (val) {
    await NotificationManager.instance.showTestNotification(); // 즉시 알림
    await NotificationManager.instance.scheduleOneShotTestInSeconds(15); // 15초 뒤 스케줄 : 참고로 여기 15초는 제대로 동작용 보여주기 위한것이니 다음주에 고치자
  } else {
    await NotificationManager.instance.cancelAll();
  }
},

// onChanged: (val) async {
//   setState(() => _notificationsEnabled = val);

//   if (val) {
//     await NotificationManager.instance.showTestNotification(); // 즉시 알림
//     await NotificationManager.instance.scheduleDailyHydrationReminders();
//     await NotificationManager.instance.scheduleTestRemindersNext1to3Minutes(); // +1~+3분 3개
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text('Scheduled test reminders for +1/+2/+3 minutes')),
//     );
//   } else {
//     await NotificationManager.instance.cancelAll();
//   }
// },

              ),

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveSettings,
                  child: const Text('Save Settings'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
