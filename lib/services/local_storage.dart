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
    final uids = await isar.gachaRecords.where().uidProperty().findAll();
    return uids.toSet().where((id) => id != 'unknown' && id.trim().isNotEmpty).toList();
  }

  /// 將 API 獲取的 JSON 紀錄寫入 Isar 資料庫
  static Future<void> saveRecords(String uid, String key, List<dynamic> rawRecords) async {
    final isar = await db;

    final List<GachaRecord> isarRecords = rawRecords.map((json) {
      return GachaRecord()
        ..uid = uid
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

    final records = await isar.gachaRecords.filter()
        .uidEqualTo(uid)
        .poolCategoryEqualTo(key)
        .sortByGachaTs()
        .findAll();

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
}