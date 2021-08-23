import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'bounding_box.dart';
import 'camera.dart';
import 'dart:math' as math;
import 'package:tflite/tflite.dart';
import 'package:just_audio/just_audio.dart';

class LiveFeed extends StatefulWidget {
  final List<CameraDescription> cameras;
  LiveFeed(this.cameras);
  @override
  _LiveFeedState createState() => _LiveFeedState();
}

class _LiveFeedState extends State<LiveFeed> {
  List<dynamic> _res;
  List<dynamic> _recognitions;
  int _imageHeight = 0;
  int _imageWidth = 0;
  AudioPlayer player;

  initCameras() async {

  }
  loadTfModel() async {
    await Tflite.loadModel(
      model: "assets/models/trafficLight1.tflite",
      labels: "assets/models/new_labels.txt",
    );
  }
  /* 
  The set recognitions function assigns the values of recognitions,
  imageHeight and width to the variables defined here as callback
  */
  setRecognitions(recognitions, imageHeight, imageWidth) {
    setState(() {
      _recognitions = recognitions;
      _res = _recognitions.where((e) =>
      e["detectedClass"] == "traffic light").toList();
      _imageHeight = imageHeight;
      _imageWidth = imageWidth;
      //player.setAsset(beep);
      //player.play();
    });
  }

  @override
  void initState() { 
    super.initState();
    loadTfModel();
    player = AudioPlayer();
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Size screen = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: Text("Real Time Object Detection"),
      ),
      body: Stack(
        children: <Widget>[
          CameraFeed(widget.cameras, setRecognitions),
          BoundingBox(
            _res == null ? [] : _res,
            math.max(_imageHeight, _imageWidth),
            math.min(_imageHeight, _imageWidth),
            screen.height,
            screen.width, player
          ),
        ],
      ),
    );
  }
}