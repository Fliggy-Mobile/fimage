import 'dart:ui';
import 'package:fimage/base/decoder.dart';
import 'package:fimage/base/image_info.dart';
import 'package:fimage/base/loader.dart';
import 'package:fimage/gif/gif_decoder.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

extension FSafeMap on Map {
  String getString(key, {String def}) {
    if (this[key] is String) {
      return this[key];
    }
    return def;
  }

  int getInt(key, {int def}) {
    if (this[key] is int) {
      return this[key];
    }
    return def;
  }

  bool getBool(key, {bool def}) {
    if (this[key] is bool) {
      return this[key];
    }
    return def;
  }

  T get<T>(key, {T def}) {
    if (this[key] is T) {
      return this[key];
    }
    return def;
  }
}

///currentFrame = -1 is first frame has not come back, = 0 is first frame.
/// totalFrame = 0 is all the frame data has not come back.
/// so, you can do many other thing use this callback.
typedef FImageFrameBuilder = Widget Function(
    BuildContext context, Widget child, int currentFrame, int totalFrame);

///All data analysis complete callback
typedef FOnFetchCompleted = Function(BaseMultiImageInfo multiImageInfo);

///image controller
///_repetitionCount = -2 is repetitionCount data not resolved yet.
class FImageController extends AnimationController {
  int repetitionCount = -2;

  int _curRepetitionCount = 0;

  int get curRepetitionCount => _curRepetitionCount;

  FImageController(
      {@required TickerProvider vsync,
      double value = 0.0,
      Duration reverseDuration,
      Duration duration,
      this.repetitionCount = -2,
      AnimationBehavior animationBehavior})
      : super(
            value: value,
            reverseDuration: reverseDuration,
            duration: duration,
            lowerBound: 0,
            upperBound: 1.0,
            animationBehavior: animationBehavior ?? AnimationBehavior.normal,
            vsync: vsync);

  ///you can use this map storage some temp var
  Map _map = Map();

  set(key, value) => _map[key] = value;

  T get<T>(key, {T def}) {
    if (_map[key] is T) {
      return _map[key];
    }
    return def;
  }

  @override
  void reset() {
    super.reset();
    _map.clear();
    repetitionCount = -2;
    _curRepetitionCount = 0;
  }

  @override
  void dispose() {
    super.dispose();
    _map.clear();
  }
}

// ignore: must_be_immutable
class FImage extends StatefulWidget {
  FImage({
    @required this.imageProvider,
    this.controller,
    this.decoder,
    this.needRepaintBoundary = true,
    this.semanticLabel,
    this.excludeFromSemantics = false,
    this.width,
    this.height,
    this.onFetchCompleted,
    this.color,
    this.colorBlendMode,
    this.fit,
    this.alignment = Alignment.center,
    this.repeat = ImageRepeat.noRepeat,
    this.centerSlice,
    this.matchTextDirection = false,
    this.frameBuilder,
  }) : assert(imageProvider != null);

  final FOnFetchCompleted onFetchCompleted;
  final FImageController controller;
  final ImageProvider imageProvider;
  final Decoder decoder;
  final bool needRepaintBoundary;
  final double width;
  final double height;
  final Color color;
  final BlendMode colorBlendMode;
  final BoxFit fit;
  final AlignmentGeometry alignment;
  final ImageRepeat repeat;
  final Rect centerSlice;
  final bool matchTextDirection;
  final String semanticLabel;
  final bool excludeFromSemantics;
  final FImageFrameBuilder frameBuilder;

  @override
  State<StatefulWidget> createState() {
    return _FImageState();
  }
}

class _FImageState extends State<FImage> with TickerProviderStateMixin {
  BaseMultiImageInfo _multiImageInfo;
  int _curIndex = 0;
  int _curRepetitionCount = 0;
  bool _fetchComplete = false;
  bool isAutoController = false;
  FImageController controller;

  ImageInfo get _imageInfo {
    if (_getInfoLength <= _curIndex) return null;
    return _multiImageInfo?.frameInfoList[_curIndex];
  }

