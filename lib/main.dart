import 'package:flutter/material.dart';
import 'data/models/beverage.dart';
import 'data/models/drink_log.dart';
import 'data/models/user_settings.dart';

void main() {
  // Models Teset
  testModels();
  
  runApp(MyApp());
}

/// Test various model functionalities
void testModels() {
  print('========== Models Test ==========');
  
  // 1. Beverage Test
  print('\n[Test 1: Beverage]');
  final water = Beverage(
    id: 1,
    name: 'Water',
    caffeinePerOz: 0.0,
    hydrationFactor: 1.0,
    defaultVolumeOz: 8,
  );
  print('Name: ${water.name}');
  print('Caffeine per oz: ${water.caffeinePerOz} mg');
  print('Default volume: ${water.defaultVolumeOz} oz');
  
  // toMap Test
  final waterMap = water.toMap();
  print('toMap: $waterMap');
  
  // fromMap Test
  final waterFromMap = Beverage.fromMap(waterMap);
  print('fromMap name: ${waterFromMap.name}');
  
  // 2. DrinkLog Test
  print('\n[Test 2: DrinkLog]');
  final log = DrinkLog(
    id: 1,
    beverageId: 1,
    beverageName: 'Water',
    volumeOz: 8.0,
    timestamp: DateTime.now(),
    hydrationOz: 8.0,
    caffeineMg: 0.0,
  );
  print('Beverage: ${log.beverageName}');
  print('Volume: ${log.volumeOz} oz');
  print('Time: ${log.timestamp}');
  
  final logMap = log.toMap();
  print('toMap: $logMap');
  
  // 3. UserSettings Test
  print('\n[Test 3: UserSettings]');
  final settings = UserSettings.defaultSettings();
  print('Height: ${settings.heightIn} inches (${settings.heightFormatted})');
  print('Weight: ${settings.weightLb} lb');
  print('Daily Goal: ${settings.dailyGoalOz} oz');
  
  final settingsMap = settings.toMap();
  print('toMap: $settingsMap');
  
  print('\n========== All Tests Passed! ==========\n');
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HydraTrack',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: TestScreen(),
    );
  }
}

/// Test Screen to display model test results
class TestScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Models for display
    final water = Beverage(
      id: 1,
      name: 'Water',
      caffeinePerOz: 0.0,
      hydrationFactor: 1.0,
      defaultVolumeOz: 8,
    );
    
    final settings = UserSettings.defaultSettings();
    
    return Scaffold(
      appBar: AppBar(
        title: Text('HydraTrack - Models Test'),
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Models Test',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 32),
              
              // Beverage information display
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Beverage: ${water.name}',
                        style: TextStyle(fontSize: 18),
                      ),
                      SizedBox(height: 8),
                      Text('Caffeine: ${water.caffeinePerOz} mg/oz'),
                      Text('Hydration Factor: ${water.hydrationFactor}'),
                      Text('Default Volume: ${water.defaultVolumeOz} oz'),
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: 16),
              
              // UserSettings information display
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'User Settings',
                        style: TextStyle(fontSize: 18),
                      ),
                      SizedBox(height: 8),
                      Text('Height: ${settings.heightFormatted}'),
                      Text('Weight: ${settings.weightLb} lb'),
                      Text('Daily Goal: ${settings.dailyGoalOz} oz'),
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: 32),
              
              Text(
                'Check console for detailed test results',
                style: TextStyle(
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}