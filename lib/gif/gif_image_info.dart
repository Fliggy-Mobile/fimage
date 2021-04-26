import 'package:fimage/base/image_info.dart';
import 'package:flutter/cupertino.dart';

class GifImageInfo extends BaseMultiImageInfo {
  GifImageInfo(
      {@required frameInfoList,
      repetitionCount = 0,
      totalDuration = const Duration(milliseconds: 0)})
      : super(
          frameInfoList: frameInfoList,
          repetitionCount: repetitionCount,
          totalDuration: totalDuration,
        );
}
