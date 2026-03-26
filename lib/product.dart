enum ProductStatus { available, busy }

class Product {
  final String id;
  final String name;
  final String description;
  final String imagePath;
  final double? price;
  ProductStatus status;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.imagePath,
    this.price,
    this.status = ProductStatus.available,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'image_path': imagePath,
      'price': price,
      'status': status.toString().split('.').last,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      imagePath: map['image_path'],
      price: map['price'],
      status: map['status'] == 'available' 
          ? ProductStatus.available 
          : ProductStatus.busy,
    );
  }

  factory Product.fromQRCode(String qrData) {
    final parts = qrData.split('|');
    if (parts.length >= 4) {
      return Product(
        id: parts[0],
        name: parts[1],
        description: parts[2],
        imagePath: parts[3],
        price: parts.length > 4 ? double.tryParse(parts[4]) : null,
      );
    }
    throw Exception('Неверный формат QR-кода');
  }

  String toQRCodeString() {
    return '$id|$name|$description|$imagePath|${price ?? ''}';
  }

  static List<Product> initializeProductList() {
    return [
      Product(
        id: '1',
        name: 'Яблоко',
        description: 'IPhone 13',
        imagePath: 'assets/images/apple.jpg',
        price: 50,
      ),
      Product(
        id: '2',
        name: 'Honor смартфон',
        description: 'Смартфон Honor с отличной камерой',
        imagePath: 'assets/images/honor.jpg',
        price: 25000,
      ),
      Product(
        id: '3',
        name: 'MacBook',
        description: 'Ноутбук Apple MacBook',
        imagePath: 'assets/images/mac.jpg',
        price: 120000,
      ),
      Product(
        id: '4',
        name: 'Samsung Galaxy',
        description: 'Смартфон Samsung Galaxy',
        imagePath: 'assets/images/smart_sam.jpg',
        price: 30000,
      ),
      Product(
        id: '5',
        name: 'Sony PlayStation',
        description: 'Игровая консоль Sony PlayStation',
        imagePath: 'assets/images/sony.jpg',
        price: 45000,
      ),
      Product(
        id: '6',
        name: 'Vivo смартфон',
        description: 'Смартфон Vivo',
        imagePath: 'assets/images/vivo.jpg',
        price: 20000,
      ),
    ];
  }
}