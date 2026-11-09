import 'package:flutter/material.dart';

import '../models/gacha_record.dart';
import '../widgets/rarity_distribution_bar.dart';

class SubBannerStatsDialog extends StatelessWidget {
  final SubBannerGroup banner;

  const SubBannerStatsDialog({super.key, required this.banner});

  @override
  Widget build(BuildContext context) {
    // 特許與重構卡池具有獨立的階段免費尋訪機制。
    final bool hasFreeMechanic =
        banner.poolCategory == 'Special' || banner.poolCategory == 'Refactor';

    return AlertDialog(
      backgroundColor: const Color(0xFF181920),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Colors.white12),
      ),
      title: Text(
        '【${banner.bannerName}】詳細統計',
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
            hasFreeMechanic ? '🔸 常規尋訪' : '🔸 尋訪統計',
            style: const TextStyle(
              color: Color(0xFFFFCC00),
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _buildDialogStatRow('總計投入', '${banner.regularPulls} 抽'),
          _buildDialogStatRow('獲得 6★', '${banner.regularSixStarCount} 個'),

          // 只有取得 6★ 時，才顯示 UP／歪明細與相關機率統計。
          if (banner.regularSixStarCount > 0) ...[
            _buildDialogStatRow(
              '出彩明細',
              '${banner.regularUpCount} UP / ${banner.regularOffCount} 歪',
            ),
            _buildDialogStatRow('平均出彩', banner.regularAvgStr),
            _buildDialogStatRow('常規彩率', banner.regularRateStr),
          ],

          // 有常規尋訪紀錄時，顯示稀有度分布。
          if (banner.regularPulls > 0)
            RarityDistributionBar(
              total: banner.regularPulls,
              stars6: banner.regularSixStarCount,
              stars5: banner.regularFiveStarCount,
              stars4: banner.regularFourStarCount,
            ),

          // 有免費尋訪紀錄時，才顯示獨立的免費尋訪統計。
          if (banner.freePulls > 0) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(color: Colors.white12, height: 1),
            ),
            const Text(
              '🔹 階段免費尋訪',
              style: TextStyle(
                color: Color(0xFF60A5FA),
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildDialogStatRow('總計投入', '${banner.freePulls} 抽'),
            _buildDialogStatRow('獲得 6★', '${banner.freeSixStarCount} 個'),

            // 免費尋訪取得 6★ 時，才顯示其 UP／歪明細與相關統計。
            if (banner.freeSixStarCount > 0) ...[
              _buildDialogStatRow(
                '出彩明細',
                '${banner.freeUpCount} UP / ${banner.freeOffCount} 歪',
              ),
              _buildDialogStatRow('平均出彩', banner.freeAvgStr),
              _buildDialogStatRow('免費彩率', banner.freeRateStr),
            ],
          ],

          // 有免費尋訪紀錄時，顯示免費尋訪的稀有度分布。
          if (banner.freePulls > 0)
            RarityDistributionBar(
              total: banner.freePulls,
              stars6: banner.freeSixStarCount,
              stars5: banner.freeFiveStarCount,
              stars4: banner.freeFourStarCount,
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
  Widget _buildDialogStatRow(String label, String value) {
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
