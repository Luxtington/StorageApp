import 'package:auth_front/db_helper.dart';
import 'package:auth_front/product.dart';
import 'package:auth_front/product_history.dart';
import 'package:auth_front/user.dart';

class ProductService {
  final DatabaseHelper dbHelper = DatabaseHelper();

  Future<List<Product>> getAllProducts() async {
    final db = await dbHelper.open();
    final products = await db.query('products');
    return products.map((p) => Product.fromMap(p)).toList();
  }

  Future<Product?> getProductById(String id) async {
    final db = await dbHelper.open();
    final products = await db.query('products', where: 'id = ?', whereArgs: [id]);
    return products.isNotEmpty ? Product.fromMap(products.first) : null;
  }

  Future<void> addProduct(Product product) async {
    final db = await dbHelper.open();
    await db.insert('products', product.toMap());
  }

  Future<bool> takeProduct(String productId, User user) async {
    final db = await dbHelper.open();
    
    final product = await getProductById(productId);
    if (product == null) return false;
    if (product.status != ProductStatus.available) return false;

    await db.update(
      'products',
      {'status': 'busy'},
      where: 'id = ?',
      whereArgs: [productId],
    );

    await db.insert('product_history', {
      'product_id': productId,
      'user_id': user.id,
      'taken_at': DateTime.now().toIso8601String(),
      'returned_at': null,
    });

    return true;
  }

  Future<bool> returnProduct(String productId, User user) async {
    final db = await dbHelper.open();
    
    final product = await getProductById(productId);
    if (product == null) return false;
    if (product.status != ProductStatus.busy) return false;

    final history = await db.query(
      'product_history',
      where: 'product_id = ? AND returned_at IS NULL',
      whereArgs: [productId],
    );

    if (history.isEmpty) return false;

    await db.update(
      'product_history',
      {'returned_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [history.first['id']],
    );

    await db.update(
      'products',
      {'status': 'available'},
      where: 'id = ?',
      whereArgs: [productId],
    );

    return true;
  }

  Future<List<ProductHistory>> getProductHistory(String productId) async {
    final db = await dbHelper.open();
    final history = await db.query(
      'product_history',
      where: 'product_id = ?',
      whereArgs: [productId],
    );
    return history.map((h) => ProductHistory.fromMap(h)).toList();
  }

  Future<List<ProductHistory>> getUserHistory(int userId) async {
    final db = await dbHelper.open();
    final history = await db.query(
      'product_history',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    return history.map((h) => ProductHistory.fromMap(h)).toList();
  }
}