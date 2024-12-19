import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ログイン画面',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  bool _isLoading = false;  // ローディング中フラグ
  String? _errorMessage;    // エラーメッセージ
  
  Future<void> _login() async {
    final code = _codeController.text.trim();
    final password = _passwordController.text.trim();
    
    // 入力検証 (例: 空チェック)
    if (code.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = '行政コードとパスワードを入力してください';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // ここで実際のAPIエンドポイントを指定
      // final url = Uri.parse('https://example.com/login');
      // use a local server for testing
      final url = Uri.parse('http://localhost:8000/login');  
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'code': code, 'password': password}),
      );
      
      if (response.statusCode == 200) {
        // 例: {"success": true, "token": "xxxxxx"} など
        final data = json.decode(response.body);
        if (data['success'] == true) {
          // ログイン成功時は次の画面へ遷移
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const NextPage()),
          );
        } else {
          setState(() {
            _errorMessage = 'ログインに失敗しました。コードまたはパスワードを確認してください。';
          });
        }
      } else {
        setState(() {
          _errorMessage = 'サーバーエラーが発生しました。しばらくお待ちください。';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'ネットワークエラーが発生しました。接続を確認してください。';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ログイン画面'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 300, // フォームの幅
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black), // 外枠の線
              borderRadius: BorderRadius.circular(8), // 角を丸くする
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'ログインフォーム',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                // 行政コード入力欄
                TextField(
                  controller: _codeController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: '行政コード入力欄',
                  ),
                ),
                const SizedBox(height: 20),
                // パスワード入力欄
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'パスワード入力欄',
                  ),
                ),
                const SizedBox(height: 20),
                // エラーメッセージ表示欄
                if (_errorMessage != null) ...[
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 20),
                ],
                // ローディング中はプログレスインジケータを表示
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _login,
                        child: const Text('ログイン'),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class NextPage extends StatelessWidget {
  const NextPage({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('次のページ'),
      ),
      body: const Center(
        child: Text('ログイン成功後の画面'),
      ),
    );
  }
}