  int get _getInfoLength {
    return _multiImageInfo?.frameCount ?? 0;
  }

  int get _getNextIndex {
    if (controller == null) return 0;
    var nextIndex = (controller.value /
            (controller.upperBound - controller.lowerBound) *
            (_getInfoLength - 1))
        .floor();
    if (nextIndex == _getInfoLength - 1 &&
        (controller.repetitionCount > _curRepetitionCount ||
            controller.repetitionCount == -1)) {
      _curRepetitionCount++;
      if (mounted) controller.forward(from: controller.lowerBound);
    }
    return nextIndex;
  }

  @override
  void initState() {
    super.initState();
    controller = widget.controller;
    widget.controller?.addListener(_listener);
  }

  @override
  void dispose() {
    super.dispose();
    controller?.removeListener(_listener);
    if (isAutoController) {
      controller?.dispose();
    }
  }

  @override
  void didUpdateWidget(FImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.imageProvider != oldWidget.imageProvider) {
      _fetchImage();
    }

    if (widget.controller != oldWidget.controller &&
        widget.controller != null) {
      oldWidget.controller?.removeListener(_listener);
      isAutoController = false;
      controller?.removeListener(_listener);
      controller = widget.controller;
      controller.addListener(_listener);
    }
  }

  void _needAutoController() {
    if (mounted && controller == null && _getInfoLength > 1) {
      isAutoController = true;
      controller = FImageController(vsync: this);
      controller.addListener(_listener);
    }
  }

  void _listener() {
    if (_curIndex != _getNextIndex && _fetchComplete) {
      if (mounted) {
        setState(() {
          _curIndex = _getNextIndex;
        });
      }
    }
  }

  void _fetchImage() {
    _fetchComplete = false;
    fetchImage(widget.imageProvider, widget.decoder ?? GifDecoder(),
        firstFrameListener: (firstImageInfo) {
      if (mounted) {
        setState(() {
          _multiImageInfo = BaseMultiImageInfo(frameInfoList: [firstImageInfo]);
          _curIndex = 0;
        });
      }
    }, allFrameListener: (allImageInfo) {
      if (mounted) {
        _multiImageInfo = allImageInfo;
        _curRepetitionCount = 0;
        _fetchComplete = true;
        _curIndex = _getNextIndex;
        _needAutoController();
        controller?.duration =
            widget.controller?.duration ?? _multiImageInfo.totalDuration;
        controller?.set('onFetchCompleted', true);
        if (_getInfoLength > 1) {
          if (controller.repetitionCount == -2) {
            controller.repetitionCount = _multiImageInfo.repetitionCount;
          }
        }
        if (widget.onFetchCompleted != null) {
          widget.onFetchCompleted(_multiImageInfo);
        }
        if (_getInfoLength > 1) {
          setState(() {
            if (isAutoController) {
              controller.forward();
            }
          });
        }
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_multiImageInfo == null) {
      _fetchImage();
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget result = new RawImage(
      image: _imageInfo?.image,
      width: widget.width,
      height: widget.height,
      scale: _imageInfo?.scale ?? 1.0,
      color: widget.color,
      colorBlendMode: widget.colorBlendMode,
      fit: widget.fit,
      alignment: widget.alignment,
      repeat: widget.repeat,
      centerSlice: widget.centerSlice,
      matchTextDirection: widget.matchTextDirection,
    );
    if (!widget.excludeFromSemantics) {
      result = Semantics(
        container: widget.semanticLabel != null,
        image: true,
        label: widget.semanticLabel == null ? '' : widget.semanticLabel,
        child: result,
      );
    }
    if (widget.frameBuilder != null) {
      result = widget.frameBuilder(
          context,
          result,
          _multiImageInfo != null ? _curIndex : -1,
          _fetchComplete ? _getInfoLength : 0);
    }

    if (widget.needRepaintBoundary) {
      result = RepaintBoundary(
        child: result,
      );
    }

    return result;
  }
}
