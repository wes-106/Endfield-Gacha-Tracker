import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

import 'local_storage.dart';

/// 負責處理所有與備份、檔案匯出、匯入相關的底層邏輯
class BackupService {
  // ==========================================================================
  // 1. 手動匯出資料備份 (JSON)
  // ==========================================================================
  static Future<void> exportBackupJson(BuildContext context, String? currentUid) async {
    final messenger = ScaffoldMessenger.of(context);

    if (currentUid == null) {
      messenger.showSnackBar(const SnackBar(content: Text('目前沒有可備份的帳號資料')));
      return;
    }

    try {
      final special = await LocalStorage.loadRecords(currentUid, 'pool_special');
      final refactor = await LocalStorage.loadRecords(currentUid, 'pool_refactor');
      final standard = await LocalStorage.loadRecords(currentUid, 'pool_standard');
      final weapon = await LocalStorage.loadRecords(currentUid, 'pool_weapon');
      final beginner = await LocalStorage.loadRecords(currentUid, 'pool_beginner');

      final Map<String, dynamic> backupData = {
        'uid': currentUid,
        'version': 1,
        'exportTime': DateTime.now().toIso8601String(),
        'records': {
          'pool_special': special,
          'pool_refactor': refactor,
          'pool_standard': standard,
          'pool_weapon': weapon,
          'pool_beginner': beginner,
        }
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(backupData);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'Endfield_Backup_${currentUid}_$timestamp.json';

      Uri? outputUri = await FilePicker.saveFile(
        dialogTitle: '選擇備份檔案儲存位置',
        fileName: fileName,
        bytes: Uint8List.fromList(utf8.encode(jsonString)),
      );

      if (outputUri == null) return;
      String outputFile = outputUri.toFilePath();

      messenger.showSnackBar(
        SnackBar(
          content: Text('✅ 備份檔已成功儲存至：\n$outputFile'),
          backgroundColor: const Color(0xFF10B981),
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('❌ 匯出備份失敗：$e'), backgroundColor: const Color(0xFFEF4444)),
      );
    }
  }

  // ==========================================================================
  // 2. 導入資料備份 (開啟系統檔案總管選取 JSON 檔)
  // ==========================================================================
  static Future<void> importBackupFromFile(
      BuildContext context,
      List<String> accountUids,
      Function(String newUid) onSuccess,
      ) async {
    final messenger = ScaffoldMessenger.of(context);

    try {
      final PlatformFile? pickedFile = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (pickedFile == null || pickedFile.path == null) return;

      File file = File(pickedFile.path!);
      String rawJson = await file.readAsString();

      if (rawJson.isEmpty) return;

      final Map<String, dynamic> backupData = jsonDecode(rawJson);
      final String uid = backupData['uid'];
      final Map<String, dynamic> records = backupData['records'];

      List<Map<String, dynamic>> safeCast(dynamic source) {
        if (source == null) return [];
        return (source as List).map((item) => Map<String, dynamic>.from(item as Map)).toList();
      }

      if (records.containsKey('pool_special')) {
        await LocalStorage.saveRecords(uid, 'pool_special', safeCast(records['pool_special']));
      }
      if (records.containsKey('pool_refactor')) {
        await LocalStorage.saveRecords(uid, 'pool_refactor', safeCast(records['pool_refactor']));
      }
      if (records.containsKey('pool_standard')) {
        await LocalStorage.saveRecords(uid, 'pool_standard', safeCast(records['pool_standard']));
      }
      if (records.containsKey('pool_weapon')) {
        await LocalStorage.saveRecords(uid, 'pool_weapon', safeCast(records['pool_weapon']));
      }
      if (records.containsKey('pool_beginner')) {
        await LocalStorage.saveRecords(uid, 'pool_beginner', safeCast(records['pool_beginner']));
      }

      if (!accountUids.contains(uid)) {
        accountUids.add(uid);
      }

      await onSuccess(uid);

      messenger.showSnackBar(
        const SnackBar(content: Text('🎉 歷史備份還原成功！'), backgroundColor: Color(0xFF10B981)),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('❌ 檔案讀取或解析失敗：$e'), backgroundColor: const Color(0xFFEF4444)),
      );
    }
  }

