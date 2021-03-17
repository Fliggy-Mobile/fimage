import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui show Codec;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

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
  dynamic data;
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
    data = await key.bundle.load(key.name);
  } else if (provider is FileImage) {
    data = await provider.file.readAsBytes();
  } else if (provider is MemoryImage) {
    data = provider.bytes;
  }
  return data;
}
