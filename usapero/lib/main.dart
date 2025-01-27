import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:math' show asin, cos, sin, sqrt;
import 'package:flutter/services.dart' show rootBundle;
import 'package:csv/csv.dart';
// import 'package:path/path.dart' as path;
import 'package:flutter_rating_stars/flutter_rating_stars.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Disaster Report App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.pink),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
      debugShowCheckedModeBanner: true,
    );
  }
}

class HoverableCard extends StatefulWidget {
  final Widget child;

  const HoverableCard({super.key, required this.child});

  @override
  HoverableCardState createState() => HoverableCardState();
}

class HoverableCardState extends State<HoverableCard> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() {
          _isHovering = true;
        });
      },
      onExit: (_) {
        setState(() {
          _isHovering = false;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: _isHovering
            ? (Matrix4.identity()..scale(1.02))
            : Matrix4.identity(),
        // 影を付けるなどのアニメーションもできる
        decoration: BoxDecoration(
          boxShadow: _isHovering
              ? [
                  BoxShadow(
                    color: const Color.fromARGB(255, 244, 230, 237),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  )
                ]
              : [],
        ),
        child: widget.child,
      ),
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

  bool _isLoading = false; // ローディング中フラグ
  String? _errorMessage; // エラーメッセージ

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
  militaryattack('軍事攻撃'),
  nuclearcontamination('核汚染'),
  other('その他'),
  all('すべて');

  final String label;
  const DisasterType(this.label);
}

enum DisasterTypeSort {
  dateAsc, // 日時の昇順
  dateDesc, // 日時の降順
  importanceAsc, // 重要度の昇順
  importanceDesc, // 重要度の降順
}

class NextPage extends StatefulWidget {
  const NextPage({super.key});

  @override
  State<NextPage> createState() => _NextPageState();
}

class Disaster {
  String name;
  double latitude;
  double longitude;
  DisasterType type;
  // ざっくりした所在地を表すフィールド
  String? notsoaccuratelocation;
  String? description;
  List<String> images = [];
  int? id; // Optional id field
  // Optional isSampleData field
  bool isSampleData = false;
  // Required importance field, a integer from 1 to 10
  int importance;
  // Required datetime field
  DateTime datetime;

  Disaster({
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.type,
    required this.importance,
    required this.datetime,
    this.description,
    this.notsoaccuratelocation,
    this.images = const [],
    this.id, // Optional id in the constructor
    this.isSampleData = false,
  });
}

// 「災害名」→「DisasterType」の対応表
final Map<String, DisasterType> _disasterNameToTypeMap = {
  '火災': DisasterType.fire,
  '山火事': DisasterType.forestFire,
  '地震': DisasterType.earthquake,
  '地盤沈下': DisasterType.sinkhole,
  '土砂災害': DisasterType.earthstrike,
  '津波': DisasterType.tsunami,
  '洪水': DisasterType.flood,
  '台風': DisasterType.typhoon,
  '竜巻': DisasterType.tornado,
  '豪雨': DisasterType.heavyRain,
  '大雪': DisasterType.heavySnow,
  '火山噴火': DisasterType.volcanicEruption,
  '人為事故': DisasterType.humanerror,
  '熊襲撃': DisasterType.bearassault,
  '軍事攻撃': DisasterType.militaryattack,
  '核汚染': DisasterType.nuclearcontamination,
};

DisasterType getDisasterTypeFromName(String name) {
  // マッピングテーブルに無い場合は「その他」を返す
  return _disasterNameToTypeMap[name] ?? DisasterType.other;
}

class CityData {
  final String citycode;
  final String prefname;
  final String cityName1;
  final String cityName2;
  final double lat;
  final double lng;

  CityData({
    required this.citycode,
    required this.prefname,
    required this.cityName1,
    required this.cityName2,
    required this.lat,
    required this.lng,
  });
}

class CrosshairPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.lightGreen
      ..strokeWidth = 4;

    // Draw vertical line
    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      paint,
    );

    // Draw horizontal line
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

// =================================================================================================
// Helper functions
// =================================================================================================

double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
  // 地球上の2点(緯度・経度)間の距離を求める(単位: km)
  double degToRad(double degree) {
    return degree * (3.141592653589793 / 180.0);
  }

  const double earthRadius = 6371.0; // 地球の半径(km)
  double dLat = degToRad(lat2 - lat1);
  double dLon = degToRad(lon2 - lon1);

  double a = sin(dLat / 2) * sin(dLat / 2) +
      cos(degToRad(lat1)) * cos(degToRad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
  double c = 2 * asin(sqrt(a));
  return earthRadius * c;
}

