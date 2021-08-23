import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:just_audio/just_audio.dart';

const beep = 'assets/sounds/beep.mp3';
const boop = 'assets/sounds/boop.mp3';

const left = 'assets/sounds/left.mp3';
const right = 'assets/sounds/right.mp3';
const pan = 'assets/sounds/boop.mp3';
const forward = 'assets/sounds/forward.mp3';


class BoundingBox extends StatelessWidget {
  final List<dynamic> results;
  final int previewH;
  final int previewW;
  final double screenH;
  final double screenW;
  AudioPlayer player;

  BoundingBox(
    this.results,
    this.previewH,
    this.previewW,
    this.screenH,
    this.screenW,
    this.player
  );

  @override
  Widget build(BuildContext context) {
    List<Widget> _renderBox() {
      return results.map((re) {
        var _x = re["rect"]["x"];
        var _w = re["rect"]["w"];
        var _y = re["rect"]["y"];
        var _h = re["rect"]["h"];
        var scaleW, scaleH, x, y, w, h;

        if (screenH / screenW > previewH / previewW) {
          scaleW = screenH / previewH * previewW;
          scaleH = screenH;
          var difW = (scaleW - screenW) / scaleW;
          x = (_x - difW / 2) * scaleW;
          w = _w * scaleW;
          if (_x < difW / 2) w -= (difW / 2 - _x) * scaleW;
          y = _y * scaleH;
          h = _h * scaleH;
        } else {
          scaleH = screenW / previewW * previewH;
          scaleW = screenW;
          var difH = (scaleH - screenH) / scaleH;
          x = _x * scaleW;
          w = _w * scaleW;
          y = (_y - difH / 2) * scaleH;
          h = _h * scaleH;
          if (_y < difH / 2) h -= (difH / 2 - _y) * scaleH;
        }

        var color = Colors.blue;

        if (x + w / 2 < screenW / 3) {
          //left
          color = Colors.purple;
          player.setAsset(left);
          player.play();
        } else if (x + w / 2 < screenW / 3 * 2) {
          //forward
          color = Colors.lightGreen;
          player.setAsset(forward);
          player.play();
        } else if (re == null) {
          //pan
          color = Colors.blue;
          player.setAsset(boop);
          player.play();
        } else {
          //right
          color = Colors.orange;
          player.setAsset(right);
          player.play();
        }

        return Positioned(
          left: math.max(0, x),
          top: math.max(0, y),
          width: w,
          height: h,
          child: Container(
            padding: EdgeInsets.only(top: 5.0, left: 5.0),
            decoration: BoxDecoration(
              border: Border.all(
                color: color,
                width: 3.0,
              ),
            ),
            child: Text(
              "${re["detectedClass"]} ${(re["confidenceInClass"] * 100).toStringAsFixed(0)}%",
              style: TextStyle(
                color: color,
                fontSize: 14.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }).toList();
    }

    return Stack(
      children: _renderBox(),
    );
  }
}
