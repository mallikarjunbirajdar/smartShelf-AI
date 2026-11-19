import 'dart:math' as math;
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;

class LetterboxResult {
  LetterboxResult({
    required this.tensor,
    required this.ratio,
    required this.padX,
    required this.padY,
    required this.sourceWidth,
    required this.sourceHeight,
  });

  final Float32List tensor;
  final double ratio;
  final double padX;
  final double padY;
  final int sourceWidth;
  final int sourceHeight;
}

class ImagePreprocessorService {
  static const int inputSize = 640;

  static LetterboxResult fromImage(img.Image source) {
    final srcW = source.width;
    final srcH = source.height;
    final ratio = math.min(inputSize / srcW, inputSize / srcH);
    final newW = (srcW * ratio).round();
    final newH = (srcH * ratio).round();
    final padX = (inputSize - newW) / 2.0;
    final padY = (inputSize - newH) / 2.0;

    final resized = img.copyResize(
      source,
      width: newW,
      height: newH,
      interpolation: img.Interpolation.linear,
    );

    final canvas = img.Image(width: inputSize, height: inputSize);
    img.fill(canvas, color: img.ColorRgb8(114, 114, 114));
    img.compositeImage(
      canvas,
      resized,
      dstX: padX.round(),
      dstY: padY.round(),
    );

    final tensor = Float32List(1 * 3 * inputSize * inputSize);
    var i = 0;
    for (var y = 0; y < inputSize; y++) {
      for (var x = 0; x < inputSize; x++) {
        final p = canvas.getPixel(x, y);
        tensor[i] = p.r / 255.0;
        tensor[inputSize * inputSize + i] = p.g / 255.0;
        tensor[2 * inputSize * inputSize + i] = p.b / 255.0;
        i++;
      }
    }

    return LetterboxResult(
      tensor: tensor,
      ratio: ratio,
      padX: padX,
      padY: padY,
      sourceWidth: srcW,
      sourceHeight: srcH,
    );
  }

  static LetterboxResult fromCameraImage(
    CameraImage cameraImage, {
    required int sensorOrientation,
    required CameraLensDirection lensDirection,
  }) {
    return fromImage(
      orientCameraImage(
        cameraImage,
        sensorOrientation: sensorOrientation,
        lensDirection: lensDirection,
      ),
    );
  }

  /// Camera frame in the same orientation used for detection boxes.
  static img.Image orientCameraImage(
    CameraImage cameraImage, {
    required int sensorOrientation,
    required CameraLensDirection lensDirection,
  }) {
    final rgb = convertCameraImage(cameraImage);
    img.Image oriented = rgb;

    if (sensorOrientation == 90) {
      oriented = img.copyRotate(rgb, angle: 90);
    } else if (sensorOrientation == 270) {
      oriented = img.copyRotate(rgb, angle: 270);
    } else if (sensorOrientation == 180) {
      oriented = img.copyRotate(rgb, angle: 180);
    }

    if (lensDirection == CameraLensDirection.front) {
      oriented = img.flipHorizontal(oriented);
    }

    return oriented;
  }

  static img.Image convertCameraImage(CameraImage cameraImage) {
    final format = cameraImage.format.group;
    if (format == ImageFormatGroup.bgra8888) {
      return img.Image.fromBytes(
        width: cameraImage.width,
        height: cameraImage.height,
        bytes: cameraImage.planes[0].bytes.buffer,
        order: img.ChannelOrder.bgra,
      );
    }

    final width = cameraImage.width;
    final height = cameraImage.height;
    final yPlane = cameraImage.planes[0];
    final uPlane = cameraImage.planes[1];
    final vPlane = cameraImage.planes[2];
    final uvPixelStride = uPlane.bytesPerPixel ?? 1;

    final out = img.Image(width: width, height: height);
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final yp = yPlane.bytes[y * yPlane.bytesPerRow + x];
        final uvIndex =
            (y ~/ 2) * uPlane.bytesPerRow + (x ~/ 2) * uvPixelStride;
        final up = uPlane.bytes[uvIndex];
        final vp = vPlane.bytes[
            (y ~/ 2) * vPlane.bytesPerRow +
                (x ~/ 2) * (vPlane.bytesPerPixel ?? uvPixelStride)];

        final r = (yp + 1.370705 * (vp - 128)).round();
        final g =
            (yp - 0.337633 * (up - 128) - 0.698001 * (vp - 128)).round();
        final b = (yp + 1.732446 * (up - 128)).round();
        out.setPixelRgb(
          x,
          y,
          r.clamp(0, 255),
          g.clamp(0, 255),
          b.clamp(0, 255),
        );
      }
    }
    return out;
  }

  static img.Image? decodeFileBytes(Uint8List bytes) => img.decodeImage(bytes);
}
