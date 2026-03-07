import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:auth_front/product.dart';
import 'package:auth_front/product_detail_screen.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final MobileScannerController controller = MobileScannerController();
  bool _isProcessing = false;

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

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    for (final barcode in capture.barcodes) {
      if (barcode.rawValue != null) {
        setState(() => _isProcessing = true);
        await controller.stop();
        
        try {
          final product = Product.fromQRCode(barcode.rawValue!);
          
          if (mounted) {
            _showProductInfoSnackBar(product);
          }
        } catch (e) {
          setState(() => _isProcessing = false);
          if (mounted) {
            _showErrorDialog(
              'Ошибка сканирования',
              'Это не QR-код товара или он поврежден',
            );
          }
        }
        break;
      }
    }
  }

  void _showProductInfoSnackBar(Product product) {
    ScaffoldMessenger.of(context).clearSnackBars();
    
    final snackBar = SnackBar(
      duration: const Duration(seconds: 8),
      elevation: 6,
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.blue[800],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Товар найден: ${product.name}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Описание: ${product.description}'),
          if (product.price != null) Text('Цена: ${product.price} ₽'),
          Text('ID: ${product.id}', style: const TextStyle(fontSize: 10)),
        ],
      ),
      action: SnackBarAction(
        label: 'ПЕРЕЙТИ',
        textColor: Colors.white,
        onPressed: () {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailScreen(product: product),
            ),
          ).then((_) => _resumeScanning());
        },
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar).closed.then((reason) {
      if (reason != SnackBarClosedReason.action) {
        _resumeScanning();
      }
    });
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.error, color: Colors.red),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resumeScanning();
            },
            child: const Text('ПОНЯТНО'),
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
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}