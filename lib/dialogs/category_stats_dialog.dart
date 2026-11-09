import 'package:flutter/material.dart';

import '../models/gacha_record.dart';
import '../widgets/rarity_distribution_bar.dart';

class CategoryStatsDialog extends StatelessWidget {
  final String poolTitle;
  final List<SubBannerGroup> banners;

  const CategoryStatsDialog({
    super.key,
    required this.poolTitle,
    required this.banners,
  });

  @override
  Widget build(BuildContext context) {
    // 彙總所有子卡池的常規尋訪數據。
    final int regPulls = banners.fold(0, (sum, b) => sum + b.regularPulls);
    final int regSixStars = banners.fold(
      0,
      (sum, b) => sum + b.regularSixStarCount,
    );
    final int regUp = banners.fold(0, (sum, b) => sum + b.regularUpCount);
    final int regOff = banners.fold(0, (sum, b) => sum + b.regularOffCount);
    final double regAvg = regSixStars > 0 ? (regPulls / regSixStars) : 0.0;
    final double regRate = regPulls > 0
        ? ((regSixStars / regPulls) * 100)
        : 0.0;
    final int regFiveStars = banners.fold(
      0,
      (sum, b) => sum + b.regularFiveStarCount,
    );
    final int regFourStars = banners.fold(
      0,
      (sum, b) => sum + b.regularFourStarCount,
    );

    // 彙總所有子卡池的免費尋訪數據。
    final int freePulls = banners.fold(0, (sum, b) => sum + b.freePulls);
    final int freeSixStars = banners.fold(
      0,
      (sum, b) => sum + b.freeSixStarCount,
    );
    final int freeUp = banners.fold(0, (sum, b) => sum + b.freeUpCount);
    final int freeOff = banners.fold(0, (sum, b) => sum + b.freeOffCount);
    final double freeAvg = freeSixStars > 0 ? (freePulls / freeSixStars) : 0.0;
    final double freeRate = freePulls > 0
        ? ((freeSixStars / freePulls) * 100)
        : 0.0;
    final int freeFiveStars = banners.fold(
      0,
      (sum, b) => sum + b.freeFiveStarCount,
    );
    final int freeFourStars = banners.fold(
      0,
      (sum, b) => sum + b.freeFourStarCount,
    );

    // 判斷卡池是否具有獨立的免費尋訪機制。
    final bool hasFreeMechanic = poolTitle == '特許尋訪' || poolTitle == '重構尋訪';

    return AlertDialog(
      backgroundColor: const Color(0xFF181920),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Colors.white12),
      ),
      title: Text(
        '【$poolTitle】總和統計',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 常規尋訪統計。
          Text(
            hasFreeMechanic ? '🔸 歷史常規尋訪' : '🔸 歷史尋訪統計',
            style: const TextStyle(
              color: Color(0xFFFFCC00),
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _buildMiniStatRow('總計投入', '$regPulls 抽'),
          _buildMiniStatRow('獲得 6★', '$regSixStars 個'),
          if (regSixStars > 0) ...[
            _buildMiniStatRow('出彩明細', '$regUp UP / $regOff 歪'),
            _buildMiniStatRow('綜合平均', '${regAvg.toStringAsFixed(1)} 抽'),
            _buildMiniStatRow('綜合彩率', '${regRate.toStringAsFixed(2)}%'),
          ],
          if (regPulls > 0)
            RarityDistributionBar(
              total: regPulls,
              stars6: regSixStars,
              stars5: regFiveStars,
              stars4: regFourStars,
            ),

          // 有免費尋訪紀錄時，額外顯示免費尋訪統計。
          if (freePulls > 0) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(color: Colors.white12, height: 1),
            ),
            const Text(
              '🔹 歷史免費尋訪',
              style: TextStyle(
                color: Color(0xFF60A5FA),
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildMiniStatRow('總計投入', '$freePulls 抽'),
            _buildMiniStatRow('獲得 6★', '$freeSixStars 個'),
            if (freeSixStars > 0) ...[
              _buildMiniStatRow('出彩明細', '$freeUp UP / $freeOff 歪'),
              _buildMiniStatRow('綜合平均', '${freeAvg.toStringAsFixed(1)} 抽'),
              _buildMiniStatRow('綜合彩率', '${freeRate.toStringAsFixed(2)}%'),
            ],
          ],
          if (freePulls > 0)
            RarityDistributionBar(
              total: freePulls,
              stars6: freeSixStars,
              stars5: freeFiveStars,
              stars4: freeFourStars,
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
  }

  /// 建立左右排列的統計數值列。
  Widget _buildMiniStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 13),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
