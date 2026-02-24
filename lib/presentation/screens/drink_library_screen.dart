import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/app_card.dart';
import '../widgets/app_button.dart';
import '../../data/dao/beverages_dao.dart';
import '../../data/models/beverage.dart'; 

class DrinkLibraryScreen extends StatefulWidget {
  const DrinkLibraryScreen({super.key});

  @override
  State<DrinkLibraryScreen> createState() => _DrinkLibraryScreenState();
}

class _DrinkLibraryScreenState extends State<DrinkLibraryScreen> {

  final BeverageDao dao = BeverageDao();
  List<Beverage> beverages = [];

  List<Beverage> filteredBeverages = [];
   
  bool isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadBeverages();
  }

  Future<void> _loadBeverages() async {
    try {
      final result = await dao.getAllBeverages();
      setState(() {
        beverages = result;
         filteredBeverages = result;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      debugPrint('Error loading beverages: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load drinks: $e')),
        );
      }
    }
  }




void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value.trim().toLowerCase();

      if (_searchQuery.isEmpty) {
        
        filteredBeverages = beverages;
      } else {
        filteredBeverages = beverages.where((bev) {
          final name = bev.name.toLowerCase();
          return name.contains(_searchQuery);
        }).toList();
      }
    });
  }






  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Drink Library'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Top info / future filters
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Browse available drinks',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            const SizedBox(height: 16),

             TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search drinks by name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                isDense: true,
              ),
              onChanged: _onSearchChanged,
            ),
            const SizedBox(height: 16),

            AppButton(
              label: 'Add Drink',
              filled: false,
              //Call add drink input method
              onPressed: () => _showDrinkInput(context),
            ),

            if (isLoading)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )

            else if (beverages.isEmpty)
              const Expanded(
                child: Center(
                  child: Text('No drinks found in database'),
                ),
              )

             else if (filteredBeverages.isEmpty)
              const Expanded(
                child: Center(
                  child: Text('No drinks match your search'),
                ),
              )

            else
              Expanded(
                child: ListView.separated(
                  itemCount: filteredBeverages.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final beverage = filteredBeverages[index];
                    final totalCaffeine = beverage.caffeinePerOz * beverage.defaultVolumeOz;

                    return AppCard(
                      child: ListTile(
                        title: Text(beverage.name),
                        subtitle: Text(
                          'Volume: ${beverage.defaultVolumeOz.toStringAsFixed(1)} oz\n'
                          'Caffeine: ${totalCaffeine.toStringAsFixed(0)} mg  |  '
                          'Hydration: ${beverage.hydrationFactor.toStringAsFixed(2)}x',
                        ),
                        isThreeLine: true,
                        onTap: () {
                          // Delete this comment later
                          // debugPrint('Selected ${beverage.name}');
                          Navigator.pop(context, beverage);
                        },
                      ),
                    );
                  },
                ),
              ),

            const SizedBox(height: 12),

            // Temporary back button (can also use system back)
            AppButton(
              label: 'Back to Home',
              filled: false,
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  //Activate input dialog and process results
  void _showDrinkInput(BuildContext context) async {
    final drink = await showDialog(
      context: context,
      builder: (context) => DrinkInput(),
    );

    if(drink != null){
      String name = drink["name"];
      double size = drink["size"];
      double caff = drink["caff"];

      double caffPerOz = caff / size;
      double hydFac = switch (caffPerOz) {
        >= 60 => 0.6,
        >= 40 && < 60 => 0.65,
        >= 25 && < 40 => 0.7,
        >= 15 && < 25 => 0.75,
        >= 10 && < 15 => 0.8,
        >= 5 && < 10 => 0.85,
        >= 2 && < 5 => 0.9,
        > 0 && < 2 => 0.95,
        0 => 1.0,
        _ => 0.0
      };

      //Add a drink using the name, caffPerOz, hydFac, and size
      addDrink(size: size, hydFac: hydFac, caffPerOz: caffPerOz, name: name);
    }
  }
}

Future<void> addDrink({
  required double size,
  required double hydFac,
  required double caffPerOz,
  required String name,
}) async {
  final supabase = Supabase.instance.client;
  final userId = supabase.auth.currentUser?.id;
  
  await supabase.from('custom_beverages').insert({
    'id': null,
    'user_id': userId,
    'name': name,
    'caffeine_per_oz': caffPerOz,
    'hydration_factor': hydFac,
    'default_volume_oz': size,
  });
}

class DrinkInput extends StatefulWidget {
  @override
  _AddCustomDrink createState() => _AddCustomDrink();
}

//Create the input fields for the custom drink and return the values
class _AddCustomDrink extends State<DrinkInput> {
  //Ensures control of input text
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _sizeController = TextEditingController();
  final TextEditingController _caffeineController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameController.dispose();
    _sizeController.dispose();
    _caffeineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Enter your custom drink'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(hintText: "Drink name"),
              validator: (value) {
                if (value == null || value.isEmpty){
                  return "Please enter a drink name";
                }
                return null;
              }
            ),
            TextFormField(
              controller: _sizeController,
              decoration: InputDecoration(hintText: "Drink size"),
              validator: (value) {
                if (value == null || value.isEmpty){
                  return "Please enter a drink size";
                }
                else {
                  double? size = double.tryParse(value);
                  if (size == null){
                    return "Please enter a number";
                  }
                }
                return null;
              }
            ),
            TextFormField(
              controller: _caffeineController,
              decoration: InputDecoration(hintText: "Drink caffeine content"),
              validator: (value) {
                if (value == null || value.isEmpty){
                  return "Please enter a caffeine amount";
                }
                else {
                  double? caff = double.tryParse(value);
                  if (caff == null){
                    return "Please enter a number";
                  }
                }
                return null;
              }
            )
          ],
        )
      ),
      actions: <Widget>[
        TextButton(child: const Text("Cancel"),
          onPressed: () {
            Navigator.of(context).pop();
            _nameController.clear();
            _sizeController.clear();
            _caffeineController.clear();
          },
        ),
        TextButton(child: const Text("Submit"),
          onPressed: () {
            if (_formKey.currentState!.validate()) {
            // Return the entered data to the caller
              Navigator.of(context).pop({
                'name': _nameController.text,
                'size': double.parse(_sizeController.text),
                'caff': double.parse(_caffeineController.text)
              });
            }
          },
        )
      ]
    );
  }
}