
import 'package:flutter/material.dart';
import 'package:hydratrack/data/models/drink_log.dart';
import '../../data/dao/beverages_dao.dart';
import '../../data/models/beverage.dart';

class LogScreen extends StatefulWidget {
  @override
  _LogScreenState createState() => _LogScreenState();
}

class _LogScreenState extends State<LogScreen> {
  final BeverageDao dao = BeverageDao();
  List<DrinkLog> log = [];
  bool isLoading = false;
  String statusMessage = 'Ready to test';
  double hydragoal = 1400;
  double currhydra = 0;
  double cafflim = 400;
  double currcaff = 0;
  double coffcaff = 80;
  double coffhydra = 190;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Log Test'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.emoji_events_outlined), // trophy icon
            tooltip: 'Test Database',
            onPressed: () {
              Navigator.pushNamed(context, '/');
            },
          ),
        ]
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Status message
            Container(
              padding: EdgeInsets.all(16),
              color: Colors.grey[200],
              width: double.infinity,
              child: Text(
                statusMessage,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            //Test charts
            Padding(
              padding: EdgeInsets.all(16),
              child: Wrap(
                spacing: 8,
                children: [
                  Column(
                    children: [
                      Container(
                        height: 200 - (currhydra / hydragoal) * 200,
                        width: 50,
                        color: Colors.grey,
                      ),
                      Container(
                        height: (currhydra / hydragoal) * 200,
                        width: 50,
                        color: Colors.blue,
                      ),
                      Text('Current Hydration: $currhydra ml'),
                      Text('Hydration Goal: $hydragoal ml')
                    ],
                  ),
                  Column(
                    children: [
                      Container(
                        height: 200 - (currcaff / cafflim) * 200,
                        width: 50,
                        color: Colors.grey,
                      ),
                      Container(
                        height: (currcaff / cafflim) * 200,
                        width: 50,
                        color: Colors.red,
                      ),
                      Text('Current Caffeine: $currcaff ml'),
                      Text('Caffeine Limit: $cafflim ml')
                    ],
                  ),
                ]
              ),
            ),

            // Test buttons
            Padding(
              padding: EdgeInsets.all(16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ElevatedButton(
                    onPressed: isLoading ? null : testAddWater,
                    child: Text('Add water'),
                  ),
                  ElevatedButton(
                    onPressed: isLoading ? null : testAddCoffee,
                    child: Text('Add coffee'),
                  ),
                  ElevatedButton(
                    onPressed: isLoading ? null : testReset,
                    child: Text('New day'),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView.builder(
                itemCount: log.length,
                itemBuilder: (context, index) {
                  final beverage = log[index];
                  return ListTile(
                    title: Text('${beverage.id}'),
                    subtitle: Text(
                      'Time: ${beverage.timestamp} mg/oz | '
                      'Hydration: ${beverage.actualHydrationOz}',
                    ),
                    leading: Text('${beverage.volumeOz} oz'),
                    trailing: IconButton(
                                onPressed: null,//deleteBev(index),
                                icon: const Icon(Icons.delete)
                              ),
                  );
                },
              ),
            ),

            // Loading indicator
            if (isLoading)
              Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }

  // Test: Add water
  Future<void> testAddWater() async {
    setState(() {
      isLoading = true;
      statusMessage = 'Adding water...';
    });

    try {
      setState(() {
        currhydra += 200;
        statusMessage = 'Added 200ml of water';
        isLoading = false;
        log.add(DrinkLog(beverageId: 1, volumeOz: 200, timestamp: DateTime.now(), actualHydrationOz: 200));
      });
    } catch (e) {
      setState(() {
        statusMessage = 'Error: $e';
        isLoading = false;
      });
    }
  }

  VoidCallback deleteBev(int index) {
    setState(() {
      isLoading = true;
      statusMessage = 'Removing log...';
    });

    try {
      setState(() {
        currhydra -= log[index].actualHydrationOz;
        isLoading = false;
        log.removeAt(index);
        return;
      });
    } catch (e) {
      setState(() {
        statusMessage = 'Error: $e';
        isLoading = false;
        return;
      });
    }
    return doNothing;
  }

  void doNothing(){}

  Future<void> testReset() async {
    setState(() {
      isLoading = true;
      statusMessage = 'Resetting...';
    });

    try {
      setState(() {
        currhydra = 0;
        currcaff = 0;
        statusMessage = 'Reset';
        isLoading = false;
        log = [];
      });
    } catch (e) {
      setState(() {
        statusMessage = 'Error: $e';
        isLoading = false;
      });
    }
  }

  // Test: Add coffee
  Future<void> testAddCoffee() async {
    setState(() {
      isLoading = true;
      statusMessage = 'Adding coffee...';
    });

    try {
      setState(() {
        currhydra += coffhydra;
        currcaff += coffcaff;
        statusMessage = 'Added 200ml of coffee';
        isLoading = false;
        log.add(DrinkLog(beverageId: 2, volumeOz: 200, timestamp: DateTime.now(), actualHydrationOz: 190));
      });
    } catch (e) {
      setState(() {
        statusMessage = 'Error: $e';
        isLoading = false;
      });
    }
  }
}