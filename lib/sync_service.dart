import 'package:auth_front/firebase_service.dart';
import 'package:auth_front/db_helper.dart';
import 'package:auth_front/product.dart';

class SyncService {
  final FirebaseService _firebase = FirebaseService();
  final DatabaseHelper _localDb = DatabaseHelper();

  Future<void> syncProductsToLocal() async {
    final hasInternet = await _firebase.hasInternetConnection();
    if (!hasInternet) return;

    final db = await _localDb.open();
    final firebaseProducts = await _firebase.getProductsStream().first;
    
    await db.delete('products');
    
    for (var product in firebaseProducts) {
      await db.insert('products', product.toMap());
    }
  }

  Future<void> syncLocalChangesToFirebase() async {
    final hasInternet = await _firebase.hasInternetConnection();
    if (!hasInternet) return;

    final db = await _localDb.open();
    final localProducts = await db.query('products');
    
    for (var product in localProducts) {
      await _firebase.updateProductStatus(
        product['id'] as String, 
        product['status'] == 'available' 
            ? ProductStatus.available 
            : ProductStatus.busy
      );
    }
  }

  Future<void> fullSync() async {
    await syncProductsToLocal();
    await syncLocalChangesToFirebase();
  }
}