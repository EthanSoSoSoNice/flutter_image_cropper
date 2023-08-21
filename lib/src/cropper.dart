import "package:flutter/foundation.dart";
import 'package:flutter/material.dart';
import "controller.dart";
import "package:image/image.dart" as image_lib;
import "calculator.dart";
import "drawing_data.dart";
import "painter.dart";
import 'dart:math' as math;
import "dart:ui" as ui;

class ImageCropper extends StatefulWidget {
  const ImageCropper({
    super.key,
    required this.image,
    required this.controller,
    required this.onCropped,
    this.aspectRatio = 4 / 3,
    this.painterTheme = const CropperPainterTheme(),
    this.scale = 1.0,
    this.disableMove = false
  });

  final Function(image_lib.Image image) onCropped;
  final ui.Image image;
  final CropperController controller;
  final double aspectRatio;
  final double scale;
  final CropperPainterTheme painterTheme;
  final bool disableMove;

  @override
  State<StatefulWidget> createState() => ImageCropperState();
}

class ImageCropperState extends State<ImageCropper> {
  
  Offset _lastFocalPoint = Offset.zero;
  late double _initialScale;
  int _fingersOnScreen = 0;

  late CropperDrawingData _data;
  Calculator? _calculator;

  @override
  void initState() {
    super.initState();
    _initialScale = widget.scale;
    // set controller delegates
    widget.controller.crop = () => { _crop() };
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {

      if (_calculator == null) {
        _calculator = Calculator(
            viewSize: Size(constraints.maxWidth, constraints.maxHeight),
            image: widget.image,
            scale: _initialScale,
            aspectRatio: widget.aspectRatio,
            move: Offset.zero);

        _data = _calculator!.calculate();
      }

      return GestureDetector(
        onScaleStart: (details) {

          if(widget.disableMove) return;

          _lastFocalPoint = details.focalPoint;
          _initialScale = _calculator!.scale;
          _fingersOnScreen = details.pointerCount;
        },
        onScaleUpdate: (details) {
          if (_fingersOnScreen == 1) {
            var delta = details.focalPoint - _lastFocalPoint;
            _lastFocalPoint = details.focalPoint;
            setState(() {
              _data = (_calculator!..move += delta).calculate();
            });
          }

          if (_fingersOnScreen == 2) {
            setState(() {
              _data = (_calculator!
                    ..scale = math.max(1.0, _initialScale * details.scale))
                  .calculate();
            });
          }
        },
        child: CustomPaint(
          painter: CropperPainter(data: _data, theme: widget.painterTheme),
        ),
      );
    });
  }

  // Crop out of the portion of the image corresponding to the croppring area
  void _crop() async {

    final uiBytes = await _data.image.toByteData();
    final imageWidth = _data.image.width;
    final imageHeight = _data.image.height;

    final x = ((_data.croppingRect.left - _data.imageRect.left) *
            _calculator!.widthRatio ~/
            _calculator!.scale)
        .toInt();

    final y = ((_data.croppingRect.top - _data.imageRect.top) *
            _calculator!.heightRatio ~/
            _calculator!.scale)
        .toInt();

    final widthCropped = _data.croppingRect.width *
        _calculator!.widthRatio ~/
        _calculator!.scale;

    final heightCropped = _data.croppingRect.height *
        _calculator!.heightRatio ~/
        _calculator!.scale;

    final imageCropped = await compute((message) {
      final img = image_lib.Image.fromBytes(
        width: imageWidth,
        height: imageHeight,
        bytes: uiBytes!.buffer,
        numChannels: 4,
      );

      var imgCropped = image_lib.copyCrop(
        img,
        x: x,
        y: y,
        width: widthCropped,
        height: heightCropped,
      );

      return imgCropped;
    }, 
    null);

    widget.onCropped(imageCropped);
  }
}
