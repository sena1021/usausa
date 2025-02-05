import 'package:flutter/material.dart';
import 'package:flutter_rating_stars/flutter_rating_stars.dart';
import 'main.dart';

class DisasterDetailsPage extends StatefulWidget {
  final Disaster disaster;
  const DisasterDetailsPage({super.key, required this.disaster});

  @override
  State<DisasterDetailsPage> createState() => _DisasterDetailsPageState();
}

class _DisasterDetailsPageState extends State<DisasterDetailsPage> {
  int _currentImageIndex = 0;

  Disaster get _disaster => widget.disaster;
  int get _imageCount => _disaster.images.length;

  void _previousImage() {
    setState(() {
      _currentImageIndex =
          (_currentImageIndex - 1 + _imageCount) % _imageCount;
    });
  }

  void _nextImage() {
    setState(() {
      _currentImageIndex = (_currentImageIndex + 1) % _imageCount;
    });
  }

  /// 状態に応じたテキストを取得する関数
  String _getStatusText(int status) {
    switch (status) {
      case 0:
        return '未対応';
      case 1:
        return '対応中';
      case 2:
        return '対応済み';
      default:
        return '不明';
    }
  }

  /// 状態に応じた色を取得する関数
  Color _getStatusColor(int status) {
    switch (status) {
      case 0:
        return Colors.red;
      case 1:
        return Colors.yellow;
      case 2:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(title: const Text('災害詳細')),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(screenWidth * 0.02),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// ---- 1) メイン上段: 画像と情報を左右並べる ----
              Row(
                children: [
                  // 左側(画像表示)
                  _buildLeftImageSection(screenWidth, screenHeight),
                  // 右側(テキストなどの詳細情報)
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(left: screenWidth * 0.02),
                      child: _buildRightInfoSection(screenWidth, screenHeight),
                    ),
                  ),
                ],
              ),

              /// ---- 2) 複数画像がある場合のみのナビゲーション ----
              if (_imageCount > 1) ...[
                SizedBox(height: screenHeight * 0.02),
                _buildImageNavigationControls(screenWidth, screenHeight),
              ],

              /// ---- -1) 閉じるボタン ----
              SizedBox(height: screenHeight * 0.02),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    vertical: screenHeight * 0.015,
                    horizontal: screenWidth * 0.05,
                  ),
                  textStyle: TextStyle(fontSize: screenWidth * 0.022),
                ),
                child: const Text('閉じる'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 左側: 画像表示用ウィジェット
  Widget _buildLeftImageSection(double screenWidth, double screenHeight) {
    final imageHeight = screenHeight * 0.6;
    final imageWidth = imageHeight; // 正方形っぽい比率にしたい場合

    // 画像がある場合と無い場合で表示を切り替え
    if (_disaster.images.isNotEmpty) {
      return SizedBox(
        width: imageWidth,
        height: imageHeight,
        child: Image.memory(
          decodeBase64ToBytes(_disaster.images[_currentImageIndex]),
          fit: BoxFit.cover,
        ),
      );
    } else {
      return SizedBox(
        width: imageWidth,
        height: imageHeight,
        child: Icon(Icons.image, size: imageHeight * 0.6),
      );
    }
  }

  /// 右側: 災害の詳細情報(名前・日時・重要度・所在地など)
  Widget _buildRightInfoSection(double screenWidth, double screenHeight) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// 災害名
        Text(
          _disaster.name,
          style: TextStyle(
            fontSize: screenWidth * 0.025,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: screenHeight * 0.015),

        /// 日時
        Text(
          '日時: ${_disaster.datetime}',
          style: TextStyle(fontSize: screenWidth * 0.022),
        ),
        SizedBox(height: screenHeight * 0.015),

        /// 重要度 (RatingStars 使用)
        Row(
          children: [
            Text(
              '重要度: ',
              style: TextStyle(fontSize: screenWidth * 0.022),
            ),
            RatingStars(
              value: _disaster.importance.toDouble(),
              starCount: 10,
              maxValue: 10,
              starSize: screenWidth * 0.02,
              starSpacing: screenWidth * 0.01,
              valueLabelVisibility: false,
              starColor: Colors.pink,
              starOffColor: const Color(0xffe7e8ea),
            ),
          ],
        ),
        SizedBox(height: screenHeight * 0.015),

        /// 近隣情報
        Text(
          '近隣: ${_disaster.notsoaccuratelocation ?? '不明'}',
          style: TextStyle(fontSize: screenWidth * 0.022),
        ),
        SizedBox(height: screenHeight * 0.015),

        /// status: 0: 未対応, 1: 対応中, 2: 対応済み, other: 不明
        /// 未対応: 赤色, 対応中: 黄色, 対応済み: 緑色
        Text(
          '状態: ${_getStatusText(_disaster.status)}',
          style: TextStyle(
            fontSize: screenWidth * 0.022,
            color: _getStatusColor(_disaster.status),
          ),
        ),
        SizedBox(height: screenHeight * 0.015),

        /// 詳細情報(オプショナル)
        if (_disaster.description != null)
          Text(
            '詳細情報: ${_disaster.description}',
            style: TextStyle(fontSize: screenWidth * 0.022),
          ),
        SizedBox(height: screenHeight * 0.015),
        
        /// optional disaster.comment
        /// コメントがある場合のみ表示
        if (_disaster.comment != null)
          Text(
            'コメント: ${_disaster.comment}',
            style: TextStyle(fontSize: screenWidth * 0.022),
          ),

      ],
    );
  }

  /// 複数画像がある場合の「前/次」ボタンと現在の枚数表示
  Widget _buildImageNavigationControls(double screenWidth, double screenHeight) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Text(
          '${_currentImageIndex + 1}/$_imageCount',
          style: TextStyle(fontSize: screenWidth * 0.022),
        ),
        SizedBox(width: screenWidth * 0.01),
        ElevatedButton(
          onPressed: _previousImage,
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(
              vertical: screenHeight * 0.015,
              horizontal: screenWidth * 0.05,
            ),
            textStyle: TextStyle(fontSize: screenWidth * 0.022),
          ),
          child: const Text('前の画像'),
        ),
        SizedBox(width: screenWidth * 0.01),
        ElevatedButton(
          onPressed: _nextImage,
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(
              vertical: screenHeight * 0.015,
              horizontal: screenWidth * 0.05,
            ),
            textStyle: TextStyle(fontSize: screenWidth * 0.022),
          ),
          child: const Text('次の画像'),
        ),
      ],
    );
  }
}
