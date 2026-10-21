import 'dart:io';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../models/gacha_record.dart';

class LocalStorage {
  static Isar? _isar;

  /// 初始化並獲取 Isar 資料庫實體 (Singleton)
  static Future<Isar> get db async {
    if (_isar != null) return _isar!;

    Directory dir;
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      // 桌面版：存放於 AppData/Support 目錄，防止 OneDrive 備份衝突
      dir = await getApplicationSupportDirectory();
    } else {
      // 行動版：存放於應用程式私有沙盒目錄
      dir = await getApplicationDocumentsDirectory();
    }

    _isar = await Isar.open(
      [GachaRecordSchema],
      directory: dir.path,
    );
    return _isar!;
  }

  /// 獲取本地資料庫中所有已儲存的帳號 UID 列表
  static Future<List<String>> getAllUids() async {
    final isar = await db;

    // 抓出資料庫中所有不重複的 uid
    final uids = await isar.gachaRecords.where().uidProperty().findAll();
    Set<String> cleanUids = uids.toSet().where((id) => id != 'unknown' && id.trim().isNotEmpty).toSet();

    Set<String> finalUids = {};

    for (var uid in cleanUids) {
      if (!uid.contains('_')) {
        // 舊版的純 UID，執行全面遷移
        final legacyUid = uid;
        final migratedUid = '${uid}_2';

        final legacyRecords = await isar.gachaRecords.filter().uidEqualTo(legacyUid).findAll();
        if (legacyRecords.isNotEmpty) {
          await isar.writeTxn(() async {
            for (var record in legacyRecords) {
              // 建立一個全新實例或直接修改並放回，確保 Isar 寫入新 UID 索引
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

  /// 將 API 獲取的 JSON 紀錄寫入 Isar 資料庫
  static Future<void> saveRecords(String uid, String key, List<dynamic> rawRecords) async {
    // 如果傳入的 uid 沒有後綴，強制補上 _2
    final targetUid = uid.contains('_') ? uid : '${uid}_2';
    final isar = await db;

    final List<GachaRecord> isarRecords = rawRecords.map((json) {
      return GachaRecord()
        ..uid = targetUid
        ..seqId = json['seqId']?.toString() ?? ''
        ..poolCategory = key
        ..poolName = json['poolName'] ?? '未知卡池'
        ..kind = json['kind']?.toString() ?? ''
        ..rarity = json['rarity'] is int ? json['rarity'] : int.tryParse(json['rarity']?.toString() ?? '4') ?? 4
        ..name = json['nameText'] ?? json['charName'] ?? json['weaponName'] ?? '未知'
        ..gachaTs = int.tryParse(json['gachaTs']?.toString() ?? '0') ?? 0;
    }).where((r) => r.seqId.isNotEmpty).toList();

    // 寫入資料庫 (利用 replace: true 自動覆蓋重複資料)
    await isar.writeTxn(() async {
      await isar.gachaRecords.putAll(isarRecords);
    });
  }

  /// 從 Isar 讀取特定帳號與大類的紀錄，並轉回 Map 以相容解析器
  static Future<List<dynamic>> loadRecords(String uid, String key) async {
    final isar = await db;

    // 1. 先嘗試以帶有後綴的新格式讀取 (例如 "123456789_2")
    var records = await isar.gachaRecords.filter()
        .uidEqualTo(uid)
        .poolCategoryEqualTo(key)
        .sortByGachaTs()
        .findAll();

    // 2. 如果新格式查不到資料，且傳入的 UID 是以 "_2" 結尾（亞服）
    // 這代表玩家可能是舊版升上來的，我們嘗試去資料庫撈舊版的「純 UID」資料！
    if (records.isEmpty && uid.endsWith('_2')) {
      final legacyUid = uid.split('_').first;
      final legacyRecords = await isar.gachaRecords.filter()
          .uidEqualTo(legacyUid)
          .poolCategoryEqualTo(key)
          .sortByGachaTs()
          .findAll();

      if (legacyRecords.isNotEmpty) {
        // 如果舊資料存在，我們順手把它們「搬家」到新格式的 uid 上，免得每次都要重新查舊檔
        List<GachaRecord> migratedRecords = legacyRecords.map((r) {
          return GachaRecord()
            ..id = Isar.autoIncrement // 讓 Isar 自動生成新 ID 避免衝突
            ..uid = uid
            ..seqId = r.seqId
            ..poolCategory = r.poolCategory
            ..poolName = r.poolName
            ..kind = r.kind
            ..rarity = r.rarity
            ..name = r.name
            ..gachaTs = r.gachaTs;
        }).toList();

        await isar.writeTxn(() async {
          await isar.gachaRecords.putAll(migratedRecords);
        });

        // 重新賦值以回傳遷移後的紀錄
        records = await isar.gachaRecords.filter()
            .uidEqualTo(uid)
            .poolCategoryEqualTo(key)
            .sortByGachaTs()
            .findAll();
      }
    }

    return records.map((r) => {
      'seqId': r.seqId,
      'poolName': r.poolName,
      'kind': r.kind,
      'rarity': r.rarity,
      'nameText': r.name,
      'gachaTs': r.gachaTs.toString(),
    }).toList();
  }

  /// 本地資料去重複與合併
  static List<dynamic> mergeRecords(List<dynamic> oldList, List<dynamic> newList) {
    Map<String, dynamic> mergedMap = {};

    for (var item in oldList) {
      String seqId = item['seqId']?.toString() ?? '';
      if (seqId.isNotEmpty) mergedMap[seqId] = item;
    }

    for (var item in newList) {
      String seqId = item['seqId']?.toString() ?? '';
      if (seqId.isNotEmpty) mergedMap[seqId] = item;
    }

    return mergedMap.values.toList();
  }

  /// 備份專用的整包匯入方法 (具備自動正規化 UID 與原子性交易)
  static Future<void> importBackupData(String uid, Map<String, List<dynamic>> poolsData, {required bool isOverwrite}) async {
    // 如果匯入的 uid 沒有後綴，強制補上 _2
    final targetUid = uid.contains('_') ? uid : '${uid}_2';
    final isar = await db;

    List<GachaRecord> allRecordsToInsert = [];

    poolsData.forEach((poolKey, rawRecords) {
      final parsedRecords = rawRecords.map((json) {
        return GachaRecord()
          ..uid = targetUid
          ..seqId = json['seqId']?.toString() ?? ''
          ..poolCategory = poolKey
          ..poolName = json['poolName'] ?? '未知卡池'
          ..kind = json['kind']?.toString() ?? ''
          ..rarity = json['rarity'] is int ? json['rarity'] : int.tryParse(json['rarity']?.toString() ?? '4') ?? 4
          ..name = json['nameText'] ?? json['charName'] ?? json['weaponName'] ?? '未知'
          ..gachaTs = int.tryParse(json['gachaTs']?.toString() ?? '0') ?? 0;
      }).where((r) => r.seqId.isNotEmpty).toList();

      allRecordsToInsert.addAll(parsedRecords);
    });

    await isar.writeTxn(() async {
      if (isOverwrite) {
        await isar.gachaRecords.filter().uidEqualTo(targetUid).deleteAll();
      }

      await isar.gachaRecords.putAll(allRecordsToInsert);
    });
  }
}