/// Fileを読み込み、Base64エンコード文字列を返す関数
/// Fileを読み込み、Base64エンコード文字列を返す関数
Future<String> encodeFileToBase64(File file) async {
  try {
    // ファイルのバイナリデータを読み込む
    final bytes = await file.readAsBytes();
    // Base64エンコードして文字列を返す
    return base64Encode(bytes);
  } catch (e) {
    rethrow;
  }
}

Future<String> encodeAssetToBase64(String assetPath) async {
  final ByteData data = await rootBundle.load(assetPath);
  final Uint8List bytes = data.buffer.asUint8List();
  return base64Encode(bytes);
}

/// Base64文字列からFileを生成し、指定したパスに書き出す関数
Future<File> decodeBase64ToFile(String base64Str, String filePath) async {
  try {
    // Base64文字列をバイナリデータにデコード
    final decodedBytes = base64Decode(base64Str);
    // ファイルとして書き出す
    final file = File(filePath);
    return await file.writeAsBytes(decodedBytes);
  } catch (e) {
    rethrow;
  }
}

/// Uint8List（Web等で取得したバイナリ）をBase64文字列に変換
String encodeBytesToBase64(Uint8List bytes) {
  return base64Encode(bytes);
}

/// Base64文字列をUint8Listにデコード
Uint8List decodeBase64ToBytes(String base64Str) {
  return base64Decode(base64Str);
}

// =================================================================================================
// End of Helper functions
// =================================================================================================

class DisasterDetailsPage extends StatelessWidget {
  final Disaster disaster;

  const DisasterDetailsPage({super.key, required this.disaster});

