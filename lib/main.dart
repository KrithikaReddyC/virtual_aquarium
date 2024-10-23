import 'dart:math'; 
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();
  runApp(VirtualAquariumApp());
}

class VirtualAquariumApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Virtual Aquarium',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: AquariumScreen(),
    );
  }
}

class AquariumScreen extends StatefulWidget {
  @override
  _AquariumScreenState createState() => _AquariumScreenState();
}

class _AquariumScreenState extends State<AquariumScreen> with SingleTickerProviderStateMixin {
  List<Fish> fishList = [];
  late AnimationController _controller;
  double fishSpeed = 1.0;
  Color selectedColor = Colors.blue;
  bool collisionEffectsEnabled = true;
  late Database _database;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: Duration(milliseconds: 30))
      ..addListener(_animateFish)
      ..repeat();

    // Initialize database and load settings
    _initializeDatabase();
  }

  Future<void> _initializeDatabase() async {
    _database = await getDatabase();
    await _loadSettings();
  }

  @override
  void dispose() {
    _controller.dispose();
    _database.close();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await loadSettings(_database);
      setState(() {
        fishSpeed = settings['speed'];
        selectedColor = Color(settings['color']);
        final fishCount = settings['fishCount'];
        fishList = List.generate(
          fishCount, 
          (_) => Fish(color: selectedColor, speed: fishSpeed)
        );
      });
    } catch (e) {
      print('Error loading settings: $e');
    }
  }

  Future<void> _saveSettings() async {
    try {
      await saveSettings(
        _database,
        fishList.length,
        fishSpeed,
        selectedColor.value,
      );

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Settings saved successfully!'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving settings: ${e.toString()}'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _addFish() {
    if (fishList.length < 10) {
      setState(() {
        fishList.add(Fish(color: selectedColor, speed: fishSpeed));
      });
    }
  }

  void _animateFish() {
    setState(() {
      for (var fish in fishList) {
        fish.move();
      }
      if (collisionEffectsEnabled) {
        _checkCollisions();
      }
    });
  }

  void _checkCollisions() {
    for (int i = 0; i < fishList.length; i++) {
      for (int j = i + 1; j < fishList.length; j++) {
        _checkForCollision(fishList[i], fishList[j]);
      }
    }
  }

  void _checkForCollision(Fish fish1, Fish fish2) {
    if ((fish1.position.dx - fish2.position.dx).abs() < 20 &&
        (fish1.position.dy - fish2.position.dy).abs() < 20) {
      fish1.changeDirection();
      fish2.changeDirection();

      setState(() {
        fish1.color = Random().nextBool() ? Colors.red : Colors.green;
        fish2.color = Random().nextBool() ? Colors.blue : Colors.yellow;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Virtual Aquarium'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  color: Colors.lightBlue[100],
                  border: Border.all(color: Colors.blue, width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Stack(
                  children: fishList.map((fish) => fish.build()).toList(),
                ),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: _addFish,
                    child: Text('Add Fish'),
                  ),
                  ElevatedButton(
                    onPressed: _saveSettings,
                    child: Text('Save Settings'),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Text('Fish Speed: ${fishSpeed.toStringAsFixed(1)}'),
              Slider(
                value: fishSpeed,
                min: 0.5,
                max: 5.0,
                onChanged: (value) {
                  setState(() {
                    fishSpeed = value;
                    // Update existing fish speeds
                    for (var fish in fishList) {
                      fish.updateSpeed(value);
                    }
                  });
                },
              ),
              DropdownButton<Color>(
                value: selectedColor,
                items: [
                  DropdownMenuItem(value: Colors.blue, child: Text('Blue')),
                  DropdownMenuItem(value: Colors.red, child: Text('Red')),
                  DropdownMenuItem(value: Colors.green, child: Text('Green')),
                ],
                onChanged: (color) {
                  if (color != null) {
                    setState(() {
                      selectedColor = color;
                    });
                  }
                },
              ),
              SwitchListTile(
                title: Text('Enable Collision Effects'),
                value: collisionEffectsEnabled,
                onChanged: (value) {
                  setState(() {
                    collisionEffectsEnabled = value;
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class Fish {
  Color color;
  double speed;
  Offset position = Offset(150, 150);
  double dx = 1;
  double dy = 1;
  final Random random = Random();

  Fish({required this.color, required this.speed}) {
    dx = random.nextBool() ? speed : -speed;
    dy = random.nextBool() ? speed : -speed;
  }

  void move() {
    position = Offset(position.dx + dx, position.dy + dy);
    if (position.dx <= 0 || position.dx >= 280) {
      dx = -dx;
    }
    if (position.dy <= 0 || position.dy >= 280) {
      dy = -dy;
    }
  }

  void changeDirection() {
    dx = -dx;
    dy = -dy;
  }

  void updateSpeed(double newSpeed) {
    speed = newSpeed;
    dx = dx.isNegative ? -speed : speed;
    dy = dy.isNegative ? -speed : speed;
  }

  Widget build() {
    return Positioned(
      left: position.dx,
      top: position.dy,
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

// Database helper functions
Future<Database> getDatabase() async {
  final dbPath = await getDatabasesPath();
  final path = p.join(dbPath, 'aquarium.db');

  return openDatabase(
    path,
    onCreate: (db, version) async {
      await db.execute('''
        CREATE TABLE settings(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          fishCount INTEGER,
          speed REAL,
          color INTEGER
        )
      ''');
      
      // Insert default settings
      await db.insert('settings', {
        'fishCount': 0,
        'speed': 1.0,
        'color': Colors.blue.value,
      });
    },
    version: 1,
  );
}

Future<void> saveSettings(Database db, int fishCount, double speed, int color) async {
  await db.transaction((txn) async {
    // Delete existing settings
    await txn.delete('settings');
    
    // Insert new settings
    await txn.insert('settings', {
      'fishCount': fishCount,
      'speed': speed,
      'color': color,
    });
  });
}

Future<Map<String, dynamic>> loadSettings(Database db) async {
  final List<Map<String, dynamic>> maps = await db.query('settings');
  
  if (maps.isNotEmpty) {
    return maps.first;
  } else {
    // Return default settings if none exist
    return {
      'fishCount': 0,
      'speed': 1.0,
      'color': Colors.blue.value,
    };
  }
}

