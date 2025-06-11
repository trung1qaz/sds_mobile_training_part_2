import 'package:flutter/material.dart';
import '../data/product_api.dart';
import 'home_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late Product currentProduct;
  bool isLoading = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    currentProduct = widget.product;
    loadProductDetails();
  }

  void loadProductDetails() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final productDetails = await getProductDetails(widget.product.id);
      setState(() {
        currentProduct = productDetails;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });

      if (e.toString().contains('Unauthorized')) {
        _handleUnauthorized();
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
              Navigator.of(context).pushReplacementNamed('/');
            },
            child: Text('Đăng nhập lại'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog() {
    final _formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: currentProduct.name);
    final priceCtrl = TextEditingController(text: currentProduct.price.toString());
    final quantityCtrl = TextEditingController(text: currentProduct.quantity.toString());
    final coverCtrl = TextEditingController(text: currentProduct.cover);
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Chỉnh sửa sản phẩm'),
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
                    final updatedProduct = Product(
                      id: currentProduct.id,
                      name: nameCtrl.text.trim(),
                      price: int.parse(priceCtrl.text),
                      quantity: int.parse(quantityCtrl.text),
                      cover: coverCtrl.text.trim(),
                    );

                    final result = await updateProductInApi(updatedProduct);

                    setState(() {
                      currentProduct = result;
                    });

                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Cập nhật sản phẩm thành công')),
                    );
                  } catch (e) {
                    setDialogState(() => isSubmitting = false);

                    if (e.toString().contains('Unauthorized')) {
                      Navigator.pop(context);
                      _handleUnauthorized();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Lỗi cập nhật: $e')),
                      );
                    }
                  }
                }
              },
              child: Text('Cập nhật'),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteProduct() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa sản phẩm "${currentProduct.name}"?'),
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
      setState(() => isLoading = true);

      try {
        await deleteProductFromApi(currentProduct.id);
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Xóa sản phẩm thành công')),
        );
      } catch (e) {
        setState(() => isLoading = false);

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

  Widget _buildProductImage() {
    return Container(
      height: 300,
      width: double.infinity,
      child: Image.network(
        currentProduct.cover,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                  loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[300],
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  color: Colors.grey[600],
                  size: 64,
                ),
                SizedBox(height: 8),
                Text(
                  'Không thể tải hình ảnh',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(currentProduct.name),
        backgroundColor: Colors.orange,
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            tooltip: 'Chỉnh sửa',
            onPressed: isLoading ? null : _showEditDialog,
          ),
          IconButton(
            icon: Icon(Icons.delete),
            tooltip: 'Xóa',
            onPressed: isLoading ? null : _deleteProduct,
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
              onPressed: loadProductDetails,
              child: Text('Thử lại'),
            ),
          ],
        ),
      )
          : SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProductImage(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentProduct.name,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.attach_money, color: Colors.green),
                      Text(
                        '${currentProduct.price} đ',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.inventory, color: Colors.blue),
                      Text(
                        'Số lượng: ${currentProduct.quantity}',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Thông tin chi tiết',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 12),
                          _buildInfoRow('ID sản phẩm', currentProduct.id.toString()),
                          _buildInfoRow('Tên sản phẩm', currentProduct.name),
                          _buildInfoRow('Giá bán', '${currentProduct.price} đ'),
                          _buildInfoRow('Số lượng tồn kho', '${currentProduct.quantity}'),
                          _buildInfoRow('URL hình ảnh', currentProduct.cover, isUrl: true),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: !isLoading ? BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _showEditDialog,
                  icon: Icon(Icons.edit),
                  label: Text('Chỉnh sửa'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _deleteProduct,
                  icon: Icon(Icons.delete),
                  label: Text('Xóa'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ) : null,
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isUrl = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: isUrl
                ? Text(
              value,
              style: TextStyle(
                color: Colors.blue,
                decoration: TextDecoration.underline,
              ),
            )
                : Text(value),
          ),
        ],
      ),
    );
  }
}