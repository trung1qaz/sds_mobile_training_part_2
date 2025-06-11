import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../pages/home_screen.dart';

class ApiService {
  static const String baseUrl = 'https://training-api-unrp.onrender.com';

  static String? getAuthToken() {
    final box = Hive.box('authBox');
    return box.get('authToken');
  }

  static Options getAuthOptions() {
    final token = getAuthToken();
    return Options(
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': token,
      },
    );
  }

  static final Dio dio = Dio(BaseOptions(baseUrl: baseUrl));
}

Future<List<Product>> fetchProductsFromApi() async {
  try {
    final response = await ApiService.dio.get(
      '/products?page=2&size=10',
      options: ApiService.getAuthOptions(),
    );

    final List<dynamic> productList = response.data['data'];
    return productList.map((item) => Product(
      id: item['id'],
      name: item['name'],
      price: item['price'],
      quantity: item['quantity'],
      cover: item['cover'],
    )).toList();
  } on DioError catch (e) {
    if (e.response?.statusCode == 401) {
      throw Exception('Unauthorized - Please login again');
    }
    throw Exception('Failed to load products: ${e.message}');
  }
}

Future<Product> addProductToApi(Product product) async {
  try {
    final response = await ApiService.dio.post(
      '/products',
      options: ApiService.getAuthOptions(),
      data: json.encode({
        'name': product.name,
        'price': product.price,
        'quantity': product.quantity,
        'cover': product.cover,
      }),
    );

    final jsonData = response.data['data'];
    return Product(
      id: jsonData['id'] ?? product.id,
      name: jsonData['name'] ?? product.name,
      price: jsonData['price'] ?? product.price,
      quantity: jsonData['quantity'] ?? product.quantity,
      cover: jsonData['cover'] ?? product.cover,
    );
  } on DioError catch (e) {
    if (e.response?.statusCode == 401) {
      throw Exception('Unauthorized - Please login again');
    }
    throw Exception('Failed to add product: ${e.message}');
  }
}

Future<Product> updateProductInApi(Product product) async {
  try {
    final response = await ApiService.dio.put(
      '/products/${product.id}',
      options: ApiService.getAuthOptions(),
      data: json.encode({
        'name': product.name,
        'price': product.price,
        'quantity': product.quantity,
        'cover': product.cover,
      }),
    );

    final jsonData = response.data['data'];
    return Product(
      id: jsonData['id'] ?? product.id,
      name: jsonData['name'] ?? product.name,
      price: jsonData['price'] ?? product.price,
      quantity: jsonData['quantity'] ?? product.quantity,
      cover: jsonData['cover'] ?? product.cover,
    );
  } on DioError catch (e) {
    if (e.response?.statusCode == 401) {
      throw Exception('Unauthorized - Please login again');
    }
    throw Exception('Failed to update product: ${e.message}');
  }
}

Future<bool> deleteProductFromApi(int productId) async {
  try {
    final response = await ApiService.dio.delete(
      '/products/$productId',
      options: ApiService.getAuthOptions(),
    );

    return response.statusCode == 200 || response.statusCode == 204;
  } on DioError catch (e) {
    if (e.response?.statusCode == 401) {
      throw Exception('Unauthorized - Please login again');
    }
    throw Exception('Failed to delete product: ${e.message}');
  }
}

Future<Product> getProductDetails(int productId) async {
  try {
    final response = await ApiService.dio.get(
      '/products/$productId',
      options: ApiService.getAuthOptions(),
    );

    final item = response.data['data'];
    return Product(
      id: item['id'],
      name: item['name'],
      price: item['price'],
      quantity: item['quantity'],
      cover: item['cover'],
    );
  } on DioError catch (e) {
    if (e.response?.statusCode == 401) {
      throw Exception('Unauthorized - Please login again');
    }
    throw Exception('Failed to load product details: ${e.message}');
  }
}
