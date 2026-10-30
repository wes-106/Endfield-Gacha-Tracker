import 'package:flutter/material.dart';
// 引入資料模型
import '../models/gacha_record.dart';

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

  // 抽出原本的顏色計算邏輯
  static Color getPityColor(int pity) {
    if (pity <= 30) return const Color(0xFF10B981);
    if (pity <= 60) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  @override
  Widget build(BuildContext context) {
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
                final isMobileCard = forceDesktop ? false : (MediaQuery.of(context).size.width < 600);

                final titleRow = Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFCC00),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        banner.isWeapon ? 'WEAPON' : 'POOL',
                        style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 10),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '【${banner.bannerName}】',
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Colors.white),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      banner.upTargetName,
                      style: const TextStyle(fontSize: 12, color: Color(0xFFFFCC00), fontWeight: FontWeight.w600),
                    ),
                  ],
                );

                final bool hasFreeMechanic = banner.poolCategory == 'Special' || banner.poolCategory == 'Refactor';

                // 動態決定標籤的前綴文字
                final String pullPrefix = hasFreeMechanic ? '常規投入' : '本池投入';
                final String starPrefix = hasFreeMechanic ? '常規 6★' : '本池 6★';

                // 準備要在卡片上顯示的標籤
                List<Widget> coreBadges = [];

                if (forceDesktop && exportConfig != null) {
                  // === 導出圖片模式：根據玩家設定攤開數據 ===
                  coreBadges.add(_buildBannerBadge(pullPrefix, '${banner.regularPulls} 抽', isHighlight: true));
                  String starText = '${banner.regularSixStarCount} 個';
                  if (exportConfig!['showUpOff'] == true && banner.regularSixStarCount > 0) {
                    starText += ' (${banner.regularUpCount} UP / ${banner.regularOffCount} 歪)';
                  }
                  coreBadges.add(_buildBannerBadge(starPrefix, starText));
                  if (exportConfig!['showAvg'] == true && banner.regularSixStarCount > 0) {
                    coreBadges.add(_buildBannerBadge('常規平均', banner.regularAvgStr));
                  }
                  if (exportConfig!['showRate'] == true && banner.regularSixStarCount > 0) {
                    coreBadges.add(_buildBannerBadge('常規彩率', banner.regularRateStr));
                  }
                } else {
                  // === App 內一般模式：顯示「投入、6★、全部數據按鈕」 ===
                  coreBadges = [
                    _buildBannerBadge(pullPrefix, '${banner.regularPulls} 抽', isHighlight: true),
                    _buildBannerBadge(starPrefix, '${banner.regularSixStarCount} 個'),
                    GestureDetector(
                      onTap: () => _showStatsDialog(context, banner),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFA855F7).withAlpha(38),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFA855F7)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.bar_chart, color: Color(0xFFD8B4FE), size: 14),
                            SizedBox(width: 4),
                            Text('全部數據', style: TextStyle(color: Color(0xFFD8B4FE), fontWeight: FontWeight.bold, fontSize: 12)),
                          ],
                        ),
                      ),
                    )
                  ];
                }
                // 準備稀有度條形圖 (移至卡片頂部區域)
                final bool showRarity = forceDesktop && (exportConfig?['showRarityBar'] == true) && banner.regularPulls > 0;
                final Widget rarityBarWidget = showRarity
                    ? Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: _buildRarityBar(banner.regularPulls, banner.regularSixStarCount, banner.regularFiveStarCount, banner.regularFourStarCount),
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
                      style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12),
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
                    value: (banner.currentPity / banner.hardPityLimit).clamp(0.0, 1.0),
                    minHeight: 8,
                    backgroundColor: const Color(0xFF252732),
                    valueColor: AlwaysStoppedAnimation<Color>(getPityColor(banner.currentPity)),
                  ),
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    nextMilestoneHint,
                    style: const TextStyle(color: Color(0xFFA855F7), fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  '本池 6★ 抽卡記錄',
                  style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12),
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
                  ...banner.sixStars.map((item) => _buildPityPillRow(item, banner.hardPityLimit)),
                // 控制免費區塊與分隔線的顯示
                Builder(
                  builder: (context) {
                    final bool isFreePool = banner.poolCategory == 'Special' || banner.poolCategory == 'Refactor';
                    final bool hasFreeData = banner.effectivePulls > 0 || banner.freePullsCount > 0;
                    final bool isEnabledInSettings = forceDesktop ? (exportConfig?['showFreePulls'] == true) : true;

                    // 上方條件都滿足，才一起渲染「分隔線」與「內容」
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
  // 內部輔助 UI 元件 (Helper Widgets)
  // ==========================================================================

  /// 構建卡池標題列下方的小數據標籤 (如：本池投入、平均出彩)
  Widget _buildBannerBadge(String label, String value, {bool isHighlight = false}) {
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
              child: const Icon(Icons.card_giftcard, color: Color(0xFFD8B4FE), size: 18),
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
    final barColor = item.isFree ? const Color(0xFF3B82F6) : getPityColor(item.pityCount);

    final avatarUrl = characterAvatarMap[item.name] ?? weaponAvatarMap[item.name];

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          // 1. 角色/武器頭像區塊
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF262834),
              border: Border.all(
                color: item.isFree ? const Color(0xFF3B82F6) : const Color(0xFFFFCC00),
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
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFFCC00), fontSize: 13),
                  ),
                ),
              )
                  : Center(
                child: Text(
                  item.name.isNotEmpty ? item.name[0] : '?',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFFCC00), fontSize: 13),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // 2. 名稱與日期文字區塊
          SizedBox(
            width: 84,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                Text(item.dateStr, style: const TextStyle(color: Colors.white38, fontSize: 10)),
              ],
            ),
          ),
          // 3. 動態長度的抽數進度條區塊
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
                        decoration: BoxDecoration(color: barColor, borderRadius: BorderRadius.circular(12)),
                      ),
                      Positioned(
                        left: isBarTooShort ? barWidth + 6 : null,
                        right: isBarTooShort ? null : (constraints.maxWidth - barWidth) + 10,
                        child: Text(
                          '${item.pityCount} 抽',
                          style: TextStyle(
                            color: isBarTooShort ? Colors.white70 : Colors.black,
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
          // 4. 右側狀態小標籤
          if (item.isFree) ...[
            _buildTagBadge('${item.freePhase ?? 30}抽免', const Color(0xFF3B82F6)),
            if (item.isUp != null) ...[
              const SizedBox(width: 6),
              _buildTagBadge(item.isUp! ? 'UP' : '歪', item.isUp! ? const Color(0xFFFFCC00) : const Color(0xFFEF4444)),
            ],
          ] else if (item.isUp == null) ...[
            _buildTagBadge('未知', Colors.white54),
          ] else ...[
            _buildTagBadge(item.isUp! ? 'UP' : '歪', item.isUp! ? const Color(0xFFFFCC00) : const Color(0xFFEF4444)),
          ],
        ],
      ),
    );
  }

  /// 構建 30 抽後贈送的十連尋訪中，若未出 6★ 時的「未出彩」佔位提示列
  Widget _buildFreeTenPullsSection(BuildContext context, SubBannerGroup banner) {
    if (banner.poolCategory != 'Special' && banner.poolCategory != 'Refactor') return const SizedBox.shrink();
    if (banner.effectivePulls == 0 && banner.freePullsCount == 0) return const SizedBox.shrink();

    // 依據卡池分類設定最大值與節點
    final bool isRefactor = banner.poolCategory == 'Refactor';
    final int maxPulls = isRefactor ? 90 : 30;
    final List<int> milestones = isRefactor ? [30, 60, 90] : [30];

    final int triggeredPhases = banner.freePullsCount ~/ 10;
    final double progressRatio = (banner.effectivePulls / maxPulls).clamp(0.0, 1.0);
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
              style: TextStyle(color: Color(0xFF60A5FA), fontSize: 12, fontWeight: FontWeight.bold),
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
                        decoration: BoxDecoration(color: const Color(0xFF2A2D36), borderRadius: BorderRadius.circular(3)),
                      ),
                    ),
                    // 填滿進度條 (藍色)
                    Positioned(
                      left: 0,
                      bottom: 5,
                      width: constraints.maxWidth * progressRatio,
                      child: Container(
                        height: 6,
                        decoration: BoxDecoration(color: const Color(0xFF60A5FA), borderRadius: BorderRadius.circular(3)),
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
                              // 上方的進度數字 (30, 60, 90)
                              Text(
                                '$node',
                                style: TextStyle(
                                  color: isReached ? const Color(0xFF60A5FA) : Colors.white54,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 4),
                              // 圓點
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isReached ? const Color(0xFF60A5FA) : const Color(0xFF1E2029),
                                  border: Border.all(
                                    color: isReached ? Colors.white : const Color(0xFF60A5FA).withAlpha(128),
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
                children: phaseSixStars.map((sixStar) => _buildPityPillRow(sixStar, 10)).toList(),
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
          // 1. 佔位頭像 (問號)
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF262834),
              border: Border.all(color: const Color(0xFF3B82F6), width: 1.5),
            ),
            child: const Center(
              child: Icon(Icons.help_outline, color: Color(0xFF3B82F6), size: 18),
            ),
          ),
          const SizedBox(width: 10),
          // 2. 文字區塊
          const SizedBox(
            width: 84,
            child: Text(
              '未出 6★',
              style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold, fontSize: 13),
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
          // 3. 階段標籤
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
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
  /// 彈出詳細數據面板視窗
  void _showStatsDialog(BuildContext context, SubBannerGroup banner) {
    final bool hasFreeMechanic = banner.poolCategory == 'Special' || banner.poolCategory == 'Refactor';
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF181920),
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Colors.white12),
          ),
          title: Text(
            '【${banner.bannerName}】詳細統計',
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- 常規尋訪區塊 ---
              Text(
                hasFreeMechanic ? '🔸 常規尋訪' : '🔸 尋訪統計',
                style: const TextStyle(color: Color(0xFFFFCC00), fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildDialogStatRow('總計投入', '${banner.regularPulls} 抽'),
              _buildDialogStatRow('獲得 6★', '${banner.regularSixStarCount} 個'),
              if (banner.regularSixStarCount > 0) ...[
                _buildDialogStatRow('出彩明細', '${banner.regularUpCount} UP / ${banner.regularOffCount} 歪'),
                _buildDialogStatRow('平均出彩', banner.regularAvgStr),
                _buildDialogStatRow('常規彩率', banner.regularRateStr),
              ],
              if (banner.regularPulls > 0)
                _buildRarityBar(
                    banner.regularPulls,
                    banner.regularSixStarCount,
                    banner.regularFiveStarCount,
                    banner.regularFourStarCount
                ),

              // --- 免費尋訪區塊 (若有) ---
              if (banner.freePulls > 0) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(color: Colors.white12, height: 1),
                ),
                const Text('🔹 階段免費尋訪', style: TextStyle(color: Color(0xFF60A5FA), fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _buildDialogStatRow('總計投入', '${banner.freePulls} 抽'),
                _buildDialogStatRow('獲得 6★', '${banner.freeSixStarCount} 個'),
                if (banner.freeSixStarCount > 0) ...[
                  _buildDialogStatRow('出彩明細', '${banner.freeUpCount} UP / ${banner.freeOffCount} 歪'),
                  _buildDialogStatRow('平均出彩', banner.freeAvgStr),
                  _buildDialogStatRow('免費彩率', banner.freeRateStr),
                ],
              ],
              if (banner.freePulls > 0)
                _buildRarityBar(
                    banner.freePulls,
                    banner.freeSixStarCount,
                    banner.freeFiveStarCount,
                    banner.freeFourStarCount
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('關閉', style: TextStyle(color: Colors.white70)),
            ),
          ],
        );
      },
    );
  }

  // 小視窗內的排版輔助元件
  Widget _buildDialogStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
  /// 繪製橫向堆疊條形圖 (稀有度分布)
  Widget _buildRarityBar(int total, int stars6, int stars5, int stars4) {
    if (total == 0) return const SizedBox.shrink();

    // 如果有 3★ 或其他星級，算進 others
    final int others = total - stars6 - stars5 - stars4;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 6),
        const Text('稀有度分布', style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: 10,
            child: Row(
              children: [
                if (stars6 > 0) Expanded(flex: stars6, child: Container(color: const Color(0xFFFFCC00))),
                if (stars5 > 0) Expanded(flex: stars5, child: Container(color: const Color(0xFFA855F7))),
                if (stars4 > 0) Expanded(flex: stars4, child: Container(color: const Color(0xFF60A5FA))),
                if (others > 0) Expanded(flex: others, child: Container(color: Colors.white24)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('6★ ${(stars6 / total * 100).toStringAsFixed(1)}%', style: const TextStyle(color: Color(0xFFFFCC00), fontSize: 11, fontWeight: FontWeight.bold)),
            Text('5★ ${(stars5 / total * 100).toStringAsFixed(1)}%', style: const TextStyle(color: Color(0xFFA855F7), fontSize: 11, fontWeight: FontWeight.bold)),
            Text('4★ ${(stars4 / total * 100).toStringAsFixed(1)}%', style: const TextStyle(color: Color(0xFF60A5FA), fontSize: 11, fontWeight: FontWeight.bold)),
            if (others > 0)
              Text('其他 ${(others / total * 100).toStringAsFixed(1)}%', style: const TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 6),
      ],
    );
  }
}