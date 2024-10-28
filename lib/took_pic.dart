import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:testfire/detector.dart';
import 'package:image/image.dart' as img;

class TookPic extends StatefulWidget {
  const TookPic(
      {super.key,
      required this.path,
      required this.detectorHelper,
      required this.crop});

  final String path;
  final DetectorHelper detectorHelper;
  final List<int> crop;

  @override
  _TookPicState createState() => _TookPicState();
}

class _TookPicState extends State<TookPic> {
  var _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  String? text;
  Uint8List? cropped;

  @override
  void dispose() {
    _textRecognizer.close();
    super.dispose();
  }

  void process() async {
    final image = img.decodeImage(await File(widget.path).readAsBytes());
    int width = widget.crop[1] - widget.crop[0];
    int height = widget.crop[3] - widget.crop[2];
    img.Image crop = img.copyCrop(image!,
        x: widget.crop[0], y: widget.crop[2], width: width, height: height);
    final bytes = Uint8List.fromList(img.encodePng(crop));
    final tempDir = Directory.systemTemp;
    final tempFile = await File("${tempDir.path}/temp").writeAsBytes(bytes);

    // OCR
    // final inputImage = InputImage.fromBytes(
    //     bytes: bytes,
    //     metadata: InputImageMetadata(
    //         size: Size(width.toDouble(), height.toDouble()),
    //         rotation: InputImageRotation.rotation0deg,
    //         bytesPerRow: 2,
    //         format: InputImageFormat.bgra8888));
    final inputImage = InputImage.fromFilePath(tempFile.path);
    final recognition = await _textRecognizer.processImage(inputImage);

    setState(() {
      cropped = bytes;
     text = recognition.text;
    });
  }

  @override
  void initState() {
    super.initState();
    process();
    // Crop image according to prediction
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          children: [
            if(cropped != null) Image.memory(cropped!),
                  Text(
                      "Recognition: $text")
          ],
        )
      )
    );
  }
}
