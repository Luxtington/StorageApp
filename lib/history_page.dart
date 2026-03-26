import 'package:flutter/material.dart';
import 'package:auth_front/product_service.dart';
import 'package:auth_front/product_history.dart';
import 'package:auth_front/user_service.dart';
import 'package:auth_front/user.dart';

class HistoryScreen extends StatefulWidget {
  final User user;
  const HistoryScreen({super.key, required this.user});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final ProductService _productService = ProductService();
  final UserService _userService = UserService();
  List<ProductHistory> history = [];
  Map<String, String> productNames = {};
  Map<int, String> userNames = {};     
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    
    // Получаем всю историю
    final db = await _productService.dbHelper.open();
    final historyData = await db.query('product_history');
    history = historyData.map((h) => ProductHistory.fromMap(h)).toList();
    
    // Загружаем названия товаров
    for (var h in history) {
      if (!productNames.containsKey(h.productId)) {
        final product = await _productService.getProductById(h.productId);
        if (product != null) {
          productNames[h.productId] = product.name;
        } else {
          productNames[h.productId] = 'Неизвестный товар';
        }
      }
      
      if (!userNames.containsKey(h.userId)) {
        final user = await _userService.getUserById(h.userId);
        if (user != null) {
          userNames[h.userId] = user.name;
        } else {
          userNames[h.userId] = 'Неизвестный пользователь';
        }
      }
    }
    
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('История операций'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadHistory,
            tooltip: 'Обновить',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : history.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history, size: 80, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'История пуста',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      Text(
                        'Никто еще не брал товары',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: history.length,
                  itemBuilder: (context, index) {
                    final h = history[index];
                    final productName = productNames[h.productId] ?? 'Загрузка...';
                    final userName = userNames[h.userId] ?? 'Загрузка...';
                    final isReturned = h.returnedAt != null;
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Товар и статус
                            Row(
                              children: [
                                Icon(
                                  isReturned 
                                      ? Icons.assignment_return 
                                      : Icons.shopping_cart,
                                  color: isReturned ? Colors.green : Colors.orange,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    productName,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isReturned ? Colors.green : Colors.orange,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    isReturned ? 'Возвращен' : 'Взят',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(),
                            
                            // Пользователь
                            Row(
                              children: [
                                const Icon(Icons.person, size: 16, color: Colors.grey),
                                const SizedBox(width: 8),
                                Text(
                                  'Пользователь: $userName',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            
                            // Дата взятия
                            Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                                const SizedBox(width: 8),
                                Text(
                                  'Взят: ${_formatDateTime(h.takenAt)}',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                            
                            // Дата возврата (если есть)
                            if (isReturned) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Возвращен: ${_formatDateTime(h.returnedAt!)}',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                            ],
                            
                            // ID товара (мелким шрифтом)
                            const SizedBox(height: 8),
                            Text(
                              'ID товара: ${h.productId}',
                              style: const TextStyle(fontSize: 10, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}.${dateTime.month}.${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}