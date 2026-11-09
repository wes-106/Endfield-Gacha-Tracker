import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'local_storage.dart';

/// 負責處理備份資料的建立、匯出、匯入及還原。
class BackupService {
  // --------------------------------------------------------------------------
  // 1. 建立標準備份資料
  // --------------------------------------------------------------------------

  /// 讀取指定 UID 的所有卡池紀錄，組裝成標準備份 JSON 結構。
  static Future<Map<String, dynamic>> _buildBackupData(String uid) async {
    final special = await LocalStorage.loadRecords(uid, 'pool_special');
    final refactor = await LocalStorage.loadRecords(uid, 'pool_refactor');
    final standard = await LocalStorage.loadRecords(uid, 'pool_standard');
    final weapon = await LocalStorage.loadRecords(uid, 'pool_weapon');
    final beginner = await LocalStorage.loadRecords(uid, 'pool_beginner');

    return {
      'uid': uid,
      'version': 1,
      'exportTime': DateTime.now().toIso8601String(),
      'records': {
        'pool_special': special,
        'pool_refactor': refactor,
        'pool_standard': standard,
        'pool_weapon': weapon,
        'pool_beginner': beginner,
      },
    };
  }

  // --------------------------------------------------------------------------
  // 2. 手動匯出 JSON 備份
  // --------------------------------------------------------------------------

