import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:hive/hive.dart';
import 'product_detail_screen.dart';


class Product {
  final int id;
  final String name;
  final int price;
  final int quantity;
  final String cover;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
    required this.cover,
  });
}

Future<List<Product>> fetchProductsFromApi() async {
  final box = Hive.box('authBox');
  final token = box.get('token');

  print("Fetched token: $token");
  print("Token type: ${token.runtimeType}");

  if (token == null || token.toString().isEmpty) {
    throw Exception('Token not found. Please log in again.');
  }

  final cleanToken = token.toString().trim();
  print("Clean token: $cleanToken");

  final response = await http.get(
    Uri.parse('https://training-api-unrp.onrender.com/products?page=2&size=10'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $cleanToken',
    },
  );

  print("Status: ${response.statusCode}");
  print("Response headers: ${response.headers}");
  print("Body: ${response.body}");

  if (response.statusCode == 200) {
    final jsonData = json.decode(response.body);

    if (jsonData['data'] == null) {
      throw Exception('No data field in response');
    }

    final List<dynamic> productList = jsonData['data'];
    return productList.map((item) => Product(
      id: item['id'],
      name: item['name'],
      price: item['price'],
      quantity: item['quantity'],
      cover: item['cover'],
    )).toList();
  } else if (response.statusCode == 401) {
    box.delete('token');
    throw Exception('Session expired. Please log in again.');
  } else {
    throw Exception('Failed to load products: ${response.statusCode} - ${response.body}');
  }
}

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Product> products = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  void fetchData() async {
    try {
      final apiProducts = await fetchProductsFromApi();
      setState(() {
        products = apiProducts;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);


      if (e.toString().contains('Session expired')) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Phiên đăng nhập hết hạn'),
            content: Text('Vui lòng đăng nhập lại'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.pushReplacementNamed(context, '/');
                },
                child: Text('Đăng nhập lại'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải sản phẩm: $e')),
        );
      }
    }
  }

  void _logout() {
    // Clear the token from storage
    final box = Hive.box('authBox');
    box.delete('token');
    Navigator.pushReplacementNamed(context, '/');
  }

  void _addProduct() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Thêm sản phẩm mới')),
    );
    // TODO: Làm lại màn hình thêm sản phẩm
  }

  void _updateProduct() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Cập nhật sản phẩm')),
    );
    // TODO: Làm lại màn hình cập nhật sản phẩm
  }

  void _deleteProduct() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Xóa sản phẩm'),
          content: Text('Chọn sản phẩm từ danh sách để xóa'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Đóng'),
            ),
          ],
        );
      },
    );
    // TODO: Làm lại xóa sản phẩm
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Quản lý sản phẩm"),
        backgroundColor: Colors.orange,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Đăng xuất',
            onPressed: _logout,
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : products.isEmpty
          ? Center(child: Text("Chưa có sản phẩm nào."))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 4,
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              contentPadding: const EdgeInsets.all(12),
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  product.cover,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                ),
              ),
              title: Text(
                product.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.deepOrange,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  "Giá: ${product.price} đ\nSố lượng: ${product.quantity}",
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              isThreeLine: true,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        ProductDetailScreen(product: product),
                  ),
                );
              },
            ),
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.orange.shade50,
        selectedItemColor: Colors.deepOrange,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle),
            label: 'Thêm',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.edit),
            label: 'Cập nhật',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.delete),
            label: 'Xóa',
          ),
        ],
        onTap: (index) {
          switch (index) {
            case 0:
              _addProduct();
              break;
            case 1:
              _updateProduct();
              break;
            case 2:
              _deleteProduct();
              break;
          }
        },
      ),
    );
  }
}