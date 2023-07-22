import "dart:ui";
import "dart:math" as math;
import 'package:flutter_image_cropper/src/drawing_data.dart';

class Calculator {
  Image image;
  double scale;
  double aspectRatio;
  Offset move;
  Size viewSize;
  late double widthRatio;
  late double heightRatio;


  late Size _rawImageRectSize;
  late Size _scaledImageRectSize;
  late Rect _croppingRect;
  late Rect _imageRect;


  Calculator({
    required this.viewSize,
    required this.image,
    required this.scale,
    required this.aspectRatio,
    required this.move
  });


  CropperDrawingData calculate() {

    _calcImageRect();
    _calcCropRect();
    _moveImage();

    Rect viewRect = Rect.fromLTWH(
      0,
      0,
      viewSize.width,
      viewSize.height
    );

    return CropperDrawingData(
      viewRect: viewRect, 
      imageRect: _imageRect, 
      croppingRect: _croppingRect,
      image: image
    );
  }

  void _moveImage(){
    var imageOffsetInCenterOfView = Offset(
      (viewSize.width - _scaledImageRectSize.width) / 2,
      (viewSize.height - _scaledImageRectSize.height) / 2,
    );

    // boundaries check
    Offset safeMove = Offset(_croppingRect.left, _croppingRect.top) - imageOffsetInCenterOfView;

    move = Offset(
      move.dx >= 0 ? math.min(safeMove.dx, move.dx) : math.max(-safeMove.dx, move.dx),
      move.dy >= 0 ? math.min(move.dy, safeMove.dy) : math.max(move.dy, -safeMove.dy)
    );

    var dstLeft = move.dx + imageOffsetInCenterOfView.dx;
    var dstTop = move.dy + imageOffsetInCenterOfView.dy;
    _imageRect = Rect.fromLTWH(
      dstLeft, 
      dstTop, 
      _scaledImageRectSize.width,
      _scaledImageRectSize.height
    );
  }

  void _calcImageRect() {
    double viewportAspectRatio = viewSize.width / viewSize.height;
    double imageAspectRatio = image.width / image.height;

    double newImageWidth;
    double newImageHeight;

    if (imageAspectRatio > viewportAspectRatio) {
      newImageWidth = viewSize.width;
      newImageHeight = viewSize.width * imageAspectRatio;
    } else {
      newImageHeight = viewSize.height;
      newImageWidth = viewSize.height / imageAspectRatio;
    }

    _rawImageRectSize = Size(newImageWidth, newImageHeight);

    widthRatio = image.width / newImageWidth;
    heightRatio = image.height / newImageHeight;

    _scaledImageRectSize = Size(_rawImageRectSize.width * scale,
        _rawImageRectSize.height * scale);
  }


  void _calcCropRect() {
    var width = _rawImageRectSize.width;
    var height = _rawImageRectSize.width / aspectRatio;
    if (height > _rawImageRectSize.height) {
      height = _rawImageRectSize.height;
      width = _rawImageRectSize.height * aspectRatio;
    }

    _croppingRect = Rect.fromLTWH(
      (viewSize.width - width) / 2,
      (viewSize.height - height) / 2,
      width,
      height,
    );
  }

}
