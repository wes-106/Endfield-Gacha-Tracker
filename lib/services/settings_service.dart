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

  /// 讀取所有設定。
  static Future<Map<String, dynamic>> loadSettings() async {
    final file = await _getSettingsFile();

    if (!await file.exists()) {
      return {};
    }

    try {
      final content = await file.readAsString();
      final data = jsonDecode(content);

      if (data is Map) {
        return Map<String, dynamic>.from(data);
      }

      throw const FormatException('設定檔格式錯誤，預期應為 JSON 物件。');
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

  /// 儲存指定帳號的別名，並保留其他既有設定。
  static Future<bool> saveAccountName(String uid, String name) async {
    final trimmedName = name.trim();

    if (trimmedName.isEmpty) return false;

    try {
      final file = await _getSettingsFile();
      await file.parent.create(recursive: true);

      final data = await loadSettings();

      // 讀取既有帳號別名，避免覆蓋其他帳號的名稱。
      Map<String, String> names = {};

      if (data['account_names'] is Map) {
        names = Map<String, String>.from(
          (data['account_names'] as Map).map(
            (key, value) => MapEntry(key.toString(), value.toString()),
          ),
        );
      }

      names[uid] = trimmedName;
      data['account_names'] = names;

      await file.writeAsString(jsonEncode(data));
      return true;
    } catch (e) {
      debugPrint('儲存帳號名稱失敗：$e');
      return false;
    }
  }
}
