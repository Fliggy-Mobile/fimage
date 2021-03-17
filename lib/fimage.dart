import 'dart:async';
import 'dart:developer';

import 'dart:io';
import 'dart:ui' as ui show Codec;
import 'dart:ui';
import 'package:fimage/base/loader.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:image/image.dart' hide Color, BlendMode;

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

typedef FirstFrameListener = void Function(ImageInfo firstImageInfo);
typedef AllFrameListener = void Function(GifImageInfo allImageInfo);

///currentFrame = -1,为第一帧还没有回来，0为第一帧。totalFrame = 0,为全部帧数据还没有回来。
typedef FImageFrameBuilder = Widget Function(
    BuildContext context, Widget child, int currentFrame, int totalFrame);

///image缓存
class FImageCache {
  final int maximumSize;
  FImageCache({int maximumSize}) : maximumSize = maximumSize ?? 500;

  final _cache = <String, GifImageInfo>{};

  void clear() {
    _cache.clear();
  }

  bool containsKey(String key) {
    return _cache.containsKey(key);
  }

  GifImageInfo get(String key) {
    if (!containsKey(key)) {
      return null;
    }
    var imageInfo = _cache.remove(key);
    _cache[key] = imageInfo;
    return imageInfo;
  }

  GifImageInfo putIfAbsent(String key, GifImageInfo Function() ifAbsent) {
    var imageInfo = _cache.putIfAbsent(key, () => ifAbsent());
    _checkCacheSize();
    return imageInfo;
  }

  GifImageInfo update(
      String key,
      GifImageInfo Function(GifImageInfo imageInfo) update,
      GifImageInfo Function() ifAbsent) {
    var imageInfo = _cache.update(key, (value) => update(value),
        ifAbsent: () => ifAbsent());
    _cache.remove(key);
    _cache[key] = imageInfo;
    _checkCacheSize();
    return imageInfo;
  }

  bool evict(Object key) {
    final GifImageInfo pendingImage = _cache.remove(key);
    if (pendingImage != null) {
      return true;
    }
    return false;
  }

  void _checkCacheSize() {
    while (_cache.length > maximumSize) {
      _cache.remove(_cache.keys.first);
    }
  }
}

///gif缓存对外实例
final fImageCache = FImageCache();

///gif数据
class GifImageInfo {
  List<ImageInfo> _imageInfo = [];
  List<ImageInfo> get imageInfo => _imageInfo;
  int _duration = 0;
  int get duration => _duration;
  int _repetitionCount = 0;
  int get repetitionCount => _repetitionCount;
}

///gif动画控制器
class FGifController extends AnimationController {
  FGifController(
      {@required TickerProvider vsync,
      double value = 0.0,
      Duration reverseDuration,
      Duration duration,
      AnimationBehavior animationBehavior})
      : super(
            value: value,
            reverseDuration: reverseDuration,
            duration: duration,
            lowerBound: 0,
            upperBound: 1.0,
            animationBehavior: animationBehavior ?? AnimationBehavior.normal,
            vsync: vsync);

  Map _map = Map();
  set(key, value) => _map[key] = value;
  T get<T>(key, {T def}) {
    if (_map[key] is T) {
      return _map[key];
    }
    return def;
  }

  @override
  void dispose() {
    super.dispose();
    _map.clear();
  }
}

class FImage extends StatefulWidget {
  FImage({
    @required this.image,
    @required this.controller,
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
  }) : assert(image != null && controller != null);
  final VoidCallback onFetchCompleted;
  final FGifController controller;
  final ImageProvider image;
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
  List<ImageInfo> _infos;
  int _duration = 0;
  int _curIndex = 0;
  int _nextIndex = 0;
  int _totalIndex = 0;
  int _totalRepetitionCount = 0;
  int _curRepetitionCount = 0;
  bool _fetchComplete = false;

  ImageInfo get _imageInfo {
    if (!_fetchComplete) return null;
    return _infos == null ? null : _infos[_curIndex];
  }

  int _getInfoLength() {
    if (!_fetchComplete) return 0;
    return _infos == null || _infos.isEmpty ? 0 : _infos.length - 1;
  }

