import 'package:auth_front/db_helper.dart';
import 'package:auth_front/user.dart';
import 'package:auth_front/firebase_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide User;

class UserService {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final FirebaseService _firebase = FirebaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<User?> register(String name, String email, String password) async {
    final firebaseUser = await _firebase.registerWithEmail(name, email, password);
    
    if (firebaseUser == null) return null;
    
    final db = await _dbHelper.open();
    final existing = await db.query('users', where: 'email = ?', whereArgs: [email]);
    
    if (existing.isEmpty) {
      await db.insert('users', firebaseUser.toMap());
    }
    
    return firebaseUser;
  }

Future<User?> login(String email, String password) async {
  try {
    final userCredential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    
    final userDoc = await _firestore
        .collection('users')
        .where('email', isEqualTo: email)
        .get();
    
    String role = 'user';
    if (userDoc.docs.isNotEmpty) {
      role = userDoc.docs.first.data()['role'] ?? 'user';
    }
    
    final db = await _dbHelper.open();
    final localUser = User(
      id: 0,
      name: userDoc.docs.first.data()['name'] ?? email.split('@').first,
      email: email,
      password: password,
      role: role,
    );
    
    await db.insert('users', localUser.toMap());
    
    return localUser;
  } catch (e) {
    print('Ошибка входа: $e');
    return null;
  }
}

  Future<bool> isAdminExistsInFirebase() async {
  try {
    final db = await _dbHelper.open();
    final users = await db.query('users', where: 'role = ?', whereArgs: ['admin']);
    return users.isNotEmpty;
  } catch (e) {
    return false;
  }
}

Future<void> setUserRole(String email, String role) async {
  final user = await _firebase.loginWithEmail(email, 'admin123');
  if (user != null) {
    final db = await _dbHelper.open();
    await db.update(
      'users',
      {'role': role},
      where: 'email = ?',
      whereArgs: [email],
    );
  }
}

  Future<bool> isUserExistsByEmail(String email) async {
    final db = await _dbHelper.open();
    final users = await db.query('users', where: 'email = ?', whereArgs: [email]);
    return users.isNotEmpty;
  }

  Future<bool> isCorrectUserDetails(String email, String password) async {
    final user = await login(email, password);
    return user != null;
  }

  Future<User?> getUserById(int id) async {
    final db = await _dbHelper.open();
    final users = await db.query('users', where: 'id = ?', whereArgs: [id]);
    return users.isNotEmpty ? User.fromMap(users.first) : null;
  }

  Future<User?> getUserByEmail(String email) async {
    final db = await _dbHelper.open();
    final users = await db.query('users', where: 'email = ?', whereArgs: [email]);
    return users.isNotEmpty ? User.fromMap(users.first) : null;
  }

  bool canCreateProduct(User user) {
    return user.role == 'admin';
  }

  Future<void> logout() async {
    await _firebase.logout();
  }
}