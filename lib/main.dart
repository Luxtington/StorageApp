import 'package:auth_front/user_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:auth_front/login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp();
    print('Firebase инициализирован успешно');
  } catch (e) {
    print('Ошибка инициализации Firebase: $e');
  }

  await _createAdminIfNotExists();
  
  runApp(const MyApp());
}

Future<void> _createAdminIfNotExists() async {
  final userService = UserService();
  
  final adminExists = await userService.isAdminExistsInFirebase();
  
  if (!adminExists) {
    await userService.register(
      'Администратор',
      'admin@example.com',
      'admin123',
    );
    
    await userService.setUserRole('admin@example.com', 'admin');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Auth Front',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}