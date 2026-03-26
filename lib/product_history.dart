class ProductHistory {
  final int id;
  final String productId;
  final int userId;
  final DateTime takenAt;
  final DateTime? returnedAt;

  ProductHistory({
    required this.id,
    required this.productId,
    required this.userId,
    required this.takenAt,
    this.returnedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'product_id': productId,
      'user_id': userId,
      'taken_at': takenAt.toIso8601String(),
      'returned_at': returnedAt?.toIso8601String(),
    };
  }

  factory ProductHistory.fromMap(Map<String, dynamic> map) {
    return ProductHistory(
      id: map['id'],
      productId: map['product_id'],
      userId: map['user_id'],
      takenAt: DateTime.parse(map['taken_at']),
      returnedAt: map['returned_at'] != null 
          ? DateTime.parse(map['returned_at']) 
          : null,
    );
  }
}