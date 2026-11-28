import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path_provider/path_provider.dart';

import 'local_storage.dart';

/// 負責處理備份資料的建立、匯出、匯入及還原。
class BackupService {
  // --------------------------------------------------------------------------
  // 1. 備份資料建立與共用輔助方法
  // --------------------------------------------------------------------------

  /// 讀取指定帳號的卡池紀錄與遊戲角色資訊，組裝成標準備份 JSON 結構。
  static Future<Map<String, dynamic>> _buildBackupData(String uid) async {
    final special = await LocalStorage.loadRecords(uid, 'pool_special');
    final refactor = await LocalStorage.loadRecords(uid, 'pool_refactor');
    final standard = await LocalStorage.loadRecords(uid, 'pool_standard');
    final weapon = await LocalStorage.loadRecords(uid, 'pool_weapon');
    final beginner = await LocalStorage.loadRecords(uid, 'pool_beginner');
    final gameRole = await LocalStorage.getGameRole(uid);

    return {
      'uid': uid,
      'version': 2,
      'exportTime': DateTime.now().toIso8601String(),
      'gameRole': gameRole == null
          ? null
          : {
              'accountUid': gameRole.accountUid,
              'roleId': gameRole.roleId,
              'nickName': gameRole.nickName,
              'serverId': gameRole.serverId,
              'serverName': gameRole.serverName,
            },
      'records': {
        'pool_special': special,
        'pool_refactor': refactor,
        'pool_standard': standard,
        'pool_weapon': weapon,
        'pool_beginner': beginner,
      },
    };
  }

  /// 從備份資料還原遊戲角色資訊。
  ///
  /// localDbUid 使用既有的本機帳號與伺服器識別鍵。
  /// 覆蓋模式下若備份明確記錄 gameRole 為 null，則刪除現有角色資料；
  /// 合併模式則保留原有角色資料。
  static Future<void> _restoreGameRole(
    String localDbUid,
    dynamic rawGameRole, {
    required bool isOverwrite,
  }) async {
    // 備份中的 gameRole 為 null 時，依匯入模式決定是否保留現有資料。
    if (rawGameRole == null) {
      if (isOverwrite) {
        await LocalStorage.deleteGameRole(localDbUid);
      }
      return;
    }

    if (rawGameRole is! Map) {
      throw Exception('遊戲角色資料格式錯誤');
    }

    final Map<String, dynamic> roleData = Map<String, dynamic>.from(
      rawGameRole,
    );

    final String? accountUid = roleData['accountUid']?.toString();
    final String? serverId = roleData['serverId']?.toString();

    if (accountUid == null ||
        accountUid.isEmpty ||
        serverId == null ||
        serverId.isEmpty) {
      throw Exception('遊戲角色資料缺少必要的帳號或伺服器資訊');
    }

    // 確保角色資訊確實屬於這份備份的本機帳號。
    if ('${accountUid}_$serverId' != localDbUid) {
      throw Exception('遊戲角色資料與備份帳號不一致');
    }

    await LocalStorage.saveGameRole(
      localDbUid: localDbUid,
      accountUid: accountUid,
      serverId: serverId,
      roleId: roleData['roleId']?.toString(),
      nickName: roleData['nickName']?.toString(),
      serverName: roleData['serverName']?.toString(),
    );
  }

  /// 檢查備份格式版本是否受到支援。
  ///
  /// v1：舊版備份，不包含 gameRole 欄位。
  /// v2：新版備份，包含 gameRole 欄位。
  static void _validateBackupVersion(Map<String, dynamic> backupData) {
    final version = backupData['version'];

    if (version is! int) {
      throw Exception('備份檔缺少有效的版本資訊。');
    }

    switch (version) {
      case 1:
        // v1 為舊版格式，不應包含 gameRole 欄位。
        if (backupData.containsKey('gameRole')) {
          throw Exception('備份版本與資料格式不一致。');
        }
        break;

      case 2:
        // v2 必須包含 gameRole 欄位，即使內容為 null 也可以。
        if (!backupData.containsKey('gameRole')) {
          throw Exception('v2 備份缺少 gameRole 欄位。');
        }
        break;

      default:
        throw Exception('不支援的備份版本：$version');
    }
  }

  /// 將備份中的 UID 正規化為目前使用的本機識別鍵格式。
  static String _normalizeLocalDbUid(String uid) {
    return uid.contains('_') ? uid : '${uid}_2';
  }

  // --------------------------------------------------------------------------
  // 2. 手動匯出 JSON 備份
  // --------------------------------------------------------------------------

  /// 將指定帳號的尋訪紀錄與遊戲角色資訊匯出為 JSON 備份檔。
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
      final gameRole = await LocalStorage.getGameRole(currentUid);

