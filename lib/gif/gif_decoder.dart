import 'dart:async';
import 'dart:typed_data';

import 'package:fimage/base/decoder.dart';
import 'package:fimage/base/image_info.dart';
import 'package:fimage/base/loader.dart';

import 'dart:ui' as ui show Codec;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'gif_image_info.dart';

class GifDecoder extends Decoder {
  Future<BaseMultiImageInfo> decode(Uint8List data,
      {FirstFrameListener firstFrameListener}) async {
    ui.Codec codec = await PaintingBinding.instance.instantiateImageCodec(data);
    if (codec.frameCount == 0)
      throw Exception('GifDecoder decode is an empty codec');

    int duration = 0;
    List<BaseImageInfo> imageInfoList = [];
    for (int i = 0; i < codec.frameCount; i++) {
      FrameInfo frameInfo = await codec.getNextFrame();
      var imageInfo =
          BaseImageInfo(image: frameInfo.image, duration: frameInfo.duration);
      imageInfoList.add(imageInfo);
      if (i == 0 && firstFrameListener != null) {
        firstFrameListener.call(imageInfo);
      }
      duration += frameInfo.duration.inMilliseconds;
    }
    GifImageInfo info = GifImageInfo(
        frameInfoList: imageInfoList,
        repetitionCount: codec.repetitionCount,
        totalDuration: Duration(milliseconds: duration));
    return info;
  }
}
