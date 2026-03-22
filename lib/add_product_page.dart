import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:auth_front/product.dart';
import 'package:qr_flutter/qr_flutter.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  
  File? _selectedImage;
  String? _savedImagePath;
  final ImagePicker _picker = ImagePicker();
  
  Product? _generatedProduct;
  String? _qrCodeData;

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        final String permanentPath = await _saveImagePermanently(image);
        
        setState(() {
          _selectedImage = File(image.path);
          _savedImagePath = permanentPath;
        });

        final fileExists = await File(permanentPath).exists();
        print('Файл сохранен по пути: $permanentPath');
        print('Файл существует: $fileExists');

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Изображение загружено'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Ошибка загрузки: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка загрузки: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<String> _saveImagePermanently(XFile image) async {
    try {
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      
      final Directory productsDir = Directory('${appDocDir.path}/product_images');
      if (!await productsDir.exists()) {
        await productsDir.create(recursive: true);
      }
      
      final String fileName = 'product_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String savedPath = '${productsDir.path}/$fileName';
      
      final File tempFile = File(image.path);
      final File savedFile = await tempFile.copy(savedPath);
      
      print('Фото сохранено: $savedPath');
      return savedPath;
    } catch (e) {
      print('Ошибка сохранения: $e');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Добавление товара'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
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
                      const SizedBox(height: 16),
                      
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            if (_selectedImage != null) ...[
                              Container(
                                height: 200,
                                width: double.infinity,
                                child: Image.file(
                                  _selectedImage!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    print('Ошибка загрузки превью: $error');
                                    return Container(
                                      color: Colors.grey,
                                      child: const Center(
                                        child: Icon(Icons.error, size: 50),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ] else ...[
                              InkWell(
                                onTap: _pickImage,
                                child: Container(
                                  height: 150,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.add_photo_alternate,
                                        size: 50,
                                        color: Colors.grey.shade600,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Нажмите для загрузки изображения',
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Название товара *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Введите название товара';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Описание *',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Введите описание товара';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      
                      TextFormField(
                        controller: _priceController,
                        decoration: const InputDecoration(
                          labelText: 'Цена',
                          border: OutlineInputBorder(),
                          prefixText: '₽ ',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 20),
                      
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _selectedImage == null ? null : _generateQRCode,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _selectedImage == null ? Colors.grey : Colors.blue,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text(
                            _selectedImage == null 
                                ? 'Сначала загрузите изображение' 
                                : 'Сгенерировать QR-код',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            if (_generatedProduct != null && _qrCodeData != null) ...[
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Text(
                        'QR-код товара',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      QrImageView(
                        data: _qrCodeData!,
                        version: QrVersions.auto,
                        size: 200,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Товар: ${_generatedProduct!.name}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _saveProduct,
                            icon: const Icon(Icons.save),
                            label: const Text('Сохранить'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _generateQRCode() {
    if (_formKey.currentState!.validate() && _selectedImage != null && _savedImagePath != null) {
      final id = 'PROD_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
      
      final product = Product(
        id: id,
        name: _nameController.text,
        description: _descriptionController.text,
        imagePath: _savedImagePath!,
        price: _priceController.text.isNotEmpty 
            ? double.tryParse(_priceController.text) 
            : null,
      );
      
      setState(() {
        _generatedProduct = product;
        _qrCodeData = product.toQRCodeString();
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('QR-код успешно сгенерирован')),
      );
    }
  }

  void _saveProduct() {
    if (_generatedProduct != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Товар "${_generatedProduct!.name}" сохранен'),
          backgroundColor: Colors.green,
        ),
      );
      
      Navigator.pop(context, _generatedProduct);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }
}