  // ==========================================================================
  // 3. 從內部的「自動備份檔」一鍵還原
  // ==========================================================================
  static Future<void> restoreFromAutoBackup(
      BuildContext context,
      String? currentUid,
      Function() onSuccess,
      ) async {
    final messenger = ScaffoldMessenger.of(context);

    if (currentUid == null) {
      messenger.showSnackBar(const SnackBar(content: Text('請先選擇要還原的帳號')));
      return;
    }

    try {
      final fileName = 'Endfield_AutoBackup_$currentUid.json';
      File? file;

      if (Platform.isAndroid || Platform.isIOS) {
        final directory = await getApplicationDocumentsDirectory();
        file = File('${directory.path}/$fileName');
      } else {
        final directory = await getDownloadsDirectory();
        if (directory != null) file = File('${directory.path}${Platform.pathSeparator}$fileName');
      }

      if (file == null || !await file.exists()) {
        messenger.showSnackBar(
          const SnackBar(content: Text('❌ 找不到此帳號的自動備份檔，可能尚未產生'), backgroundColor: Color(0xFFF59E0B)),
        );
        return;
      }

      String rawJson = await file.readAsString();
      final Map<String, dynamic> backupData = jsonDecode(rawJson);
      final String uid = backupData['uid'];
      final Map<String, dynamic> records = backupData['records'];

      if (records.containsKey('pool_special')) {
        await LocalStorage.saveRecords(uid, 'pool_special', List<Map<String, dynamic>>.from(records['pool_special']));
      }
      if (records.containsKey('pool_refactor')) {
        await LocalStorage.saveRecords(uid, 'pool_refactor', List<Map<String, dynamic>>.from(records['pool_refactor']));
      }
      if (records.containsKey('pool_standard')) {
        await LocalStorage.saveRecords(uid, 'pool_standard', List<Map<String, dynamic>>.from(records['pool_standard']));
      }
      if (records.containsKey('pool_weapon')) {
        await LocalStorage.saveRecords(uid, 'pool_weapon', List<Map<String, dynamic>>.from(records['pool_weapon']));
      }
      if (records.containsKey('pool_beginner')) {
        await LocalStorage.saveRecords(uid, 'pool_beginner', List<Map<String, dynamic>>.from(records['pool_beginner']));
      }

      onSuccess();

      messenger.showSnackBar(
        const SnackBar(content: Text('🛡️ 已成功從最新的自動備份檔還原資料！'), backgroundColor: Color(0xFF10B981)),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('❌ 還原失敗：$e'), backgroundColor: const Color(0xFFEF4444)),
      );
    }
  }

  // ==========================================================================
  // 4. 背景產生自動備份檔 (無 UI 互動，供 API 同步完畢後呼叫)
  // ==========================================================================
  static Future<void> saveAutoBackup(String uid) async {
    try {
      final specialData = await LocalStorage.loadRecords(uid, 'pool_special');
      final refactorData = await LocalStorage.loadRecords(uid, 'pool_refactor');
      final standardData = await LocalStorage.loadRecords(uid, 'pool_standard');
      final weaponData = await LocalStorage.loadRecords(uid, 'pool_weapon');
      final beginnerData = await LocalStorage.loadRecords(uid, 'pool_beginner');

      final Map<String, dynamic> backupData = {
        'uid': uid,
        'version': 1,
        'exportTime': DateTime.now().toIso8601String(),
        'records': {
          'pool_special': specialData,
          'pool_refactor': refactorData,
          'pool_standard': standardData,
          'pool_weapon': weaponData,
          'pool_beginner': beginnerData,
        }
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(backupData);
      final fileName = 'Endfield_AutoBackup_$uid.json';

      if (Platform.isAndroid || Platform.isIOS) {
        final directory = await getApplicationDocumentsDirectory();
        await File('${directory.path}/$fileName').writeAsString(jsonString);
      } else {
        final directory = await getDownloadsDirectory();
        if (directory != null) {
          await File('${directory.path}${Platform.pathSeparator}$fileName').writeAsString(jsonString);
        }
      }
    } catch (e) {
      debugPrint('自動背景備份失敗: $e');
    }
  }
}