import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:auth_front/product.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal(); // возвращаем один и тот же снглтон

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'inventory.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        role TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE products(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT NOT NULL,
        image_path TEXT NOT NULL,
        price REAL,
        status TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE product_history(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id TEXT NOT NULL,
        user_id INTEGER NOT NULL,
        taken_at TEXT NOT NULL,
        returned_at TEXT,
        FOREIGN KEY (product_id) REFERENCES products(id),
        FOREIGN KEY (user_id) REFERENCES users(id)
      )
    ''');

    await db.insert('users', {
      'name': 'Администратор',
      'email': 'admin@example.com',
      'password': 'admin123',
      'role': 'admin',
    });

    for (var product in Product.initializeProductList()) {
      await db.insert('products', {
        'id': product.id,
        'name': product.name,
        'description': product.description,
        'image_path': product.imagePath,
        'price': product.price,
        'status': product.status == ProductStatus.available ? 'available' : 'busy',
      });
    }
  }

  Future<Database> open() async {
    return await database;
  }

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
    }
  }
}