      // 檔名優先使用遊戲 UID；缺少角色 UID 時，退回使用本機識別鍵。
      final String fileUid = gameRole?.roleId?.isNotEmpty == true
          ? gameRole!.roleId!
          : currentUid;

      // 優先使用角色資料中的伺服器 ID。
      final String serverId = gameRole?.serverId ?? '2';

      final fileName = 'Endfield_Backup_${fileUid}_${serverId}_$timestamp.json';

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
    Future<void> Function(String newUid) onSuccess, {
    Future<void> Function()? onLegacyBackupWithoutRole,
  }) async {
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
      _validateBackupVersion(backupData);

      final int backupVersion = backupData['version'] as int;
      final bool isLegacyBackupWithoutRole =
          backupVersion == 1 && !backupData.containsKey('gameRole');

      // 檢查備份檔是否包含必要的帳號與紀錄資料。
      if (!backupData.containsKey('uid') ||
          backupData['uid'] == null ||
          backupData['uid'].toString().trim().isEmpty) {
        throw Exception('無效的備份格式：缺少帳號 UID');
      }

      if (!backupData.containsKey('records') || backupData['records'] is! Map) {
        throw Exception('無效的備份格式：缺少尋訪紀錄 (records)');
      }

      // 將備份 UID 統一轉換為本機識別鍵格式。
      final String rawBackupUid = backupData['uid'].toString().trim();
      final String uid = _normalizeLocalDbUid(rawBackupUid);

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

      // v2 備份才包含遊戲角色資訊；v1 備份僅還原抽卡紀錄。
      String? roleRestoreError;

      if (backupData.containsKey('gameRole')) {
        try {
          await _restoreGameRole(
            uid,
            backupData['gameRole'],
            isOverwrite: isOverwrite,
          );
        } catch (e) {
          // 抽卡紀錄已經匯入，不因角色資訊還原失敗而回報整體匯入失敗。
          roleRestoreError = e.toString();
          debugPrint('遊戲角色資訊還原失敗：$e');
        }
      }

      // 檢查匯入後資料庫是否已存在有效的遊戲角色 UID；
      // 若已有有效 roleId，則無須再提示帳號選單會顯示「UID: 未知」。
      bool shouldShowLegacyNotice = false;

      if (isLegacyBackupWithoutRole) {
        try {
          final existingRole = await LocalStorage.getGameRole(uid);
          final bool hasValidRoleId =
              existingRole?.roleId?.trim().isNotEmpty == true;

          shouldShowLegacyNotice = !hasValidRoleId;
        } catch (roleQueryError) {
          debugPrint('查詢既有遊戲角色資訊失敗：$roleQueryError');
          shouldShowLegacyNotice = true;
        }
      }

      // 將新匯入的帳號加入帳號清單。
      if (!accountUids.contains(uid)) {
        accountUids.add(uid);
      }

      String? uiUpdateError;

      try {
        await onSuccess(uid);
      } catch (uiError) {
        uiUpdateError = uiError.toString().replaceFirst(
          RegExp(r'^Exception:\s*'),
          '',
        );
        debugPrint('資料已匯入，但畫面更新失敗：$uiError');
      }

      if (!context.mounted) return true;

      final warnings = <String>[];
      if (roleRestoreError != null) {
        warnings.add('遊戲角色資訊還原失敗（$roleRestoreError）');
      }
      if (uiUpdateError != null) {
        warnings.add('畫面自動重新整理失敗，請手動切換帳號或重啟程式檢視');
      }

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            warnings.isEmpty
                ? (isOverwrite ? '🎉 備份還原成功 (已完全覆蓋)！' : '🎉 備份匯入成功 (已合併紀錄)！')
                : '⚠️ 資料已匯入，但${warnings.join('；')}。',
          ),
          backgroundColor: warnings.isEmpty
              ? const Color(0xFF10B981)
              : const Color(0xFFF59E0B),
          duration: const Duration(seconds: 5),
        ),
      );

      if (shouldShowLegacyNotice && onLegacyBackupWithoutRole != null) {
        await onLegacyBackupWithoutRole();
      }

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
  // 4. 自動備份與還原
  // --------------------------------------------------------------------------

  /// 將指定帳號的尋訪紀錄與遊戲角色資訊寫入自動備份檔。
  static Future<void> saveAutoBackup(String uid) async {
    try {
      final Map<String, dynamic> backupData = await _buildBackupData(uid);
      final jsonString = const JsonEncoder.withIndent('  ').convert(backupData);
      final gameRole = await LocalStorage.getGameRole(uid);

      final String fileUid = gameRole?.roleId?.isNotEmpty == true
          ? gameRole!.roleId!
          : uid;

      final String serverId = gameRole?.serverId ?? '2';

      final fileName = 'Endfield_AutoBackup_${fileUid}_$serverId.json';

      // 行動裝置使用應用程式文件目錄，桌面平台使用下載目錄。
      if (Platform.isAndroid) {
        final directory = await getApplicationDocumentsDirectory();

        await File('${directory.path}/$fileName').writeAsString(jsonString);
      } else {
        final directory = await getDownloadsDirectory();

        if (directory == null) {
          throw Exception('無法取得下載資料夾，無法建立自動備份');
        }

        await File('${directory.path}${Platform.pathSeparator}$fileName')
            .writeAsString(jsonString);
      }
    } catch (e, stackTrace) {
      debugPrint('自動背景備份失敗: $e');
      debugPrintStack(stackTrace: stackTrace);

      // 讓呼叫端能接收錯誤並決定後續處理方式。
      rethrow;
    }
  }

  /// 使用指定帳號的自動備份檔，優先還原版本較新的備份。
  ///
  /// 先掃描自動備份目錄，依 JSON 內的 UID 與版本篩選候選檔案；
  /// 優先選擇符合 UID 的 v2 備份，同版本則選擇修改時間最新者。
  /// 找不到 v2 時才使用 v1。
  static Future<bool> restoreFromAutoBackup(
    BuildContext context,
    String? currentUid,
    Future<void> Function() onSuccess, {
    Future<void> Function()? onLegacyBackupWithoutRole,
  }) async {
    final messenger = ScaffoldMessenger.of(context);

    if (currentUid == null) {
      if (!context.mounted) return false;

      messenger.showSnackBar(const SnackBar(content: Text('請先選擇要還原的帳號')));
      return false;
    }

    try {
      // 統一目標帳號的本機識別鍵格式。
      final String targetUid = _normalizeLocalDbUid(currentUid);

      // 依照作業系統取得自動備份檔的存放位置。
      final Directory? directory;

      if (Platform.isAndroid) {
        directory = await getApplicationDocumentsDirectory();
      } else {
        directory = await getDownloadsDirectory();
      }

      if (directory == null || !await directory.exists()) {
        throw Exception('無法取得自動備份檔案的存放目錄');
      }

      // 儲存符合目標 UID 的備份檔案及其版本、修改時間。
      final List<({File file, int version, DateTime modified})> candidates = [];

      // 第一階段：掃描目錄，依 JSON 內的 UID 與版本篩選候選檔案。
      await for (final entity in directory.list(followLinks: false)) {
        if (entity is! File) continue;

        final String fileName = entity.uri.pathSegments.isNotEmpty
            ? entity.uri.pathSegments.last
            : '';

        // 只檢查自動備份 JSON，忽略其他檔案。
        if (!fileName.startsWith('Endfield_AutoBackup_') ||
            !fileName.endsWith('.json')) {
          continue;
        }

        try {
          final String contents = await entity.readAsString();

          if (contents.isEmpty) continue;

          final dynamic decodedJson = jsonDecode(contents);

          if (decodedJson is! Map) continue;

          final Map<String, dynamic> backupData = Map<String, dynamic>.from(
            decodedJson,
          );

          // 取得備份 UID 與版本。
          final dynamic rawUid = backupData['uid'];
          final dynamic rawVersion = backupData['version'];

          if (rawUid is! String || rawUid.trim().isEmpty) continue;
          if (rawVersion is! int) continue;

          // 目前只支援 v1、v2 備份。
          if (rawVersion != 1 && rawVersion != 2) continue;
          _validateBackupVersion(backupData);

          // 將備份 UID 正規化後，再與目前帳號比對。
          final String backupUid = _normalizeLocalDbUid(rawUid.trim());

          if (backupUid != targetUid) continue;

          // 記錄符合條件的備份檔及最後修改時間。
          final FileStat fileStat = await entity.stat();

          candidates.add((
            file: entity,
            version: rawVersion,
            modified: fileStat.modified,
          ));
        } catch (e) {
          // 單一備份損壞或無法讀取時，跳過該檔案並繼續掃描。
          debugPrint('略過無法讀取的自動備份檔 ${entity.path}：$e');
        }
      }

      // 找不到符合 UID 的備份時，不進行還原。
      if (candidates.isEmpty) {
        if (!context.mounted) return false;

        messenger.showSnackBar(
          const SnackBar(
            content: Text('❌ 找不到此帳號的有效自動備份檔'),
            backgroundColor: Color(0xFFF59E0B),
          ),
        );
        return false;
      }

      // 第二階段：優先選擇 v2；相同版本則選擇修改時間最新者。
      candidates.sort((a, b) {
        final int versionOrder = b.version.compareTo(a.version);

        if (versionOrder != 0) {
          return versionOrder;
        }

        return b.modified.compareTo(a.modified);
      });

      final selectedCandidate = candidates.first;
      final File backupFile = selectedCandidate.file;

      debugPrint(
        '選擇自動備份檔：${backupFile.path} '
        '(v${selectedCandidate.version})',
      );

      // 讀取選定的備份檔，進行完整解析與驗證。
      final String contents = await backupFile.readAsString();

      if (contents.isEmpty) {
        throw Exception('自動備份檔為空');
      }

      final dynamic decodedJson = jsonDecode(contents);

      if (decodedJson is! Map) {
        throw Exception('自動備份檔格式錯誤：不是有效的 JSON 字典結構');
      }

      final Map<String, dynamic> backupData = Map<String, dynamic>.from(
        decodedJson,
      );

      // 確認備份版本與對應資料格式正確。
      _validateBackupVersion(backupData);

      final int backupVersion = backupData['version'] as int;
      final bool isLegacyBackupWithoutRole =
          backupVersion == 1 && !backupData.containsKey('gameRole');

      // 再次驗證備份 UID，避免檔案在掃描後發生變動。
      final dynamic rawUid = backupData['uid'];

      if (rawUid is! String || rawUid.trim().isEmpty) {
        throw Exception('自動備份檔缺少有效的帳號 UID');
      }

      final String uid = _normalizeLocalDbUid(rawUid.trim());

      if (uid != targetUid) {
        throw Exception('備份檔帳號與目前選取的帳號不一致');
      }

      // 確認備份包含有效的卡池紀錄資料。
      if (backupData['records'] is! Map) {
        throw Exception('自動備份檔缺少有效的尋訪紀錄 (records)');
      }

      final Map<String, dynamic> records = Map<String, dynamic>.from(
        backupData['records'] as Map,
      );

      // 將備份中的各卡池資料整理成匯入所需的格式。
      final Map<String, List<dynamic>> parsedPools = {};

      records.forEach((key, value) {
        if (value is! List) {
          throw Exception('卡池資料格式錯誤：$key');
        }

        parsedPools[key] = value;
      });

      // 使用覆蓋模式，讓資料庫還原至自動備份的狀態。
      await LocalStorage.importBackupData(uid, parsedPools, isOverwrite: true);

      // 還原自動備份中的遊戲角色資訊。
      String? roleRestoreError;

      if (backupData.containsKey('gameRole')) {
        try {
          await _restoreGameRole(
            uid,
            backupData['gameRole'],
            isOverwrite: true,
          );
        } catch (e) {
          // 抽卡紀錄已還原，不因角色資訊失敗而中斷後續流程。
          roleRestoreError = e.toString();
          debugPrint('自動備份的遊戲角色資訊還原失敗：$e');
        }
      }

      // 檢查還原後資料庫是否已存在有效的遊戲角色 UID。
      bool shouldShowLegacyNotice = false;

      if (isLegacyBackupWithoutRole) {
        try {
          final existingRole = await LocalStorage.getGameRole(uid);
          final bool hasValidRoleId =
              existingRole?.roleId?.trim().isNotEmpty == true;

          shouldShowLegacyNotice = !hasValidRoleId;
        } catch (roleQueryError) {
          debugPrint('查詢既有遊戲角色資訊失敗：$roleQueryError');
          shouldShowLegacyNotice = true;
        }
      }

      String? uiUpdateError;

      try {
        await onSuccess();
      } catch (uiError) {
        uiUpdateError = uiError.toString().replaceFirst(
          RegExp(r'^Exception:\s*'),
          '',
        );
        debugPrint('資料已還原，但畫面更新失敗：$uiError');
      }

      if (!context.mounted) return true;

      final warnings = <String>[];
      if (roleRestoreError != null) {
        warnings.add('遊戲角色資訊還原失敗（$roleRestoreError）');
      }
      if (uiUpdateError != null) {
        warnings.add('畫面自動重新整理失敗，請手動切換帳號或重啟程式檢視');
      }

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            warnings.isEmpty
                ? '🛡️ 已成功從自動備份檔還原資料！'
                : '⚠️ 資料已還原，但${warnings.join('；')}。',
          ),
          backgroundColor: warnings.isEmpty
              ? const Color(0xFF10B981)
              : const Color(0xFFF59E0B),
          duration: const Duration(seconds: 5),
        ),
      );

      if (shouldShowLegacyNotice && onLegacyBackupWithoutRole != null) {
        await onLegacyBackupWithoutRole();
      }

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
}
