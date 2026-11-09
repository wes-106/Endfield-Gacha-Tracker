import 'dart:io';
import 'dart:convert';
import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class DictionaryService {
  static const String _avatarUrl =
      'https://raw.githubusercontent.com/wes-106/endfield-dictionary/refs/heads/main/avatar_mapping.json';

  static const String _weaponUrl =
      'https://raw.githubusercontent.com/wes-106/endfield-dictionary/refs/heads/main/weapon_mapping.json';

  static const String _bannerUpUrl =
      'https://raw.githubusercontent.com/wes-106/endfield-dictionary/refs/heads/main/banner_up_mapping.json';

  /// 取得字典快取檔案位置
  static Future<File> _getCacheFile() async {
    Directory dir;

    if (Platform.isWindows) {
      dir = await getApplicationSupportDirectory();
    } else {
      dir = await getApplicationDocumentsDirectory();
    }

    return File('${dir.path}${Platform.pathSeparator}dictionary_cache.json');
  }

  /// 載入本地字典快取
  static Future<Map<String, dynamic>> loadDictionaries() async {
    Map<String, dynamic> result = {
      'avatar': <String, String>{},
      'weapon': <String, String>{},
      'bannerUp': <String, List<String>>{},
    };

    final File cacheFile = await _getCacheFile();

    // 1. 讀取本地快取
    try {
      if (await cacheFile.exists()) {
        final String content = await cacheFile.readAsString();

        final dynamic decoded = jsonDecode(content);

        if (decoded is Map) {
          final Map<String, dynamic> cachedData = Map<String, dynamic>.from(
            decoded,
          );

          // 讀取角色字典
          if (cachedData['avatar'] is Map) {
            result['avatar'] = Map<String, String>.from(
              (cachedData['avatar'] as Map).map(
                (key, value) => MapEntry(key.toString(), value.toString()),
              ),
            );
          }

          // 讀取武器字典
          if (cachedData['weapon'] is Map) {
            result['weapon'] = Map<String, String>.from(
              (cachedData['weapon'] as Map).map(
                (key, value) => MapEntry(key.toString(), value.toString()),
              ),
            );
          }

          // 讀取卡池 UP 字典
          if (cachedData['bannerUp'] is Map) {
            final Map bannerData = cachedData['bannerUp'];

            result['bannerUp'] = bannerData.map((key, value) {
              if (value is! List) {
                throw const FormatException('BannerUp 資料格式錯誤');
              }

              return MapEntry(
                key.toString(),
                value.map((e) => e.toString()).toList(),
              );
            });
          }
        }
      }
    } catch (e) {
      debugPrint('讀取字典快取失敗: $e');
    }

    // 2. 從遠端更新字典
    try {
      // 每分鐘變更一次 Cache Buster
      final String cacheBuster =
          '?t=${DateTime.now().millisecondsSinceEpoch ~/ 60000}';

      final responses = await Future.wait([
        http
            .get(Uri.parse('$_avatarUrl$cacheBuster'))
            .timeout(const Duration(seconds: 5)),

        http
            .get(Uri.parse('$_weaponUrl$cacheBuster'))
            .timeout(const Duration(seconds: 5)),

        http
            .get(Uri.parse('$_bannerUpUrl$cacheBuster'))
            .timeout(const Duration(seconds: 5)),
      ]);

      // 確認三份資料都成功取得
      if (responses.every((response) => response.statusCode == 200)) {
        // 解碼 JSON
        final dynamic avatarDecoded = jsonDecode(
          utf8.decode(responses[0].bodyBytes),
        );

        final dynamic weaponDecoded = jsonDecode(
          utf8.decode(responses[1].bodyBytes),
        );

        final dynamic bannerDecoded = jsonDecode(
          utf8.decode(responses[2].bodyBytes),
        );

        // 驗證角色及武器 JSON 格式
        if (avatarDecoded is! Map ||
            weaponDecoded is! Map ||
            bannerDecoded is! Map) {
          throw const FormatException('遠端字典 JSON 格式錯誤');
        }

        // 轉換角色字典
        final Map<String, String> newAvatar = avatarDecoded.map(
          (key, value) => MapEntry(key.toString(), value.toString()),
        );

        // 轉換武器字典
        final Map<String, String> newWeapon = weaponDecoded.map(
          (key, value) => MapEntry(key.toString(), value.toString()),
        );

        // 轉換卡池 UP 字典
        final Map<String, List<String>> newBannerUp = bannerDecoded.map((
          key,
          value,
        ) {
          if (value is! List) {
            throw const FormatException('遠端 BannerUp 資料格式錯誤');
          }

          return MapEntry(
            key.toString(),
            value.map((e) => e.toString()).toList(),
          );
        });

        // 更新結果
        result['avatar'] = newAvatar;
        result['weapon'] = newWeapon;
        result['bannerUp'] = newBannerUp;

        // 3. 儲存新快取
        await cacheFile.parent.create(recursive: true);

        await cacheFile.writeAsString(
          jsonEncode(result),
          encoding: utf8,
          flush: true,
        );

        debugPrint('遠端字典更新成功');
      } else {
        debugPrint(
          '遠端字典下載失敗，HTTP 狀態碼：'
          '${responses.map((r) => r.statusCode).toList()}',
        );
      }
    } catch (e) {
      debugPrint('遠端字典更新失敗，使用本地快取：$e');
    }

    return result;
  }
}
