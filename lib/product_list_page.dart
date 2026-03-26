import 'package:auth_front/history_page.dart';
import 'package:auth_front/login_page.dart';
import 'package:flutter/material.dart';
import 'package:auth_front/user.dart';
import 'package:auth_front/product.dart';
import 'package:auth_front/product_service.dart';
import 'package:auth_front/user_service.dart';
import 'package:auth_front/add_product_page.dart';
import 'package:auth_front/product_detail_screen.dart';
import 'package:auth_front/qr_scanner_screen.dart';
import 'package:auth_front/product_image.dart';

class ProductListScreen extends StatefulWidget {
  final User user;
  const ProductListScreen({super.key, required this.user});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  List<Product> products = [];
  final ProductService _productService = ProductService();
  final UserService _userService = UserService(); 

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final loadedProducts = await _productService.getAllProducts();
    setState(() {
      products = loadedProducts;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Список товаров'),
        actions: [
          if (_userService.canCreateProduct(widget.user))
            IconButton(
              icon: const Icon(Icons.history),
              onPressed: _showHistory,
              tooltip: 'История операций',
            ),
          if (_userService.canCreateProduct(widget.user))
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _addProduct,
              tooltip: 'Добавить товар',
            ),
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: _scanQRCode,
            tooltip: 'Сканировать QR-код',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Выйти',
          ),
        ],
      ),
      body: products.isEmpty
          ? const Center(
              child: Text('Нет товаров'),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return Card(
                  color: const Color.fromARGB(255, 146, 153, 158),
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: ProductImage(
                      imagePath: product.imagePath,
                      width: 80,
                      height: 80,
                    ),
                    title: Text(
                      product.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(product.description),
                        if (product.price != null) ...[
                          const SizedBox(height: 4),
                          Text('Цена: ${product.price} ₽'),
                        ],
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: product.status == ProductStatus.available
                                ? Colors.green
                                : Colors.red,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            product.status == ProductStatus.available
                                ? 'Свободен'
                                : 'Занят',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProductDetailScreen(
                            product: product,
                            user: widget.user,
                          ),
                        ),
                      ).then((_) => _loadProducts());
                    },
                  ),
                );
              },
            ),
    );
  }

  void _addProduct() async {
    final result = await Navigator.push<Product>(
      context,
      MaterialPageRoute(
        builder: (context) => AddProductScreen(user: widget.user),
      ),
    );

    if (result != null) {
      await _productService.addProduct(result);
      await _loadProducts();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Товар "${result.name}" добавлен'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _showHistory() {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => HistoryScreen(user: widget.user),
    ),
   );
  }

  void _scanQRCode() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QRScannerScreen(user: widget.user),
      ),
    ).then((_) => _loadProducts());
  }

  void _logout() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }
}