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
  late Future<RecognizedText> recognizedText;
  late Uint8List cropped;

  @override
  void initState() {
    super.initState();
  // Crop image according to prediction
    final image = img.decodeImage(File(widget.path).readAsBytesSync());
    int width = widget.crop[1] - widget.crop[0];
    int height = widget.crop[3] - widget.crop[2];
    img.Image crop = img.copyCrop(image!,
        x: widget.crop[0], y: widget.crop[2], width: width, height: height);
    final bytes = Uint8List.fromList(img.encodePng(crop));

    // OCR
    final inputImage = InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
            size: Size(width.toDouble(), height.toDouble()),
            rotation: InputImageRotation.rotation0deg,
            bytesPerRow: 2,
            format: InputImageFormat.bgra8888));
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    setState(() {
      cropped = bytes;
      recognizedText = textRecognizer.processImage(inputImage);
    });
  }

  @override
  Widget build(BuildContext context) {
        return Scaffold(
        body: Center(
      child: Stack(
        children: [
          Image.memory(cropped),
          FutureBuilder<RecognizedText>(
              future: recognizedText,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }

                return Text("Recognition: ${snapshot.data != null ? snapshot.data!.text : "None"}");
              })
        ],
      ),
    ));
  }
}
