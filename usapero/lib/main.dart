import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.purpleAccent),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
      debugShowCheckedModeBanner: true,
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
    // if entered rokafox, rokafox, then it will be successful
    // REMOVE THIS IN PRODUCTION
    if (code == 'rokafox' && password == 'rokafox') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const NextPage()),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
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
          if (!mounted) return;
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
      // appBar: AppBar(
      //   title: const Text('ログイン画面'),
      //   backgroundColor: Theme.of(context).colorScheme.primary,
      // ),
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
                  'ログイン',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                // 行政コード入力欄
                TextField(
                  controller: _codeController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: '行政コード',
                  ),
                ),
                const SizedBox(height: 20),
                // パスワード入力欄
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'パスワード',
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

enum DisasterType {
  fire('火災'),
  forestFire('山火事'),
  earthquake('地震'),
  sinkhole('地盤沈下'),
  earthstrike('土砂災害'),
  tsunami('津波'),
  flood('洪水'),
  typhoon('台風'),
  tornado('竜巻'),
  heavyRain('豪雨'),
  heavySnow('大雪'),
  volcanicEruption('火山噴火'),
  humanerror('人為事故'),
  bearassault('熊襲撃'),
  militaryattack('軍事襲撃'),
  nuclearcontamination('核汚染'),
  other('その他');

  final String label;
  const DisasterType(this.label);
}

class NextPage extends StatefulWidget {
  const NextPage({super.key});

  @override
  State<NextPage> createState() => _NextPageState();
}

class _NextPageState extends State<NextPage> {
  int _selectedIndex = 0;
  DisasterType? _selectedDisaster;
  String _description = '';
  bool _isImportant = false;
  int _importance = 5;
  List<File> _selectedImages = [];
  List<Uint8List> _selectedImageBytes = [];
  // 取得した位置情報を格納するための変数（任意）
  String _locationMessage = '位置情報は取得されていません';
  String _manualLatitude = '';
  String _manualLongitude = '';
  String _disasterSubmitResponseMessage = '';
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();

  // for building map
  final MapController _mapController = MapController();
  // 初期位置・ズーム
  final LatLng _initialCenter = LatLng(35.0, 135.0);
  final double _initialZoom = 5.0;

