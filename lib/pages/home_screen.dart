import 'package:flutter/material.dart';
import '../data/product_api.dart';
import 'product_detail_screen.dart';
import 'package:hive_flutter/hive_flutter.dart';

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

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Product> products = [];
  bool isLoading = true;
  String? errorMessage;
  int _nextId = 21;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  void fetchData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final apiProducts = await fetchProductsFromApi();
      setState(() {
        products = apiProducts;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });

      if (e.toString().contains('Unauthorized')) {
        _handleUnauthorized();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tải dữ liệu: $e'),
            action: SnackBarAction(
              label: 'Thử lại',
              onPressed: fetchData,
            ),
          ),
        );
      }
    }
  }

  void _handleUnauthorized() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Phiên đăng nhập hết hạn'),
        content: Text('Vui lòng đăng nhập lại'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _logout();
            },
            child: Text('Đăng nhập lại'),
          ),
        ],
      ),
    );
  }

  void _showAddProductDialog() {
    final _formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final quantityCtrl = TextEditingController();
    final coverCtrl = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Thêm sản phẩm'),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    decoration: InputDecoration(labelText: 'Tên sản phẩm'),
                    validator: (value) =>
                    value == null || value.isEmpty ? 'Bắt buộc' : null,
                  ),
                  TextFormField(
                    controller: priceCtrl,
                    decoration: InputDecoration(labelText: 'Giá (vnđ)'),
                    keyboardType: TextInputType.number,
                    validator: (value) =>
                    value == null || int.tryParse(value) == null
                        ? 'Phải là số'
                        : null,
                  ),
                  TextFormField(
                    controller: quantityCtrl,
                    decoration: InputDecoration(labelText: 'Số lượng'),
                    keyboardType: TextInputType.number,
                    validator: (value) =>
                    value == null || int.tryParse(value) == null
                        ? 'Phải là số'
                        : null,
                  ),
                  TextFormField(
                    controller: coverCtrl,
                    decoration: InputDecoration(labelText: 'URL hình ảnh'),
                    validator: (value) =>
                    value == null || value.isEmpty ? 'Bắt buộc' : null,
                  ),
                  if (isSubmitting)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: CircularProgressIndicator(),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.pop(context),
              child: Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: isSubmitting ? null : () async {
                if (_formKey.currentState!.validate()) {
                  setDialogState(() => isSubmitting = true);

                  try {
                    final newProduct = Product(
                      id: _nextId++,
                      name: nameCtrl.text.trim(),
                      price: int.parse(priceCtrl.text),
                      quantity: int.parse(quantityCtrl.text),
                      cover: coverCtrl.text.trim(),
                    );

                    final addedProduct = await addProductToApi(newProduct);

                    setState(() {
                      products.add(addedProduct);
                    });

                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Thêm sản phẩm thành công')),
                    );
                  } catch (e) {
                    setDialogState(() => isSubmitting = false);

                    if (e.toString().contains('Unauthorized')) {
                      Navigator.pop(context);
                      _handleUnauthorized();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Lỗi thêm sản phẩm: $e')),
                      );
                    }
                  }
                }
              },
              child: Text('Thêm'),
            ),
          ],
        ),
      ),
    );
  }

  void removeProduct(int index) async {
    final product = products[index];

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa sản phẩm "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Xóa'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      try {
        await deleteProductFromApi(product.id);
        setState(() {
          products.removeAt(index);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Xóa sản phẩm thành công')),
        );
      } catch (e) {
        if (e.toString().contains('Unauthorized')) {
          _handleUnauthorized();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi xóa sản phẩm: $e')),
          );
        }
      }
    }
  }

  void _logout() {
    // Clear auth data
    final box = Hive.box('authBox');
    box.delete('authToken');
    box.delete('currentUser');

    Navigator.pushReplacementNamed(context, '/');
  }

  Widget _buildProductImage(String imageUrl) {
    return Image.network(
      imageUrl,
      width: 60,
      height: 60,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          width: 60,
          height: 60,
          child: Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                  loadingProgress.expectedTotalBytes!
                  : null,
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: 60,
          height: 60,
          color: Colors.grey[300],
          child: Icon(
            Icons.error_outline,
            color: Colors.grey[600],
            size: 30,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Quản lý sản phẩm"),
        backgroundColor: Colors.orange,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Tải lại',
            onPressed: fetchData,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Đăng xuất',
            onPressed: _logout,
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Có lỗi xảy ra',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: fetchData,
              child: Text('Thử lại'),
            ),
          ],
        ),
      )
          : products.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text("Chưa có sản phẩm nào."),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _showAddProductDialog,
              child: Text('Thêm sản phẩm đầu tiên'),
            ),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: () async => fetchData(),
        child: ListView.builder(
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
                  child: _buildProductImage(product.cover),
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
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  tooltip: 'Xoá sản phẩm',
                  onPressed: () => removeProduct(index),
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.add_box_rounded),
                tooltip: 'Thêm sản phẩm',
                onPressed: _showAddProductDialog,
              ),
            ],
          ),
        ),
      ),
    );
  }
}