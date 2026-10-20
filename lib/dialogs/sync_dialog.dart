import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../services/local_storage.dart';
import '../services/backup_service.dart';
import '../services/data_parser.dart';
import '../models/gacha_record.dart';

class SyncDialog extends StatefulWidget {
  final String? savedAccountToken;
  final Map<String, List<String>> bannerUpMap;
  // 回調函數：同步完成後通知主畫面更新狀態與資料
  final Function(String newUid, Map<String, List<SubBannerGroup>> newPools) onSyncCompleted;
  final Function(String statusText) onStatusChanged;
  final Function(bool isSyncing) onSyncingChanged;
  final bool autoBackupEnabled;

  const SyncDialog({
    super.key,
    required this.savedAccountToken,
    required this.bannerUpMap,
    required this.onSyncCompleted,
    required this.onStatusChanged,
    required this.onSyncingChanged,
    required this.autoBackupEnabled,
  });

  @override
  State<SyncDialog> createState() => _SyncDialogState();
}

class _SyncDialogState extends State<SyncDialog> {
  late final TextEditingController _controller;
  final GachaApiService _apiService = GachaApiService();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.savedAccountToken ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF181920),
      title: const Row(
        children: [
          Icon(Icons.sync, color: Color(0xFFFFCC00), size: 20),
          SizedBox(width: 8),
          Text('同步 / 導入尋訪紀錄', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        ],
      ),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.5)),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Row(
                children: [
                  Icon(Icons.public, color: Color(0xFFFCA5A5), size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '請注意：本工具目前僅適用於「終末地國際服 (Global)」，不支援陸服或 B 服帳號資料解析。',
                      style: TextStyle(color: Color(0xFFFCA5A5), fontSize: 12, fontWeight: FontWeight.bold, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const Text('獲取 Token 流程：', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF252732),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    icon: const Icon(Icons.login, size: 16),
                    label: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('1. 登入官網', style: TextStyle(fontSize: 12)),
                    ),
                    onPressed: () async {
                      final url = Uri.parse('https://user.gryphline.com/');
                      try {
                        await launchUrl(url, mode: LaunchMode.externalApplication);
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('無法開啟網頁，請確認手機是否已安裝瀏覽器！')),
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF252732),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    icon: const Icon(Icons.content_copy, size: 16),
                    label: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('2. 獲取 Token', style: TextStyle(fontSize: 12)),
                    ),
                    onPressed: () async {
                      final url = Uri.parse('https://web-api.gryphline.com/cookie_store/account_token');
                      try {
                        await launchUrl(url, mode: LaunchMode.externalApplication);
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('無法開啟網頁，請確認手機是否已安裝瀏覽器！')),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(color: Colors.white12),
            ),
            const Text('3. 將獲取到的整段文字貼在下方：', style: TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 8),
            TextField(
              controller: _controller,
              maxLines: 4,
              style: const TextStyle(fontSize: 12),
              decoration: const InputDecoration(
                hintText: '例如: {"data":{"content":"KcjPLsX..."}} 或純字串',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.hourglass_bottom, color: Colors.white54, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '溫馨提示：初次導入由於需要獲取完整的歷史尋訪紀錄，可能會耗費較多時間，同步期間請勿關閉程式。',
                    style: TextStyle(color: Colors.white54, fontSize: 12, height: 1.4),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消', style: TextStyle(color: Colors.white54)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFCC00)),
          onPressed: () async {
            final rawInput = _controller.text.trim();
            if (rawInput.isEmpty) return;

            final dialogContext = context;
            Navigator.pop(dialogContext); // 關閉對話框

            widget.onSyncingChanged(true);
            widget.onStatusChanged('正在解析帳號驗證碼...\n(初次同步較耗時，請耐心等候)');

            try {
              final authResult = await AuthService.getU8Token(rawInput);
              final finalU8Token = authResult["token"]!;
              final fetchedUid = authResult["uid"]!;

              // 讀取舊資料提供增量更新防護網
              final localSpecial = await LocalStorage.loadRecords(fetchedUid, 'pool_special');
              final localRefactor = await LocalStorage.loadRecords(fetchedUid, 'pool_refactor');
              final localStandard = await LocalStorage.loadRecords(fetchedUid, 'pool_standard');
              final localWeapon = await LocalStorage.loadRecords(fetchedUid, 'pool_weapon');
              final localBeginner = await LocalStorage.loadRecords(fetchedUid, 'pool_beginner');

              Set<String> knownSeqIds = {};
              for (var list in [localSpecial, localRefactor, localStandard, localWeapon, localBeginner]) {
                for (var r in list) {
                  knownSeqIds.add(r['seqId']?.toString() ?? '');
                }
              }

              // 階段 1：角色池
              widget.onStatusChanged('正在檢查角色卡池新紀錄...');
              final charRecordsMap = await _apiService.fetchAllCharacters(finalU8Token, knownSeqIds);

              final mergedSpecial = LocalStorage.mergeRecords(localSpecial, charRecordsMap['Special'] ?? []);
              await LocalStorage.saveRecords(fetchedUid, 'pool_special', mergedSpecial);

              final mergedRefactor = LocalStorage.mergeRecords(localRefactor, charRecordsMap['Refactor'] ?? []);
              await LocalStorage.saveRecords(fetchedUid, 'pool_refactor', mergedRefactor);

              final mergedStandard = LocalStorage.mergeRecords(localStandard, charRecordsMap['Standard'] ?? []);
              await LocalStorage.saveRecords(fetchedUid, 'pool_standard', mergedStandard);

              final mergedBeginner = LocalStorage.mergeRecords(localBeginner, charRecordsMap['Beginner'] ?? []);
              await LocalStorage.saveRecords(fetchedUid, 'pool_beginner', mergedBeginner);

              final parsedSpecial = parseRawDataToModels(mergedSpecial, widget.bannerUpMap, isWeaponPool: false);
              final parsedRefactor = parseRawDataToModels(mergedRefactor, widget.bannerUpMap, isWeaponPool: false);
              final parsedStandard = parseRawDataToModels(mergedStandard, widget.bannerUpMap, isWeaponPool: false);
              final parsedBeginner = parseRawDataToModels(mergedBeginner, widget.bannerUpMap, isWeaponPool: false);

              // 階段 2：武器池
              widget.onStatusChanged('角色紀錄完成！\n正在檢查武器卡池新紀錄...');
              final rawWeaponRecords = await _apiService.fetchWeaponRecords(finalU8Token, knownSeqIds);

              final mergedWeapon = LocalStorage.mergeRecords(localWeapon, rawWeaponRecords);
              await LocalStorage.saveRecords(fetchedUid, 'pool_weapon', mergedWeapon);
              final parsedWeaponBanners = parseRawDataToModels(mergedWeapon, widget.bannerUpMap, isWeaponPool: true);

              // 階段 3：資料整理
              widget.onStatusChanged('資料整理中...');
              final Map<String, List<SubBannerGroup>> newPools = {
                'Special': parsedSpecial,
                'Refactor': parsedRefactor,
                'Standard': parsedStandard,
                'Weapon': parsedWeaponBanners,
                'Beginner': parsedBeginner,
              };

              // 若開啟自動備份則在背景存檔
              if (widget.autoBackupEnabled) {
                await BackupService.saveAutoBackup(fetchedUid);
              }

              widget.onSyncCompleted(fetchedUid, newPools);
              widget.onSyncingChanged(false);

              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('🎉 尋訪紀錄同步完成！'), backgroundColor: Color(0xFF10B981)),
              );
            } catch (e) {
              if (!context.mounted) return;
              widget.onSyncingChanged(false);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('❌ 錯誤：$e'), backgroundColor: const Color(0xFFEF4444)),
              );
            }
          },
          child: const Text('開始同步', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}