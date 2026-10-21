import 'package:flutter/material.dart';
import '../dialogs/info_dialogs.dart';
import '../services/backup_service.dart';

class AppDrawer extends StatelessWidget {
  final String? currentUid;
  final List<String> accountUids;
  final bool isSyncing;
  final bool autoBackupEnabled;

  // 各種按鈕的回調函數
  final Function(String) onUidChanged;
  final VoidCallback onExportPressed;
  final VoidCallback onSyncPressed;
  final Function(bool) onAutoBackupChanged;
  final VoidCallback onReloadRequested;

  const AppDrawer({
    super.key,
    required this.currentUid,
    required this.accountUids,
    required this.isSyncing,
    required this.autoBackupEnabled,
    required this.onUidChanged,
    required this.onExportPressed,
    required this.onSyncPressed,
    required this.onAutoBackupChanged,
    required this.onReloadRequested,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF14151B),
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Color(0xFF181920),
              border: Border(bottom: BorderSide(color: Colors.white12)),
            ),
            child: SizedBox(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    width: 24, height: 4, color: const Color(0xFFFFCC00), margin: const EdgeInsets.only(bottom: 8),
                  ),
                  const Text('ENDFIELD', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                  const Text('尋訪紀錄終端', style: TextStyle(color: Colors.white54, fontSize: 14)),
                ],
              ),
            ),
          ),
          if (accountUids.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '切換帳號',
                    style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  if (accountUids.isNotEmpty)
                    PopupMenuButton<String>(
                      initialValue: currentUid,
                      tooltip: '',
                      position: PopupMenuPosition.under,
                      constraints: const BoxConstraints(minWidth: 170, maxWidth: 170),
                      color: const Color(0xFF2A2D36),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Colors.white12),
                      ),
                      child: Container(
                        width: 170,
                        height: 30,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E2029),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'UID: ${currentUid ?? "未知"}',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_drop_down, color: Color(0xFFFFCC00), size: 18),
                          ],
                        ),
                      ),
                      itemBuilder: (context) => accountUids.map((uid) => PopupMenuItem<String>(
                        value: uid,
                        height: 40,
                        padding: EdgeInsets.zero,
                        child: Center(
                          child: Text(
                            'UID: $uid',
                            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ),
                      )).toList(),
                      onSelected: (newUid) {
                        if (newUid != currentUid) {
                          onUidChanged(newUid);
                        }
                      },
                    ),
                ],
              ),
            ),
          if (accountUids.isNotEmpty) const Divider(color: Colors.white12, height: 16),

          ListTile(
            leading: Icon(Icons.sync, color: isSyncing ? Colors.white24 : const Color(0xFFFFCC00)),
            title: Text('同步尋訪紀錄', style: TextStyle(color: isSyncing ? Colors.white24 : Colors.white, fontWeight: FontWeight.bold)),
            onTap: isSyncing ? null : () { Navigator.pop(context); onSyncPressed(); },
          ),
          ListTile(
            leading: Icon(Icons.download, color: isSyncing ? Colors.white24 : const Color(0xFF60A5FA)),
            title: Text('導出圖片', style: TextStyle(color: isSyncing ? Colors.white24 : Colors.white, fontWeight: FontWeight.bold)),
            onTap: isSyncing ? null : () { Navigator.pop(context); onExportPressed(); },
          ),
          ListTile(
            leading: const Icon(Icons.upload_file, color: Color(0xFF60A5FA)),
            title: const Text('匯出資料備份 (JSON)', style: TextStyle(color: Colors.white70, fontSize: 13)),
            onTap: () async {
              // 如果有超過一個帳號，彈出選擇對話框；否則直接匯出
              if (accountUids.length > 1) {
                final selectedUid = await showDialog<String>(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    backgroundColor: const Color(0xFF181920),
                    title: const Text('請點選要匯出的帳號', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: accountUids.map((uid) => ListTile(
                        leading: const Icon(Icons.person, color: Color(0xFF60A5FA)),
                        title: Text(
                            'UID: $uid',
                            style: TextStyle(
                              // 當前帳號用特別的顏色標註
                                color: uid == currentUid ? const Color(0xFFFFCC00) : Colors.white,
                                fontWeight: uid == currentUid ? FontWeight.bold : FontWeight.normal
                            )
                        ),
                        // 用副標題提示哪個是當前帳號
                        subtitle: uid == currentUid ? const Text('當前畫面顯示中', style: TextStyle(color: Colors.white54, fontSize: 12)) : null,
                        // 右側統一放一個「匯出」的小圖示，暗示點擊行為
                        trailing: const Icon(Icons.upload_file, color: Colors.white54, size: 18),
                        onTap: () => Navigator.pop(dialogContext, uid),
                      )).toList(),
                    ),
                  ),
                );
                if (selectedUid != null && context.mounted) {
                  await BackupService.exportBackupJson(context, selectedUid);
                  if (context.mounted) Navigator.pop(context); // 執行完再關閉側邊欄
                }
              } else {
                await BackupService.exportBackupJson(context, currentUid);
                if (context.mounted) Navigator.pop(context);
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.folder_open, color: Color(0xFF34D399)),
            title: const Text('導入歷史備份 (JSON)', style: TextStyle(color: Colors.white70, fontSize: 13)),
            onTap: () async {
              // 【修復 Bug】移除先 pop 的動作，保持 context 存活，直到 await 結束
              await BackupService.importBackupFromFile(context, currentUid, accountUids, (newUid) {
                if (newUid != currentUid) {
                  onUidChanged(newUid);
                } else {
                  onReloadRequested();
                }
              });

              // 全部讀取、驗證、寫入完畢後，安全地關閉側邊欄
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.restore, color: Color(0xFFF59E0B)),
            title: const Text('從最新的自動備份還原', style: TextStyle(color: Colors.white70, fontSize: 13)),
            onTap: () async {
              await BackupService.restoreFromAutoBackup(context, currentUid, () => onReloadRequested());
              if (context.mounted) Navigator.pop(context);
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.security_update_good, color: Color(0xFF34D399), size: 20),
            title: const Text('每次同步後自動備份', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            subtitle: const Text('自動覆蓋舊檔，防止資料遺失', style: TextStyle(color: Colors.white54, fontSize: 10)),
            value: autoBackupEnabled,
            activeThumbColor: const Color(0xFFFFCC00),
            dense: true,
            onChanged: (val) {
              onAutoBackupChanged(val);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(val ? '✅ 已開啟：每次同步後將自動備份' : '❌ 已關閉自動備份功能'),
                  behavior: SnackBarBehavior.floating,
                  margin: const EdgeInsets.only(top: 40, left: 20, right: 20),
                  dismissDirection: DismissDirection.up,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
          const Divider(color: Colors.white12),
          ListTile(
            leading: const Icon(Icons.info_outline, color: Colors.white54),
            title: const Text('免責聲明與使用條款', style: TextStyle(color: Colors.white54, fontSize: 13)),
            onTap: () {
              InfoDialogs.showDisclaimerDialog(context);
            },
          ),
        ],
      ),
    );
  }
}