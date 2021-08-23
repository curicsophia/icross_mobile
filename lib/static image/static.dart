import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite/tflite.dart';
import 'package:just_audio/just_audio.dart';

const left = 'assets/sounds/left.mp3';
const right = 'assets/sounds/right.mp3';
const pan = 'assets/sounds/boop.mp3';
const forward = 'assets/sounds/forward.mp3';

class StaticImage extends StatefulWidget {

  @override
  _StaticImageState createState() => _StaticImageState();
}

class _StaticImageState extends State<StaticImage> {
  AudioPlayer player;

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  File _image;
  List _recognitions;
  bool _busy;
  double _imageWidth, _imageHeight;

  final picker = ImagePicker();

  // this function loads the model
  loadTfModel() async {
    await Tflite.loadModel(
      model: "assets/models/trafficLight1.tflite",
      labels: "assets/models/new_labels.txt",
    );
  }

  // this function detects the objects on the image
  detectObject(File image) async {
    var recognitions = await Tflite.detectObjectOnImage(
      path: image.path,       // required
      model: "EfficientDet",
      imageMean: 127.5,     
      imageStd: 127.5,      
      threshold: 0.4,       // defaults to 0.1
      numResultsPerClass: 10,// defaults to 5
      asynch: true          // defaults to true
    );
    FileImage(image)
        .resolve(ImageConfiguration())
        .addListener((ImageStreamListener((ImageInfo info, bool _) {
          setState(() {
            _imageWidth = info.image.width.toDouble();
            _imageHeight = info.image.height.toDouble();
          });
        }))); 
    setState(() {
      _recognitions = recognitions;
    });
  }

  @override
  void initState() { 
    super.initState();
    player = AudioPlayer();
    _busy = true;
    loadTfModel().then((val) {{
      setState(() {
        _busy = false;
      });
    }});
  }
  // display the bounding boxes over the detected objects
  List<Widget> renderBoxes(Size screen) {
    if (_recognitions == null) return [];
    if (_imageWidth == null || _imageHeight == null) return [];

    double factorX = screen.width;
    double factorY = _imageHeight / _imageHeight * screen.width;

    Color blue = Colors.blue;

    List<dynamic> res = _recognitions.where((e) =>
    e["detectedClass"] == "traffic light").toList();
    if (res == null){
      player.setAsset(pan);
      player.play();
      return [];
    }

    return res.map((re) {
      var x = re["rect"]["x"] * factorX;
      var w = re["rect"]["w"] * factorX;

      if (x + w/2 < screen.width/3) {
        player.setAsset(left);
        player.play();
      } else if (x + w/2 < screen.width/3 * 2) {
        player.setAsset(forward);
        player.play();
      } else if (res == null) {
        player.setAsset(pan);
        player.play();
      } else {
        player.setAsset(right);
        player.play();
      }
      return Container(
        child: Positioned(
            left: re["rect"]["x"] * factorX,
            top: re["rect"]["y"] * factorY,
            width: re["rect"]["w"] * factorX,
            height: re["rect"]["h"] * factorY,
            child: ((re["confidenceInClass"] > 0.50))? Container(
              decoration: BoxDecoration(
                  border: Border.all(
                    color: blue,
                    width: 3,
                  )
              ),
              child: Text(
                "${re["detectedClass"]} ${(re["confidenceInClass"] * 100).toStringAsFixed(0)}%",
                style: TextStyle(
                  background: Paint()..color = blue,
                  color: Colors.white,
                  fontSize: 15,
                ),
              ),
            ) : Container()
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    List<Widget> stackChildren = [];

    stackChildren.add(
      Positioned(
        // using ternary operator
        child: _image == null ? 
        Container(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text("Please Select an Image"),
            ],
          ),
        )
      : // if not null then 
        Container(
          child:Image.file(_image)
        ),
      )
    );

    stackChildren.addAll(renderBoxes(size));

    if (_busy) {
      stackChildren.add(
        Center(
          child: CircularProgressIndicator(),
        )
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Object Detector"),
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          FloatingActionButton(
            heroTag: "Fltbtn2",
            child: Icon(Icons.camera_alt),
            onPressed: getImageFromCamera,
          ),
          SizedBox(width: 10,),
          FloatingActionButton(
            heroTag: "Fltbtn1",
            child: Icon(Icons.photo),
            onPressed: getImageFromGallery,
          ),
        ],
      ),
      body: Container(
        alignment: Alignment.center,
        child:Stack(
        children: stackChildren,
      ),
      ),
    );
  }
  // gets image from camera and runs detectObject
  Future getImageFromCamera() async {
    final pickedFile = await picker.getImage(source: ImageSource.camera);

    setState(() {
      if(pickedFile != null) {
        _image = File(pickedFile.path);
      } else {
        print("No image Selected"); 
      }
    });
    detectObject(_image);
  }
  // gets image from gallery and runs detectObject
  Future getImageFromGallery() async {
    final pickedFile = await picker.getImage(source: ImageSource.gallery);
    setState(() {
      if(pickedFile != null) {
        _image = File(pickedFile.path);
      } else {
        print("No image Selected");
      }
    });
    detectObject(_image);
  }
}