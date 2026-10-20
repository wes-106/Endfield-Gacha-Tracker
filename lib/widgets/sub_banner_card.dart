import 'package:flutter/material.dart';
// 引入資料模型
import '../models/gacha_record.dart';

class SubBannerCard extends StatelessWidget {
  final SubBannerGroup banner;
  final bool forceDesktop;
  final Map<String, String> characterAvatarMap;
  final Map<String, String> weaponAvatarMap;

  const SubBannerCard({
    super.key,
    required this.banner,
    this.forceDesktop = false,
    required this.characterAvatarMap,
    required this.weaponAvatarMap,
  });

  // 🟢 抽出原本的顏色計算邏輯
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

                if (isMobileCard) {
                  // 手機版排版：標題在第一行，第二行使用橫向滑動
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      titleRow,
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildBannerBadge('本池投入', '${banner.totalPulls} 抽', isHighlight: true),
                            const SizedBox(width: 8),
                            _buildBannerBadge('本池 6★', '${banner.actualSixStarCount} 個'),
                            const SizedBox(width: 8),
                            _buildBannerBadge('平均出彩', banner.avgPityStr),
                          ],
                        ),
                      ),
                    ],
                  );
                } else {
                  // 電腦版排版：維持原本的左右兩端對齊 (Wrap)
                  return Wrap(
                    spacing: 16,
                    runSpacing: 10,
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      titleRow,
                      Wrap(
                        spacing: 10,
                        children: [
                          _buildBannerBadge('本池投入', '${banner.totalPulls} 抽', isHighlight: true),
                          _buildBannerBadge('本池 6★', '${banner.actualSixStarCount} 個'),
                          _buildBannerBadge('平均出彩', banner.avgPityStr),
                        ],
                      ),
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
                    const Text(
                      '小保底',
                      style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12),
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
                      '此卡池常規區間目前尚無 6★ 出金紀錄',
                      style: TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                  )
                else
                  ...banner.sixStars.map((item) => _buildPityPillRow(item, banner.hardPityLimit)),
                if (banner.hasFree10Section) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(color: Colors.white12, height: 1),
                  ),
                  const Text(
                    '30 抽後贈送十連尋訪',
                    style: TextStyle(color: Color(0xFF60A5FA), fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                  const SizedBox(height: 10),
                  if (banner.free10SixStars.isEmpty)
                    _buildEmptyFree10Row()
                  else
                    ...banner.free10SixStars.map((item) => _buildPityPillRow(item, 10)),
                ],
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
          if (item.isFree)
            _buildTagBadge('免', const Color(0xFF3B82F6))
          else
            _buildTagBadge(item.isUp ? 'UP' : '歪', item.isUp ? const Color(0xFFFFCC00) : const Color(0xFFEF4444)),
        ],
      ),
    );
  }

  /// 構建 30 抽後贈送的十連尋訪中，若未出 6★ 時的「未出彩」佔位提示列
  Widget _buildEmptyFree10Row() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF1E2029),
              border: Border.all(color: const Color(0xFF3B82F6), width: 1.5),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.help_outline, color: Color(0xFF60A5FA), size: 20),
          ),
          const SizedBox(width: 10),
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
                color: const Color(0xFF14151B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _buildTagBadge('免', const Color(0xFF3B82F6)),
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
}