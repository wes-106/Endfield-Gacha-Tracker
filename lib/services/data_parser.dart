import '../models/gacha_record.dart';

/// 將原始抽卡資料解析為 UI 支援的 SubBannerGroup 模型
List<SubBannerGroup> parseRawDataToModels(
    List<dynamic> rawRecords,
    Map<String, List<String>> bannerUpMap, {
      bool isWeaponPool = false,
      String poolCategory = '',
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
  Map<String, int> poolRegular4Stars = {};
  Map<String, int> poolRegular5Stars = {};
  Map<String, int> poolFree4Stars = {};
  Map<String, int> poolFree5Stars = {};

  int globalPityCount = 0;
  List<String> orderedPoolNames = [];
  bool sharesPity = (poolCategory == 'Special' || poolCategory == 'Standard');

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
    poolRegular4Stars.putIfAbsent(poolName, () => 0);
    poolRegular5Stars.putIfAbsent(poolName, () => 0);
    poolFree4Stars.putIfAbsent(poolName, () => 0);
    poolFree5Stars.putIfAbsent(poolName, () => 0);

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

      // 根據卡池分類套用不同的免費十連規則
      bool isFreeTenPull = false;

      if (poolCategory == 'Special') {
        // 特許尋訪：僅在 31~40 抽為免費
        isFreeTenPull = (currentTotal >= 31 && currentTotal <= 40);
      } else if (poolCategory == 'Refactor') {
        // 重構尋訪：31~40、71~80、111~120 抽皆為免費 (30、60、90抽後贈送)
        isFreeTenPull = (currentTotal >= 31 && currentTotal <= 40) ||
            (currentTotal >= 71 && currentTotal <= 80) ||
            (currentTotal >= 111 && currentTotal <= 120);
      }

      // 嚴謹判斷是否為 UP 對象 (若對照表無該卡池資料，設為 null 代表未知)
      bool? isTargetUp;
      if (bannerUpMap.containsKey(poolName) && bannerUpMap[poolName]!.isNotEmpty) {
        isTargetUp = bannerUpMap[poolName]!.contains(name);
      }

      if (rarity == 4) {
        if (isFreeTenPull) {
          poolFree4Stars[poolName] = poolFree4Stars[poolName]! + 1;
        } else {
          poolRegular4Stars[poolName] = poolRegular4Stars[poolName]! + 1;
        }
      } else if (rarity == 5) {
        if (isFreeTenPull) {
          poolFree5Stars[poolName] = poolFree5Stars[poolName]! + 1;
        } else {
          poolRegular5Stars[poolName] = poolRegular5Stars[poolName]! + 1;
        }
      }

      if (isFreeTenPull) {
        poolFreePullsCount[poolName] = poolFreePullsCount[poolName]! + 1;
        if (rarity == 6) {
          // 計算目前的免費十連屬於哪個階段 (30, 60, 90)
          int currentPhase = ((currentTotal - 1) ~/ 40) * 30 + 30;
          if (poolCategory == 'Special') currentPhase = 30; // 特許尋訪防呆

          poolFree10SixStars[poolName]!.add(SixStarPityItem(
            name: name,
            pityCount: currentTotal - ((currentPhase ~/ 30) * 40 - 10), // 修正相對抽數顯示
            isUp: isTargetUp,
            dateStr: dateStr,
            isFree: true,
            freePhase: currentPhase, // 寫入階段標記
          ));
        }
        continue;
      }

      poolEffectivePulls[poolName] = poolEffectivePulls[poolName]! + 1;
      poolLocalPity[poolName] = poolLocalPity[poolName]! + 1;

      // 根據是否跨池繼承，更新該池當下的「墊抽進度條 (poolFinalGlobalPity)」
      if (sharesPity) {
        globalPityCount++;
        poolFinalGlobalPity[poolName] = globalPityCount;
      } else {
        poolFinalGlobalPity[poolName] = poolLocalPity[poolName]!;
      }

      if (rarity == 6) {
        poolSixStars[poolName]!.add(SixStarPityItem(
          name: name,
          pityCount: poolLocalPity[poolName]!,
          isUp: isTargetUp,
          dateStr: dateStr,
        ));

        if (sharesPity) {
          globalPityCount = 0;
        }
        poolLocalPity[poolName] = 0;
        poolFinalGlobalPity[poolName] = 0;
      }
    }
  }

  List<SubBannerGroup> subBanners = [];

  for (String poolName in orderedPoolNames.reversed) {
    // 僅計算 kind 為 draw 的真實抽卡次數 (直接讀取已統計算好的數值)
    final totalRawPulls = poolTotalDrawCount[poolName] ?? 0;

    List<String> upList = bannerUpMap[poolName] ?? [];
    String displayUpName = upList.isEmpty ? 'UP未知' : upList.join(' / ');

    // 武庫與啟程尋訪的小保底上限為 40 抽，其餘為 80 抽
    int hardPity = (poolCategory == 'Weapon' || poolCategory == 'Beginner') ? 40 : 80;

    subBanners.add(SubBannerGroup(
      bannerName: poolName,
      poolCategory: poolCategory,
      upTargetName: displayUpName,
      periodStr: '已同步',
      totalPulls: totalRawPulls,
      effectivePulls: poolEffectivePulls[poolName]!,
      currentPity: poolFinalGlobalPity[poolName]!,
      hardPityLimit: hardPity,
      isWeapon: isWeaponPool,
      freePullsCount: poolFreePullsCount[poolName]!,
      sixStars: poolSixStars[poolName]!.reversed.toList(),
      free10SixStars: poolFree10SixStars[poolName]!.reversed.toList(),
      regularFourStarCount: poolRegular4Stars[poolName] ?? 0,
      regularFiveStarCount: poolRegular5Stars[poolName] ?? 0,
      freeFourStarCount: poolFree4Stars[poolName] ?? 0,
      freeFiveStarCount: poolFree5Stars[poolName] ?? 0,
    ));
  }

  return subBanners;
}