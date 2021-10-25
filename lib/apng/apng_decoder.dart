import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:fimage/base/decoder.dart';
import 'package:fimage/base/image_info.dart';
import 'package:fimage/base/loader.dart';
import 'package:image/image.dart' as img;

import 'apng_image_info.dart';

class ApngDecoder extends Decoder {
  Future<BaseMultiImageInfo> decode(Uint8List data,
      {FirstFrameListener firstFrameListener}) async {
    img.Animation anim = img.decodeAnimation(data);
    int duration = 0;
    List<BaseImageInfo> imageInfoList = [];
    for (int i = 0; i < anim.length; i++) {
      img.Image frameImage = anim[i];
      if (frameImage.duration <= 0) {
        // 没有时间信息，默认 24 帧
        frameImage.duration = 41;
      }
      var bytes = frameImage.getBytes(format: img.Format.rgba);
      ui.ImmutableBuffer immutableBuffer =
          await ui.ImmutableBuffer.fromUint8List(bytes);
      final ui.ImageDescriptor descriptor = ui.ImageDescriptor.raw(
        immutableBuffer,
        width: frameImage.width,
        height: frameImage.height,
        // rowBytes: frameImage.width * 4,
        pixelFormat: ui.PixelFormat.rgba8888,
      );
      ui.Codec codec = await descriptor.instantiateCodec(
          targetWidth: frameImage.width, targetHeight: frameImage.height);
      ui.FrameInfo frameInfo = await codec.getNextFrame();
      var imageInfo = BaseImageInfo(
          image: frameInfo.image,
          duration: Duration(milliseconds: frameImage.duration));
      imageInfoList.add(imageInfo);
      if (i == 0 && firstFrameListener != null) {
        firstFrameListener.call(imageInfo);
      }
      duration += frameImage.duration;
    }
    ApngImageInfo info = ApngImageInfo(
        frameInfoList: imageInfoList,
        repetitionCount: anim.loopCount == 0 ? -1 : anim.loopCount,
        totalDuration: Duration(milliseconds: duration));
    return info;
  }
}
