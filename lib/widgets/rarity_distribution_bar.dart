import 'package:flutter/material.dart';

class RarityDistributionBar extends StatelessWidget {
  final int total;
  final int stars6;
  final int stars5;
  final int stars4;

  const RarityDistributionBar({
    super.key,
    required this.total,
    required this.stars6,
    required this.stars5,
    required this.stars4,
  });

  @override
  Widget build(BuildContext context) {
    // 沒有任何紀錄時，不顯示分布圖。
    if (total == 0) return const SizedBox.shrink();

    // 未列入 4★、5★、6★ 的數量統一歸類為其他。
    final int others = total - stars6 - stars5 - stars4;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 6),
        const Text(
          '稀有度分布',
          style: TextStyle(
            color: Colors.white54,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: 14,
            child: Row(
              children: [
                if (stars6 > 0)
                  Expanded(
                    flex: stars6,
                    child: Container(color: const Color(0xFFFFCC00)),
                  ),
                if (stars5 > 0)
                  Expanded(
                    flex: stars5,
                    child: Container(color: const Color(0xFFA855F7)),
                  ),
                if (stars4 > 0)
                  Expanded(
                    flex: stars4,
                    child: Container(color: const Color(0xFF60A5FA)),
                  ),
                if (others > 0)
                  Expanded(
                    flex: others,
                    child: Container(color: Colors.white24),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '6★ ${(stars6 / total * 100).toStringAsFixed(1)}%',
              style: const TextStyle(
                color: Color(0xFFFFCC00),
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '5★ ${(stars5 / total * 100).toStringAsFixed(1)}%',
              style: const TextStyle(
                color: Color(0xFFA855F7),
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '4★ ${(stars4 / total * 100).toStringAsFixed(1)}%',
              style: const TextStyle(
                color: Color(0xFF60A5FA),
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (others > 0)
              Text(
                '其他 ${(others / total * 100).toStringAsFixed(1)}%',
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
      ],
    );
  }
}
