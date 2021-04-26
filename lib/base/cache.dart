import 'image_info.dart';

///image cache
class FImageCache {
  final int maximumSize;
  FImageCache({int maximumSize}) : maximumSize = maximumSize ?? 1000;

  final _cache = <String, BaseMultiImageInfo>{};

  void clear() {
    _cache.clear();
  }

  bool containsKey(String key) {
    return _cache.containsKey(key);
  }

  BaseMultiImageInfo get(String key) {
    if (!containsKey(key)) {
      return null;
    }
    var imageInfo = _cache.remove(key);
    _cache[key] = imageInfo;
    return imageInfo;
  }

  BaseMultiImageInfo putIfAbsent(
      String key, BaseMultiImageInfo Function() ifAbsent) {
    var imageInfo = _cache.putIfAbsent(key, () => ifAbsent());
    _checkCacheSize();
    return imageInfo;
  }

  BaseMultiImageInfo update(
      String key,
      BaseMultiImageInfo Function(BaseMultiImageInfo imageInfo) update,
      BaseMultiImageInfo Function() ifAbsent) {
    var imageInfo = _cache.update(key, (value) => update(value),
        ifAbsent: () => ifAbsent());
    _cache.remove(key);
    _cache[key] = imageInfo;
    _checkCacheSize();
    return imageInfo;
  }

  bool evict(Object key) {
    final BaseMultiImageInfo pendingImage = _cache.remove(key);
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

///image cache instance
final fImageCache = FImageCache();
