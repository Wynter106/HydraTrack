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
  final _birthdateController = TextEditingController();
  final _heightFtController = TextEditingController(text: '5');
  final _heightInController = TextEditingController(text: '7');
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
    _birthdateController.addListener(() {
      setState(() {});
      _calculateCaffeineLimit();
    });
  }

  @override
  void dispose() {
    _birthdateController.dispose();
    _heightFtController.dispose();
    _heightInController.dispose();
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
        _birthdateController.text = profile['birthdate'];
        
        if (profile['height_ft'] != null) {
          _heightFtController.text = profile['height_ft'].toString();
          _heightInController.text = profile['height_in'].toString();
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

  int? _calculateAge() {
    final birthdate = DateTime.tryParse(_birthdateController.text);
    if (birthdate == null) return null;
    
    final now = DateTime.now();
    int age = now.year - birthdate.year;
    if (now.month < birthdate.month || 
        (now.month == birthdate.month && now.day < birthdate.day)) {
      age--;
    }
    return age;
  }

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
    if (_birthdateController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter birthdate')),
      );
      return;
    }

    final birthdate = DateTime.tryParse(_birthdateController.text);
    if (birthdate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid date format (YYYY-MM-DD)')),
      );
      return;
    }

    final heightFt = int.tryParse(_heightFtController.text);
    final heightIn = int.tryParse(_heightInController.text);
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
        'birthdate': _birthdateController.text,
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
        }
        Navigator.pop(context);
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
          : SingleChildScrollView(
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

                  TextField(
                    controller: _birthdateController,
                    decoration: InputDecoration(
                      labelText: 'Birthdate (YYYY-MM-DD)',
                      border: OutlineInputBorder(),
                      helperText: age != null ? 'Age: $age' : null,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  SizedBox(height: 16),

                  Text('Height', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                  SizedBox(height: 8),
                  Row(
                    children: [
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
                      SizedBox(width: 12),
                      DropdownButton<String>(
                        value: _heightUnit,
                        items: [
                          DropdownMenuItem(value: 'ft', child: Text('ft/in')),
                          DropdownMenuItem(value: 'cm', child: Text('cm')),
                        ],
                        onChanged: (value) {
                          setState(() => _heightUnit = value!);
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
                          setState(() => _volumeUnit = value!);
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
                    color: Colors.blue[50],
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
                            ),
                          ),
                          SizedBox(height: 8),
                          Text('💧 Hydration Goal: ${_goalController.text.isEmpty ? "?" : _goalController.text} $_volumeUnit/day'),
                          Text('☕ Caffeine Limit: ${_caffeineLimitController.text.isEmpty ? "400" : _caffeineLimitController.text} mg/day'),
                          if (age != null && age < 21)
                            Text('🔒 Alcohol tracking disabled (under 21)'),
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
    );
  }
}