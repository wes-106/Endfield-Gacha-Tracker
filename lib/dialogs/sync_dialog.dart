import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../services/local_storage.dart';
import '../services/backup_service.dart';
import '../services/data_parser.dart';
import '../models/gacha_record.dart';
import '../models/pool_config.dart';

class SyncDialog extends StatefulWidget {
  final String? savedAccountToken;
  final Map<String, List<String>> bannerUpMap;

  final Function(String newUid, Map<String, List<SubBannerGroup>> newPools)
  onSyncCompleted;
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

  /// 執行完整同步流程，取得遠端紀錄並合併至本機資料。
  Future<void> _startFullSync(
    Map<String, dynamic> role,
    String oauthToken,
  ) async {
    // 對話框關閉後仍需要透過 ScaffoldMessenger 顯示同步結果。
    final messenger = ScaffoldMessenger.of(context);

    final onSyncingChanged = widget.onSyncingChanged;
    final onStatusChanged = widget.onStatusChanged;
    final onSyncCompleted = widget.onSyncCompleted;

    final autoBackupEnabled = widget.autoBackupEnabled;
    final bannerUpMap = widget.bannerUpMap;

    // 取得 API 使用的原始 UID 與伺服器代號。
    final String realUid = role["uid"].toString();
    final String serverId = role["serverId"]?.toString() ?? '2';

    // 本機 UID 加上伺服器代號，區分同一帳號在不同伺服器的資料。
    final String localDbUid = '${realUid}_$serverId';

    Navigator.pop(context);
    onSyncingChanged(true);
    onStatusChanged('正在獲取伺服器授權...');

    try {
      // 使用原始 UID 與 OAuth Token 向鷹角取得 API 授權 Token。
      final finalU8Token = await AuthService.fetchU8Token(realUid, oauthToken);

      // 載入各卡池的本機紀錄，並彙整已存在的序號以避免重複取得。
      final Map<String, List<Map<String, dynamic>>> localDataMap = {};
      final Set<String> knownSeqIds = {};

      for (final config in appPoolConfigs) {
        final data = await LocalStorage.loadRecords(localDbUid, config.dbKey);

        localDataMap[config.uiKey] = List<Map<String, dynamic>>.from(data);

        for (var record in data) {
          knownSeqIds.add(record['seqId']?.toString() ?? '');
        }
      }

      // 取得角色卡池的新紀錄。
      onStatusChanged('正在檢查角色卡池新紀錄...');

      final charRecordsMap = await _apiService.fetchAllCharacters(
        finalU8Token,
        serverId,
        knownSeqIds,
      );

      onStatusChanged('資料整理中...');

      final Map<String, List<SubBannerGroup>> newPools = {};

      // 合併並儲存所有非武器卡池的紀錄。
      for (final config in appPoolConfigs.where((c) => !c.isWeapon)) {
        final merged = LocalStorage.mergeRecords(
          localDataMap[config.uiKey]!,
          charRecordsMap[config.uiKey] ?? [],
        );

        await LocalStorage.saveRecords(localDbUid, config.dbKey, merged);

        newPools[config.uiKey] = parseRawDataToModels(
          merged,
          bannerUpMap,
          isWeaponPool: config.isWeapon,
          poolCategory: config.uiKey,
        );
      }

      // 取得並合併武器卡池紀錄。
      onStatusChanged('角色紀錄完成！\n正在檢查武器卡池新紀錄...');

      final rawWeaponRecords = await _apiService.fetchWeaponRecords(
        finalU8Token,
        serverId,
        knownSeqIds,
      );

      final weaponConfig = appPoolConfigs.firstWhere(
        (config) => config.isWeapon,
      );

      final mergedWeapon = LocalStorage.mergeRecords(
        localDataMap[weaponConfig.uiKey]!,
        rawWeaponRecords,
      );

      await LocalStorage.saveRecords(
        localDbUid,
        weaponConfig.dbKey,
        mergedWeapon,
      );

      newPools[weaponConfig.uiKey] = parseRawDataToModels(
        mergedWeapon,
        bannerUpMap,
        isWeaponPool: true,
        poolCategory: weaponConfig.uiKey,
      );

      // 自動備份失敗不影響已完成的資料同步。
      bool backupSuccess = true;

      if (autoBackupEnabled) {
        try {
          onStatusChanged('正在執行自動備份...');
          await BackupService.saveAutoBackup(localDbUid);
        } catch (backupError) {
          backupSuccess = false;
        }
      }

      // 將同步完成的 UID 與各卡池資料交回呼叫端。
      onSyncCompleted(localDbUid, newPools);

      if (backupSuccess) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('🎉 尋訪紀錄同步完成！'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      } else {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('⚠️ 資料同步成功，但「自動備份」失敗。'),
            backgroundColor: Color(0xFFF59E0B),
            duration: Duration(seconds: 5),
          ),
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
          Text(
            '同步 / 導入尋訪紀錄',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 偵測到多個角色時，改為顯示伺服器與角色選擇清單。
            if (_availableRoles.isNotEmpty) ...[
              const Text(
                '✨ 偵測到多個伺服器紀錄，請點擊選擇要同步的帳號：',
                style: TextStyle(
                  color: Color(0xFFFFCC00),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E2029),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white12),
                ),
                // 使用透明 Material，讓 ListView 中的 ListTile 保有互動效果。
                child: Material(
                  color: Colors.transparent,
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _availableRoles.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1, color: Colors.white12),
                    itemBuilder: (context, index) {
                      final roleData = _availableRoles[index];

                      final serverName =
                          roleData['serverName']?.toString() ?? '未知伺服器';
                      final nickName =
                          roleData['nickName']?.toString() ?? '未知角色';
                      final uid = roleData['uid']?.toString() ?? '未知';

                      return ListTile(
                        hoverColor: Colors.white.withAlpha(15),
                        leading: const Icon(
                          Icons.person,
                          color: Color(0xFF60A5FA),
                        ),
                        title: Text(
                          '$serverName - $nickName',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          'UID: $uid',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                        trailing: const Icon(
                          Icons.chevron_right,
                          color: Colors.white54,
                        ),
                        onTap: () =>
                            _startFullSync(roleData, _workingOauthToken!),
                      );
                    },
                  ),
                ),
              ),
            ] else ...[
              // 尚未取得角色清單時，顯示 Token 輸入與操作說明。
              Container(
                padding: const EdgeInsets.all(10),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withAlpha(38),
                  border: Border.all(
                    color: const Color(0xFFEF4444).withAlpha(128),
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.public, color: Color(0xFFFCA5A5), size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '請注意：本工具目前僅適用於「終末地國際服 (Global)」，不支援陸服帳號資料解析。',
                        style: TextStyle(
                          color: Color(0xFFFCA5A5),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Text(
                '獲取 Token 流程：',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
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
                        try {
                          final launched = await launchUrl(
                            Uri.parse('https://user.gryphline.com/'),
                            mode: LaunchMode.externalApplication,
                          );

                          if (!launched && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('無法開啟網頁，請確認是否安裝或設定預設瀏覽器！'),
                                backgroundColor: Color(0xFFEF4444),
                              ),
                            );
                          }
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('無法開啟網頁，發生預期外的系統錯誤！'),
                              backgroundColor: Color(0xFFEF4444),
                            ),
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
                        child: Text(
                          '2. 獲取 Token',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                      onPressed: () async {
                        try {
                          final launched = await launchUrl(
                            Uri.parse(
                              'https://web-api.gryphline.com/cookie_store/account_token',
                            ),
                            mode: LaunchMode.externalApplication,
                          );

                          if (!launched && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('無法開啟網頁，請確認是否安裝或設定預設瀏覽器！'),
                                backgroundColor: Color(0xFFEF4444),
                              ),
                            );
                          }
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('無法開啟網頁，發生預期外的系統錯誤！'),
                              backgroundColor: Color(0xFFEF4444),
                            ),
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
              const Text(
                '3. 將獲取到的整段文字貼在下方：',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
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
              const SizedBox(height: 12),

              // 提醒使用者首次同步可能需要較長時間。
              const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.hourglass_empty, color: Colors.white54, size: 16),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '溫馨提示：初次導入由於需要獲取完整的歷史尋訪紀錄，可能會耗費較長時間，同步期間請勿關閉程式。',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
      actions: _availableRoles.isNotEmpty
          ? [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  '取消',
                  style: TextStyle(color: Colors.white54),
                ),
              ),
            ]
          : [
              TextButton(
                onPressed: _isFetchingRoles
                    ? null
                    : () => Navigator.pop(context),
                child: Text(
                  '取消',
                  style: TextStyle(
                    color: _isFetchingRoles ? Colors.white24 : Colors.white54,
                  ),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFCC00),
                ),
                onPressed: _isFetchingRoles
                    ? null
                    : () async {
                        final rawInput = _controller.text.trim();

                        if (rawInput.isEmpty) return;

                        setState(() {
                          _isFetchingRoles = true;
                        });

                        try {
                          final roleData = await AuthService.getAccountRoles(
                            rawInput,
                          );

                          final roles = roleData["roles"] as List<dynamic>;
                          final oauthToken = roleData["oauthToken"] as String;

                          if (roles.length == 1) {
                            // 只有一個角色時，直接開始同步，不顯示選擇清單。
                            _startFullSync(roles.first, oauthToken);
                          } else {
                            // 多個角色時，保存角色與授權 Token，切換至選擇清單。
                            setState(() {
                              _availableRoles = roles;
                              _workingOauthToken = oauthToken;
                              _isFetchingRoles = false;
                            });
                          }
                        } catch (e) {
                          if (!mounted) return;

                          setState(() {
                            _isFetchingRoles = false;
                          });

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                e.toString().replaceAll('Exception: ', ''),
                              ),
                              backgroundColor: const Color(0xFFEF4444),
                            ),
                          );
                        }
                      },
                child: _isFetchingRoles
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          color: Colors.black,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        '開始同步',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
    );
  }
}
