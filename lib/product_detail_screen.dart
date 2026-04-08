import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:auth_front/product.dart';
import 'package:auth_front/user.dart';
import 'package:auth_front/product_service.dart';
import 'package:auth_front/product_image.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;
  final User user;
  const ProductDetailScreen({
    super.key,
    required this.product,
    required this.user,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late Product _product;
  final ProductService _productService = ProductService();

  @override
  void initState() {
    super.initState();
    _product = widget.product;
  }

  Future<void> _getActualProduct() async {
    final updated = await _productService.getProductById(widget.product.id);
    if (updated != null) {
      setState(() {
        _product = updated;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_product.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code),
            onPressed: () => _showQRCodeDialog(context),
            tooltip: 'Показать QR-код',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: ProductImage(
                  imagePath: _product.imagePath,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 20),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Информация о товаре',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(),
                    _buildInfoRow('ID', _product.id),
                    _buildInfoRow('Название', _product.name),
                    _buildInfoRow('Описание', _product.description),
                    if (_product.price != null)
                      _buildInfoRow('Цена', '${_product.price} ₽'),
                    _buildInfoRow(
                      'Статус',
                      _product.status == ProductStatus.available
                          ? 'Свободен'
                          : 'Занят',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _toggleProductStatus,
                icon: Icon(
                  _product.status == ProductStatus.available
                      ? Icons.shopping_cart
                      : Icons.assignment_return,
                ),
                label: Text(
                  _product.status == ProductStatus.available
                      ? 'Взять товар'
                      : 'Вернуть товар',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _product.status == ProductStatus.available
                      ? Colors.green
                      : Colors.orange,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),

            const SizedBox(height: 20),

            Center(
              child: ElevatedButton.icon(
                onPressed: () => _showQRCodeDialog(context),
                icon: const Icon(Icons.qr_code),
                label: const Text('Показать QR-код товара'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Future<void> _toggleProductStatus() async {
    bool success;
    String message;

    if (_product.status == ProductStatus.available) {
      success = await _productService.takeProduct(_product.id, widget.user);
      message = 'Товар "${_product.name}" взят';
    } else {
      success = await _productService.returnProduct(_product.id, widget.user);
      message = 'Товар "${_product.name}" возвращен';
    }

    if (success) {
      await _getActualProduct();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Не удалось выполнить операцию'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showQRCodeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'QR-код товара',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: QrImageView(
                    data: _product.toQRCodeString(),
                    version: QrVersions.auto,
                    size: 200,
                    backgroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _product.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  _product.description,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (_product.price != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Цена: ${_product.price} ₽',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Закрыть'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}