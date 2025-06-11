import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'home_screen.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sds_mobile_training_p2/data/user.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:dio/dio.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final taxCtrl = TextEditingController();
  final userCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;

  void login() async {
    if (_formKey.currentState!.validate()) {
      final dio = Dio();
      final url = ("https://training-api-unrp.onrender.com/login2");
      // final headers = {"Content-Type": "application/json"};
      final body = jsonEncode({
        "tax_code": int.tryParse(taxCtrl.text),
        "user_name": userCtrl.text.trim(),
        "password": passCtrl.text.trim(),
      });
      try {
        final response = await dio.post(url, data: body);
        final data = response.data;

        if (response.statusCode == 200 && data["success"] == true) {
          final token = data["data"]["token"];

          final box = Hive.box('authBox');
          List<User> userList = box.get('userList', defaultValue: []).cast<User>();

          final newUser = User(
            taxCtrl: int.parse(taxCtrl.text),
            userCtrl: userCtrl.text,
          );

          userList.removeWhere((u) =>
          u.taxCtrl == newUser.taxCtrl && u.userCtrl == newUser.userCtrl);
          userList.add(newUser);

          box.put('userList', userList);
          box.put('authToken', token);
          box.put('currentUser', {
            'tax_code': int.parse(taxCtrl.text),
            'user_name': userCtrl.text,
          });

          Navigator.pushReplacementNamed(context, '/home');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Đăng nhập thất bại, sai tên đăng nhập hoặc mật khẩu"),
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Lỗi kết nối: ${e.toString()}"),
          ),
        );
      }
    } else {
      setState(() {
        _autovalidateMode = AutovalidateMode.always;
      });
    }
  }

  void showRecentLoginsDialog() {
    final box = Hive.box('authBox');
    List<User> userList = List<User>.from(box.get('userList', defaultValue: []));

    if (userList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không có tài khoản nào trước đó')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: Text('Chọn tài khoản'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: userList.length,
              itemBuilder: (context, index) {
                final user = userList[index];
                return ListTile(
                  title: Text(user.userCtrl),
                  subtitle: Text(user.taxCtrl.toString()),
                  trailing: IconButton(
                    icon: Icon(Icons.backspace_outlined),
                    onPressed: () {
                      setStateDialog(() {
                        userList.removeAt(index);
                        box.put('userList', userList);
                      });
                    },
                  ),
                  onTap: () {
                    setState(() {
                      taxCtrl.text = user.taxCtrl.toString();
                      userCtrl.text = user.userCtrl;
                    });
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    taxCtrl.dispose();
    userCtrl.dispose();
    passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          autovalidateMode: _autovalidateMode,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SvgPicture.asset('assets/icon/logo.svg'),
              const SizedBox(height: 20),

              CustomInputField(
                label: "Mã số thuế",
                controller: taxCtrl,
                hintText: 'Điền mã số thuế',
                validator: (value) {
                  if (value == null || value.trim().length != 10) {
                    return "Mã số thuế phải có 10 chữ số";
                  }
                  return null;
                },
                keyboardType: TextInputType.number,
              ),
              CustomInputField(
                label: "Tài khoản",
                controller: userCtrl,
                hintText: 'Điền tài khoản',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Tên đăng nhập không được để trống";
                  }
                  return null;
                },
              ),
              CustomInputField(
                label: "Mật khẩu",
                controller: passCtrl,
                hintText: 'Điền mật khẩu',
                isPassword: true,
                validator: (value) {
                  if (value == null ||
                      value.trim().length < 6 ||
                      value.trim().length > 50) {
                    return "Mật khẩu phải từ 6 đến 50 ký tự";
                  }
                  return null;
                },
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    "Đăng nhập",
                    style: TextStyle(fontSize: 24, color: Colors.white),
                  ),
                ),
              ),
              Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: showRecentLoginsDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    "Tài khoản gần đây",
                    style: TextStyle(fontSize: 18, color: Colors.orange),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Help Row
              Row(
                children: <Widget>[
                  Expanded(
                    child: Row(
                      children: <Widget>[
                        SvgPicture.asset(
                          'assets/icon/headphone.svg',
                          width: 18,
                        ),
                        SizedBox(width: 1),
                        Text('Trợ giúp'),
                      ],
                    ),
                  ),
                  Spacer(),
                  Expanded(
                    child: Row(
                      children: <Widget>[
                        SvgPicture.asset(
                          'assets/icon/social_link.svg',
                          width: 18,
                        ),
                        SizedBox(width: 2),
                        Text('Group'),
                      ],
                    ),
                  ),
                  Spacer(),
                  Expanded(
                    child: Row(
                      children: <Widget>[
                        SvgPicture.asset('assets/icon/vector.svg', width: 18),
                        SizedBox(width: 2),
                        Text('Tra cứu'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CustomInputField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final String hintText;
  final String? Function(String?) validator;
  final bool isPassword;
  final TextInputType keyboardType;

  const CustomInputField({
    super.key,
    required this.label,
    required this.controller,
    required this.hintText,
    required this.validator,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
  });

  @override
  State<CustomInputField> createState() => _CustomInputFieldState();
}

class _CustomInputFieldState extends State<CustomInputField> {
  bool _showSuffix = false;
  bool _showPassword = false;

  @override
  Widget build(BuildContext context) {
    Widget? suffixIcon;
    if (widget.isPassword && _showSuffix) {
      suffixIcon = IconButton(
        icon: _showPassword
            ? SvgPicture.asset('assets/icon/eye_slash.svg')
            : SvgPicture.asset('assets/icon/eye.svg'),
        onPressed: () => setState(() => _showPassword = !_showPassword),
      );
    } else if (_showSuffix) {
      suffixIcon = IconButton(
        icon: SvgPicture.asset('assets/icon/delete.svg'),
        onPressed: () {
          widget.controller.clear();
          setState(() => _showSuffix = false);
        },
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: widget.controller,
          obscureText: widget.isPassword ? !_showPassword : false,
          keyboardType: widget.keyboardType,
          validator: widget.validator,
          onChanged: (value) {
            setState(() {
              _showSuffix = value.isNotEmpty;
            });
          },
          decoration: InputDecoration(
            hintText: widget.hintText,
            enabledBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.orange),
            ),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.orangeAccent),
            ),
            suffixIcon: suffixIcon,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}