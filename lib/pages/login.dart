import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/version_utils.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  final _dio = Dio();

  @override
  void initState() {
    super.initState();
    _checkForUpdate();
    _tryAutoLogin();
  }

  Future<void> _tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final lastLoginDate = prefs.getString('login_date');
    final savedUsername = prefs.getString('username');
    final savedPassword = prefs.getString('password');

    if (savedUsername != null) {
      _usernameController.text = savedUsername;
    }

    if (lastLoginDate != null &&
        savedUsername != null &&
        savedPassword != null) {
      final lastLogin = DateFormat('yyyy-MM-dd').parse(lastLoginDate);
      final now = DateTime.now();
      final difference = now.difference(lastLogin).inDays;

      if (difference < 14) {
        _passwordController.text = savedPassword;
        _login();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('登录已过期，请重新登录')),
          );
        }
      }
    }
  }

  Future<void> _checkForUpdate() async {
    await VersionUtils.checkForUpdate(context);
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _dio.post(
        'http://hungryhenry.xyz/api/login.php',
        options: Options(
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8'
          },
        ),
        data: jsonEncode(<String, String>{
          'username': _usernameController.text,
          'password': _passwordController.text,
        }),
      );

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
            'uid', jsonDecode(response.data)['data']['uid'].toString());
        await prefs.setString(
            'password', jsonDecode(response.data)['data']['password']);
        await prefs.setString(
            'username', jsonDecode(response.data)['data']['username']);
        await prefs.setString(
            'mail', jsonDecode(response.data)['data']['mail']);

        DateTime now = DateTime.now();
        String formattedDate = DateFormat('yyyy-MM-dd').format(now);
        await prefs.setString('login_date', formattedDate);
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('登录失败，请检查用户名和密码')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('网络错误，请稍后重试')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Argumate',
                  style: Theme.of(context).textTheme.displayLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: '用户名',
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '请输入用户名';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: '密码',
                    prefixIcon: Icon(Icons.lock),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '请输入密码';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('登录'),
                ),
                //免登录游客模式
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/home');
                  },
                  child: Text('游客模式'),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () async {
                    // 打开注册网页
                    if (await canLaunchUrl(
                        Uri.parse('http://hungryhenry.xyz/blog/admin/'))) {
                      await launchUrl(
                          Uri.parse('http://hungryhenry.xyz/blog/admin/'));
                    }
                  },
                  child: const Text('还没有账号？立即注册'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
