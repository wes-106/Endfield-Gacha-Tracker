import 'dart:io';

import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';

import '../models/gacha_record.dart';

class LocalStorage {
  static Isar? _isar;

  /// 初始化並取得 Isar 資料庫。
  static Future<Isar> get db async {
    if (_isar != null) return _isar!;

    final Directory dir;

    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      dir = await getApplicationSupportDirectory();
    } else {
      dir = await getApplicationDocumentsDirectory();
    }

    _isar = await Isar.open([GachaRecordSchema], directory: dir.path);

    return _isar!;
  }

  /// 取得本機資料庫中所有有效的帳號 UID。
  ///
  /// 舊版資料只儲存純 UID，沒有伺服器區域後綴。
  /// 目前將這類舊資料視為亞服帳號，統一補上 `_2`，
  /// 並同步更新資料庫中的紀錄。
  static Future<List<String>> getAllUids() async {
    final isar = await db;

    final uids = await isar.gachaRecords.where().uidProperty().findAll();

    final cleanUids = uids
        .toSet()
        .where((id) => id != 'unknown' && id.trim().isNotEmpty)
        .toSet();

    final finalUids = <String>{};

    for (final uid in cleanUids) {
      if (!uid.contains('_')) {
        // 將舊版純 UID 遷移為帶有伺服器區域後綴的格式。
        final legacyUid = uid;
        final migratedUid = '${uid}_2';

        final legacyRecords = await isar.gachaRecords
            .filter()
            .uidEqualTo(legacyUid)
            .findAll();

        if (legacyRecords.isNotEmpty) {
          await isar.writeTxn(() async {
            for (final record in legacyRecords) {
              record.uid = migratedUid;
              await isar.gachaRecords.put(record);
            }
          });
        }

        finalUids.add(migratedUid);
      } else {
        finalUids.add(uid);
      }
    }

    return finalUids.toList();
  }

  /// 將 API 取得的原始 JSON 紀錄轉換後寫入資料庫。
  ///
  /// 若傳入的 UID 尚未包含區域後綴，預設補上 `_2`。
  static Future<void> saveRecords(
    String uid,
    String key,
    List<dynamic> rawRecords,
  ) async {
    final targetUid = uid.contains('_') ? uid : '${uid}_2';
    final isar = await db;

    final List<GachaRecord> isarRecords = rawRecords
        .map((json) {
          return _toGachaRecord(targetUid, key, json as Map<String, dynamic>);
        })
        .where((record) => record.seqId.isNotEmpty)
        .toList();

    await isar.writeTxn(() async {
      await isar.gachaRecords.putAll(isarRecords);
    });
  }

  /// 讀取指定帳號與卡池類別的紀錄，並轉換為 Map 格式。
  static Future<List<dynamic>> loadRecords(String uid, String key) async {
    final isar = await db;

    var records = await isar.gachaRecords
        .filter()
        .uidEqualTo(uid)
        .poolCategoryEqualTo(key)
        .sortByGachaTs()
        .findAll();

    // 新格式沒有資料時，嘗試從舊版純 UID 資料遷移。
    if (records.isEmpty && uid.endsWith('_2')) {
      final legacyUid = uid.split('_').first;

      final legacyRecords = await isar.gachaRecords
          .filter()
          .uidEqualTo(legacyUid)
          .poolCategoryEqualTo(key)
          .sortByGachaTs()
          .findAll();

      if (legacyRecords.isNotEmpty) {
        // 建立新的資料實體，保留原紀錄內容並改用新 UID。
        final migratedRecords = legacyRecords.map((record) {
          return GachaRecord()
            ..id = Isar.autoIncrement
            ..uid = uid
            ..seqId = record.seqId
            ..poolCategory = record.poolCategory
            ..poolName = record.poolName
            ..kind = record.kind
            ..rarity = record.rarity
            ..name = record.name
            ..gachaTs = record.gachaTs;
        }).toList();

        await isar.writeTxn(() async {
          await isar.gachaRecords.putAll(migratedRecords);
        });

        // 重新讀取遷移後的資料。
        records = await isar.gachaRecords
            .filter()
            .uidEqualTo(uid)
            .poolCategoryEqualTo(key)
            .sortByGachaTs()
            .findAll();
      }
    }

    return records
        .map(
          (record) => {
            'seqId': record.seqId,
            'poolName': record.poolName,
            'kind': record.kind,
            'rarity': record.rarity,
            'nameText': record.name,
            'gachaTs': record.gachaTs.toString(),
          },
        )
        .toList();
  }

  /// 合併兩份尋訪紀錄，依 seqId 去除重複資料。
  static List<dynamic> mergeRecords(
    List<dynamic> oldList,
    List<dynamic> newList,
  ) {
    final Map<String, dynamic> mergedMap = {};

    for (final item in oldList) {
      final seqId = item['seqId']?.toString() ?? '';

      if (seqId.isNotEmpty) {
        mergedMap[seqId] = item;
      }
    }

    for (final item in newList) {
      final seqId = item['seqId']?.toString() ?? '';

      if (seqId.isNotEmpty) {
        mergedMap[seqId] = item;
      }
    }

    return mergedMap.values.toList();
  }

  /// 將備份資料匯入資料庫。
  ///
  /// isOverwrite 為 true 時，先刪除該帳號原有的所有紀錄，再匯入備份。
  /// isOverwrite 為 false 時，保留原有資料，並依唯一索引合併紀錄。
  static Future<void> importBackupData(
    String uid,
    Map<String, List<dynamic>> poolsData, {
    required bool isOverwrite,
  }) async {
    final targetUid = uid.contains('_') ? uid : '${uid}_2';
    final isar = await db;

    final List<GachaRecord> allRecordsToInsert = [];

    poolsData.forEach((poolKey, rawRecords) {
      final parsedRecords = rawRecords
          .map((json) {
            return _toGachaRecord(
              targetUid,
              poolKey,
              json as Map<String, dynamic>,
            );
          })
          .where((record) => record.seqId.isNotEmpty)
          .toList();

      allRecordsToInsert.addAll(parsedRecords);
    });

    await isar.writeTxn(() async {
      if (isOverwrite) {
        await isar.gachaRecords.filter().uidEqualTo(targetUid).deleteAll();
      }

      await isar.gachaRecords.putAll(allRecordsToInsert);
    });
  }

  /// 將原始 JSON 資料轉換為 GachaRecord 資料實體。
  ///
  /// 對可能缺少或格式不符的欄位提供預設值，
  /// 避免匯入資料不完整時無法建立紀錄。
  static GachaRecord _toGachaRecord(
    String uid,
    String poolCategory,
    Map<String, dynamic> item,
  ) {
    return GachaRecord()
      ..uid = uid
      ..seqId = item['seqId']?.toString() ?? ''
      ..poolCategory = poolCategory
      ..poolName = item['poolName']?.toString() ?? '未知卡池'
      ..kind = item['kind']?.toString() ?? ''
      ..rarity = item['rarity'] is int
          ? item['rarity']
          : int.tryParse(item['rarity']?.toString() ?? '4') ?? 4
      ..name =
          item['nameText'] ?? item['charName'] ?? item['weaponName'] ?? '未知'
      ..gachaTs = int.tryParse(item['gachaTs']?.toString() ?? '0') ?? 0;
  }

  /// 關閉 Isar 資料庫，並刪除指定的本機設定與快取檔案。
  ///
  /// 僅支援 Windows 桌面版本。
  /// 此操作不會刪除使用者另外匯出的備份檔。
  static Future<void> closeAndDeleteAllData() async {
    if (!Platform.isWindows) {
      throw UnsupportedError('此功能僅支援 Windows 桌面版本');
    }

    // 先關閉資料庫，釋放檔案鎖定。
    if (_isar != null) {
      await _isar!.close();
      _isar = null;
    }

    final Directory dir = await getApplicationSupportDirectory();

    // 僅刪除明確列出的檔案，避免誤刪其他使用者資料。
    final filesToDelete = [
      'app_settings.json',
      'default.isar',
      'default.isar-lck',
      'dictionary_cache.json',
      'shared_preferences.json',
    ];

    final List<String> failedFiles = [];

    for (final fileName in filesToDelete) {
      final file = File('${dir.path}${Platform.pathSeparator}$fileName');

      if (await file.exists()) {
        try {
          await file.delete();
        } catch (e) {
          failedFiles.add(fileName);
          debugPrint('刪除檔案失敗 ($fileName): $e');
        }
      }
    }

    if (failedFiles.isNotEmpty) {
      throw Exception(
        '部分檔案刪除失敗，請檢查權限或重新啟動程式：\n'
        '${failedFiles.join(', ')}',
      );
    }
  }
}
