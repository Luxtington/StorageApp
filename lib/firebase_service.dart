import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:auth_front/user.dart' as local;
import 'package:auth_front/product.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<local.User?> registerWithEmail(String name, String email, String password) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'name': name,
        'email': email,
        'role': 'user',
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      final usersCount = await _firestore.collection('users').get();
      if (usersCount.docs.length == 1) {
        await _firestore.collection('users').doc(userCredential.user!.uid).update({
          'role': 'admin',
        });
      }
      
      return local.User(
        id: int.tryParse(userCredential.user!.uid) ?? 0,
        name: name,
        email: email,
        password: password,
        role: usersCount.docs.length == 1 ? 'admin' : 'user',
      );
    } catch (e) {
      print('Ошибка регистрации: $e');
      return null;
    }
  }

  Future<local.User?> loginWithEmail(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      final userDoc = await _firestore.collection('users').doc(userCredential.user!.uid).get();
      final userData = userDoc.data()!;
      
      return local.User(
        id: int.tryParse(userCredential.user!.uid) ?? 0,
        name: userData['name'],
        email: userData['email'],
        password: password,
        role: userData['role'],
      );
    } catch (e) {
      print('Ошибка входа: $e');
      return null;
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  Stream<List<Product>> getProductsStream() {
    return _firestore.collection('products').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Product(
          id: doc.id,
          name: data['name'],
          description: data['description'],
          imagePath: data['image_path'],
          price: data['price'],
          status: data['status'] == 'available' 
              ? ProductStatus.available 
              : ProductStatus.busy,
        );
      }).toList();
    });
  }

  Future<void> addProductToFirestore(Product product) async {
    await _firestore.collection('products').doc(product.id).set({
      'name': product.name,
      'description': product.description,
      'image_path': product.imagePath,
      'price': product.price,
      'status': product.status == ProductStatus.available ? 'available' : 'busy',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateProductStatus(String productId, ProductStatus newStatus) async {
    await _firestore.collection('products').doc(productId).update({
      'status': newStatus == ProductStatus.available ? 'available' : 'busy',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> addHistoryEntry({
    required String productId,
    required String userId,
    required DateTime takenAt,
    DateTime? returnedAt,
  }) async {
    await _firestore.collection('history').add({
      'product_id': productId,
      'user_id': userId,
      'taken_at': takenAt.toIso8601String(),
      'returned_at': returnedAt?.toIso8601String(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateHistoryEntry(String historyId, DateTime returnedAt) async {
    await _firestore.collection('history').doc(historyId).update({
      'returned_at': returnedAt.toIso8601String(),
    });
  }

  Stream<QuerySnapshot> getHistoryStream() {
    return _firestore.collection('history').orderBy('taken_at', descending: true).snapshots();
  }

  Future<bool> hasInternetConnection() async {
    try {
      await _firestore.collection('users').limit(1).get();
      return true;
    } catch (e) {
      return false;
    }
  }
}