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

  void _previousImage() {
    setState(() {
      _currentImageIndex =
          (_currentImageIndex - 1 + widget.disaster.images.length) %
              widget.disaster.images.length;
    });
  }

  void _nextImage() {
    setState(() {
      _currentImageIndex = (_currentImageIndex + 1) % widget.disaster.images.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final disaster = widget.disaster;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final imageHeight = screenHeight * 0.6;
    final imageWidth = imageHeight;

    return Scaffold(
      appBar: AppBar(title: const Text('災害詳細')),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(screenWidth * 0.02),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (disaster.images.isNotEmpty)
                    SizedBox(
                      width: imageWidth,
                      height: imageHeight,
                      child: Image.memory(
                        decodeBase64ToBytes(disaster.images[_currentImageIndex]),
                        fit: BoxFit.cover,
                      ),
                    )
                  else
                    SizedBox(
                      width: imageWidth,
                      height: imageHeight,
                      child: Icon(Icons.image, size: imageHeight * 0.6),
                    ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(left: screenWidth * 0.02),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            disaster.name,
                            style: TextStyle(
                              fontSize: screenWidth * 0.025,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: screenHeight * 0.015),
                          Text(
                            '日時: ${disaster.datetime}',
                            style: TextStyle(fontSize: screenWidth * 0.022),
                          ),
                          SizedBox(height: screenHeight * 0.015),
                          Row(
                            children: [
                              Text(
                                '重要度: ',
                                style:
                                    TextStyle(fontSize: screenWidth * 0.022),
                              ),
                              RatingStars(
                                value: disaster.importance.toDouble(),
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
                          Text(
                            '近隣: ${disaster.notsoaccuratelocation ?? '不明'}',
                            style: TextStyle(fontSize: screenWidth * 0.022),
                          ),
                          SizedBox(height: screenHeight * 0.015),
                          if (disaster.description != null)
                            Text(
                              '詳細情報: ${disaster.description}',
                              style: TextStyle(fontSize: screenWidth * 0.022),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              if (disaster.images.length > 1) ...[
                SizedBox(height: screenHeight * 0.02),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      '${_currentImageIndex + 1}/${disaster.images.length}',
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
                ),
              ],
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
}
