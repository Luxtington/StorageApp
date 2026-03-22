import 'dart:io';  // Этот импорт нужен для File в других местах

import 'package:auth_front/product.dart';
import 'package:auth_front/add_product_page.dart';
import 'package:auth_front/product_detail_screen.dart';
import 'package:auth_front/qr_scanner_screen.dart';
import 'package:flutter/material.dart';
import 'package:auth_front/product_image.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  List<Product> products = Product.initializeProductList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Список товаров'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addProduct,
            tooltip: 'Добавить товар',
          ),
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: _scanQRCode,
            tooltip: 'Сканировать QR-код товара',
          ),
        ],
      ),
      body: ListView.builder(
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
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: product.status == ProductStatus.available
                          ? Colors.green
                          : Colors.red,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      product.status == ProductStatus.available ? 'Свободен' : 'Занят',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ],
              ),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProductDetailScreen(product: product),
                  ),
                );
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
      MaterialPageRoute(builder: (context) => const AddProductScreen()),
    );

    if (result != null) {
      setState(() {
        products.add(result);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Товар "${result.name}" добавлен'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _scanQRCode() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const QRScannerScreen()),
    );
  }
}