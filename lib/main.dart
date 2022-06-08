import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:object_detection/classifier.dart';
import 'package:object_detection/image_utils.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:tflite_flutter_helper/tflite_flutter_helper.dart';

late List<CameraDescription> _cameras;
bool isWorking = false;
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _cameras = await availableCameras();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late CameraController controller;
  Classifier classifier = Classifier();
  bool isReady = false;
  initCamera() {
    controller = CameraController(_cameras[0], ResolutionPreset.ultraHigh);
    controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      controller.startImageStream((imageStream) {
        if (!isWorking) {
          predict(imageStream);
        }
      });
      setState(() {
        isReady = true;
      });
    }).catchError((Object e) {
      if (e is CameraException) {
        switch (e.code) {
          case 'CameraAccessDenied':
            print('User denied camera access.');
            break;
          default:
            print('Handle other errors.');
            break;
        }
      }
    });
  }

  predict(imageStream) async {
    await classifier.predict(ImageUtils.convertYUV420ToImage(imageStream));
  }

  initModel() async {
    classifier.loadModel();
    classifier.loadLabels();
    initCamera();
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    initModel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SafeArea(
      child: !isReady
          ? const Center(child: CircularProgressIndicator())
          : CameraPreview(controller),
    ));
  }
}
