import 'package:isar/isar.dart';

part 'gacha_record.g.dart';

/// Isar 資料庫中的抽卡紀錄。
@collection
class GachaRecord {
  Id id = Isar.autoIncrement;

  /// 與 seqId 組成複合唯一索引，避免不同帳號的紀錄互相覆蓋。
  @Index(composite: [CompositeIndex('seqId')], unique: true, replace: true)
  String uid = 'unknown';

  late String seqId;

  @Index()
  late String poolCategory;

  late String poolName;
  late String kind;
  late int rarity;
  late String name;

  /// 抽卡時間戳，用於排序與保底計算。
  @Index()
  late int gachaTs;
}

/// 單筆 6★ 紀錄，包含常規出彩、免費出彩與系統贈禮。
class SixStarPityItem {
  final String name;
  final int pityCount;
  final bool? isUp;
  final String dateStr;
  final bool isMilestone;
  final bool isFree;
  final int? freePhase;

  SixStarPityItem({
    required this.name,
    required this.pityCount,
    this.isUp,
    required this.dateStr,
    this.isMilestone = false,
    this.isFree = false,
    this.freePhase,
  });
}

/// 單一子卡池的抽卡統計資料。
class SubBannerGroup {
  final String bannerName;
  final String poolCategory;
  final String upTargetName;
  final String periodStr;
  final int totalPulls;
  final int effectivePulls;
  final int currentPity;
  final int hardPityLimit;
  final bool isWeapon;
  final int freePullsCount;
  final List<SixStarPityItem> sixStars;
  final List<SixStarPityItem> free10SixStars;
  final int regularFourStarCount;
  final int regularFiveStarCount;
  final int freeFourStarCount;
  final int freeFiveStarCount;

  SubBannerGroup({
    required this.bannerName,
    required this.poolCategory,
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
    this.regularFourStarCount = 0,
    this.regularFiveStarCount = 0,
    this.freeFourStarCount = 0,
    this.freeFiveStarCount = 0,
  });

  /// 是否已進入免費十連區間。
  bool get hasFree10Section => !isWeapon && freePullsCount > 0;

  // 常規抽卡統計（不含免費抽與系統贈禮）
  int get regularPulls => effectivePulls;
  int get regularSixStarCount => sixStars.where((e) => !e.isMilestone).length;
  int get regularUpCount =>
      sixStars.where((e) => !e.isMilestone && e.isUp == true).length;
  int get regularOffCount =>
      sixStars.where((e) => !e.isMilestone && e.isUp == false).length;

  String get regularAvgStr {
    if (regularSixStarCount == 0) return '-';

    final avgPulls = regularPulls / regularSixStarCount;
    return '${avgPulls.toStringAsFixed(1)} 抽';
  }

  String get regularRateStr {
    if (regularPulls == 0) return '0.00%';

    return '${((regularSixStarCount / regularPulls) * 100).toStringAsFixed(2)}%';
  }

  // 免費抽卡統計
  int get freePulls => freePullsCount;
  int get freeSixStarCount => free10SixStars.length;
  int get freeUpCount => free10SixStars.where((e) => e.isUp == true).length;
  int get freeOffCount => free10SixStars.where((e) => e.isUp == false).length;

  String get freeAvgStr {
    if (freeSixStarCount == 0) return '-';

    return '${(freePulls / freeSixStarCount).toStringAsFixed(1)} 抽';
  }

  String get freeRateStr {
    if (freePulls == 0) return '0.00%';

    return '${((freeSixStarCount / freePulls) * 100).toStringAsFixed(2)}%';
  }
}
