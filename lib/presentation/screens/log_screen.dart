
import 'package:flutter/material.dart';
import '../../data/dao/beverages_dao.dart';
import '../../data/models/beverage.dart';

class LogScreen extends StatefulWidget {
  @override
  _LogScreenState createState() => _LogScreenState();
}

class _LogScreenState extends State<LogScreen> {
  final BeverageDao dao = BeverageDao();
  List<Beverage> beverages = [];
  bool isLoading = false;
  String statusMessage = 'Ready to test';
  int hydragoal = 1400;
  int currhydra = 0;
  int cafflim = 400;
  int currcaff = 0;
  int coffcaff = 80;
  int coffhydra = 190;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Log Test'),
        backgroundColor: Colors.blue,
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
                    onPressed: null,
                    child: Text('Go to database'),
                  ),
                  ElevatedButton(
                    onPressed: isLoading ? null : testReset,
                    child: Text('New day'),
                  ),
                ],
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
      });
    } catch (e) {
      setState(() {
        statusMessage = 'Error: $e';
        isLoading = false;
      });
    }
  }

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
      });
    } catch (e) {
      setState(() {
        statusMessage = 'Error: $e';
        isLoading = false;
      });
    }
  }
}