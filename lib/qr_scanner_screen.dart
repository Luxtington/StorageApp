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
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: isSuccess ? Colors.green.shade100 : Colors.red.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isSuccess ? Icons.check_circle : Icons.error,
                  color: isSuccess ? Colors.green : Colors.red,
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    if (isSuccess) {
                      Navigator.pop(context, true);
                    } else {
                      _resumeScanning();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'OK',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
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
        title: const Text(
          'Сканирование QR-кода',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1565C0),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.switch_camera),
            onPressed: () => controller.switchCamera(),
            tooltip: 'Переключить камеру',
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: _onDetect,
          ),
          // Затемнение по краям
          Container(
            color: Colors.black.withOpacity(0.5),
            child: Center(
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 3),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Уголки рамки
                    Positioned(
                      top: 0,
                      left: 0,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(color: Colors.green.shade400, width: 4),
                            left: BorderSide(color: Colors.green.shade400, width: 4),
                          ),
                          borderRadius: BorderRadius.only(topLeft: Radius.circular(16)),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(color: Colors.green.shade400, width: 4),
                            right: BorderSide(color: Colors.green.shade400, width: 4),
                          ),
                          borderRadius: BorderRadius.only(topRight: Radius.circular(16)),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Colors.green.shade400, width: 4),
                            left: BorderSide(color: Colors.green.shade400, width: 4),
                          ),
                          borderRadius: BorderRadius.only(bottomLeft: Radius.circular(16)),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Colors.green.shade400, width: 4),
                            right: BorderSide(color: Colors.green.shade400, width: 4),
                          ),
                          borderRadius: BorderRadius.only(bottomRight: Radius.circular(16)),
                        ),
                      ),
                    ),
                    // Подсказка внутри рамки
                    Center(
                      child: Container(
                        margin: const EdgeInsets.all(8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Наведите QR-код\nв область рамки',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: Colors.white,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Обработка...',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
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