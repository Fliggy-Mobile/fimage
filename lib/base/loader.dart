import 'dart:io';
import 'dart:typed_data';

import 'package:fimage/base/decoder.dart';
import 'package:fimage/base/image_info.dart';
import 'package:fimage/gif/gif_decoder.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'cache.dart';

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

Future<Uint8List> loadImage(ImageProvider provider) async {
  Uint8List data;
  if (provider is NetworkImage) {
    final Uri resolved = Uri.base.resolve(provider.url);
    final HttpClientRequest request = await _httpClient.getUrl(resolved);
    provider.headers?.forEach((String name, String value) {
      request.headers.add(name, value);
    });

    final HttpClientResponse response = await request.close();

    if (response.statusCode != HttpStatus.ok) {
      throw NetworkImageLoadException(
          statusCode: response.statusCode, uri: resolved);
    }
    data = await consolidateHttpClientResponseBytes(
      response,
    );
  } else if (provider is AssetImage) {
    AssetBundleImageKey key = await provider.obtainKey(ImageConfiguration());
    data = (await key.bundle.load(key.name)).buffer.asUint8List();
  } else if (provider is FileImage) {
    data = await provider.file.readAsBytes();
  } else if (provider is MemoryImage) {
    data = provider.bytes;
  }
  return data;
}

typedef FirstFrameListener = Function(BaseImageInfo firstImageInfo);
typedef AllFrameListener = Function(BaseMultiImageInfo allImageInfo);

final Map<String, List<AllFrameListener>> _allFrameMap = Map();
final Map<String, List<FirstFrameListener>> _firstFrameMap = Map();

void _addToFrameMap(FirstFrameListener firstFrameListener,
    AllFrameListener allFrameListener, String key) {
  _firstFrameMap.update(key, (value) {
    value?.add(firstFrameListener);
    return value;
  }, ifAbsent: () => []..add(firstFrameListener));

  _allFrameMap.update(key, (value) {
    value?.add(allFrameListener);
    return value;
  }, ifAbsent: () => []..add(allFrameListener));
}

///request image
///Can be called before use for pre-loading
void fetchImage(ImageProvider provider, Decoder decoder,
    {FirstFrameListener firstFrameListener,
    AllFrameListener allFrameListener}) async {
  BaseMultiImageInfo info;
  dynamic data;
  String key;

  try {
    key = provider is NetworkImage
        ? provider.url
        : provider is AssetImage
            ? provider.keyName + (provider.bundle?.toString() ?? "")
            : provider is MemoryImage
                ? provider.bytes.toString()
                : "";
    if (key == null || key.isEmpty) return;

    if (fImageCache.get(key) != null) {
      print('fetchImage use cache');
      info = fImageCache.get(key);
      firstFrameListener
          ?.call(info.frameCount > 0 ? info.frameInfoList[0] : null);
      return allFrameListener?.call(info);
    } else if (fImageCache.containsKey(key)) {
      _addToFrameMap(firstFrameListener, allFrameListener, key);
      return;
    } else {
      fImageCache.putIfAbsent(key, () => null);
      _addToFrameMap(firstFrameListener, allFrameListener, key);
    }

    data = await loadImage(provider);

    decoder ??= GifDecoder();
    info = await decoder.decode(data, firstFrameListener: (imageInfo) {
      if (_firstFrameMap.containsKey(key)) {
        var list = _firstFrameMap.remove(key);
        list?.forEach((element) {
          element?.call(imageInfo);
          element = null;
        });
        list.clear();
      }
    });
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
    var list = _firstFrameMap.remove(key);
    list?.forEach((element) {
      element?.call(null);
      element = null;
    });
    var list2 = _allFrameMap.remove(key);
    list2?.forEach((element) {
      element?.call(null);
      element = null;
    });
  }
  return;
}
