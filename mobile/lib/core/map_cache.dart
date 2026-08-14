import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:dio_cache_interceptor_hive_store/dio_cache_interceptor_hive_store.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

late final CacheStore mapCacheStore;

Future<void> initMapCache() async {
  if (kIsWeb) {
    mapCacheStore = MemCacheStore();
    return;
  }

  final dir = await getApplicationDocumentsDirectory();
  final cacheDir = Directory('${dir.path}/map_tiles_cache');
  if (!cacheDir.existsSync()) {
    cacheDir.createSync(recursive: true);
  }
  mapCacheStore = HiveCacheStore(cacheDir.path);
}
