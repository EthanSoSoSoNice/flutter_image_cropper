import "dart:ui" as ui;
import "package:image/image.dart" as image_lib;

class ImageConverter {

  // https://github.com/brendan-duncan/image/blob/main/doc/flutter.md
  static Future<ui.Image> imageToUiImage(image_lib.Image image) async {
    if (image.format != image_lib.Format.uint8 || image.numChannels != 4) {
      final cmd = image_lib.Command()
        ..image(image)
        ..convert(format: image_lib.Format.uint8, numChannels: 4);
      final rgba8 = await cmd.getImageThread();
      if (rgba8 != null) {
        image = rgba8;
      }
    }
    ui.ImmutableBuffer buffer =
        await ui.ImmutableBuffer.fromUint8List(image.toUint8List());

    ui.ImageDescriptor id = ui.ImageDescriptor.raw(buffer,
        height: image.height,
        width: image.width,
        pixelFormat: ui.PixelFormat.rgba8888);

    ui.Codec codec = await id.instantiateCodec(
        targetHeight: image.height, targetWidth: image.width);

    ui.FrameInfo fi = await codec.getNextFrame();
    ui.Image uiImage = fi.image;
    return uiImage;
  }

  static Future<image_lib.Image> uiImageToImage(ui.Image uiImage) async {
    final uiBytes = await uiImage.toByteData();

    final image = image_lib.Image.fromBytes(
      width: uiImage.width, 
      height: uiImage.height,
      bytes: uiBytes!.buffer,
      numChannels: 4
    );
    return image;

  }

  static Future<void> imageToFile(String path, image_lib.Image image) async {
    var cmd = image_lib.Command()
    ..image(image)
    ..writeToFile(path);

    await cmd.executeThread();
  }

  static Future<image_lib.Image?> fileToImage(String path) async {
    return image_lib.decodeImageFile(path);
  }


}