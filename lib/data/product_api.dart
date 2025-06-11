import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hive_flutter/hive_flutter.dart';
import '../pages/home_screen.dart';

class ApiService {
  static const String baseUrl = 'https://training-api-unrp.onrender.com';

  static String? getAuthToken() {
    final box = Hive.box('authBox');
    return box.get('authToken');
  }

  static Map<String, String> getAuthHeaders() {
    final token = getAuthToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': '$token',
    };
  }
}

Future<List<Product>> fetchProductsFromApi() async {
  try {
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/products?page=2&size=10'),
      headers: ApiService.getAuthHeaders(),
    );

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      final List<dynamic> productList = jsonData['data'];
      return productList.map((item) => Product(
        id: item['id'],
        name: item['name'],
        price: item['price'],
        quantity: item['quantity'],
        cover: item['cover'],
      )).toList();
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized - Please login again');
    } else {
      throw Exception('Failed to load products: ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Network error: $e');
  }
}

Future<Product> addProductToApi(Product product) async {
  try {
    final response = await http.post(
      Uri.parse('${ApiService.baseUrl}/products'),
      headers: ApiService.getAuthHeaders(),
      body: json.encode({
        'name': product.name,
        'price': product.price,
        'quantity': product.quantity,
        'cover': product.cover,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final jsonData = json.decode(response.body);
      return Product(
        id: jsonData['data']['id'] ?? product.id,
        name: jsonData['data']['name'] ?? product.name,
        price: jsonData['data']['price'] ?? product.price,
        quantity: jsonData['data']['quantity'] ?? product.quantity,
        cover: jsonData['data']['cover'] ?? product.cover,
      );
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized - Please login again');
    } else {
      throw Exception('Failed to add product: ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Network error while adding product: $e');
  }
}

Future<Product> updateProductInApi(Product product) async {
  try {
    final response = await http.put(
      Uri.parse('${ApiService.baseUrl}/products/${product.id}'),
      headers: ApiService.getAuthHeaders(),
      body: json.encode({
        'name': product.name,
        'price': product.price,
        'quantity': product.quantity,
        'cover': product.cover,
      }),
    );

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      return Product(
        id: jsonData['data']['id'] ?? product.id,
        name: jsonData['data']['name'] ?? product.name,
        price: jsonData['data']['price'] ?? product.price,
        quantity: jsonData['data']['quantity'] ?? product.quantity,
        cover: jsonData['data']['cover'] ?? product.cover,
      );
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized - Please login again');
    } else {
      throw Exception('Failed to update product: ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Network error while updating product: $e');
  }
}

// Delete product from API
Future<bool> deleteProductFromApi(int productId) async {
  try {
    final response = await http.delete(
      Uri.parse('${ApiService.baseUrl}/products/$productId'),
      headers: ApiService.getAuthHeaders(),
    );

    if (response.statusCode == 200 || response.statusCode == 204) {
      return true;
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized - Please login again');
    } else {
      throw Exception('Failed to delete product: ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Network error while deleting product: $e');
  }
}

// Get single product details
Future<Product> getProductDetails(int productId) async {
  try {
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/products/$productId'),
      headers: ApiService.getAuthHeaders(),
    );

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      final item = jsonData['data'];
      return Product(
        id: item['id'],
        name: item['name'],
        price: item['price'],
        quantity: item['quantity'],
        cover: item['cover'],
      );
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized - Please login again');
    } else {
      throw Exception('Failed to load product details: ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Network error: $e');
  }
}