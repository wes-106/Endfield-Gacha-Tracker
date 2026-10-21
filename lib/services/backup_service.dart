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
  // 2. 導入資料備份 (開啟系統檔案總管選取 JSON 檔並顯示預覽)
  // ==========================================================================
  static Future<void> importBackupFromFile(
      BuildContext context,
      String? currentUid, // [新增] 傳入目前的 UID 用於防呆比對
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

      if (rawJson.isEmpty) throw Exception('備份檔為空');

      // 嚴格格式驗證：防止盲目信任 JSON 結構
      final dynamic decodedJson = jsonDecode(rawJson);
      if (decodedJson is! Map<String, dynamic>) {
        throw Exception('檔案格式錯誤：不是有效的 JSON 字典結構');
      }

      final Map<String, dynamic> backupData = decodedJson;

      if (!backupData.containsKey('uid') || backupData['uid'] == null || backupData['uid'].toString().trim().isEmpty) {
        throw Exception('無效的備份格式：缺少帳號 UID');
      }
      if (!backupData.containsKey('records') || backupData['records'] is! Map) {
        throw Exception('無效的備份格式：缺少尋訪紀錄 (records)');
      }

      // 如果匯入的備份 UID 沒有帶伺服器後綴，自動為其補上 _2 (亞服)
      final String rawBackupUid = backupData['uid'].toString();
      final String uid = rawBackupUid.contains('_') ? rawBackupUid : '${rawBackupUid}_2';
      final Map<String, dynamic> records = backupData['records'];

      // 解析備份時間
      String displayTime = '未知時間';
      final String rawTime = backupData['exportTime']?.toString() ?? '';
      if (rawTime.isNotEmpty) {
        try {
          final dt = DateTime.parse(rawTime).toLocal();
          displayTime = '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
        } catch (_) {}
      }

      // 嚴格型別驗證與卡池解析
      int totalRecords = 0;
      final Map<String, List<dynamic>> parsedPools = {};

      List<Map<String, dynamic>> safeCast(dynamic source) {
        if (source == null) return [];
        if (source is! List) throw Exception('卡池資料格式錯誤：預期為陣列 (List)');
        return source.map((item) {
          if (item is! Map) throw Exception('單筆抽卡紀錄格式錯誤：預期為字典 (Map)');
          return Map<String, dynamic>.from(item);
        }).toList();
      }

      records.forEach((key, value) {
        final list = safeCast(value);
        parsedPools[key] = list;
        totalRecords += list.length;
      });

      if (totalRecords == 0) throw Exception('此備份檔內無任何尋訪紀錄');

      // 統計本機資料庫中目前的總紀錄數
      int currentDbTotal = 0;
      for (var pool in ['pool_special', 'pool_refactor', 'pool_standard', 'pool_weapon', 'pool_beginner']) {
        final existingList = await LocalStorage.loadRecords(uid, pool);
        currentDbTotal += existingList.length;
      }

      // 判斷是否發生 UID 錯置 (要匯入的備份 UID 與當前畫面 UID 不符)
      final bool isUidMismatch = (currentUid != null && currentUid != uid);

      if (!context.mounted) return;

      // 彈出預覽對話框詢問玩家
      final bool? isOverwrite = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: const Color(0xFF181920),
          title: const Text('📥 匯入備份預覽', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // [新增] UID 錯置防呆警告 UI
              if (isUidMismatch) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0x33EF4444),
                    border: Border.all(color: const Color(0xFFEF4444)),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '警告：此備份檔的帳號 ($uid) 與您目前畫面上的帳號 ($currentUid) 不同！匯入後將自動切換至該帳號。',
                          style: const TextStyle(color: Color(0xFFFCA5A5), fontSize: 13, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              Text('目標帳號：$uid', style: const TextStyle(color: Colors.white, fontSize: 16)),
              Text('備份時間：$displayTime', style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFF1E2029), borderRadius: BorderRadius.circular(8)),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('本機現有紀錄：', style: TextStyle(color: Colors.white70)),
                        Text('$currentDbTotal 筆', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const Divider(color: Colors.white12, height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('備份檔紀錄數：', style: TextStyle(color: Colors.white70)),
                        Text('$totalRecords 筆', style: const TextStyle(color: Color(0xFFFFCC00), fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(color: Colors.white24),
              ),
              const Text('請選擇匯入模式：', style: TextStyle(color: Color(0xFFFFCC00), fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('➕ 合併紀錄：\n保留現有資料，僅補入缺失的紀錄。', style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4)),
              const SizedBox(height: 8),
              const Text('⚠️ 完全覆蓋：\n刪除此帳號目前的紀錄，將資料庫還原至與此備份檔完全相同的狀態。', style: TextStyle(color: Color(0xFFFCA5A5), fontSize: 13, height: 1.4)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, null),
              child: const Text('取消', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
              icon: const Icon(Icons.add_circle_outline, size: 18, color: Colors.white),
              label: const Text('合併', style: TextStyle(color: Colors.white)),
              onPressed: () => Navigator.pop(dialogContext, false),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
              icon: const Icon(Icons.warning_amber_rounded, size: 18, color: Colors.white),
              label: const Text('覆蓋', style: TextStyle(color: Colors.white)),
              onPressed: () => Navigator.pop(dialogContext, true),
            ),
          ],
        ),
      );

      if (isOverwrite == null) return;

      // 匯入前自動備份現有資料 (如果該 UID 本來就有資料的話)
      if (currentDbTotal > 0) {
        await saveAutoBackup(uid);
      }

      // 呼叫原子性匯入方法
      await LocalStorage.importBackupData(uid, parsedPools, isOverwrite: isOverwrite);

      if (!accountUids.contains(uid)) {
        accountUids.add(uid);
      }

      await onSuccess(uid);

      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(
            content: Text(isOverwrite ? '🎉 備份還原成功 (已完全覆蓋)！' : '🎉 備份匯入成功 (已合併紀錄)！'),
            backgroundColor: const Color(0xFF10B981)
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('❌ 檔案讀取或匯入失敗：\n$e'), backgroundColor: const Color(0xFFEF4444)),
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