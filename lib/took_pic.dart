import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:testfire/detector.dart';

class TookPic extends StatelessWidget{
  const TookPic({super.key, required this.pic, required this.detectorHelper});

  final XFile pic;
  final DetectorHelper detectorHelper;

  @override
  Widget build(BuildContext context) {
    // detectorHelper.inferenceCameraFrame()
    return Scaffold();
  }

}