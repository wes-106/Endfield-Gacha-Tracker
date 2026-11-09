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
  final orderedPoolNames = <String>{};
  bool sharesPity = (poolCategory == 'Special' || poolCategory == 'Standard');

  for (var r in sortedRecords) {
    String poolName = r['poolName'] ?? '未知卡池';
    String kind = r['kind']?.toString() ?? '';
    int rarity = r['rarity'] is int
        ? r['rarity']
        : int.tryParse(r['rarity']?.toString() ?? '4') ?? 4;
    String name = r['nameText'] ?? r['charName'] ?? r['weaponName'] ?? '未知';
    int ts = int.tryParse(r['gachaTs']?.toString() ?? '0') ?? 0;
    String dateStr = ts > 0
        ? DateTime.fromMillisecondsSinceEpoch(ts).toString().substring(0, 10)
        : '未知日期';

    orderedPoolNames.add(poolName);

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
      poolSixStars[poolName]!.add(
        SixStarPityItem(
          name: kind == 'gift_weapon' ? '贈送UP武器 ($name)' : '贈送UP潛能 ($name)',
          pityCount: poolEffectivePulls[poolName]!,
          isUp: true,
          dateStr: dateStr,
          isMilestone: true,
        ),
      );
      continue;
    }

    // 處理常規抽卡
    if (kind == 'draw') {
      poolTotalDrawCount[poolName] = poolTotalDrawCount[poolName]! + 1;
      int currentTotal = poolTotalDrawCount[poolName]!;

      // 根據卡池分類套用不同的免費十連規則
      bool isFreeTenPull = false;

      if (poolCategory == 'Special') {
        isFreeTenPull = (currentTotal >= 31 && currentTotal <= 40);
      } else if (poolCategory == 'Refactor') {
        isFreeTenPull =
            (currentTotal >= 31 && currentTotal <= 40) ||
            (currentTotal >= 71 && currentTotal <= 80) ||
            (currentTotal >= 111 && currentTotal <= 120);
      }

      // 判斷是否為 UP 對象，無資料時為 null
      bool? isTargetUp;
      if (bannerUpMap.containsKey(poolName) &&
          bannerUpMap[poolName]!.isNotEmpty) {
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
          int currentPhase = ((currentTotal - 1) ~/ 40) * 30 + 30;
          if (poolCategory == 'Special') currentPhase = 30;

          poolFree10SixStars[poolName]!.add(
            SixStarPityItem(
              name: name,
              pityCount: currentTotal - ((currentPhase ~/ 30) * 40 - 10),
              isUp: isTargetUp,
              dateStr: dateStr,
              isFree: true,
              freePhase: currentPhase,
            ),
          );
        }
        continue;
      }

      poolEffectivePulls[poolName] = poolEffectivePulls[poolName]! + 1;
      poolLocalPity[poolName] = poolLocalPity[poolName]! + 1;

      // 根據跨池繼承設定，更新目前墊抽進度
      if (sharesPity) {
        globalPityCount++;
        poolFinalGlobalPity[poolName] = globalPityCount;
      } else {
        poolFinalGlobalPity[poolName] = poolLocalPity[poolName]!;
      }

      if (rarity == 6) {
        poolSixStars[poolName]!.add(
          SixStarPityItem(
            name: name,
            pityCount: poolLocalPity[poolName]!,
            isUp: isTargetUp,
            dateStr: dateStr,
          ),
        );

        if (sharesPity) {
          globalPityCount = 0;
        }
        poolLocalPity[poolName] = 0;
        poolFinalGlobalPity[poolName] = 0;
      }
    }
  }

  List<SubBannerGroup> subBanners = [];

  for (String poolName in orderedPoolNames.toList().reversed) {
    // 僅計算 kind 為 draw 的真實抽卡總次數
    final totalRawPulls = poolTotalDrawCount[poolName] ?? 0;

    List<String> upList = bannerUpMap[poolName] ?? [];
    String displayUpName = upList.isEmpty ? 'UP未知' : upList.join(' / ');

    int hardPity = (poolCategory == 'Weapon' || poolCategory == 'Beginner')
        ? 40
        : 80;

    subBanners.add(
      SubBannerGroup(
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
      ),
    );
  }

  return subBanners;
}
