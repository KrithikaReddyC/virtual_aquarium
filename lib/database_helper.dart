// import 'package:flutter/material.dart';
// import 'package:sqflite/sqflite.dart';
// import 'package:path/path.dart' as p;

// class DatabaseHelper {
//   // Singleton pattern for DatabaseHelper
//   static final DatabaseHelper _instance = DatabaseHelper._internal();
//   factory DatabaseHelper() => _instance;

//   DatabaseHelper._internal();

//   // Database instance
//   Database? _database;

//   // Database initialization function
//   Future<Database> getDatabase() async {
//     if (_database != null) return _database!;

//     // Get database path
//     final dbPath = await getDatabasesPath();
//     final path = p.join(dbPath, 'aquarium.db');

//     // Open database
//     _database = await openDatabase(
//       path,
//       onCreate: (db, version) async {
//         // Create settings table on first initialization
//         await db.execute('''
//           CREATE TABLE settings(
//             id INTEGER PRIMARY KEY AUTOINCREMENT,
//             fishCount INTEGER,
//             speed REAL,
//             color INTEGER
//           )
//         ''');

//         // Insert default settings
//         await db.insert('settings', {
//           'fishCount': 0,
//           'speed': 1.0,
//           'color': Colors.blue.value,
//         });
//       },
//       version: 1,
//     );

//     return _database!;
//   }

//   // Save settings to the database
//   Future<void> saveSettings(int fishCount, double speed, int color) async {
//     final db = await getDatabase();

//     // Use a transaction to safely delete old settings and insert new ones
//     await db.transaction((txn) async {
//       await txn.delete('settings'); // Delete the old settings
//       await txn.insert('settings', {
//         'fishCount': fishCount,
//         'speed': speed,
//         'color': color,
//       });
//     });
//   }

//   // Load settings from the database
//   Future<Map<String, dynamic>> loadSettings() async {
//     final db = await getDatabase();

//     // Query the settings table
//     final List<Map<String, dynamic>> maps = await db.query('settings');

//     if (maps.isNotEmpty) {
//       return maps.first; // Return the first (and only) settings row
//     } else {
//       // Return default settings if none exist
//       return {
//         'fishCount': 0,
//         'speed': 1.0,
//         'color': Colors.blue.value,
//       };
//     }
//   }

//   // Close the database when not needed
//   Future<void> closeDatabase() async {
//     final db = await getDatabase();
//     db.close();
//   }
// }

///////
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Database? _database;

  Future<Database> getDatabase() async {
    if (_database != null) return _database!;

    // Get the correct database path
    String dbPath = await getDatabasesPath();
    String fullPath = path.join(dbPath, 'aquarium.db');

    // Open the database and create the table if not exists
    _database = await openDatabase(
      fullPath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE settings (
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
          'color': 0xFF0000FF, // Default to blue
        });
      },
    );

    return _database!;
  }

  Future<void> saveSettings(int fishCount, double speed, int color) async {
    final db = await getDatabase();

    await db.transaction((txn) async {
      await txn.delete('settings');
      await txn.insert('settings', {
        'fishCount': fishCount,
        'speed': speed,
        'color': color,
      });
    });
  }

  Future<Map<String, dynamic>> loadSettings() async {
    final db = await getDatabase();

    final List<Map<String, dynamic>> result = await db.query('settings');
    if (result.isNotEmpty) {
      return result.first;
    } else {
      // Return default settings if no data found
      return {
        'fishCount': 0,
        'speed': 1.0,
        'color': 0xFF0000FF, // Default to blue
      };
    }
  }
}
