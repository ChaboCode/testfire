import 'dart:developer';
import 'dart:ui' as ui;
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:testfire/detector.dart';
import 'package:image/image.dart' as image_lib;
import 'package:testfire/took_pic.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  final firstCamera = cameras.first;
  runApp(
      MaterialApp(theme: ThemeData.dark(), home: MyApp(camera: firstCamera)));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key, required this.camera});

  final CameraDescription camera;

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  late CameraController _controller;
  late DetectorHelper detectorHelper;
  bool _isProcessing = false;
  ui.Image? _displayImage;
  List<int> inference = [0, 0, 0, 0];

  initCamera() {
    _controller = CameraController(widget.camera, ResolutionPreset.medium,
        imageFormatGroup: ImageFormatGroup.yuv420);
    _controller.initialize().then((value) {
      _controller.startImageStream(imageAnalysis);
      if (mounted) {
        setState(() {});
      }
    });
  }

  Future<void> imageAnalysis(CameraImage cameraImage) async {
    if (_isProcessing) return;
    _isProcessing = true;
    final mask = await detectorHelper.inferenceCameraFrame(cameraImage);
    _isProcessing = false;
    if (mounted) {
      log("width: ${cameraImage.width}");
      log("height: ${cameraImage.height}");
      _convertToImage(mask, cameraImage.height, cameraImage.width);
    }
  }

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    detectorHelper = DetectorHelper();
    detectorHelper.initHelper();
    initCamera();
    super.initState();
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    // });
  }

  // @override
  // Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
  //   switch (state) {
  //     case AppLifecycleState.paused:
  //       _controller.stopImageStream();
  //       break;
  //     case AppLifecycleState.resumed:
  //       if (!_controller.value.isStreamingImages) {
  //         await _controller.startImageStream(imageAnalysis);
  //       }
  //       break;
  //     default:
  //   }
  // }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    detectorHelper.close();
    super.dispose();
  }

  void _convertToImage(List<double> normalMask, int originImageWidth,
      int originImageHeight) async {
    final mask = [
      (normalMask[0] * originImageWidth).floor(),
      (normalMask[1] * originImageWidth).floor(),
      (normalMask[2] * originImageHeight).floor(),
      (normalMask[3] * originImageHeight).floor(),
    ];
    setState(() {
      inference = mask;
    });
    List<int> imageMatrix = [];
    for (int i = 0; i < originImageWidth; i++) {
      for (int j = 0; j < originImageHeight; j++) {
        if (mask[0] == i && mask[2] == j) {
          imageMatrix.addAll([0, 255, 0, 255]);
        } else if (mask[1] == i && mask[3] == j) {
          imageMatrix.addAll([255, 0, 0, 255]);
        } else {
          imageMatrix.addAll([0, 0, 0, 0]);
        }
      }
    }

    image_lib.Image convertedImage = image_lib.Image.fromBytes(
        width: originImageWidth,
        height: originImageHeight,
        bytes: Uint8List.fromList(imageMatrix).buffer,
        numChannels: 4);
    final bytes = image_lib.encodePng(convertedImage);
    ui.Codec codec = await ui.instantiateImageCodec(bytes);
    ui.FrameInfo frameInfo = await codec.getNextFrame();
    setState(() {
      _displayImage = frameInfo.image;
    });
  }

  Widget cameraWidget(context) {
    // calculate scale to fit output image to screen
    var scale = 1.0;
    if (_displayImage != null) {
      final minOutputSize = _displayImage!.width > _displayImage!.height
          ? _displayImage!.height
          : _displayImage!.width;
      final minScreenSize =
          MediaQuery.of(context).size.width > MediaQuery.of(context).size.height
              ? MediaQuery.of(context).size.height
              : MediaQuery.of(context).size.width;
      scale = minScreenSize / minOutputSize;
    }
    return Stack(children: [
      CameraPreview(_controller),
      if (_displayImage != null)
        Transform.scale(
            scale: scale,
            child: CustomPaint(
              painter: OverlayPainter()..updateImage(_displayImage!),
            )),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> list = [];
    list.add(SizedBox(
        child: (!_controller.value.isInitialized)
            ? Container()
            : cameraWidget(context)));
    return Scaffold(
      appBar: AppBar(
          title: const Center(
        child: Text('TensorFlow Placas'),
      )),
      body: cameraWidget(context),
      floatingActionButton: FloatingActionButton(onPressed: () async {
        final image = await _controller.takePicture();
        if (!context.mounted) {
          return;
        }
        Navigator.of(context).push(MaterialPageRoute(builder: (context) {
          return TookPic(
            path: image.path,
            detectorHelper: detectorHelper,
            crop: inference,
          );
        }));
      }),
    );
  }
}

class OverlayPainter extends CustomPainter {
  late final ui.Image image;

  updateImage(ui.Image image) {
    this.image = image;
  }

  @override
  paint(Canvas canvas, Size size) {
    canvas.drawImage(image, Offset.zero, Paint());
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
