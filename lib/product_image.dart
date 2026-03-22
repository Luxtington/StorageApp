import 'dart:io';
import 'package:flutter/material.dart';

class ProductImage extends StatelessWidget {
  final String imagePath;
  final double width;
  final double height;
  final BoxFit fit;

  const ProductImage({
    super.key,
    required this.imagePath,
    this.width = 80,
    this.height = 80,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    if (imagePath.startsWith('assets/')) {
      return Image.asset(
        imagePath,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
      );
    }
    
    return Image.file(
      File(imagePath),
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        print('Ошибка загрузки файла: $imagePath');
        return _buildPlaceholder();
      },
    );
  }

Widget _buildPlaceholder() {
  return Image.asset(
    'assets/images/apple.jpg', 
    width: width,
    height: height,
    fit: BoxFit.cover,
    errorBuilder: (context, error, stackTrace) {
      return Container(
        color: Colors.grey.shade300,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_not_supported, color: Colors.grey.shade600),
            const SizedBox(height: 4),
            Text('Нет фото', style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
      );
    },
  );
}
}