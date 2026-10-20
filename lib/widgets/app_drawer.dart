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
  final VoidCallback onReloadRequested; // 用於還原備份後刷新主畫面

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

                  // 手機版 (APK) 側邊欄：多帳號切換下拉選單
                  if (accountUids.isNotEmpty)
                    PopupMenuButton<String>(
                      initialValue: currentUid,
                      tooltip: '',
                      position: PopupMenuPosition.under,
                      constraints: const BoxConstraints(minWidth: 140, maxWidth: 140),
                      color: const Color(0xFF2A2D36),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Colors.white12),
                      ),
                      child: Container(
                        width: 140,
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
            onTap: () {
              Navigator.pop(context);
              BackupService.exportBackupJson(context, currentUid);
            },
          ),
          ListTile(
            leading: const Icon(Icons.folder_open, color: Color(0xFF34D399)),
            title: const Text('導入歷史備份 (JSON)', style: TextStyle(color: Colors.white70, fontSize: 13)),
            onTap: () {
              Navigator.pop(context);
              BackupService.importBackupFromFile(context, accountUids, (newUid) {
                if (newUid != currentUid) {
                  onUidChanged(newUid);
                } else {
                  onReloadRequested();
                }
              });
            },
          ),
          ListTile(
            leading: const Icon(Icons.restore, color: Color(0xFFF59E0B)),
            title: const Text('從最新的自動備份還原', style: TextStyle(color: Colors.white70, fontSize: 13)),
            onTap: () {
              Navigator.pop(context);
              BackupService.restoreFromAutoBackup(context, currentUid, () => onReloadRequested());
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
              Navigator.pop(context);
              InfoDialogs.showDisclaimerDialog(context);
            },
          ),
        ],
      ),
    );
  }
}