  int _getNextIndex() {
    return (widget.controller.value * _getInfoLength()).floor();
  }

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_listener);
  }

  @override
  void dispose() {
    super.dispose();
    widget.controller.removeListener(_listener);
  }

  @override
  void didUpdateWidget(FImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.image != oldWidget.image) {
      _fetchGif();
    }
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller.removeListener(_listener);
      widget.controller.addListener(_listener);
    }
  }

  void _listener() {
    _nextIndex = _getNextIndex();
    // print(
    //     '_curIndex=$_curIndex   controller.value=${widget.controller.value}  _nextIndex=$_nextIndex');
    if (_curIndex != _nextIndex && _fetchComplete) {
      if (mounted)
        setState(() {
          _curIndex = _nextIndex;
        });
    }
  }

  void _fetchGif() {
    //var time = DateTime.now().millisecondsSinceEpoch;
    fetchGif(widget.image, firstFrameListener: (firstImageInfo) {
      if (mounted) {
        setState(() {
          // print(
          //     'firstFrameListener= ${DateTime.now().millisecondsSinceEpoch - time}');
          _infos = [firstImageInfo];
          _curIndex = 0;
          _fetchComplete = true;
        });
      }
    }, allFrameListener: (imageInfo) {
      if (mounted)
        setState(() {
          // print(
          //     'allFrameListener= ${DateTime.now().millisecondsSinceEpoch - time}');
          _infos = imageInfo.imageInfo;
          _curRepetitionCount = 0;
          _totalRepetitionCount = imageInfo.repetitionCount;
          _duration = imageInfo.duration;
          _fetchComplete = true;
          widget.controller.duration = Duration(milliseconds: _duration);
          widget.controller.set('onFetchCompleted', true);
          _curIndex = _getNextIndex();
          _totalIndex = imageInfo.imageInfo.length;
          if (widget.onFetchCompleted != null) {
            widget.onFetchCompleted();
          }
        });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_infos == null) {
      _fetchGif();
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
    if (widget.frameBuilder != null)
      result = widget.frameBuilder(
          context, result, _infos != null ? _curIndex : -1, _totalIndex);

    return result;
  }
}

final HttpClient _sharedHttpClient = HttpClient()..autoUncompress = false;

HttpClient get _httpClient {
  HttpClient client = _sharedHttpClient;
  assert(() {
    if (debugNetworkImageHttpClientProvider != null)
      client = debugNetworkImageHttpClientProvider();
    return true;
  }());
  return client;
}

final Map<String, List<AllFrameListener>> _allFrameMap = Map();
final Map<String, List<FirstFrameListener>> _firstFrameMap = Map();

void _addToFrameMap(FirstFrameListener firstFrameListener,
    AllFrameListener allFrameListener, String key) {
  _firstFrameMap.update(key, (value) {
    value?.add(firstFrameListener);
    return value;
  }, ifAbsent: () => List()..add(firstFrameListener));

  _allFrameMap.update(key, (value) {
    value?.add(allFrameListener);
    return value;
  }, ifAbsent: () => List()..add(allFrameListener));
}

///请求gif资源
///可以在使用前调用，进行预加载
Future<void> fetchGif(ImageProvider provider,
    {FirstFrameListener firstFrameListener,
    AllFrameListener allFrameListener}) async {
  GifImageInfo info;
  dynamic data;

  String key = provider is NetworkImage
      ? provider.url
      : provider is AssetImage
          ? provider.keyName + provider.bundle?.toString()
          : provider is MemoryImage
              ? provider.bytes.toString()
              : "";

  try {
    if (fImageCache.get(key) != null) {
      info = fImageCache.get(key);
      return allFrameListener?.call(info);
    } else if (fImageCache.containsKey(key)) {
      _addToFrameMap(firstFrameListener, allFrameListener, key);
      return;
    } else {
      fImageCache.putIfAbsent(key, () => null);
      _addToFrameMap(firstFrameListener, allFrameListener, key);
    }

    // if (provider is NetworkImage) {
    //   final Uri resolved = Uri.base.resolve(provider.url);
    //   final HttpClientRequest request = await _httpClient.getUrl(resolved);
    //   provider.headers?.forEach((String name, String value) {
    //     request.headers.add(name, value);
    //   });
    //
    //   final HttpClientResponse response = await request.close();
    //
    //   if (response.statusCode != HttpStatus.ok) {
    //     throw NetworkImageLoadException(
    //         statusCode: response.statusCode, uri: resolved);
    //   }
    //   data = await consolidateHttpClientResponseBytes(
    //     response,
    //   );
    // } else if (provider is AssetImage) {
    //   AssetBundleImageKey key = await provider.obtainKey(ImageConfiguration());
    //   data = await key.bundle.load(key.name);
    // } else if (provider is FileImage) {
    //   data = await provider.file.readAsBytes();
    // } else if (provider is MemoryImage) {
    //   data = provider.bytes;
    // }

    var time0 = DateTime.now().millisecondsSinceEpoch;
    data = await loadImage(provider);
    var time1 = DateTime.now().millisecondsSinceEpoch;

    // if (provider is NetworkImage &&
    //     provider.url ==
    //         'https://media2.giphy.com/media/gdwf3hCno7Uouwdjmf/giphy.gif') {
    //   print('zhongyi time0:${DateTime.now().millisecondsSinceEpoch - time0}');
    //   var animation = GifDecoder().decodeAnimation(data);
    //   print(
    //       'zhongyi animation:$animation frame:${animation.numFrames} time:${DateTime.now().millisecondsSinceEpoch - time1}');
    //   return;
    // }

    ui.Codec codec = await PaintingBinding.instance.instantiateImageCodec(data);
    if (codec.frameCount == 0)
      throw Exception('fetchGif is an empty codec: $key');

    info = GifImageInfo();
    int duration = 0;
    info._repetitionCount = codec.repetitionCount;
    for (int i = 0; i < codec.frameCount; i++) {
      FrameInfo frameInfo = await codec.getNextFrame();
      if (i == 0 && firstFrameListener != null) {
        var imageInfo = ImageInfo(image: frameInfo.image);
        if (_firstFrameMap.containsKey(key)) {
          var list = _firstFrameMap.remove(key);
          list?.forEach((element) {
            element?.call(imageInfo);
            element = null;
          });
          list.clear();
        }
      }
      duration += frameInfo.duration.inMilliseconds;
      info._imageInfo.add(ImageInfo(image: frameInfo.image));
    }
    if (provider is NetworkImage &&
        provider.url ==
            'https://media2.giphy.com/media/gdwf3hCno7Uouwdjmf/giphy.gif') {
      print('zhongyi time1:${DateTime.now().millisecondsSinceEpoch - time1}');
    }

    info._duration = duration;

    fImageCache.update(key, (value) => info, () => info);
    if (_allFrameMap.containsKey(key)) {
      var list = _allFrameMap.remove(key);
      list?.forEach((element) {
        element?.call(info);
        element = null;
      });
      list.clear();
    }
  } catch (e) {
    print(e.toString());
    fImageCache.evict(key);
    _firstFrameMap.remove(key);
    _allFrameMap.remove(key);
  }
  return;
}