  Future<void> _pickImage() async {
    if (kIsWeb) {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
      );
      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedImageBytes = result.files
              .where((f) => f.bytes != null)
              .map((f) => f.bytes!)
              .toList();
        });
      }
    } else {
      // WebではないのでPlatform判定可能
      if (Platform.isAndroid || Platform.isIOS) {
        // モバイルはimage_pickerを使用 (複数画像選択)
        final picker = ImagePicker();
        final pickedFiles = await picker.pickMultiImage();
        if (pickedFiles.isNotEmpty) {
          setState(() {
            _selectedImages = pickedFiles.map((f) => File(f.path)).toList();
          });
        }
      } else {
        // デスクトップ(Windows/Linux/macOS)用
        final result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          allowMultiple: true,
        );
        if (result != null && result.files.isNotEmpty) {
          setState(() {
            _selectedImages = result.files
                .where((f) => f.path != null)
                .map((f) => File(f.path!))
                .toList();
          });
        }
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      if (kIsWeb) {
        // Web 用の位置情報取得ロジック (Geolocator は Web でも動作するが、
        // ユーザーがブラウザで位置情報利用を許可する必要があります。)
        // そのままでも動作しますが、環境によっては別の実装が必要となる場合あり
        Position position = await _determinePosition();
        setState(() {
          _locationMessage =
              '緯度: ${position.latitude}, 経度: ${position.longitude} (Web)';
          _manualLatitude = position.latitude.toString();
          _manualLongitude = position.longitude.toString();
          // コントローラへ反映
          _latitudeController.text = _manualLatitude;
          _longitudeController.text = _manualLongitude;
        });
      } else {
        if (Platform.isAndroid || Platform.isIOS) {
          Position position = await _determinePosition();
          setState(() {
            _locationMessage =
                '緯度: ${position.latitude}, 経度: ${position.longitude} (モバイル)';
            _manualLatitude = position.latitude.toString();
            _manualLongitude = position.longitude.toString();
            // コントローラへ反映
            _latitudeController.text = _manualLatitude;
            _longitudeController.text = _manualLongitude;
          });
        } else {
          // linux/windows desktop usually does not have GPS chip, so make no sense to get location
          setState(() {
            _locationMessage = 'このプラットフォームでは未対応です';
          });
        }
      }
    } catch (e) {
      debugPrint('位置情報の取得に失敗しました: $e');
      setState(() {
        _locationMessage = '位置情報の取得に失敗しました';
      });
    }
  }

  Future<Position> _determinePosition() async {
    // 位置情報サービスが有効かチェック
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // 位置情報サービスが無効の場合、ユーザーへ促す
      throw Exception('位置情報サービスが無効になっています。');
    }

    // 位置情報権限の状態を確認
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      // 権限がなければユーザーに許可を求める
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // それでも拒否された場合
        throw Exception('位置情報の権限が拒否されました。');
      }
    }
    
    // 永久に拒否されている場合
    if (permission == LocationPermission.deniedForever) {
      // 権限許可画面を開くなどの案内が必要
      throw Exception('位置情報の権限が永久に拒否されています。');
    }

    // ここまで来れば位置情報を取得できる
    return await Geolocator.getCurrentPosition();
  }

  Widget _buildReportForm() {
    final List<DropdownMenuEntry<DisasterType>> disasterEntries = DisasterType.values
        .map((d) => DropdownMenuEntry<DisasterType>(value: d, label: d.label))
        .toList();
        
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 災害タイプ選択ドロップダウン
          DropdownMenu<DisasterType>(
            width: double.infinity,
            label: const Text('どんな災害ですか？'),
            dropdownMenuEntries: disasterEntries,
            onSelected: (DisasterType? disaster) {
              setState(() {
                _selectedDisaster = disaster;
              });
            },
          ),
          const SizedBox(height: 16),
          // 説明用テキストフィールド（複数行）
          TextFormField(
            decoration: const InputDecoration(
              labelText: '詳細情報を教えてくれませんか？',
              border: OutlineInputBorder(),
            ),
            maxLines: 5,
            onChanged: (value) {
              setState(() {
                _description = value;
              });
            },
          ),
          const SizedBox(height: 16),
          // 重要チェックボックス
          CheckboxListTile(
            title: const Text('急を要する案件です。'),
            value: _isImportant,
            onChanged: (value) {
              setState(() {
                _isImportant = value ?? false;
              });
            },
          ),
        const SizedBox(height: 16),
        Row(
          children: [
            const Text('重要度:'),
            Expanded(
              child: Slider(
                value: _importance.toDouble(),
                min: 1,
                max: 10,
                divisions: 9,
                label: _importance.toString(),
                onChanged: (double value) {
                  setState(() {
                    _importance = value.toInt();
                  });
                },
              ),
            ),
          ],
        ),
          const SizedBox(height: 16),
          Row(
            children: [
              ElevatedButton(
                onPressed: _pickImage,
                child: const Text('画像を選択'),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: kIsWeb
                    // ▼ ここでWeb用表示を
                    ? _selectedImageBytes.isEmpty
                        ? const Text('画像が選択されていません')
                        : Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _selectedImageBytes.asMap().entries.map((entry) {
                              final index = entry.key;
                              final imageBytes = entry.value;
                              return Stack(
                                alignment: Alignment.topRight,
                                children: [
                                  Image.memory(
                                    imageBytes,
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.grey),
                                    onPressed: () {
                                      setState(() {
                                        _selectedImageBytes.removeAt(index);
                                      });
                                    },
                                  ),
                                ],
                              );
                            }).toList(),
                          )
                    // ▼ ここでモバイル・デスクトップ用表示を
                    : _selectedImages.isEmpty
                        ? const Text('画像が選択されていません')
                        : Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _selectedImages.asMap().entries.map((entry) {
                              final index = entry.key;
                              final imageFile = entry.value;
                              return Stack(
                                alignment: Alignment.topRight,
                                children: [
                                  Image.file(
                                    imageFile,
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.grey),
                                    onPressed: () {
                                      setState(() {
                                        _selectedImages.removeAt(index);
                                      });
                                    },
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 位置情報取得ボタン & メッセージ
          ElevatedButton(
            onPressed: () async {
              await _getCurrentLocation();
              // ScaffoldMessenger.of(context).showSnackBar(
              //   SnackBar(content: Text(_locationMessage)),
              // );
            },
            child: const Text('現在地を取得'),
          ),
          const SizedBox(height: 8),
          Text(_locationMessage),

          const SizedBox(height: 16),
          TextFormField(
            controller: _latitudeController,
            decoration: const InputDecoration(
              labelText: '緯度',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              _manualLatitude = value;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _longitudeController,
            decoration: const InputDecoration(
              labelText: '経度',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              _manualLongitude = value;
            },
          ),

          const SizedBox(height: 16),
          // 送信ボタン
          ElevatedButton(
            onPressed: () async {
              if (_selectedDisaster == null) {
                setState(() {
                  _disasterSubmitResponseMessage = '災害が未選択です。';
                });
                return;
              }
              double? lat = double.tryParse(_manualLatitude);
              double? lng = double.tryParse(_manualLongitude);

              if (lat == null || lng == null) {
                setState(() {
                  _disasterSubmitResponseMessage = '緯度・経度を数値で入力してください。';
                });
                return;
              }

              // デバッグ用ログ（あとで削除可能）
              debugPrint('Disaster: ${_selectedDisaster.toString()}');
              debugPrint('Description: $_description');
              debugPrint('Is Important: $_isImportant');
              debugPrint('Importance: $_importance');
              if (kIsWeb) {
                debugPrint('Selected Bytes: $_selectedImageBytes');
              } else {
                debugPrint('Selected Files: $_selectedImages');
              }
              debugPrint('Manual Position -> Lat: $lat, Lng: $lng');

              // 送信先のURL (テスト用や本番用で書き換えてください)
              final url = Uri.parse('http://localhost:8000/disaster_report');

              // サーバーへ送るデータを組み立てる
              // 画像は簡易的に Base64 化して送る方法の一例をコメントで示します。
              // マルチパート送信が必要な場合は http.MultipartRequest を使用してください。
              Map<String, dynamic> requestData = {
                'disaster': _selectedDisaster.toString(), // enum->String 変換の一例
                'description': _description,
                'isImportant': _isImportant,
                'importance': _importance,
                'location': {
                  'latitude': lat,
                  'longitude': lng,
                },
              };

              // 画像を Base64 文字列として送る場合（Web かモバイルで処理を分ける例）
              if (kIsWeb) {
                // Web 向け： Uint8List を Base64 エンコード
                List<String> base64Images = _selectedImageBytes.map((bytes) {
                  return base64Encode(bytes);
                }).toList();

                requestData['images'] = base64Images;
              } else {
                // モバイル・デスクトップ向け： File -> Uint8List -> Base64
                List<String> base64Images = [];
                for (File file in _selectedImages) {
                  final bytes = await file.readAsBytes();
                  base64Images.add(base64Encode(bytes));
                }
                requestData['images'] = base64Images;
              }

              // 実際に HTTP POST リクエストを送信
              try {
                final response = await http.post(
                  url,
                  headers: {'Content-Type': 'application/json'},
                  body: json.encode(requestData),
                );

                if (response.statusCode == 200) {
                  final data = json.decode(response.body);
                  if (data['success'] == true) {
                    // 送信成功時の処理
                    setState(() {
                      // also show the response message with data['message']
                      _disasterSubmitResponseMessage = '送信に成功しました。';
                    });
                  } else {
                    setState(() {
                      _disasterSubmitResponseMessage = '送信に失敗しました。';
                    });
                  }
                } else {
                  setState(() {
                    _disasterSubmitResponseMessage = 'サーバーエラーが発生しました。';
                  });
                }
              } catch (e) {
                // ネットワークエラーやその他例外時の処理
                setState(() {
                  _disasterSubmitResponseMessage = 'ネットワークエラーが発生しました。';
                });
              }
            },
            child: const Text('送信'),
          ),
          Text(_disasterSubmitResponseMessage),
        ],
      ),
    );
  }

  Widget _buildMap() {
    return Column(
      children: [
        // 「request data」ボタン
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: ElevatedButton(
            onPressed: () {
              // ボタン押下時の処理をここに書く
              // 例: APIリクエストで報告一覧を取得するといった実装
              // setState(() {});
            },
            child: const Text('データを取得'),
          ),
        ),
        // flutter_map を利用した地図ウィジェット
        Expanded(
          child: FlutterMap(
            // ★ MapController を渡す
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _initialCenter,
              initialZoom: _initialZoom,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
              ),
              // 必要に応じてマーカーなどを追加
              // MarkerLayer(
              //   markers: [
              //     Marker(
              //       width: 80.0,
              //       height: 80.0,
              //       point: LatLng(35.0, 135.0),
              //       builder: (ctx) => const Icon(Icons.location_on),
              //     ),
              //   ],
              // ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPageContent() {
    switch (_selectedIndex) {
      case 0:
        // 災害情報報告用フォームを返す
        return _buildReportForm();
      case 1:
        return _buildMap();
      default:
        return const Center(child: Text('不明な画面'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FBDR - Federal Bureau of Disaster Response'),
      ),
      body: _buildPageContent(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
          if (index == 0) {
            _selectedDisaster = null;
            _description = '';
            _isImportant = false;
            _importance = 5;
            _selectedImages = [];
            _selectedImageBytes = [];
            _locationMessage = '位置情報は取得されていません';
            _manualLatitude = '';
            _manualLongitude = '';
            _disasterSubmitResponseMessage = '';
          } else if (index == 1) {
            // ここで地図の初期表示位置を設定
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _mapController.move(_initialCenter, _initialZoom);
            });
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.report_outlined),
            selectedIcon: Icon(Icons.report),
            label: '災害情報報告',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: '報告一覧',
          ),
        ],
      ),
    );
  }
}
