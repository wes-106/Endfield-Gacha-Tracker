import 'package:flutter/material.dart';

import '../models/gacha_record.dart';
import '../widgets/rarity_distribution_bar.dart';
import '../dialogs/sub_banner_stats_dialog.dart';

class SubBannerCard extends StatelessWidget {
  final SubBannerGroup banner;
  final bool forceDesktop;
  final Map<String, String> characterAvatarMap;
  final Map<String, String> weaponAvatarMap;
  final Map<String, bool>? exportConfig;

  const SubBannerCard({
    super.key,
    required this.banner,
    this.forceDesktop = false,
    required this.characterAvatarMap,
    required this.weaponAvatarMap,
    this.exportConfig,
  });

  /// 根據墊抽數決定保底進度的顏色。
  /// 30 抽以下為綠色、31～60 抽為橘色、60 抽以上為紅色。
  static Color getPityColor(int pity) {
    if (pity <= 30) return const Color(0xFF10B981);
    if (pity <= 60) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  @override
  Widget build(BuildContext context) {
    // 計算下一個免費贈送節點，武器池與角色池使用不同累積規則。
    String nextMilestoneHint;
    if (banner.isWeapon) {
      final int nextTarget = banner.effectivePulls < 180
          ? 180
          : 180 + 160 * (((banner.effectivePulls - 180) ~/ 160) + 1);
      nextMilestoneHint = '${banner.effectivePulls} / $nextTarget (贈送UP武器)';
    } else {
      final int nextTarget = ((banner.effectivePulls ~/ 240) + 1) * 240;
      nextMilestoneHint = '${banner.effectivePulls} / $nextTarget (贈送UP潛能)';
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF181920),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: const BoxDecoration(
              color: Color(0xFF1E2029),
              borderRadius: BorderRadius.vertical(top: Radius.circular(9)),
              border: Border(bottom: BorderSide(color: Colors.white10)),
            ),
            child: Builder(
              builder: (context) {
                // 判斷是否為手機版螢幕 (寬度小於 600)
                final isMobileCard = forceDesktop
                    ? false
                    : (MediaQuery.of(context).size.width < 600);

                final titleRow = Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFCC00),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        banner.isWeapon ? 'WEAPON' : 'POOL',
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w900,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '【${banner.bannerName}】',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      banner.upTargetName,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFFFCC00),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                );

                final bool hasFreeMechanic =
                    banner.poolCategory == 'Special' ||
                    banner.poolCategory == 'Refactor';

                // 動態決定標籤的前綴文字
                final String pullPrefix = hasFreeMechanic ? '常規投入' : '本池投入';
                final String starPrefix = hasFreeMechanic ? '常規 6★' : '本池 6★';

                // 建立卡片數據標籤。
                List<Widget> coreBadges = [];

                if (forceDesktop && exportConfig != null) {
                  // === 導出圖片模式：根據玩家設定攤開數據 ===
                  coreBadges.add(
                    _buildBannerBadge(
                      pullPrefix,
                      '${banner.regularPulls} 抽',
                      isHighlight: true,
                    ),
                  );
                  String starText = '${banner.regularSixStarCount} 個';
                  if (exportConfig!['showUpOff'] == true &&
                      banner.regularSixStarCount > 0) {
                    starText +=
                        ' (${banner.regularUpCount} UP / ${banner.regularOffCount} 歪)';
                  }
                  coreBadges.add(_buildBannerBadge(starPrefix, starText));
                  if (exportConfig!['showAvg'] == true &&
                      banner.regularSixStarCount > 0) {
                    coreBadges.add(
                      _buildBannerBadge('常規平均', banner.regularAvgStr),
                    );
                  }
                  if (exportConfig!['showRate'] == true &&
                      banner.regularSixStarCount > 0) {
                    coreBadges.add(
                      _buildBannerBadge('常規彩率', banner.regularRateStr),
                    );
                  }
                } else {
                  // === App 內一般模式：顯示「投入、6★、全部數據按鈕」 ===
                  coreBadges = [
                    _buildBannerBadge(
                      pullPrefix,
                      '${banner.regularPulls} 抽',
                      isHighlight: true,
                    ),
                    _buildBannerBadge(
                      starPrefix,
                      '${banner.regularSixStarCount} 個',
                    ),
                    GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (_) => SubBannerStatsDialog(banner: banner),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFA855F7).withAlpha(38),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFA855F7)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.bar_chart,
                              color: Color(0xFFD8B4FE),
                              size: 14,
                            ),
                            SizedBox(width: 4),
                            Text(
                              '全部數據',
                              style: TextStyle(
                                color: Color(0xFFD8B4FE),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ];
                }
                // 依匯出設定決定是否顯示稀有度分布。
                final bool showRarity =
                    forceDesktop &&
                    (exportConfig?['showRarityBar'] == true) &&
                    banner.regularPulls > 0;
                final Widget rarityBarWidget = showRarity
                    ? Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: RarityDistributionBar(
                          total: banner.regularPulls,
                          stars6: banner.regularSixStarCount,
                          stars5: banner.regularFiveStarCount,
                          stars4: banner.regularFourStarCount,
                        ),
                      )
                    : const SizedBox.shrink();

                if (isMobileCard) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      titleRow,
                      const SizedBox(height: 12),
                      Wrap(spacing: 8, runSpacing: 8, children: coreBadges),
                      rarityBarWidget,
                    ],
                  );
                } else {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: Wrap(
                          spacing: 16,
                          runSpacing: 10,
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            titleRow,
                            Wrap(spacing: 10, children: coreBadges),
                          ],
                        ),
                      ),
                      rarityBarWidget,
                    ],
                  );
                }
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // 根據卡池分類，將啟程尋訪的文字改為「保底」
                    Text(
                      banner.poolCategory == 'Beginner' ? '保底' : '小保底',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '已墊 ${banner.currentPity} / ${banner.hardPityLimit} 抽',
                      style: TextStyle(
                        color: getPityColor(banner.currentPity),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (banner.currentPity / banner.hardPityLimit).clamp(
                      0.0,
                      1.0,
                    ),
                    minHeight: 8,
                    backgroundColor: const Color(0xFF252732),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      getPityColor(banner.currentPity),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    nextMilestoneHint,
                    style: const TextStyle(
                      color: Color(0xFFA855F7),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  '本池 6★ 抽卡記錄',
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 12),
                if (banner.sixStars.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFF14151B),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      '此卡池常規區間目前尚無 6★ 出彩紀錄',
                      style: TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                  )
                else
                  ...banner.sixStars.map(
                    (item) => _buildPityPillRow(item, banner.hardPityLimit),
                  ),
                // 符合免費卡池及顯示條件時，才渲染免費抽卡區塊。
                Builder(
                  builder: (context) {
                    // 只有 Special 與 Refactor 卡池有免費抽，採用常規投入統計名稱。
                    final bool isFreePool =
                        banner.poolCategory == 'Special' ||
                        banner.poolCategory == 'Refactor';
                    final bool hasFreeData =
                        banner.effectivePulls > 0 || banner.freePullsCount > 0;
                    final bool isEnabledInSettings = forceDesktop
                        ? (exportConfig?['showFreePulls'] == true)
                        : true;

                    // 分隔線與免費抽卡內容共用相同的顯示條件。
                    if (isFreePool && hasFreeData && isEnabledInSettings) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Divider(color: Colors.white12, height: 1),
                          ),
                          _buildFreeTenPullsSection(context, banner),
                        ],
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // Helper Widgets
  // ==========================================================================

  /// 構建卡池標題列下方的小數據標籤 (如：本池投入、平均出彩)
  Widget _buildBannerBadge(
    String label,
    String value, {
    bool isHighlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isHighlight ? const Color(0x26FFCC00) : const Color(0xFF14151B),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isHighlight ? const Color(0xFFFFCC00) : Colors.white12,
        ),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$label ',
              style: const TextStyle(color: Colors.white54, fontSize: 11),
            ),
            TextSpan(
              text: value,
              style: TextStyle(
                color: isHighlight ? const Color(0xFFFFCC00) : Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 構建單筆 6★ 抽卡紀錄的「彩色膠囊」橫列 (包含頭像、名稱、抽數與動態進度條)
  Widget _buildPityPillRow(SixStarPityItem item, int maxPity) {
    // 如果是系統贈送的里程碑 (例如 240 抽換潛能、180 抽換武器)，套用特殊的紫色樣式
    if (item.isMilestone) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0x33A855F7),
                border: Border.all(color: const Color(0xFFA855F7), width: 1.5),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.card_giftcard,
                color: Color(0xFFD8B4FE),
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                height: 28,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0x44A855F7), Color(0x887E22CE)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFA855F7)),
                ),
                alignment: Alignment.centerLeft,
                child: Text(
                  item.name,
                  style: const TextStyle(
                    color: Color(0xFFF3E8FF),
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _buildTagBadge('贈禮', const Color(0xFFA855F7)),
          ],
        ),
      );
    }

    // 常規抽卡紀錄樣式
    final barColor = item.isFree
        ? const Color(0xFF3B82F6)
        : getPityColor(item.pityCount);

    final avatarUrl =
        characterAvatarMap[item.name] ?? weaponAvatarMap[item.name];

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF262834),
              border: Border.all(
                color: item.isFree
                    ? const Color(0xFF3B82F6)
                    : const Color(0xFFFFCC00),
                width: 1.5,
              ),
            ),
            child: ClipOval(
              child: avatarUrl != null
                  ? Image.network(
                      avatarUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Center(
                        child: Text(
                          item.name.isNotEmpty ? item.name[0] : '?',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFFCC00),
                            fontSize: 13,
                          ),
                        ),
                      ),
                    )
                  : Center(
                      child: Text(
                        item.name.isNotEmpty ? item.name[0] : '?',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFFCC00),
                          fontSize: 13,
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 84,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                Text(
                  item.dateStr,
                  style: const TextStyle(color: Colors.white38, fontSize: 10),
                ),
              ],
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // 確保 1 抽也有真實的微小比例 (0.01)
                final ratio = (item.pityCount / maxPity).clamp(0.01, 1.0);
                final barWidth = constraints.maxWidth * ratio;
                // 判斷進度條是否短於 40 像素 (不足以塞入文字，需將文字外推)
                final isBarTooShort = barWidth < 40;

                return SizedBox(
                  height: 24,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.centerLeft,
                    children: [
                      Container(
                        width: barWidth,
                        decoration: BoxDecoration(
                          color: barColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      Positioned(
                        left: isBarTooShort ? barWidth + 6 : null,
                        right: isBarTooShort
                            ? null
                            : (constraints.maxWidth - barWidth) + 10,
                        child: Text(
                          '${item.pityCount} 抽',
                          style: TextStyle(
                            color: isBarTooShort
                                ? Colors.white70
                                : Colors.black,
                            fontWeight: FontWeight.w900,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          if (item.isFree) ...[
            _buildTagBadge(
              '${item.freePhase ?? 30}抽免',
              const Color(0xFF3B82F6),
            ),
            if (item.isUp != null) ...[
              const SizedBox(width: 6),
              _buildTagBadge(
                item.isUp! ? 'UP' : '歪',
                item.isUp! ? const Color(0xFFFFCC00) : const Color(0xFFEF4444),
              ),
            ],
          ] else if (item.isUp == null) ...[
            _buildTagBadge('未知', Colors.white54),
          ] else ...[
            _buildTagBadge(
              item.isUp! ? 'UP' : '歪',
              item.isUp! ? const Color(0xFFFFCC00) : const Color(0xFFEF4444),
            ),
          ],
        ],
      ),
    );
  }

  /// 構建贈送的十連尋訪中，若未出 6★ 時的「未出彩」佔位提示列
  Widget _buildFreeTenPullsSection(
    BuildContext context,
    SubBannerGroup banner,
  ) {
    if (banner.poolCategory != 'Special' && banner.poolCategory != 'Refactor') {
      return const SizedBox.shrink();
    }
    if (banner.effectivePulls == 0 && banner.freePullsCount == 0) {
      return const SizedBox.shrink();
    }

    // 依據卡池分類設定最大值與節點
    final bool isRefactor = banner.poolCategory == 'Refactor';
    final int maxPulls = isRefactor ? 90 : 30;
    final List<int> milestones = isRefactor ? [30, 60, 90] : [30];

    final int triggeredPhases = banner.freePullsCount ~/ 10;
    // 將進度限制在 0～100%，避免超過最大抽數時溢出。
    final double progressRatio = (banner.effectivePulls / maxPulls).clamp(
      0.0,
      1.0,
    );
    final int displayPulls = banner.effectivePulls.clamp(0, maxPulls);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '階段贈送十連',
              style: TextStyle(
                color: Color(0xFF60A5FA),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '$displayPulls / $maxPulls 抽',
              style: const TextStyle(
                color: Colors.white54,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // ==========================================
        // 1. 橫向進度條與節點
        // ==========================================
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SizedBox(
                height: 36,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // 底色進度條 (置於偏下方)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 5,
                      child: Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A2D36),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                    // 填滿進度條 (藍色)
                    Positioned(
                      left: 0,
                      bottom: 5,
                      width: constraints.maxWidth * progressRatio,
                      child: Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: const Color(0xFF60A5FA),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                    // 繪製各個節點與上方數字
                    ...milestones.map((node) {
                      final double nodeRatio = node / maxPulls;
                      final bool isReached = banner.effectivePulls >= node;
                      return Positioned(
                        left: constraints.maxWidth * nodeRatio - 12,
                        bottom: 2,
                        child: SizedBox(
                          width: 24,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '$node',
                                style: TextStyle(
                                  color: isReached
                                      ? const Color(0xFF60A5FA)
                                      : Colors.white54,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 4),

                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isReached
                                      ? const Color(0xFF60A5FA)
                                      : const Color(0xFF1E2029),
                                  border: Border.all(
                                    color: isReached
                                        ? Colors.white
                                        : const Color(0xFF60A5FA)
                                              .withAlpha(128),
                                    width: 2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),

        // ==========================================
        // 2. 動態顯示已觸發的紀錄
        // ==========================================
        if (triggeredPhases > 0)
          ...List.generate(triggeredPhases, (index) {
            final int currentPhase = milestones[index];
            final List<SixStarPityItem> phaseSixStars = banner.free10SixStars
                .where((item) => item.freePhase == currentPhase)
                .toList();

            if (phaseSixStars.isEmpty) {
              return _buildEmptyFreeRecordRow(currentPhase);
            } else {
              return Column(
                children: phaseSixStars
                    .map((sixStar) => _buildPityPillRow(sixStar, 10))
                    .toList(),
              );
            }
          }),
      ],
    );
  }

  // 內部輔助元件：負責繪製未出 6★ 時的空心佔位紀錄，保持排版對齊
  Widget _buildEmptyFreeRecordRow(int currentPhase) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF262834),
              border: Border.all(color: const Color(0xFF3B82F6), width: 1.5),
            ),
            child: const Center(
              child: Icon(
                Icons.help_outline,
                color: Color(0xFF3B82F6),
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 10),

          const SizedBox(
            width: 84,
            child: Text(
              '未出 6★',
              style: TextStyle(
                color: Colors.white54,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 24,
              decoration: BoxDecoration(
                color: const Color(0xFF252732).withAlpha(128),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
            ),
          ),
          const SizedBox(width: 8),

          _buildTagBadge('$currentPhase抽免', const Color(0xFF3B82F6)),
        ],
      ),
    );
  }

  /// 構建紀錄最右側的狀態小標籤 (如：UP、歪、免、贈禮)
  Widget _buildTagBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
