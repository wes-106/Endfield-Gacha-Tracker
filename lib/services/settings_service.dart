import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class SettingsService {
  /// 取得本機設定檔路徑。
  static Future<File> _getSettingsFile() async {
    final Directory dir;

    if (Platform.isWindows) {
      dir = await getApplicationSupportDirectory();
    } else {
      dir = await getApplicationDocumentsDirectory();
    }

    return File('${dir.path}${Platform.pathSeparator}app_settings.json');
  }

  /// 讀取所有設定，並相容舊版圖片匯出設定。
  static Future<Map<String, dynamic>> loadSettings() async {
    final file = await _getSettingsFile();

    if (!await file.exists()) {
      return {};
    }

    try {
      final content = await file.readAsString();
      final data = jsonDecode(content);

      if (data is! Map) {
        throw const FormatException('設定檔格式錯誤，預期應為 JSON 物件。');
      }

      final settings = Map<String, dynamic>.from(data);

      // 將舊版「帳號資訊」設定轉換成獨立的 UID 與名稱設定。
      final exportConfig = settings['export_config'];

      if (exportConfig is Map) {
        final config = Map<String, dynamic>.from(exportConfig);

        if (config['showAccount'] is bool) {
          final oldValue = config['showAccount'] as bool;

          // 僅在新設定不存在時，才使用舊設定補上預設值。
          config.putIfAbsent('showUid', () => oldValue);
          config.putIfAbsent('showName', () => oldValue);

          config.remove('showAccount');
        }

        settings['export_config'] = config;
      }

      return settings;
    } catch (e) {
      debugPrint('讀取設定檔失敗：$e');
      rethrow;
    }
  }

  /// 儲存自動備份設定，並保留其他既有設定。
  static Future<bool> saveAutoBackupPreference(bool value) async {
    try {
      final file = await _getSettingsFile();
      await file.parent.create(recursive: true);

      // 讀取既有設定，保留其他設定項目。
      final data = await loadSettings();

      data['auto_backup_enabled'] = value;

      await file.writeAsString(jsonEncode(data));
      return true;
    } catch (e) {
      debugPrint('儲存自動備份設定失敗：$e');
      return false;
    }
  }

  /// 儲存圖片匯出設定，並保留其他既有設定。
  static Future<void> saveExportConfig(Map<String, bool> config) async {
    try {
      final file = await _getSettingsFile();
      await file.parent.create(recursive: true);

      final data = await loadSettings();
      data['export_config'] = config;

      await file.writeAsString(jsonEncode(data));
    } catch (e) {
      debugPrint('儲存匯出設定失敗：$e');
      rethrow;
    }
  }
}
