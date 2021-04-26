import 'dart:typed_data';

import 'image_info.dart';
import 'loader.dart';

abstract class Decoder {
  Future<BaseMultiImageInfo> decode(Uint8List data,
      {FirstFrameListener firstFrameListener});
}