  /// 將指定帳號的尋訪紀錄匯出為 JSON 檔案。
  static Future<void> exportBackupJson(
    BuildContext context,
    String? currentUid,
  ) async {
    final messenger = ScaffoldMessenger.of(context);

    if (currentUid == null) {
      messenger.showSnackBar(const SnackBar(content: Text('目前沒有可備份的帳號資料')));
      return;
    }

    try {
      final Map<String, dynamic> backupData = await _buildBackupData(
        currentUid,
      );

      // 使用縮排格式，方便使用者檢視備份內容。
      final jsonString = const JsonEncoder.withIndent('  ').convert(backupData);

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'Endfield_Backup_${currentUid}_$timestamp.json';

      final Uri? outputUri = await FilePicker.saveFile(
        dialogTitle: '選擇備份檔案儲存位置',
        fileName: fileName,
        bytes: Uint8List.fromList(utf8.encode(jsonString)),
      );

      // 使用者取消選擇儲存位置時，不進行後續處理。
      if (outputUri == null) return;

      final outputFile = outputUri.toFilePath();

      messenger.showSnackBar(
        SnackBar(
          content: Text('✅ 備份檔已成功儲存至：\n$outputFile'),
          backgroundColor: const Color(0xFF10B981),
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('❌ 匯出備份失敗：$e'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  // --------------------------------------------------------------------------
  // 3. 從外部 JSON 檔案匯入備份
  // --------------------------------------------------------------------------

  /// 選取 JSON 備份檔，驗證資料並顯示匯入預覽。
  static Future<bool> importBackupFromFile(
    BuildContext context,
    String? currentUid,
    List<String> accountUids,
    Future<void> Function(String newUid) onSuccess,
  ) async {
    final messenger = ScaffoldMessenger.of(context);

    try {
      // 讓使用者從系統檔案選擇器挑選 JSON 備份檔。
      final PlatformFile? pickedFile = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (pickedFile == null || pickedFile.path == null) return false;

      final file = File(pickedFile.path!);
      final rawJson = await file.readAsString();

      if (rawJson.isEmpty) {
        throw Exception('備份檔為空');
      }

      // 確認 JSON 根節點為字典結構。
      final dynamic decodedJson = jsonDecode(rawJson);

      if (decodedJson is! Map<String, dynamic>) {
        throw Exception('檔案格式錯誤：不是有效的 JSON 字典結構');
      }

      final Map<String, dynamic> backupData = decodedJson;

      // 檢查備份檔是否包含必要的帳號與紀錄資料。
      if (!backupData.containsKey('uid') ||
          backupData['uid'] == null ||
          backupData['uid'].toString().trim().isEmpty) {
        throw Exception('無效的備份格式：缺少帳號 UID');
      }

      if (!backupData.containsKey('records') || backupData['records'] is! Map) {
        throw Exception('無效的備份格式：缺少尋訪紀錄 (records)');
      }

      // 若備份 UID 沒有伺服器後綴，預設補上 _2（亞服）。
      final String rawBackupUid = backupData['uid'].toString();
      final String uid = rawBackupUid.contains('_')
          ? rawBackupUid
          : '${rawBackupUid}_2';

      final Map<String, dynamic> records = backupData['records'];

      // 解析備份時間，供預覽畫面顯示。
      String displayTime = '未知時間';
      final String rawTime = backupData['exportTime']?.toString() ?? '';

      if (rawTime.isNotEmpty) {
        try {
          final dt = DateTime.parse(rawTime).toLocal();

          displayTime =
              '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
              '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
        } catch (_) {
          // 時間格式錯誤不影響紀錄匯入，預覽時保留「未知時間」。
        }
      }

      // 驗證各卡池資料型別，並統一轉換為 Map<String, dynamic>。
      int totalRecords = 0;
      final Map<String, List<dynamic>> parsedPools = {};

      List<Map<String, dynamic>> safeCast(dynamic source) {
        if (source == null) return [];

        if (source is! List) {
          throw Exception('卡池資料格式錯誤：預期為陣列 (List)');
        }

        return source.map((item) {
          if (item is! Map) {
            throw Exception('單筆抽卡紀錄格式錯誤：預期為字典 (Map)');
          }

          return Map<String, dynamic>.from(item);
        }).toList();
      }

      records.forEach((key, value) {
        final list = safeCast(value);
        parsedPools[key] = list;
        totalRecords += list.length;
      });

      if (totalRecords == 0) {
        throw Exception('此備份檔內無任何尋訪紀錄');
      }

      // 計算目標帳號目前已儲存的紀錄數量。
      int currentDbTotal = 0;

      for (var pool in [
        'pool_special',
        'pool_refactor',
        'pool_standard',
        'pool_weapon',
        'pool_beginner',
      ]) {
        final existingList = await LocalStorage.loadRecords(uid, pool);
        currentDbTotal += existingList.length;
      }

      // 判斷備份 UID 是否與目前畫面選取的帳號不同。
      final bool isUidMismatch = currentUid != null && currentUid != uid;

      if (!context.mounted) return false;

      // 顯示匯入預覽，讓使用者確認目標帳號與匯入模式。
      final bool? isOverwrite = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: const Color(0xFF181920),
          title: const Text(
            '📥 匯入備份預覽',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 備份帳號與目前選取帳號不同時，顯示警告。
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
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: Color(0xFFEF4444),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '警告：此備份檔的帳號 ($uid) 與您目前畫面上的帳號 ($currentUid) 不同！匯入後將自動切換至該帳號。',
                          style: const TextStyle(
                            color: Color(0xFFFCA5A5),
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              Text(
                '目標帳號：$uid',
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              Text(
                '備份時間：$displayTime',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E2029),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '本機現有紀錄：',
                          style: TextStyle(color: Colors.white70),
                        ),
                        Text(
                          '$currentDbTotal 筆',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Divider(color: Colors.white12, height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '備份檔紀錄數：',
                          style: TextStyle(color: Colors.white70),
                        ),
                        Text(
                          '$totalRecords 筆',
                          style: const TextStyle(
                            color: Color(0xFFFFCC00),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(color: Colors.white24),
              ),
              const Text(
                '請選擇匯入模式：',
                style: TextStyle(
                  color: Color(0xFFFFCC00),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '➕ 合併紀錄：\n保留現有資料，僅補入缺失的紀錄。',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '⚠️ 完全覆蓋：\n刪除此帳號目前的紀錄，將資料庫還原至與此備份檔完全相同的狀態。',
                style: TextStyle(
                  color: Color(0xFFFCA5A5),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, null),
              child: const Text('取消', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
              ),
              icon: const Icon(
                Icons.add_circle_outline,
                size: 18,
                color: Colors.white,
              ),
              label: const Text('合併', style: TextStyle(color: Colors.white)),
              onPressed: () => Navigator.pop(dialogContext, false),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
              ),
              icon: const Icon(
                Icons.warning_amber_rounded,
                size: 18,
                color: Colors.white,
              ),
              label: const Text('覆蓋', style: TextStyle(color: Colors.white)),
              onPressed: () => Navigator.pop(dialogContext, true),
            ),
          ],
        ),
      );

      // 使用者取消預覽時，回傳 false。
      if (isOverwrite == null) return false;

      // 匯入前先備份目標帳號現有資料，以便日後還原。
      if (currentDbTotal > 0) {
        await saveAutoBackup(uid);
      }

      await LocalStorage.importBackupData(
        uid,
        parsedPools,
        isOverwrite: isOverwrite,
      );

      // 將新匯入的帳號加入帳號清單。
      if (!accountUids.contains(uid)) {
        accountUids.add(uid);
      }

      try {
        await onSuccess(uid);
      } catch (uiError) {
        debugPrint('資料已匯入，但畫面更新失敗：$uiError');
      }

      if (!context.mounted) return true;

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            isOverwrite ? '🎉 備份還原成功 (已完全覆蓋)！' : '🎉 備份匯入成功 (已合併紀錄)！',
          ),
          backgroundColor: const Color(0xFF10B981),
        ),
      );

      return true; // 回傳 true 讓外層關閉對話框/側邊欄
    } catch (e) {
      if (!context.mounted) return false;

      messenger.showSnackBar(
        SnackBar(
          content: Text('❌ 檔案讀取或匯入失敗：\n$e'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
      return false;
    }
  }

  // --------------------------------------------------------------------------
  // 4. 從內部自動備份檔還原
  // --------------------------------------------------------------------------

  /// 使用指定帳號的自動備份檔，完全覆蓋還原其尋訪紀錄。
  static Future<bool> restoreFromAutoBackup(
    BuildContext context,
    String? currentUid,
    Future<void> Function() onSuccess,
  ) async {
    final messenger = ScaffoldMessenger.of(context);

    if (currentUid == null) {
      if (!context.mounted) return false;

      messenger.showSnackBar(const SnackBar(content: Text('請先選擇要還原的帳號')));
      return false;
    }

    try {
      final fileName = 'Endfield_AutoBackup_$currentUid.json';
      File? file;

      // 依照作業系統選擇自動備份檔的存放位置。
      if (Platform.isAndroid || Platform.isIOS) {
        final directory = await getApplicationDocumentsDirectory();
        file = File('${directory.path}/$fileName');
      } else {
        final directory = await getDownloadsDirectory();

        if (directory != null) {
          file = File('${directory.path}${Platform.pathSeparator}$fileName');
        }
      }

      if (file == null || !await file.exists()) {
        if (!context.mounted) return false;
        messenger.showSnackBar(
          const SnackBar(
            content: Text('❌ 找不到此帳號的自動備份檔，可能尚未產生'),
            backgroundColor: Color(0xFFF59E0B),
          ),
        );
        return false;
      }

      final rawJson = await file.readAsString();
      final Map<String, dynamic> backupData = jsonDecode(rawJson);

      final String uid = backupData['uid'];
      final Map<String, dynamic> records = backupData['records'];

      // 確保備份檔內的 UID 與預期還原的 UID 一致
      if (uid != currentUid) {
        throw Exception('備份檔帳號與目前選取的帳號不一致');
      }

      // 將備份中的各卡池資料整理成匯入所需的格式。
      final Map<String, List<dynamic>> parsedPools = {};

      records.forEach((key, value) {
        if (value is List) {
          parsedPools[key] = value;
        }
      });

      // 使用覆蓋模式，讓資料庫還原至自動備份的狀態。
      await LocalStorage.importBackupData(uid, parsedPools, isOverwrite: true);

      try {
        await onSuccess();
      } catch (uiError) {
        debugPrint('資料已還原，但畫面更新失敗：$uiError');
      }

      if (!context.mounted) return true;

      messenger.showSnackBar(
        const SnackBar(
          content: Text('🛡️ 已成功從最新的自動備份檔還原資料！'),
          backgroundColor: Color(0xFF10B981),
        ),
      );

      return true;
    } catch (e) {
      if (!context.mounted) return false;

      messenger.showSnackBar(
        SnackBar(
          content: Text('❌ 還原失敗：$e'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
      return false;
    }
  }

  // --------------------------------------------------------------------------
  // 5. 背景產生自動備份檔
  // --------------------------------------------------------------------------

  /// 將指定帳號的目前資料寫入自動備份檔。
  static Future<void> saveAutoBackup(String uid) async {
    try {
      final Map<String, dynamic> backupData = await _buildBackupData(uid);
      final jsonString = const JsonEncoder.withIndent('  ').convert(backupData);
      final fileName = 'Endfield_AutoBackup_$uid.json';

      // 行動裝置使用應用程式文件目錄，桌面平台使用下載目錄。
      if (Platform.isAndroid || Platform.isIOS) {
        final directory = await getApplicationDocumentsDirectory();

        await File('${directory.path}/$fileName').writeAsString(jsonString);
      } else {
        final directory = await getDownloadsDirectory();

        if (directory != null) {
          await File('${directory.path}${Platform.pathSeparator}$fileName')
              .writeAsString(jsonString);
        }
      }
    } catch (e, stackTrace) {
      debugPrint('自動背景備份失敗: $e');
      debugPrintStack(stackTrace: stackTrace);

      // 讓呼叫端能接收錯誤並決定後續處理方式。
      rethrow;
    }
  }
}
