// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'package:hive/hive.dart';
// import '../pages/home_screen.dart';
//
// Future<List<Product>> fetchProductsFromApi() async {
//   final box = Hive.box('authBox');
//   final token = box.get('token');
//
//   print("Fetched token: $token");
//
//   if (token == null || token.isEmpty) {
//     throw Exception('Token not found. Please log in again.');
//   }
//
//   final response = await http.get(
//     Uri.parse('https://training-api-unrp.onrender.com/products?page=2&size=10'),
//     headers: {
//       'Content-Type': 'application/json',
//       'Authorization': 'Bearer $token',
//     },
//   );
//
//   print("Status: ${response.statusCode}");
//   print("Body: ${response.body}");
//
//   if (response.statusCode == 200) {
//     final jsonData = json.decode(response.body);
//     final List<dynamic> productList = jsonData['data'];
//     return productList.map((item) => Product(
//       id: item['id'],
//       name: item['name'],
//       price: item['price'],
//       quantity: item['quantity'],
//       cover: item['cover'],
//     )).toList();
//   } else {
//     throw Exception('Failed to load products: ${response.statusCode}');
//   }
// }
