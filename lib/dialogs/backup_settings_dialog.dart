import 'dart:io';

import 'package:flutter/material.dart';

import '../services/backup_service.dart';
import '../services/local_storage.dart';

class BackupSettingsDialog extends StatefulWidget {
  final List<String> accountUids;
  final String? currentUid;
  final bool initialAutoBackupEnabled;
  final Future<void> Function(bool) onAutoBackupChanged;
  final Future<void> Function(String newUid) onReloadData;

  const BackupSettingsDialog({
    super.key,
    required this.accountUids,
    required this.currentUid,
    required this.initialAutoBackupEnabled,
    required this.onAutoBackupChanged,
    required this.onReloadData,
  });

  @override
  State<BackupSettingsDialog> createState() => _BackupSettingsDialogState();
}

class _BackupSettingsDialogState extends State<BackupSettingsDialog> {
  // 對話框內的自動備份開關狀態。
  late bool _autoBackupEnabled;

  @override
  void initState() {
    super.initState();
    _autoBackupEnabled = widget.initialAutoBackupEnabled;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF181920),
      title: const Row(
        children: [
          Icon(Icons.storage, color: Color(0xFF60A5FA), size: 22),
          SizedBox(width: 8),
          Text(
            '資料備份與管理',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 匯出 JSON 備份，可選擇要匯出的帳號。
            ListTile(
              leading: const Icon(Icons.upload_file, color: Color(0xFF60A5FA)),
              title: const Text(
                '匯出資料備份 (JSON)',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              onTap: () async {
                if (widget.accountUids.length > 1) {
                  final selectedUid = await showDialog<String>(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      backgroundColor: const Color(0xFF181920),
                      title: const Text(
                        '請點選要匯出的帳號',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: widget.accountUids
                            .map(
                              (uid) => ListTile(
                                leading: const Icon(
                                  Icons.person,
                                  color: Color(0xFF60A5FA),
                                ),
                                title: Text(
                                  'UID: $uid',
                                  style: TextStyle(
                                    color: uid == widget.currentUid
                                        ? const Color(0xFFFFCC00)
                                        : Colors.white,
                                    fontWeight: uid == widget.currentUid
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                                subtitle: uid == widget.currentUid
                                    ? const Text(
                                        '當前畫面顯示中',
                                        style: TextStyle(
                                          color: Colors.white54,
                                          fontSize: 12,
                                        ),
                                      )
                                    : null,
                                trailing: const Icon(
                                  Icons.upload_file,
                                  color: Colors.white54,
                                  size: 18,
                                ),
                                onTap: () => Navigator.pop(dialogContext, uid),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  );

                  // 帳號選擇完成且目前對話框仍存在時，才執行匯出。
                  if (selectedUid != null && context.mounted) {
                    await BackupService.exportBackupJson(context, selectedUid);

                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  }
                } else {
                  // 單一帳號直接匯出。
                  await BackupService.exportBackupJson(
                    context,
                    widget.currentUid,
                  );

                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                }
              },
            ),

            // 從 JSON 檔案匯入歷史備份。
            ListTile(
              leading: const Icon(Icons.folder_open, color: Color(0xFF34D399)),
              title: const Text(
                '導入歷史備份 (JSON)',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              onTap: () async {
                final success = await BackupService.importBackupFromFile(
                  context,
                  widget.currentUid,
                  widget.accountUids,
                  (newUid) async {
                    await widget.onReloadData(newUid);
                  },
                );

                if (success && context.mounted) {
                  Navigator.pop(context);
                }
              },
            ),

            const Divider(color: Colors.white12, height: 16),

            // 切換自動備份設定，並同步更新主畫面狀態與本機設定。
            SwitchListTile(
              secondary: const Icon(
                Icons.security_update_good,
                color: Color(0xFF34D399),
                size: 22,
              ),
              title: const Text(
                '每次同步後自動備份',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: const Text(
                '覆蓋舊檔，防止資料遺失',
                style: TextStyle(color: Colors.white54, fontSize: 11),
              ),
              value: _autoBackupEnabled,
              activeThumbColor: const Color(0xFFFFCC00),

              onChanged: (val) async {
                // 保存切換前的狀態，供失敗時還原。
                final previousValue = _autoBackupEnabled;

                // 先更新對話框 UI。
                setState(() => _autoBackupEnabled = val);

                final messenger = ScaffoldMessenger.of(context);

                try {
                  // 由 main.dart 統一處理主畫面狀態與本機設定儲存。
                  await widget.onAutoBackupChanged(val);

                  if (context.mounted) {
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(val ? '✅ 已開啟：每次同步後將自動備份' : '❌ 已關閉自動備份功能'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    // 儲存失敗，還原對話框狀態。
                    setState(() => _autoBackupEnabled = previousValue);

                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          '⚠️ 設定儲存失敗：'
                          '${e.toString().replaceAll('Exception: ', '')}',
                        ),
                        backgroundColor: const Color(0xFFEF4444),
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                }
              },
            ),

            // 使用最新的自動備份還原資料，完成後重新載入主畫面。
            ListTile(
              leading: const Icon(Icons.restore, color: Color(0xFFF59E0B)),
              title: const Text(
                '從最新的自動備份還原',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              onTap: () async {
                final success = await BackupService.restoreFromAutoBackup(
                  context,
                  widget.currentUid,
                  () async {
                    if (widget.currentUid != null) {
                      await widget.onReloadData(widget.currentUid!);
                    }
                  },
                );

                if (success && context.mounted) {
                  Navigator.pop(context);
                }
              },
            ),

            // 僅在 Windows 平台提供清除本機資料的功能。
            if (Platform.isWindows) ...[
              const Divider(color: Colors.white12, height: 16),
              ListTile(
                leading: const Icon(
                  Icons.delete_forever,
                  color: Color(0xFFEF4444),
                ),
                title: const Text(
                  '清除本機資料',
                  style: TextStyle(
                    color: Color(0xFFEF4444),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: const Text(
                  '重置 APP，不影響已匯出的備份',
                  style: TextStyle(color: Color(0xFFFCA5A5), fontSize: 11),
                ),
                onTap: () async {
                  // 執行刪除前，先要求使用者二次確認。
                  final bool? confirm = await showDialog<bool>(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      backgroundColor: const Color(0xFF181920),
                      title: const Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: Color(0xFFEF4444),
                          ),
                          SizedBox(width: 8),
                          Text('危險操作確認', style: TextStyle(color: Colors.white)),
                        ],
                      ),
                      content: const Text(
                        '此操作將會刪除：\n\n'
                        '• 抽卡紀錄\n'
                        '• 帳號綁定與偏好設定\n'
                        '• 圖片字典快取\n\n'
                        '您的手動與自動備份檔(.json)將被安全保留。\n'
                        '但上述本機資料一旦刪除將無法復原，確定要繼續嗎？',
                        style: TextStyle(
                          color: Colors.white70,
                          height: 1.5,
                          fontSize: 13,
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext, false),
                          child: const Text(
                            '取消',
                            style: TextStyle(color: Colors.white54),
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEF4444),
                          ),
                          onPressed: () => Navigator.pop(dialogContext, true),
                          child: const Text(
                            '確認清除',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    try {
                      // 關閉資料庫並刪除所有本機資料。
                      await LocalStorage.closeAndDeleteAllData();

                      // 刪除完成後顯示提示，要求使用者關閉程式。
                      if (context.mounted) {
                        await showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (_) => AlertDialog(
                            backgroundColor: const Color(0xFF181920),
                            title: const Row(
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: Color(0xFF10B981),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  '清除完成',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            content: const Text(
                              '所有本機資料已徹底刪除。\n'
                              '請點擊下方按鈕關閉程式以完成清除作業。',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                height: 1.5,
                              ),
                            ),
                            actions: [
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF10B981),
                                ),
                                onPressed: () {
                                  // 強制結束 Flutter 應用程式。
                                  exit(0);
                                },
                                child: const Text(
                                  '關閉程式',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                    } catch (e) {
                      // 刪除失敗時顯示錯誤訊息，保留目前畫面。
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '❌ 清除失敗：\n'
                              '${e.toString().replaceAll('Exception: ', '')}',
                            ),
                            backgroundColor: const Color(0xFFEF4444),
                            duration: const Duration(seconds: 4),
                          ),
                        );
                      }
                    }
                  }
                },
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('關閉', style: TextStyle(color: Colors.white54)),
        ),
      ],
    );
  }
}
