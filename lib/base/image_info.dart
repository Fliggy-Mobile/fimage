import 'package:flutter/cupertino.dart';

class BaseMultiImageInfo {
  final List<BaseImageInfo> frameInfoList;

  /// Number of times to repeat the animation.
  /// * 0 when the animation should be played once.
  /// * -1 for infinity repetitions.
  final int repetitionCount;
  final Duration totalDuration;

  int get frameCount {
    if (frameInfoList == null) return 0;
    return frameInfoList.length;
  }

  BaseMultiImageInfo(
      {@required this.frameInfoList,
      this.repetitionCount = 0,
      this.totalDuration = const Duration(milliseconds: 0)});
}

// ignore: must_be_immutable
class BaseImageInfo extends ImageInfo {
  final Duration duration;

  BaseImageInfo(
      {@required image,
      scale = 1.0,
      debugLabel,
      this.duration = const Duration(milliseconds: 0)})
      : super(image: image, scale: scale, debugLabel: debugLabel);
}
