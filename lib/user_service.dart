import 'package:auth_front/user.dart';
import 'package:flutter/material.dart';

List<User> allRegisteredUsers = [];

void saveUser(String name, String email, String password) {
  var newUser = User(name: name, email:email, password:password);
  allRegisteredUsers.add(newUser);
  debugPrint("New user was registered with name = ${newUser.name}");
}

bool isUserExistsByEmail(String email) {
  return allRegisteredUsers.any((user) => user.email == email);
}

bool isCorrectUserDetails(String email, String password) {
  try {
    User foundUser = allRegisteredUsers.firstWhere((user) => user.email == email);

    return foundUser.password == password;

  } catch (e) {
    return false;
  }
}