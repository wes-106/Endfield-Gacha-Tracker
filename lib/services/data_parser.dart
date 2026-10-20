import '../models/gacha_record.dart';

/// 將原始抽卡資料解析為 UI 支援的 SubBannerGroup 模型
List<SubBannerGroup> parseRawDataToModels(
    List<dynamic> rawRecords,
    Map<String, List<String>> bannerUpMap, {
      bool isWeaponPool = false,
    }) {
  if (rawRecords.isEmpty) return [];

  // 依據 seqId (時間戳) 進行全域排序
  final sortedRecords = List<dynamic>.from(rawRecords);
  sortedRecords.sort((a, b) {
    int idA = int.tryParse(a['seqId']?.toString() ?? '0') ?? 0;
    int idB = int.tryParse(b['seqId']?.toString() ?? '0') ?? 0;
    return idA.compareTo(idB);
  });

  Map<String, int> poolEffectivePulls = {};
  Map<String, int> poolTotalDrawCount = {};
  Map<String, int> poolFreePullsCount = {};
  Map<String, List<SixStarPityItem>> poolSixStars = {};
  Map<String, List<SixStarPityItem>> poolFree10SixStars = {};
  Map<String, int> poolFinalGlobalPity = {};
  Map<String, int> poolLocalPity = {};

  int globalPityCount = 0;
  List<String> orderedPoolNames = [];

  for (var r in sortedRecords) {
    String poolName = r['poolName'] ?? '未知卡池';
    String kind = r['kind']?.toString() ?? '';
    int rarity = r['rarity'] is int ? r['rarity'] : int.tryParse(r['rarity']?.toString() ?? '4') ?? 4;
    String name = r['nameText'] ?? r['charName'] ?? r['weaponName'] ?? '未知';
    int ts = int.tryParse(r['gachaTs']?.toString() ?? '0') ?? 0;
    String dateStr = ts > 0
        ? DateTime.fromMillisecondsSinceEpoch(ts).toString().substring(0, 10)
        : '未知日期';

    if (!orderedPoolNames.contains(poolName)) orderedPoolNames.add(poolName);

    poolEffectivePulls.putIfAbsent(poolName, () => 0);
    poolTotalDrawCount.putIfAbsent(poolName, () => 0);
    poolFreePullsCount.putIfAbsent(poolName, () => 0);
    poolSixStars.putIfAbsent(poolName, () => []);
    poolFree10SixStars.putIfAbsent(poolName, () => []);
    poolLocalPity.putIfAbsent(poolName, () => 0);
    poolFinalGlobalPity.putIfAbsent(poolName, () => globalPityCount);

    if (kind == 'gift_intel_book' || kind == 'gift_weapon_box') continue;

    // 處理里程碑與贈送信物、武器
    if (kind == 'gift_operator_token' || kind == 'gift_weapon') {
      poolSixStars[poolName]!.add(SixStarPityItem(
        name: kind == 'gift_weapon' ? '贈送UP武器 ($name)' : '贈送UP潛能 ($name)',
        pityCount: poolEffectivePulls[poolName]!,
        isUp: true,
        dateStr: dateStr,
        isMilestone: true,
      ));
      continue;
    }

    // 處理常規抽卡
    if (kind == 'draw') {
      poolTotalDrawCount[poolName] = poolTotalDrawCount[poolName]! + 1;
      int currentTotal = poolTotalDrawCount[poolName]!;
      bool isFreeTenPull = !isWeaponPool && (currentTotal >= 31 && currentTotal <= 40);

      // 檢查是否為 UP 對象 (若對照表無資料則預設為 true 避免誤判)
      List<String> upList = bannerUpMap[poolName] ?? [];
      bool isTargetUp = upList.isEmpty ? true : upList.contains(name);

      if (isFreeTenPull) {
        poolFreePullsCount[poolName] = poolFreePullsCount[poolName]! + 1;
        if (rarity == 6) {
          poolFree10SixStars[poolName]!.add(SixStarPityItem(
            name: name,
            pityCount: currentTotal - 30,
            isUp: isTargetUp,
            dateStr: dateStr,
            isFree: true,
          ));
        }
        continue;
      }

      poolEffectivePulls[poolName] = poolEffectivePulls[poolName]! + 1;
      globalPityCount++;
      poolLocalPity[poolName] = poolLocalPity[poolName]! + 1;
      poolFinalGlobalPity[poolName] = globalPityCount;

      if (rarity == 6) {
        poolSixStars[poolName]!.add(SixStarPityItem(
          name: name,
          pityCount: poolLocalPity[poolName]!,
          isUp: isTargetUp,
          dateStr: dateStr,
        ));

        globalPityCount = 0;
        poolLocalPity[poolName] = 0;
        poolFinalGlobalPity[poolName] = 0;
      }
    }
  }

  List<SubBannerGroup> subBanners = [];

  for (String poolName in orderedPoolNames.reversed) {
    // 僅計算 kind 為 draw 的真實抽卡次數
    int totalRawPulls = rawRecords.where((r) =>
    (r['poolName'] ?? '未知卡池') == poolName && r['kind']?.toString() == 'draw'
    ).length;

    List<String> upList = bannerUpMap[poolName] ?? [];
    String displayUpName = upList.isEmpty ? '當期UP' : upList.join(' / ');

    subBanners.add(SubBannerGroup(
      bannerName: poolName,
      upTargetName: displayUpName,
      periodStr: '已同步',
      totalPulls: totalRawPulls,
      effectivePulls: poolEffectivePulls[poolName]!,
      currentPity: poolFinalGlobalPity[poolName]!,
      isWeapon: isWeaponPool,
      freePullsCount: poolFreePullsCount[poolName]!,
      sixStars: poolSixStars[poolName]!.reversed.toList(),
      free10SixStars: poolFree10SixStars[poolName]!.reversed.toList(),
    ));
  }

  return subBanners;
}