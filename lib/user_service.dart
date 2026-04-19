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
  try {
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    
    final usersCount = await _firestore.collection('users').get();
    String role = usersCount.docs.isEmpty ? 'admin' : 'user';
    
    await _firestore.collection('users').doc(userCredential.user!.uid).set({
      'name': name,
      'email': email,
      'role': role,
      'createdAt': FieldValue.serverTimestamp(),
    });
    
    final db = await _dbHelper.open();
    final existingUsers = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );
    
    final newUser = User(
      id: 0,
      name: name,
      email: email,
      password: password,
      role: role,
    );
    
    if (existingUsers.isEmpty) {
      await db.insert('users', newUser.toMap());
    } else {
      await db.update(
        'users',
        newUser.toMap(),
        where: 'email = ?',
        whereArgs: [email],
      );
    }
    
    return newUser;
  } catch (e) {
    print('Ошибка регистрации: $e');
    return null;
  }
}

Future<User?> login(String email, String password) async {
  try {
    final userCredential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    
    final userDoc = await _firestore
        .collection('users')
        .doc(userCredential.user!.uid)
        .get();
    
    String role = 'user';
    String name = email.split('@').first;
    
    if (userDoc.exists) {
      role = userDoc.data()?['role'] ?? 'user';
      name = userDoc.data()?['name'] ?? name;
    }
    
    final db = await _dbHelper.open();
    final existingUsers = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );
    
    User? localUser;
    if (existingUsers.isNotEmpty) {
      localUser = User.fromMap(existingUsers.first);
      await db.update(
        'users',
        {
          'name': name,
          'role': role,
        },
        where: 'id = ?',
        whereArgs: [localUser.id],
      );
    } else {
      localUser = User(
        id: 0,
        name: name,
        email: email,
        password: password,
        role: role,
      );
      await db.insert('users', localUser.toMap());
    }
    
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