class User {
  int? id; 
  String name;
  String email;
  String password;
  String role;

  User({
    this.id,
    required this.name,
    required this.email,
    required this.password,
    this.role = 'user',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'password': password,
      'role': role,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      name: map['name'],
      email: map['email'],
      password: map['password'],
      role: map['role'],
    );
  }

  bool canCreateProduct(User user) {
    return user.role == 'admin';
  }
}