  @override
  Widget build(BuildContext context) {
    // 画面サイズを取得
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // 画像サイズを調整（文字のサイズに合わせるために、例えば高さを150に設定）
    double imageHeight = screenHeight * 0.6; // 画面の高さの20%を画像の高さとして設定
    double imageWidth = imageHeight; // 幅も高さに合わせて同じにする

    return Scaffold(
      appBar: AppBar(
        title: const Text('災害詳細'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(screenWidth * 0.02), // 画面の幅の2%を余白として設定
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 画像と災害情報を左右に並べる
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 画像表示
                  if (disaster.images.isNotEmpty)
                    Container(
                      margin: EdgeInsets.only(
                          right: screenWidth * 0.02), // 画像と情報の間隔を広く
                      width: imageWidth, // 画像の幅を設定
                      height: imageHeight, // 画像の高さを設定
                      child: Image.memory(
                        decodeBase64ToBytes(disaster.images.first),
                        fit: BoxFit.cover,
                      ),
                    ),
                  if (disaster.images.isEmpty)
                    SizedBox(
                      width: imageWidth, // 画像の代わりにアイコンを表示
                      height: imageHeight,
                      child: Icon(Icons.image,
                          size: imageHeight * 0.6), // アイコンサイズを調整
                    ),

                  // 右側に表示する情報
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 災害名
                        Text(
                          disaster.name,
                          style: TextStyle(
                            fontSize: screenWidth * 0.025, // 画面幅の2.5%に設定
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.015), // 間隔を少し広めに

                        // 日時
                        Text(
                          '日時: ${disaster.datetime}',
                          style: TextStyle(
                              fontSize: screenWidth * 0.022), // フォントサイズを調整
                        ),
                        SizedBox(height: screenHeight * 0.015),

                        // 重要度
                        Row(
                          children: [
                            Text(
                              '重要度: ',
                              style: TextStyle(
                                  fontSize: screenWidth * 0.022), // フォントサイズを調整
                            ),
                            RatingStars(
                              value: disaster.importance.toDouble(),
                              starCount: 10,
                              maxValue: 10,
                              starSize: screenWidth * 0.02, // スターのサイズを調整
                              starSpacing: screenWidth * 0.01, // スターの間隔を調整
                              valueLabelVisibility: false,
                              starColor: Colors.pink,
                              starOffColor: const Color(0xffe7e8ea),
                            ),
                          ],
                        ),
                        SizedBox(height: screenHeight * 0.015),

                        // 近隣
                        Text(
                          '近隣: ${disaster.notsoaccuratelocation ?? '不明'}',
                          style: TextStyle(fontSize: screenWidth * 0.022),
                        ),
                        SizedBox(height: screenHeight * 0.015),

                        // 詳細情報
                        if (disaster.description != null)
                          Text(
                            // disaster.description!,
                            '詳細情報: ${disaster.description}',
                            style: TextStyle(fontSize: screenWidth * 0.022),
                          ),
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(height: screenHeight * 0.02), // 余白を少し広めに調整

              // 閉じるボタン
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    vertical: screenHeight * 0.015, // ボタンの縦サイズを調整
                    horizontal: screenWidth * 0.05, // ボタンの横サイズを調整
                  ),
                  textStyle: TextStyle(
                      fontSize: screenWidth * 0.022), // ボタンテキストのフォントサイズを調整
                ),
                child: const Text('閉じる'),
              ),
            ],
          ),
        ),
      ),
    );
  }
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
    final List<DropdownMenuEntry<DisasterType>> disasterEntries = DisasterType
        .values
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
            dropdownMenuEntries: disasterEntries
                .where((entry) => entry.value != DisasterType.all)
                .toList(),
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
                            children: _selectedImageBytes
                                .asMap()
                                .entries
                                .map((entry) {
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
                                    icon: const Icon(Icons.delete,
                                        color: Colors.grey),
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
                            children:
                                _selectedImages.asMap().entries.map((entry) {
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
                                    icon: const Icon(Icons.delete,
                                        color: Colors.grey),
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
          Row(
            // mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton(
                onPressed: () async {
                  await _getCurrentLocation();
                },
                child: const Text('現在地を取得'),
              ),
              ElevatedButton(
                onPressed: () {
                  // Open a full screen dialog, show flutter_map and 2 buttons: "Use this location" and "Cancel"
                  // use this location: the record the center of the map to _manualLatitude and _manualLongitude
                  // cancel: close the dialog
                  showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text('地図上の位置を指定'),
                        content: SizedBox(
                          width: 400,
                          height: 400,
                          child: _buildOnlytheMap(),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: const Text('取消し'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              // ここで地図の中心位置を取得して、_manualLatitude, _manualLongitude に代入
                              final center =
                                  _mapControllerReportForm.camera.center;
                              setState(() {
                                _manualLatitude = center.latitude.toString();
                                _manualLongitude = center.longitude.toString();
                                // コントローラへ反映
                                _latitudeController.text = _manualLatitude;
                                _longitudeController.text = _manualLongitude;
                                _locationMessage =
                                    '緯度: ${center.latitude}, 経度: ${center.longitude} (地図)';
                              });
                              Navigator.of(context).pop();
                            },
                            child: const Text('確定'),
                          ),
                        ],
                      );
                    },
                  );
                },
                child: const Text('地図で場所を指定'),
              ),
            ],
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
              debugPrint('Disaster: ${_selectedDisaster?.label}'); // tsunami
              debugPrint('Description: $_description');
              debugPrint('Is Important: $_isImportant');
              debugPrint('Importance: $_importance');
              // if (kIsWeb) {
              //   debugPrint('Selected Bytes: $_selectedImageBytes');
              // } else {
              //   debugPrint('Selected Files: $_selectedImages');
              // }
              debugPrint('Manual Position -> Lat: $lat, Lng: $lng');

              // 送信先のURL (テスト用や本番用で書き換えてください)
              final url = Uri.parse('http://localhost:8000/disaster_report');

              // サーバーへ送るデータを組み立てる
              // 画像は簡易的に Base64 化して送る方法の一例をコメントで示します。
              // マルチパート送信が必要な場合は http.MultipartRequest を使用してください。
              Map<String, dynamic> requestData = {
                'disaster': _selectedDisaster?.label,
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
                  return encodeBytesToBase64(bytes);
                }).toList();

                requestData['images'] = base64Images;
              } else {
                // モバイル・デスクトップ向け： File -> Uint8List -> Base64
                List<String> base64Images = [];
                for (File file in _selectedImages) {
                  final base64Str = await encodeFileToBase64(file);
                  base64Images.add(base64Str);
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

  // for building map
  final MapController _mapController = MapController();
  final MapController _mapControllerReportForm = MapController();
  // 初期位置・ズーム
  final LatLng _initialCenter = const LatLng(38.0, 140.0);
  final double _initialZoom = 5.2;
  List<Marker> _markers = [];
  List<Disaster> _disasterData = [];
  // _originalDisasterData is used to store the original data, _removeDisasterthatIsNotInCameraView function
  // filters using this data to update _disasterData
  List<Disaster> _originalDisasterData = [];

  DisasterTypeSort _currentDisasterSort = DisasterTypeSort.dateAsc;
  DisasterType? _currentDisasterFilter = DisasterType.all;

  void _filterAndSortDisasterData() {
    if (_currentDisasterFilter == DisasterType.all) {
      _disasterData = List.from(_originalDisasterData);
    } else {
      _disasterData = _originalDisasterData
          .where((d) => d.type == _currentDisasterFilter)
          .toList();
    }
    _sortDisasterData();
  }

  void _sortDisasterData() {
    setState(() {
      switch (_currentDisasterSort) {
        case DisasterTypeSort.dateAsc:
          _disasterData.sort(
            (a, b) => a.datetime.compareTo(b.datetime),
          );
          break;
        case DisasterTypeSort.dateDesc:
          _disasterData.sort(
            (a, b) => b.datetime.compareTo(a.datetime),
          );
          break;
        case DisasterTypeSort.importanceAsc:
          _disasterData.sort(
            (a, b) => a.importance.compareTo(b.importance),
          );
          break;
        case DisasterTypeSort.importanceDesc:
          _disasterData.sort(
            (a, b) => b.importance.compareTo(a.importance),
          );
          break;
      }
    });
  }

  void _updateMarkersFromDisasterData() {
    setState(() {
      _markers = _disasterData.map((disaster) {
        return Marker(
          point: LatLng(disaster.latitude, disaster.longitude),
          width: 80,
          height: 80,
          // ここでは簡易的に FlutterLogo を表示
          child: const FlutterLogo(),
        );
      }).toList();
    });
  }

  Future<void> _getnotsoaccurateLocationbyReadingCSV() async {
    // read citylldata.csv, temper with each disaster in _disasterData and add this:
    // disaster.notsoaccuratelocation = "北海道札幌市中央区"
    // the csv looks like this:
    // citycode,prefname,citynNme1,citynNme2, lat,lng
    // 011011,北海道,札幌市,中央区,43.055460,141.340956
    // 011029,北海道,札幌市,北区,43.090850,141.340831
    // 011037,北海道,札幌市,東区,43.076069,141.363722
    // 011045,北海道,札幌市,白石区,43.047687,141.405078
    // 011053,北海道,札幌市,豊平区,43.031291,141.380106
    // 011061,北海道,札幌市,南区,42.990031,141.353497
    // 011070,北海道,札幌市,西区,43.074470,141.300889
    // 012025,北海道,函館市,,41.768793,140.728810
    // we will need to find the nearest city to the disaster location
    try {
      // 1. CSV ファイルを読み込む（例: assets/citylldata.csv）
      final csvString = await rootBundle.loadString('assets/citylldata.csv');

      // 2. CSV をパースする
      //    デフォルトでカンマ区切り。改行は \n として扱う設定を例示
      List<List<dynamic>> csvTable = const CsvToListConverter().convert(
        csvString,
        eol: '\n',
      );

      // 先頭行がヘッダの場合は削除
      // citycode,prefname,citynNme1,citynNme2,lat,lng
      // といったヘッダが入っているなら removeAt(0) する
      if (csvTable.isNotEmpty) {
        // 先頭行がヘッダ（文字列）かどうか簡易チェック
        if (csvTable.first[0].toString() == 'citycode') {
          csvTable.removeAt(0);
        }
      }

      // 3. CityData のリストを作成
      final List<CityData> cityList = csvTable.map((row) {
        return CityData(
          citycode: row[0].toString(),
          prefname: row[1]?.toString() ?? '',
          cityName1: row[2]?.toString() ?? '',
          cityName2: row[3]?.toString() ?? '',
          lat: (row[4] is num)
              ? row[4].toDouble()
              : double.tryParse(row[4].toString()) ?? 0.0,
          lng: (row[5] is num)
              ? row[5].toDouble()
              : double.tryParse(row[5].toString()) ?? 0.0,
        );
      }).toList();

      // 4. _disasterData の各災害について、最寄りの市区町村を検索
      for (final disaster in _disasterData) {
        CityData? nearestCity;
        double? nearestDistance; // これまでで一番近い距離を記録する

        for (final city in cityList) {
          final distance = calculateDistance(
            disaster.latitude,
            disaster.longitude,
            city.lat,
            city.lng,
          );
          if (nearestDistance == null || distance < nearestDistance) {
            nearestCity = city;
            nearestDistance = distance;
          }
        }

        // 5. 最寄りの市区町村が見つかった場合に、ざっくりした所在地を設定
        if (nearestCity != null) {
          disaster.notsoaccuratelocation =
              '${nearestCity.prefname}${nearestCity.cityName1}${nearestCity.cityName2}';
        } else {
          disaster.notsoaccuratelocation = '場所不明';
        }
      }

      // ※ ここで setState() を呼んで更新が必要なら呼ぶ
      setState(() {});
    } catch (e) {
      if (kDebugMode) {
        debugPrint('CSV読み込みエラー: $e');
      }
    }
  }

  void _removeDisasterthatIsNotInCameraView() {
    // マップの表示範囲外にある災害情報を削除する
    final bounds = _mapController.camera.visibleBounds;
    // debugPrint('Bounds: $bounds');
    // flutter: Bounds: LatLngBounds(north: 46.28539698115584, south: 28.712606649810624, east: 166.6049459529588, west: 113.35173571382869)
    setState(() {
      // assigin original disaster data to disaster data
      _disasterData = List.from(_originalDisasterData);
      _filterAndSortDisasterData();
      _disasterData.removeWhere((disaster) {
        return !bounds.contains(LatLng(disaster.latitude, disaster.longitude));
      });
    });
  }

  Widget _buildMap() {
    return Row(
      children: [
        _buildMapLeftPanel(),
        _buildMapMap(),
        _buildMapRight(),
      ],
    );
  }

  Widget _buildMapLeftPanel() {
    // load data and load sample data does the following:
    // _disasterData = loadedData from defined samples or from the server
    // _originalDisasterData = List.from(_disasterData);
    // _getnotsoaccurateLocationbyReadingCSV();
    // _updateMarkersFromDisasterData();
    // _sortDisasterData();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Column(
        children: [
          Tooltip(
            message: 'データを取得',
            child: IconButton(
              icon: const Icon(Icons.cloud_download, size: 32),
              onPressed: _loadDisasterData,
            ),
          ),
          const SizedBox(height: 8),
          Tooltip(
            message: 'サンプルデータ',
            child: IconButton(
              icon: const Icon(Icons.chair, size: 32),
              onPressed: _loadSampleData,
            ),
          ),
          const SizedBox(height: 8),
          // sort option
          PopupMenuButton<DisasterTypeSort>(
            icon: const Icon(Icons.sort_outlined, size: 32),
            tooltip: 'ソートオプション',
            onSelected: (DisasterTypeSort selectedSort) {
              setState(() {
                _currentDisasterSort = selectedSort;
                _sortDisasterData();
              });
            },
            itemBuilder: (BuildContext context) {
              return <PopupMenuEntry<DisasterTypeSort>>[
                const PopupMenuItem<DisasterTypeSort>(
                  value: DisasterTypeSort.dateAsc,
                  child: Text('日時（古い順）'),
                ),
                const PopupMenuItem<DisasterTypeSort>(
                  value: DisasterTypeSort.dateDesc,
                  child: Text('日時（新しい順）'),
                ),
                const PopupMenuItem<DisasterTypeSort>(
                  value: DisasterTypeSort.importanceAsc,
                  child: Text('重要度（低い順）'),
                ),
                const PopupMenuItem<DisasterTypeSort>(
                  value: DisasterTypeSort.importanceDesc,
                  child: Text('重要度（高い順）'),
                ),
              ];
            },
          ),
          const SizedBox(height: 8),
          // quick filter
          PopupMenuButton<DisasterType?>(
            icon: const Icon(Icons.filter_1_outlined, size: 32),
            tooltip: 'クイックフィルター',
            onSelected: (DisasterType? selectedType) {
              setState(() {
                _currentDisasterFilter = selectedType;
                _filterAndSortDisasterData();
                _updateMarkersFromDisasterData();
              });
            },
            itemBuilder: (BuildContext context) {
              return <PopupMenuEntry<DisasterType?>>[
                // DisasterType の値を列挙してメニューを作成
                ...DisasterType.values.map((type) {
                  return PopupMenuItem<DisasterType?>(
                    value: type,
                    child: Text(type.label),
                  );
                }),
              ];
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMapMap() {
    return Expanded(
      flex: 1,
      child: Column(
        children: [
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _initialCenter,
                initialZoom: _initialZoom,
                onMapEvent: (MapEvent event) {
                  if (event is MapEventMoveEnd ||
                      event is MapEventScrollWheelZoom) {
                    _removeDisasterthatIsNotInCameraView();
                  }
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'dev.fleaflet.flutter_map.example',
                ),
                MarkerLayer(markers: _markers),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapRight() {
    return Expanded(
      flex: 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // _buildMapRightDropdown(),
          _buildMapRightDisasterList(),
        ],
      ),
    );
  }

  // Widget _buildMapRightDropdown() {
  //   return Padding(
  //     padding: const EdgeInsets.symmetric(horizontal: 8.0),
  //     child: DropdownButton<DisasterTypeSort>(
  //       value: _currentDisasterSort,
  //       onChanged: (DisasterTypeSort? newValue) {
  //         if (newValue != null) {
  //           setState(() {
  //             _currentDisasterSort = newValue;
  //             _sortDisasterData();
  //           });
  //         }
  //       },
  //       items: const [
  //         DropdownMenuItem(
  //           value: DisasterTypeSort.dateAsc,
  //           child: Text('日時（古い順）'),
  //         ),
  //         DropdownMenuItem(
  //           value: DisasterTypeSort.dateDesc,
  //           child: Text('日時（新しい順）'),
  //         ),
  //         DropdownMenuItem(
  //           value: DisasterTypeSort.importanceAsc,
  //           child: Text('重要度（低い順）'),
  //         ),
  //         DropdownMenuItem(
  //           value: DisasterTypeSort.importanceDesc,
  //           child: Text('重要度（高い順）'),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildMapRightDisasterList() {
    return Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        itemCount: _disasterData.length,
        itemBuilder: (context, index) {
          final disaster = _disasterData[index];
          return _buildDisasterCard(disaster, index);
        },
      ),
    );
  }

  Widget _buildDisasterCard(Disaster disaster, int index) {
    return HoverableCard(
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 4.0),
        child: ListTile(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('災害: ${disaster.name}'),
              Row(
                children: [
                  const Text('重要度: '),
                  RatingStars(
                    value: disaster.importance.toDouble(),
                    starCount: 10,
                    maxValue: 10,
                    starSize: 20,
                    starSpacing: 2,
                    valueLabelVisibility: false,
                    starColor: Colors.pink,
                    starOffColor: const Color(0xffe7e8ea),
                  ),
                ],
              ),
              Text('近隣: ${disaster.notsoaccuratelocation}'),
              Text('日時: ${disaster.datetime}'),
            ],
          ),
          trailing: _buildDisasterCardTrailingButtons(disaster, index),
          onTap: () => _navigateToDisasterDetails(context, disaster),
        ),
      ),
    );
  }

  void _navigateToDisasterDetails(BuildContext context, Disaster disaster) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DisasterDetailsPage(disaster: disaster),
        fullscreenDialog: true,
      ),
    );
  }

  Widget _buildDisasterCardTrailingButtons(Disaster disaster, int index) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.map),
          onPressed: () {
            _mapController.move(
              LatLng(disaster.latitude, disaster.longitude),
              _mapController.camera.zoom,
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.delete),
          onPressed: () => _deleteDisaster(context, index),
        ),
        IconButton(
          icon: const Icon(Icons.archive),
          onPressed: () {
            // アーカイブ処理
          },
        ),
      ],
    );
  }

  Widget _buildOnlytheMap() {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapControllerReportForm,
          options: MapOptions(
            initialCenter: _initialCenter,
            initialZoom: _initialZoom,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'dev.fleaflet.flutter_map.example',
            ),
          ],
        ),
        Center(
          child: CustomPaint(
            size: Size(30, 30), // Adjust the size of the crosshair
            painter: CrosshairPainter(),
          ),
        ),
      ],
    );
  }

  Future<void> _deleteDisaster(BuildContext context, int index) async {
    // 1. 削除対象の災害情報を取得
    final disaster = _disasterData[index];

    // サンプルデータの場合は削除しない
    if (disaster.isSampleData) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('サンプルデータは削除できません。'),
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }

    // 2. サーバー側へDELETEリクエストを送信
    try {
      final id = disaster.id; // ここはDisasterクラスの実装に合わせて
      final url = Uri.parse('http://localhost:8000/disaster/$id');
      final response = await http.delete(url);

      if (response.statusCode == 200) {
        // 3. 成功時: ローカルのリストから削除して画面を更新
        setState(() {
          _disasterData.removeAt(index);
          _originalDisasterData = List.from(_disasterData);
          _updateMarkersFromDisasterData();
        });

        // SnackBarを表示して成功メッセージを通知
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('削除に成功しました。'),
              duration: Duration(seconds: 1),
            ),
          );
        }
      } else {
        // ステータスコードが200以外ならエラーとして扱う例
        final body = json.decode(response.body);
        debugPrint("削除失敗: ${response.statusCode} => $body");

        // エラーメッセージをSnackBarで通知
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('削除に失敗しました: ステータスコード ${response.statusCode}'),
              duration: Duration(seconds: 1),
            ),
          );
        }
      }
    } catch (e) {
      // ネットワーク障害など
      debugPrint("エラーが発生しました: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('エラーが発生しました: $e'),
          ),
        );
      }
    }
  }

  // Future<void> _archiveDisaster(int index) async {
  //   // 1. アーカイブ対象の災害情報を取得
  //   final disaster = _disasterData[index];

  //   // 2. サーバー側へPOSTリクエストを送信 (PUTやPATCHの可能性もあり)
  //   try {
  //     // 同様に、一意なIDを利用
  //     final id = disaster.id;
  //     final url = Uri.parse('http://localhost:8000/disaster/$id/archive');

  //     final response = await http.post(url);

  //     if (response.statusCode == 200) {
  //       // 3. 成功時: ローカルのリストから除外するなどの処理を行う
  //       //   例: 画面上からは削除して「アーカイブ済み」とみなす
  //       setState(() {
  //         _disasterData.removeAt(index);
  //         _originalDisasterData = List.from(_disasterData);
  //         _updateMarkersFromDisasterData();
  //       });
  //     } else {
  //       // ステータスコードが200以外ならエラーとして扱う例
  //       final body = json.decode(response.body);
  //       print("アーカイブ失敗: ${response.statusCode} => $body");
  //     }
  //   } catch (e) {
  //     print("エラーが発生しました: $e");
  //   }
  // }

  Future<void> _loadDisasterData() async {
    try {
      // FastAPIの /disaster エンドポイントにGETリクエストを送信
      final response =
          await http.get(Uri.parse('http://localhost:8000/disaster'));

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        // レスポンスボディをJSONとしてデコード
        final responseData = jsonDecode(decodedBody);

        // responseData は { "success": true, "reports": [ ... ] } の形を想定
        final List<dynamic> reportList = responseData["reports"];

        // レスポンスに含まれる各レポートをFlutter側のDisasterオブジェクトに変換
        final List<Disaster> loadedData = reportList.map((report) {
          final String name = report["disaster"] ?? "名称不明";
          final double latitude =
              report["location"]["latitude"]?.toDouble() ?? 0.0;
          final double longitude =
              report["location"]["longitude"]?.toDouble() ?? 0.0;
          final List<dynamic> imagesDynamic = report["images"] ?? [];
          final List<String> images =
              imagesDynamic.map((img) => img?.toString() ?? "").toList();
          final String description = report["description"] ?? "";
          final int id = report["report_id"] ?? "";
          final int importance = report["importance"] ?? 0;

          DateTime datetime;
          try {
            datetime = report["datetime"] != null
                ? DateTime.parse(report["datetime"])
                : DateTime.now();
          } catch (e) {
            datetime = DateTime.now();
            if (kDebugMode) {
              debugPrint("日付形式が不正です: ${report["datetime"]}");
            }
          }

          return Disaster(
            name: name,
            type: getDisasterTypeFromName(name),
            latitude: latitude,
            longitude: longitude,
            images: images,
            description: description,
            id: id,
            importance: importance,
            datetime: datetime,
          );
        }).toList();

        // ステートを更新してマーカーなどを再生成
        setState(() {
          _disasterData = loadedData;
          _originalDisasterData = List.from(_disasterData);
          _getnotsoaccurateLocationbyReadingCSV();
          _currentDisasterFilter = DisasterType.all;
          _updateMarkersFromDisasterData();
          _sortDisasterData();
        });
      } else {
        if (kDebugMode) {
          debugPrint("データ取得に失敗しました: ${response.statusCode}");
          debugPrint("レスポンス内容: ${response.body}");
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint("エラーが発生しました: $e");
      }
    }
  }

  // For sample data, simply load some images from assets and encode them to base64
  // In production, server will send the base64 string
  Future<void> _loadSampleData() async {
    final assetPaths = [
      'assets/images_examples/military_vehicle.jpg',
      'assets/images_examples/nuclear_waste.jpg',
      'assets/images_examples/teddy_bear.jpg',
      'assets/images_examples/snow.jpg',
      'assets/images_examples/snow_husky.jpg',
    ];

    final imagesBase64 = <String, String>{};

    for (final assetPath in assetPaths) {
      final base64Str = await encodeAssetToBase64(assetPath);
      // パスの末尾のファイル名だけ取り出したい場合は、split や正規表現で切り出す
      final fileName = assetPath.split('/').last;
      imagesBase64[fileName] = base64Str;
    }

    setState(() {
      _disasterData = [
        Disaster(
          name: '軍事攻撃',
          type: DisasterType.militaryattack,
          latitude: 35.6895,
          longitude: 139.6917,
          images: [imagesBase64['military_vehicle.jpg'] ?? ''],
          description: '軍事車両が目撃されたぞ！遠くから、巨大な車両がゆっくりと進んでくる。その外見は、確かに映画やニュースで見る軍事車両そっくりだ。',
          isSampleData: true,
          importance: 9,
          datetime: DateTime.utc(2025, 1, 1, 12, 0),
        ),
        Disaster(
          name: '核汚染',
          type: DisasterType.nuclearcontamination,
          latitude: 34.6937,
          longitude: 135.5023,
          images: [imagesBase64['nuclear_waste.jpg'] ?? ''],
          description: '静かな田園地帯に広がる小麦畑が金色に輝いていた。その中心には奇妙なものが転がっていた――錆びついた黄色い樽だ。村人たちはその樽を見つけてざわめき始めた。「放射性廃棄物が漏れているに違いない！」と、噂はあっという間に広がった。子どもたちは近寄らないように言われ、大人たちは慌てて専門家を呼び寄せた。',
          isSampleData: true,
          importance: 10,
          datetime: DateTime.utc(2025, 1, 2, 7, 13),
        ),
        Disaster(
          name: '熊襲撃',
          type: DisasterType.bearassault,
          latitude: 43.82013008282363,
          longitude: 143.85868562865505,
          images: [imagesBase64['teddy_bear.jpg'] ?? ''],
          description: '🐻🐻🐻🐻🐻🐻🐻🐻🐻🐻🐻🐻🐻🐻🐻🐻🐻🐻🐻🐻🐻🐻🐻🐻🐻🐻🐻🐻🐻🐻🐻🐻🐻🐻🐻🐻🐻🐻🐻🐻🐻🐻が出没しました。',
          isSampleData: true,
          importance: 2,
          datetime: DateTime.utc(2025, 1, 3, 8, 0),
        ),
        Disaster(
          name: '熊襲撃',
          type: DisasterType.bearassault,
          latitude: 43.81444321853834,
          longitude: 143.90273362448957,
          images: [imagesBase64['teddy_bear.jpg'] ?? ''],
          description: '熊が学校に入ったらしい！次々と子どもたちがパニックになりました。みんなは教室の隅に集まり、先生も急いで職員室に通報しました。',
          isSampleData: true,
          importance: 2,
          datetime: DateTime.utc(2025, 1, 4, 22, 0),
        ),
        Disaster(
          name: '大雪',
          type: DisasterType.heavySnow,
          latitude: 43.19764537767935,
          longitude: 141.75734214498215,
          images: [imagesBase64['snow.jpg'] ?? ''],
          description: '冬の寒さが厳しく、雪が静かに降り積もる街。小さな犬は、いつものように国道のはずれの林を走り回って遊んでいました。しかし、その日は雪がいつもより深く、まるは夢中で跳ね回るうちに深い雪の中に足を取られ、身動きが取れなくなってしまいました。',
          isSampleData: true,
          importance: 1,
          datetime: DateTime.utc(2025, 1, 5, 10, 0),
        ),
        Disaster(
          name: '大雪',
          type: DisasterType.heavySnow,
          latitude: 43.529597509514225,
          longitude: 142.1754771492199,
          images: [imagesBase64['snow_husky.jpg'] ?? '', imagesBase64['snow.jpg'] ?? ''],
          description: '冷たい風が広がる雪原には、一面の白い世界が広がっていた。雪は細かく降り続け、空から舞い落ちる結晶がキラキラと光を反射している。その中を、一匹のハスキーが駆け抜けていた。黒と白の毛が混ざり合ったその体は、雪景色と完璧に調和し、まるで雪そのものが動き出したようだった。',
          isSampleData: true,
          importance: 1,
          datetime: DateTime.utc(2025, 1, 1, 13, 0),
        ),
      ];
      _originalDisasterData = List.from(_disasterData);
      _getnotsoaccurateLocationbyReadingCSV();
      _currentDisasterFilter = DisasterType.all;
      _updateMarkersFromDisasterData();
      _sortDisasterData();
    });
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
            _latitudeController.text = '';
            _longitudeController.text = '';
            _disasterSubmitResponseMessage = '';
          } else if (index == 1) {
            // ここで地図の初期表示位置を設定
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _mapController.move(_initialCenter, _initialZoom);
            });
            _markers = [];
            _disasterData = [];
            _originalDisasterData = [];
            _currentDisasterFilter = DisasterType.all;
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
