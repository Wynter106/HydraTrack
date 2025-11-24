import 'package:flutter/material.dart';
import '../../data/dao/beverages_dao.dart';
import '../../data/models/beverage.dart';

class TestDatabaseScreen extends StatefulWidget {
  @override
  _TestDatabaseScreenState createState() => _TestDatabaseScreenState();
}

class _TestDatabaseScreenState extends State<TestDatabaseScreen> {
  final BeverageDao dao = BeverageDao();
  List<Beverage> beverages = [];
  bool isLoading = false;
  String statusMessage = 'Ready to test';

  // Test: Load all beverages
  Future<void> testLoadAll() async {
    setState(() {
      isLoading = true;
      statusMessage = 'Loading all beverages...';
    });

    try {
      final result = await dao.getAllBeverages();
      setState(() {
        beverages = result;
        statusMessage = 'Loaded ${result.length} beverages';
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        statusMessage = 'Error: $e';
        isLoading = false;
      });
    }
  }

  // Test: Search for "coffee"
  Future<void> testSearchCoffee() async {
    setState(() {
      isLoading = true;
      statusMessage = 'Searching for "coffee"...';
    });

    try {
      final result = await dao.searchBeverages('coffee');
      setState(() {
        beverages = result;
        statusMessage = 'Found ${result.length} results for "coffee"';
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        statusMessage = 'Error: $e';
        isLoading = false;
      });
    }
  }

  // Test: Count beverages
  Future<void> testCount() async {
    setState(() {
      isLoading = true;
      statusMessage = 'Counting beverages...';
    });

    try {
      final count = await dao.getBeverageCount();
      setState(() {
        statusMessage = 'Total beverages in database: $count';
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        statusMessage = 'Error: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Database Test'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.view_headline), // trophy icon
            tooltip: 'Log',
            onPressed: () {
              Navigator.pushNamed(context, '/log');
            },
          ),
  ],

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

            // Test buttons
            Padding(
              padding: EdgeInsets.all(16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ElevatedButton(
                    onPressed: isLoading ? null : testLoadAll,
                    child: Text('Load All'),
                  ),
                  ElevatedButton(
                    onPressed: isLoading ? null : testSearchCoffee,
                    child: Text('Search "Coffee"'),
                  ),
                  ElevatedButton(
                    onPressed: isLoading ? null : testCount,
                    child: Text('Count'),
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

            // Results list
            Expanded(
              child: ListView.builder(
                itemCount: beverages.length,
                itemBuilder: (context, index) {
                  final beverage = beverages[index];
                  return ListTile(
                    title: Text(beverage.name),
                    subtitle: Text(
                      'Caffeine: ${beverage.caffeinePerOz} mg/oz | '
                      'Hydration: ${beverage.hydrationFactor}',
                    ),
                    trailing: Text('${beverage.defaultVolumeOz} oz'),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}