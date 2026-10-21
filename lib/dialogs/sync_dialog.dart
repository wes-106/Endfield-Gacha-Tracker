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

  bool _isFetchingRoles = false;
  List<dynamic> _availableRoles = [];
  String? _workingOauthToken;

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

  /// 執行最終的抽卡資料獲取與寫入
  Future<void> _startFullSync(Map<String, dynamic> role, String oauthToken) async {
    final messenger = ScaffoldMessenger.of(context);
    final onSyncingChanged = widget.onSyncingChanged;
    final onStatusChanged = widget.onStatusChanged;
    final onSyncCompleted = widget.onSyncCompleted;
    final autoBackupEnabled = widget.autoBackupEnabled;
    final bannerUpMap = widget.bannerUpMap;

    // 1. 取得 API 需要的真實 Gryphline UID
    final String realUid = role["uid"].toString();
    final String serverId = role["serverId"]?.toString() ?? '2';

    // 2. 為了防止同一帳號的雙伺服器紀錄在本地資料庫互撞覆蓋，
    // 我們將本地儲存用的 UID 加上伺服器代號後綴 (例如 123456789_2)
    final String localDbUid = '${realUid}_$serverId';

    // UI 開始轉圈圈，並關閉對話框
    Navigator.pop(context);
    onSyncingChanged(true);
    onStatusChanged('正在獲取伺服器授權...');

    try {
      // 拿真實的 UID 去向鷹角換 Token
      final finalU8Token = await AuthService.fetchU8Token(realUid, oauthToken);

      // 下面所有 LocalStorage 的讀取與寫入，全部改用 localDbUid
      final localSpecial = await LocalStorage.loadRecords(localDbUid, 'pool_special');
      final localRefactor = await LocalStorage.loadRecords(localDbUid, 'pool_refactor');
      final localStandard = await LocalStorage.loadRecords(localDbUid, 'pool_standard');
      final localWeapon = await LocalStorage.loadRecords(localDbUid, 'pool_weapon');
      final localBeginner = await LocalStorage.loadRecords(localDbUid, 'pool_beginner');

      Set<String> knownSeqIds = {};
      for (var list in [localSpecial, localRefactor, localStandard, localWeapon, localBeginner]) {
        for (var r in list) { knownSeqIds.add(r['seqId']?.toString() ?? ''); }
      }

      onStatusChanged('正在檢查角色卡池新紀錄...');
      final charRecordsMap = await _apiService.fetchAllCharacters(finalU8Token, serverId, knownSeqIds);

      final mergedSpecial = LocalStorage.mergeRecords(localSpecial, charRecordsMap['Special'] ?? []);
      await LocalStorage.saveRecords(localDbUid, 'pool_special', mergedSpecial);

      final mergedRefactor = LocalStorage.mergeRecords(localRefactor, charRecordsMap['Refactor'] ?? []);
      await LocalStorage.saveRecords(localDbUid, 'pool_refactor', mergedRefactor);

      final mergedStandard = LocalStorage.mergeRecords(localStandard, charRecordsMap['Standard'] ?? []);
      await LocalStorage.saveRecords(localDbUid, 'pool_standard', mergedStandard);

      final mergedBeginner = LocalStorage.mergeRecords(localBeginner, charRecordsMap['Beginner'] ?? []);
      await LocalStorage.saveRecords(localDbUid, 'pool_beginner', mergedBeginner);

      final parsedSpecial = parseRawDataToModels(mergedSpecial, bannerUpMap, isWeaponPool: false);
      final parsedRefactor = parseRawDataToModels(mergedRefactor, bannerUpMap, isWeaponPool: false);
      final parsedStandard = parseRawDataToModels(mergedStandard, bannerUpMap, isWeaponPool: false);
      final parsedBeginner = parseRawDataToModels(mergedBeginner, bannerUpMap, isWeaponPool: false);

      onStatusChanged('角色紀錄完成！\n正在檢查武器卡池新紀錄...');
      final rawWeaponRecords = await _apiService.fetchWeaponRecords(finalU8Token, serverId, knownSeqIds);

      final mergedWeapon = LocalStorage.mergeRecords(localWeapon, rawWeaponRecords);
      await LocalStorage.saveRecords(localDbUid, 'pool_weapon', mergedWeapon);
      final parsedWeaponBanners = parseRawDataToModels(mergedWeapon, bannerUpMap, isWeaponPool: true);

      onStatusChanged('資料整理中...');
      final Map<String, List<SubBannerGroup>> newPools = {
        'Special': parsedSpecial,
        'Refactor': parsedRefactor,
        'Standard': parsedStandard,
        'Weapon': parsedWeaponBanners,
        'Beginner': parsedBeginner,
      };

      bool backupSuccess = true;
      if (autoBackupEnabled) {
        try {
          onStatusChanged('正在執行自動備份...');
          await BackupService.saveAutoBackup(localDbUid); // 改為 localDbUid
        } catch (backupError) {
          backupSuccess = false;
        }
      }

      onSyncCompleted(localDbUid, newPools);

      if (backupSuccess) {
        messenger.showSnackBar(const SnackBar(content: Text('🎉 尋訪紀錄同步完成！'), backgroundColor: Color(0xFF10B981)));
      } else {
        messenger.showSnackBar(
          const SnackBar(content: Text('⚠️ 資料同步成功，但「自動備份」失敗。'), backgroundColor: Color(0xFFF59E0B), duration: Duration(seconds: 5)),
        );
      }
    } catch (e) {
      final errorMsg = e.toString().replaceAll('Exception: ', '');
      onStatusChanged('同步失敗：$errorMsg');
      messenger.showSnackBar(
        SnackBar(
          content: Text('❌ 同步失敗：$errorMsg'),
          backgroundColor: const Color(0xFFEF4444),
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      onSyncingChanged(false);
    }
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
            // 若偵測到多個角色，UI 切換為選單
            if (_availableRoles.isNotEmpty) ...[
              const Text('✨ 偵測到多個伺服器紀錄，請點擊選擇要同步的帳號：', style: TextStyle(color: Color(0xFFFFCC00), fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 12),
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E2029),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white12),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _availableRoles.length,
                  separatorBuilder: (context, index) => const Divider(height: 1, color: Colors.white12),
                    itemBuilder: (context, index) {
                      final roleData = _availableRoles[index];

                      // 直接讀取展平後的資料
                      final serverName = roleData['serverName']?.toString() ?? '未知伺服器';
                      final nickName = roleData['nickName']?.toString() ?? '未知角色';
                      final uid = roleData['uid']?.toString() ?? '未知';

                      return ListTile(
                        hoverColor: Colors.white.withAlpha(15),
                        leading: const Icon(Icons.person, color: Color(0xFF60A5FA)),
                        title: Text('$serverName - $nickName', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: Text('UID: $uid', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                        trailing: const Icon(Icons.chevron_right, color: Colors.white54),
                        onTap: () => _startFullSync(roleData, _workingOauthToken!),
                      );
                    },
                ),
              ),
            ] else ...[
              // 原始輸入介面
              Container(
                padding: const EdgeInsets.all(10),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withAlpha(38),
                  border: Border.all(color: const Color(0xFFEF4444).withAlpha(128)),
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
                      label: const FittedBox(fit: BoxFit.scaleDown, child: Text('1. 登入官網', style: TextStyle(fontSize: 12))),
                      onPressed: () async {
                        try {
                          await launchUrl(Uri.parse('https://user.gryphline.com/'), mode: LaunchMode.externalApplication);
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('無法開啟網頁，請確認是否安裝瀏覽器！')));
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
                      label: const FittedBox(fit: BoxFit.scaleDown, child: Text('2. 獲取 Token', style: TextStyle(fontSize: 12))),
                      onPressed: () async {
                        try {
                          await launchUrl(Uri.parse('https://web-api.gryphline.com/cookie_store/account_token'), mode: LaunchMode.externalApplication);
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('無法開啟網頁，請確認是否安裝瀏覽器！')));
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
                decoration: const InputDecoration(hintText: '例如: {"data":{"content":"KcjPLsX..."}} 或純字串', border: OutlineInputBorder()),
              ),

              const SizedBox(height: 12),

              // 下方溫馨提示 (沙漏圖示與說明)
              const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.hourglass_empty, color: Colors.white54, size: 16),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '溫馨提示：初次導入由於需要獲取完整的歷史尋訪紀錄，可能會耗費較長時間，同步期間請勿關閉程式。',
                      style: TextStyle(color: Colors.white54, fontSize: 12, height: 1.4),
                    ),
                  ),
                ],
              ),
            ]
          ],
        ),
      ),
      actions: _availableRoles.isNotEmpty
          ? [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消', style: TextStyle(color: Colors.white54))),
      ]
          : [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消', style: TextStyle(color: Colors.white54))),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFCC00)),
          onPressed: _isFetchingRoles
              ? null
              : () async {
            final rawInput = _controller.text.trim();
            if (rawInput.isEmpty) return;

            setState(() { _isFetchingRoles = true; });

            try {
              final roleData = await AuthService.getAccountRoles(rawInput);
              final roles = roleData["roles"] as List<dynamic>;
              final oauthToken = roleData["oauthToken"] as String;

              if (roles.length == 1) {
                // 只有一個角色，跳過選擇直接開始同步
                _startFullSync(roles.first, oauthToken);
              } else {
                // 有多個角色，更新對話框 UI 顯示選單
                setState(() {
                  _availableRoles = roles;
                  _workingOauthToken = oauthToken;
                  _isFetchingRoles = false;
                });
              }
            } catch (e) {
              setState(() { _isFetchingRoles = false; });
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: const Color(0xFFEF4444)));
            }
          },
          child: _isFetchingRoles
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
              : const Text('開始同步', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}