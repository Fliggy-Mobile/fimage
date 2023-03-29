import 'package:fimage/base/image_info.dart';
import 'package:flutter/cupertino.dart';

class ApngImageInfo extends BaseMultiImageInfo {
  ApngImageInfo({
    @required List<BaseImageInfo> frameInfoList,
    int repetitionCount = 0,
    Duration totalDuration = const Duration(milliseconds: 0),
  }) : super(
          frameInfoList: frameInfoList,
          repetitionCount: repetitionCount,
          totalDuration: totalDuration,
        );
}
