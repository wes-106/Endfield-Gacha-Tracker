import 'package:isar/isar.dart';
part 'gacha_record.g.dart';

/// 儲存於 Isar 資料庫的原始抽卡紀錄實體
@collection
class GachaRecord {
  Id id = Isar.autoIncrement;

  /// 使用 UID 與 seqId 作為複合唯一索引。
  /// 確保多帳號環境下，相同流水號的紀錄不會互相覆蓋。
  @Index(composite: [CompositeIndex('seqId')], unique: true, replace: true)
  String uid = 'unknown';

  /// 官方抽卡紀錄流水號
  late String seqId;

  /// 卡池分類 (Special, Weapon, Standard, Refactor)
  @Index()
  late String poolCategory;

  late String poolName; // 卡池名稱 (例如：萬物更新)
  late String kind;     // 獲取方式 (例如：draw, gift_weapon)
  late int rarity;      // 星級 (缺失時預設為 4)
  late String name;     // 幹員或武器名稱

  /// 抽卡時間戳，用於保底進度與時間排序
  @Index()
  late int gachaTs;
}

/// 單筆 6★ 出彩紀錄模型
class SixStarPityItem {
  final String name;
  final int pityCount;    // 幾抽出彩 (或里程碑達成抽數)
  final bool isUp;
  final String dateStr;
  final bool isMilestone; // 是否為系統贈送里程碑 (240n 潛能 / 180+160n 武器)
  final bool isFree;      // 是否屬於角色池 31~40 抽免費區間

  SixStarPityItem({
    required this.name,
    required this.pityCount,
    this.isUp = true,
    required this.dateStr,
    this.isMilestone = false,
    this.isFree = false,
  });
}

/// 單一子卡池區塊模型
class SubBannerGroup {
  final String bannerName;     // 子卡池名稱
  final String upTargetName;   // 當期 UP 幹員/武器名稱
  final String periodStr;      // 卡池期間或狀態標籤
  final int totalPulls;        // 該池帳面累計總抽數 (含免費 10 抽)
  final int effectivePulls;    // 扣除免費 10 抽後的有效計入抽數
  final int currentPity;       // 結算後剩餘未出彩抽數 (目前墊抽)
  final int hardPityLimit;     // 保底上限
  final bool isWeapon;         // 是否為武庫申領
  final int freePullsCount;    // 已觸發的免費抽數 (0 ~ 10)
  final List<SixStarPityItem> sixStars;       // 常規 6★ 與里程碑列表
  final List<SixStarPityItem> free10SixStars; // 專屬 31~40 抽免費 6★ 列表

  SubBannerGroup({
    required this.bannerName,
    required this.upTargetName,
    required this.periodStr,
    required this.totalPulls,
    required this.effectivePulls,
    required this.currentPity,
    this.hardPityLimit = 80,
    this.isWeapon = false,
    this.freePullsCount = 0,
    required this.sixStars,
    this.free10SixStars = const [],
  });

  /// 是否已進入 30 抽後的免費 10 抽區間
  bool get hasFree10Section => !isWeapon && freePullsCount > 0;

  /// 真實抽出的 6★ 總數 (包含免費抽，排除系統贈送里程碑)
  int get actualSixStarCount =>
      sixStars.where((e) => !e.isMilestone).length + free10SixStars.length;

  /// 平均出彩抽數
  String get avgPityStr {
    if (actualSixStarCount == 0) return '-';

    double avg = totalPulls / actualSixStarCount;
    return '${avg.toStringAsFixed(1)} 抽';
  }
}