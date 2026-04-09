import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../../application/providers/profile_provider.dart';

class ProfileSetupScreen extends StatefulWidget {
  final bool isFirstTime;
  
  const ProfileSetupScreen({
    super.key,
    this.isFirstTime = true,
  });

  @override
  ProfileSetupScreenState createState() => ProfileSetupScreenState();
}

class ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _supabase = Supabase.instance.client;
  final _ageController = TextEditingController();
  final _heightFtController = TextEditingController(text: '5');
  final _heightInController = TextEditingController(text: '7');
  final _heightCmController = TextEditingController(text: '170');
  final _weightController = TextEditingController(text: '154');
  final _goalController = TextEditingController();
  final _caffeineLimitController = TextEditingController(text: '400');
  
  String _volumeUnit = 'oz';
  String _weightUnit = 'lb';
  String _heightUnit = 'ft';
  bool _loading = false;
  bool _autoCalculate = true;

  @override
  void initState() {
    super.initState();
    if (!widget.isFirstTime) {
      _loadExistingProfile();
    } else {
      _calculateGoal();
      _calculateCaffeineLimit();
    }
    
    _weightController.addListener(_calculateGoal);
    _goalController.addListener(() => setState(() {}));
    _caffeineLimitController.addListener(() => setState(() {}));
    _ageController.addListener(() {
      setState(() {});
      _calculateCaffeineLimit();
    });
  }

  @override
  void dispose() {
    _ageController.dispose();
    _heightFtController.dispose();
    _heightInController.dispose();
    _heightCmController.dispose();
    _weightController.dispose();
    _goalController.dispose();
    _caffeineLimitController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingProfile() async {
    setState(() => _loading = true);
    
    try {
      final userId = _supabase.auth.currentUser!.id;
      final profile = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();

      setState(() {
        final parsed = DateTime.tryParse(profile['birthdate'] ?? '');
        if (parsed != null) {
          final now = DateTime.now();
          int age = now.year - parsed.year;
          if (now.month < parsed.month ||
              (now.month == parsed.month && now.day < parsed.day)) age--;
          _ageController.text = age.toString();
        }
        
        if (profile['height_ft'] != null) {
          final ft = (profile['height_ft'] as num).toInt();
          final inch = (profile['height_in'] as num).toInt();
          _heightFtController.text = ft.toString();
          _heightInController.text = inch.toString();
          final totalCm = (ft * 12 + inch) * 2.54;
          _heightCmController.text = totalCm.round().toString();
        }
        
        if (profile['weight_lb'] != null) {
          _weightController.text = profile['weight_lb'].toString();
        }
        
        _goalController.text = profile['daily_hydration_goal_oz'].toString();
        _caffeineLimitController.text = profile['daily_caffeine_limit_mg'].toString();
        _volumeUnit = profile['preferred_volume_unit'] ?? 'oz';
        _weightUnit = profile['preferred_weight_unit'] ?? 'lb';
        _heightUnit = profile['preferred_height_unit'] ?? 'ft';
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading profile: $e')),
      );
    }
    
    setState(() => _loading = false);
  }

  double _lbToKg(double lb) => lb * 0.453592;
  double _kgToLb(double kg) => kg / 0.453592;

  void _calculateGoal() {
    if (!_autoCalculate) return;
    
    final weight = double.tryParse(_weightController.text);
    if (weight == null || weight <= 0) return;

    final weightKg = _weightUnit == 'lb' ? _lbToKg(weight) : weight;
    final goalMl = weightKg * 33;
    final goalOz = (goalMl / 29.5735).round();
    
    setState(() {
      _goalController.text = goalOz.toString();
    });
  }

  int? _calculateAge() => int.tryParse(_ageController.text);

  void _calculateCaffeineLimit() {
    if (!_autoCalculate) return;
    
    final age = _calculateAge();
    int limit = 400;
    if (age != null && age < 18) {
      limit = 100;
    }
    
    setState(() {
      _caffeineLimitController.text = limit.toString();
    });
  }

  Future<void> _saveProfile() async {
    final age = int.tryParse(_ageController.text);
    if (age == null || age <= 0 || age > 120) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid age')),
      );
      return;
    }
    final birthYear = DateTime.now().year - age;
    final birthdateStr = '$birthYear-01-01';

    int? heightFt;
    int? heightIn;
    if (_heightUnit == 'cm') {
      final cm = double.tryParse(_heightCmController.text) ?? 0;
      final totalInches = cm / 2.54;
      heightFt = (totalInches / 12).floor();
      heightIn = (totalInches % 12).round();
    } else {
      heightFt = int.tryParse(_heightFtController.text);
      heightIn = int.tryParse(_heightInController.text);
    }
    final weight = double.tryParse(_weightController.text);
    final goal = int.tryParse(_goalController.text);
    final caffeineLimit = int.tryParse(_caffeineLimitController.text);

    if (heightFt == null || heightIn == null || weight == null || goal == null || caffeineLimit == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter valid numbers')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final userId = _supabase.auth.currentUser!.id;
      
      final weightLb = _weightUnit == 'lb' ? weight : _kgToLb(weight);
      
      final profileData = {
        'birthdate': birthdateStr,
        'height_ft': heightFt,
        'height_in': heightIn,
        'weight_lb': weightLb,
        'daily_hydration_goal_oz': goal,
        'daily_caffeine_limit_mg': caffeineLimit,
        'preferred_volume_unit': _volumeUnit,
        'preferred_weight_unit': _weightUnit,
        'preferred_height_unit': _heightUnit,
      };
      
      if (widget.isFirstTime) {
        await _supabase.from('profiles').insert({
          'id': userId,
          ...profileData,
        });
      } else {
        await _supabase.from('profiles')
            .update(profileData)
            .eq('id', userId);
      }

      if (widget.isFirstTime) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        if (mounted) {
          await context.read<ProfileProvider>().loadProfile();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile saved successfully'),
              duration: Duration(seconds: 2),
            ),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final age = _calculateAge();

    return Scaffold(
      appBar: widget.isFirstTime 
          ? null 
          : AppBar(title: Text('Edit Profile')),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
              padding: EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (widget.isFirstTime) ...[
                    SizedBox(height: 40),
                    Icon(Icons.person_add, size: 80, color: Colors.blue),
                    SizedBox(height: 16),
                    Text(
                      'Set Up Your Profile',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'We\'ll calculate your personalized goals',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    SizedBox(height: 40),
                  ],

                  _AgeSelector(
                    controller: _ageController,
                    onChanged: () {
                      setState(() {});
                      _calculateCaffeineLimit();
                    },
                  ),
                  if (age != null && age < 18)
                    Padding(
                      padding: const EdgeInsets.only(top: 6, left: 4),
                      child: Text(
                        '⚠️ Caffeine limit set to 100 mg (under 18)',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  SizedBox(height: 16),

                  Text('Height', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      if (_heightUnit == 'ft') ...[
                        Expanded(
                          child: TextField(
                            controller: _heightFtController,
                            decoration: InputDecoration(
                              labelText: 'Feet',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _heightInController,
                            decoration: InputDecoration(
                              labelText: 'Inches',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ] else
                        Expanded(
                          child: TextField(
                            controller: _heightCmController,
                            decoration: InputDecoration(
                              labelText: 'Centimeters',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      SizedBox(width: 12),
                      DropdownButton<String>(
                        value: _heightUnit,
                        items: [
                          DropdownMenuItem(value: 'ft', child: Text('ft/in')),
                          DropdownMenuItem(value: 'cm', child: Text('cm')),
                        ],
                        onChanged: (value) {
                          if (value == null || value == _heightUnit) return;
                          setState(() {
                            if (value == 'cm') {
                              // ft/in → cm
                              final ft = int.tryParse(_heightFtController.text) ?? 0;
                              final inch = int.tryParse(_heightInController.text) ?? 0;
                              final cm = ((ft * 12 + inch) * 2.54).round();
                              _heightCmController.text = cm.toString();
                            } else {
                              // cm → ft/in
                              final cm = double.tryParse(_heightCmController.text) ?? 0;
                              final totalInches = cm / 2.54;
                              final ft = (totalInches / 12).floor();
                              final inch = (totalInches % 12).round();
                              _heightFtController.text = ft.toString();
                              _heightInController.text = inch.toString();
                            }
                            _heightUnit = value;
                          });
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _weightController,
                          decoration: InputDecoration(
                            labelText: 'Weight',
                            border: OutlineInputBorder(),
                            helperText: _autoCalculate ? 'Goals auto-update' : null,
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      SizedBox(width: 12),
                      DropdownButton<String>(
                        value: _weightUnit,
                        items: [
                          DropdownMenuItem(value: 'lb', child: Text('lb')),
                          DropdownMenuItem(value: 'kg', child: Text('kg')),
                        ],
                        onChanged: (value) {
                          final current = double.tryParse(_weightController.text);
                          if (current != null) {
                            setState(() {
                              if (_weightUnit == 'lb' && value == 'kg') {
                                _weightController.text = _lbToKg(current).toStringAsFixed(1);
                              } else if (_weightUnit == 'kg' && value == 'lb') {
                                _weightController.text = _kgToLb(current).toStringAsFixed(1);
                              }
                              _weightUnit = value!;
                            });
                            _calculateGoal();
                          }
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 24),

                  SwitchListTile(
                    title: Text('Auto-calculate goals'),
                    subtitle: Text('Hydration based on weight (×33ml), caffeine on age'),
                    value: _autoCalculate,
                    onChanged: (value) {
                      setState(() {
                        _autoCalculate = value;
                        if (value) {
                          _calculateGoal();
                          _calculateCaffeineLimit();
                        }
                      });
                    },
                  ),
                  SizedBox(height: 8),

                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _goalController,
                          decoration: InputDecoration(
                            labelText: 'Daily Hydration Goal',
                            border: OutlineInputBorder(),
                            enabled: !_autoCalculate,
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      SizedBox(width: 12),
                      DropdownButton<String>(
                        value: _volumeUnit,
                        items: [
                          DropdownMenuItem(value: 'oz', child: Text('oz')),
                          DropdownMenuItem(value: 'ml', child: Text('ml')),
                        ],
                        onChanged: (value) {
                          if (value == null || value == _volumeUnit) return;
                          final current = double.tryParse(_goalController.text);
                          setState(() {
                            if (current != null) {
                              if (_volumeUnit == 'oz' && value == 'ml') {
                                _goalController.text = (current * 29.5735).round().toString();
                              } else if (_volumeUnit == 'ml' && value == 'oz') {
                                _goalController.text = (current / 29.5735).round().toString();
                              }
                            }
                            _volumeUnit = value;
                          });
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 16),

                  TextField(
                    controller: _caffeineLimitController,
                    decoration: InputDecoration(
                      labelText: 'Daily Caffeine Limit',
                      border: OutlineInputBorder(),
                      suffixText: 'mg',
                      helperText: _autoCalculate 
                          ? 'Auto-updates based on age' 
                          : 'Recommended: 400mg adults, 100mg teens',
                      enabled: !_autoCalculate,
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  SizedBox(height: 16),

                  Card(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your Personalized Limits',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            '💧 Hydration Goal: ${_goalController.text.isEmpty ? "?" : _goalController.text} $_volumeUnit/day',
                            style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer),
                          ),
                          Text(
                            '☕ Caffeine Limit: ${_caffeineLimitController.text.isEmpty ? "400" : _caffeineLimitController.text} mg/day',
                            style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer),
                          ),
                          if (age != null && age < 21)
                            Text(
                              '🔒 Alcohol tracking disabled (under 21)',
                              style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer),
                            ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 32),

                  ElevatedButton(
                    onPressed: _saveProfile,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      widget.isFirstTime ? 'Continue' : 'Save Changes',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}

// ===== Age Selector Widget =====
class _AgeSelector extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onChanged;

  const _AgeSelector({required this.controller, required this.onChanged});

  void _increment() {
    final current = int.tryParse(controller.text) ?? 0;
    if (current < 120) {
      controller.text = (current + 1).toString();
      onChanged();
    }
  }

  void _decrement() {
    final current = int.tryParse(controller.text) ?? 0;
    if (current > 1) {
      controller.text = (current - 1).toString();
      onChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Age',
          style: TextStyle(
            fontSize: 13,
            color: colors.primary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: colors.primary, width: 1.5),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Row(
            children: [
              // Decrement
              IconButton(
                icon: Icon(Icons.remove_circle_outline, color: colors.primary, size: 20),
                onPressed: _decrement,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
              // Age display / text input
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colors.onSurface,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                    suffixText: 'yrs',
                  ),
                  onChanged: (_) => onChanged(),
                ),
              ),
              // Increment
              IconButton(
                icon: Icon(Icons.add_circle_outline, color: colors.primary, size: 20),
                onPressed: _increment,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
        ),
      ],
    );
  }
}