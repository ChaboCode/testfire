import 'dart:developer';
import 'dart:io';
import 'dart:isolate';

import 'package:camera/camera.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

import 'isolate_inference.dart';

class DetectorHelper {
  static const modelPath = 'assets/Detection.tflite';

  late final Interpreter interpreter;
  late final IsolateInference isolateInference;
  late Tensor inputTensor;
  late Tensor outputTensor;

  Future<void> _loadModel() async {
    final options = InterpreterOptions();

    if (Platform.isAndroid) {
      options.addDelegate(XNNPackDelegate());
      options.addDelegate(GpuDelegateV2());
    }

    interpreter = await Interpreter.fromAsset(modelPath, options: options);
    inputTensor = interpreter.getInputTensors().first;
    outputTensor = interpreter.getOutputTensors().first;

    log('Interpreter successful');
  }

  Future<void> initHelper() async {
    _loadModel();
    isolateInference = IsolateInference();
    await isolateInference.start();
  }

  Future<List<double>> _inference(InferenceModel inferenceModel) async {
    ReceivePort responsePort = ReceivePort();
    isolateInference.sendPort
        .send(inferenceModel..responsePort = responsePort.sendPort);
    var results = await responsePort.first;
    return results;
  }

  Future<List<double>> inferenceCameraFrame(
      CameraImage cameraImage) async {
    var isolateModel = InferenceModel(cameraImage, null, interpreter.address,
        inputTensor.shape, outputTensor.shape);
    return _inference(isolateModel);
  }

  Future<void> close() async {
    isolateInference.close();
  }
}
