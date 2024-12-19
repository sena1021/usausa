import 'package:flutter/material.dart';

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

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ログイン画面'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: Center(
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
              const TextField(
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: '行政コード入力欄',
                ),
              ),
              const SizedBox(height: 20),
              // パスワード入力欄
              const TextField(
                obscureText: true,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'パスワード入力欄',
                ),
              ),
              const SizedBox(height: 20),
              // ログインボタン
              ElevatedButton(
                onPressed: () {
                  // ログインボタン押下時の処理
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('ログインボタンが押されました')),
                  );
                },
                child: const Text('ログイン'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
