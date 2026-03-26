import 'package:auth_front/db_helper.dart';
import 'package:auth_front/user.dart';

class UserService {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<User?> register(String name, String email, String password) async {
    final db = await _dbHelper.open();
    
    final existing = await db.query('users', where: 'email = ?', whereArgs: [email]);
    if (existing.isNotEmpty) return null;

    final newUser = User(
      name: name,
      email: email,
      password: password,
      role: 'user',
    );

    await db.insert('users', newUser.toMap());
    
    final created = await db.query('users', where: 'email = ?', whereArgs: [email]);
    return User.fromMap(created.first);
  }

  Future<User?> login(String email, String password) async {
    final db = await _dbHelper.open();
    
    final users = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );
    
    return users.isNotEmpty ? User.fromMap(users.first) : null;
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

  bool canCreateProduct(User user) {
    return user.role == 'admin';
  }
}