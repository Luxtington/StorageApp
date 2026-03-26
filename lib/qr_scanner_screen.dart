import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:auth_front/product.dart';
import 'package:auth_front/product_service.dart';
import 'package:auth_front/user.dart';

class QRScannerScreen extends StatefulWidget {
  final User user;
  const QRScannerScreen({super.key, required this.user});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final MobileScannerController controller = MobileScannerController();
  bool _isProcessing = false;
  final ProductService _productService = ProductService();

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    for (final barcode in capture.barcodes) {
      if (barcode.rawValue != null) {
        setState(() => _isProcessing = true);
        await controller.stop();

        try {
          final scannedProduct = Product.fromQRCode(barcode.rawValue!);
          final product = await _productService.getProductById(scannedProduct.id);

          if (product != null && mounted) {
            bool success;
            String title, message;

            if (product.status == ProductStatus.available) {
              success = await _productService.takeProduct(product.id, widget.user);
              title = 'Товар взят';
              message = 'Вы взяли товар "${product.name}"';
            } else {
              success = await _productService.returnProduct(product.id, widget.user);
              title = 'Товар возвращен';
              message = 'Вы вернули товар "${product.name}"';
            }

            if (success) {
              _showResultDialog(title, message, true);
            } else {
              _showResultDialog('Ошибка', 'Не удалось выполнить операцию', false);
            }
          } else {
            _showResultDialog('Ошибка', 'Товар не найден в базе данных', false);
          }
        } catch (e) {
          setState(() => _isProcessing = false);
          if (mounted) {
            _showResultDialog(
              'Ошибка сканирования',
              'Это не QR-код товара или он поврежден',
              false,
            );
          }
          await controller.start();
        }
        break;
      }
    }
  }

  void _showResultDialog(String title, String message, bool isSuccess) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle : Icons.error,
              color: isSuccess ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (isSuccess) {
                Navigator.pop(context, true);
              } else {
                _resumeScanning();
              }
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _resumeScanning() async {
    setState(() => _isProcessing = false);
    await controller.start();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Сканирование QR-кода'),
        actions: [
          IconButton(
            icon: const Icon(Icons.switch_camera),
            onPressed: () => controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: _onDetect,
          ),
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.red, width: 3),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Text(
                  'Наведите на QR-код товара',
                  style: TextStyle(
                    color: Colors.white,
                    backgroundColor: Colors.black54,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}