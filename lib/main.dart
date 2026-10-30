import 'dart:io';
import 'dart:typed_data';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';

// ============================================================================
// 匯入專案模組與服務
// ============================================================================
import 'models/gacha_record.dart';
import 'models/pool_config.dart';
import 'services/local_storage.dart';
import 'services/data_parser.dart';
import 'services/backup_service.dart';
import 'dialogs/info_dialogs.dart';
import 'dialogs/export_dialog.dart';
import 'dialogs/sync_dialog.dart';
import 'widgets/sub_banner_card.dart';
import 'widgets/app_drawer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const EndfieldTrackerApp());
}
// ============================================================================
// 應用程式進入點與全域主題設定
// ============================================================================
class EndfieldTrackerApp extends StatelessWidget {
  const EndfieldTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ENDFIELD // 尋訪紀錄終端',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F1014),
        cardColor: const Color(0xFF181920),
      ),
      home: const TrackerDashboardPage(),
    );
  }
}

// ============================================================================
// 主控制面板 (Tracker Dashboard Page)
// ============================================================================
class TrackerDashboardPage extends StatefulWidget {
  const TrackerDashboardPage({super.key});

  @override
  State<TrackerDashboardPage> createState() => _TrackerDashboardPageState();
}

class _TrackerDashboardPageState extends State<TrackerDashboardPage> {

  // ==========================================================================
  // 1. 狀態變數管理 (State Variables)
  // ==========================================================================
  String selectedPool = 'Special'; // 預設選中「特許尋訪」
  String? savedAccountToken;

  String? currentUid;
  List<String> accountUids = [];

  // 截圖與匯出設定
  final ScreenshotController _exportController = ScreenshotController();
  List<SubBannerGroup> _exportBanners = [];
  bool _exportShowTime = true;
  bool _exportShowAccount = false;
  String _exportAccountName = '';

  // 同步進度狀態
  bool _isSyncing = false;
  String _syncStatus = '';

  // 自動備份開關
  bool _autoBackupEnabled = false;

  // 導出圖片的個性化設定
  Map<String, bool> _exportBadgeConfig = {
    'showUpOff': true,
    'showAvg': true,
    'showRate': true,
    'showRarityBar': true,
    'showFreePulls': true,
  };
  Map<String, String> _savedAccountNames = {};

  // 圖片 CDN 與卡池 UP 對照字典
  Map<String, String> characterAvatarMap = {};
  Map<String, String> weaponAvatarMap = {};
  Map<String, List<String>> bannerUpMap = {};

  final String _remoteAvatarJsonUrl = 'https://raw.githubusercontent.com/wes-106/endfield-dictionary/refs/heads/main/avatar_mapping.json';
  final String _remoteWeaponJsonUrl = 'https://raw.githubusercontent.com/wes-106/endfield-dictionary/refs/heads/main/weapon_mapping.json';
  final String _remoteBannerUpJsonUrl = 'https://raw.githubusercontent.com/wes-106/endfield-dictionary/refs/heads/main/banner_up_mapping.json';

  final Map<String, String> poolTypes = {
    'Special': '特許尋訪',
    'Weapon': '武庫申領',
    'Standard': '常駐尋訪',
    'Refactor': '重構尋訪',
    'Beginner': '啟程尋訪',
  };

  late Map<String, List<SubBannerGroup>> poolBannersData = {
    'Special': [],
    'Weapon': [],
    'Standard': [],
    'Refactor': [],
    'Beginner': [],
  };

  // ==========================================================================
  // 2. 生命週期與偏好設定 (Lifecycle & Preferences)
  // ==========================================================================
  @override
  void initState() {
    super.initState();
    _initializePreferencesAndData();
  }

  /// 確保開關狀態先讀取完，再去抓取網路資料
  Future<void> _initializePreferencesAndData() async {
    await _loadAutoBackupPreference();
    await _fetchRemoteAvatarMap();
  }

  /// 取得本機設定檔的絕對路徑 (與 Isar 資料庫同住一個安全目錄)
  Future<File> _getSettingsFile() async {
    Directory dir;
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      dir = await getApplicationSupportDirectory();
    } else {
      dir = await getApplicationDocumentsDirectory();
    }
    return File('${dir.path}${Platform.pathSeparator}app_settings.json');
  }

  /// 讀取本地設定
  Future<void> _loadAutoBackupPreference() async {
    try {
      final file = await _getSettingsFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        final data = jsonDecode(content);
        if (mounted) {
          setState(() {
            _autoBackupEnabled = data['auto_backup_enabled'] ?? false;

            if (data['export_config'] != null) {
              _exportBadgeConfig = Map<String, bool>.from(data['export_config']);
            }

            if (data['account_names'] != null) {
              _savedAccountNames = Map<String, String>.from(data['account_names']);
            }
          });
        }
      }
    } catch (e) {
      debugPrint('讀取設定檔失敗: $e');
    }
  }

  /// 將輸入的帳號名稱與當前 UID 綁定並存檔
  Future<void> _saveAccountName(String uid, String name) async {
    if (name.trim().isEmpty) return;

    setState(() {
      _savedAccountNames[uid] = name.trim();
    });

    try {
      final file = await _getSettingsFile();
      Map<String, dynamic> data = {};
      if (await file.exists()) {
        data = jsonDecode(await file.readAsString());
      }
      data['account_names'] = _savedAccountNames;
      await file.writeAsString(jsonEncode(data));
    } catch (e) {
      debugPrint('儲存帳號名稱失敗: $e');
    }
  }

  /// 儲存匯出設定
  Future<void> _saveExportConfig(Map<String, bool> newConfig) async {
    setState(() => _exportBadgeConfig = newConfig);
    try {
      final file = await _getSettingsFile();
      Map<String, dynamic> data = {};
      if (await file.exists()) {
        data = jsonDecode(await file.readAsString());
      }
      data['export_config'] = newConfig;
      await file.writeAsString(jsonEncode(data));
    } catch (e) {
      debugPrint('儲存匯出設定失敗: $e');
    }
  }

  /// 儲存本地設定
  Future<void> _saveAutoBackupPreference(bool value) async {
    setState(() {
      _autoBackupEnabled = value;
    });

    try {
      final file = await _getSettingsFile();
      final data = {'auto_backup_enabled': value};
      await file.writeAsString(jsonEncode(data));
    } catch (e) {
      debugPrint('儲存設定檔失敗: $e');
    }
  }

  // ==========================================================================
  // 3. 資料庫載入與網路資源同步 (Data Loading & Networking)
  // ==========================================================================

  /// 根據當前選定的 UID 從本地 Isar 資料庫載入紀錄並轉為 UI 模型
  /// 使用 Future.wait 併發載入所有卡池，提升讀取速度
  /// 加入 uid 區域變數與 mounted 檢查，防止快速切換帳號導致的非同步覆蓋
  Future<void> _loadLocalDataForCurrentUid() async {
    final uid = currentUid;
    if (uid == null) return;
    final newPoolBanners = <String, List<SubBannerGroup>>{};
    await Future.wait(
      appPoolConfigs.map((config) async {
        final localData = await LocalStorage.loadRecords(
          uid,
          config.dbKey,
        );
        newPoolBanners[config.uiKey] = parseRawDataToModels(
          localData,
          bannerUpMap,
          isWeaponPool: config.isWeapon,
          poolCategory: config.uiKey,
        );
      }),
    );
    if (!mounted || currentUid != uid) return;
    setState(() {
      poolBannersData = newPoolBanners;
    });
  }

  /// 於背景非同步下載遠端圖庫字典與卡池 UP 對照表
  Future<void> _fetchRemoteAvatarMap() async {
    final rawUids = await LocalStorage.getAllUids();
    if (rawUids.isNotEmpty) {
      // 強制把任何沒有底線的舊 UID 加上 _2 顯示與使用
      accountUids = rawUids.map((id) => id.contains('_') ? id : '${id}_2').toList();
      currentUid = accountUids.first;
      await _loadLocalDataForCurrentUid();
    }

    try {
      final String cacheBuster = '?t=${DateTime.now().millisecondsSinceEpoch}';
      final responses = await Future.wait([
        http.get(Uri.parse('$_remoteAvatarJsonUrl$cacheBuster')),
        http.get(Uri.parse('$_remoteWeaponJsonUrl$cacheBuster')),
        http.get(Uri.parse('$_remoteBannerUpJsonUrl$cacheBuster')),
      ]);

      if (responses[0].statusCode == 200) {
        final Map<String, dynamic> charData = jsonDecode(utf8.decode(responses[0].bodyBytes));
        characterAvatarMap = charData.map((key, value) => MapEntry(key, value.toString()));
      }
      if (responses[1].statusCode == 200) {
        final Map<String, dynamic> weaponData = jsonDecode(utf8.decode(responses[1].bodyBytes));
        weaponAvatarMap = weaponData.map((key, value) => MapEntry(key, value.toString()));
      }
      if (responses[2].statusCode == 200) {
        final Map<String, dynamic> upData = jsonDecode(utf8.decode(responses[2].bodyBytes));
        bannerUpMap = upData.map((key, value) => MapEntry(key, (value as List<dynamic>).map((e) => e.toString()).toList()));
      }

      if (!mounted) return;
      await _loadLocalDataForCurrentUid();
    } catch (e) {
      debugPrint('遠端圖庫或對照表載入失敗: $e');
    }
  }

  // ==========================================================================
  // 4. 圖片匯出與截圖邏輯 (Image Export & Screenshot)
  // ==========================================================================

  /// 執行卡池畫面的截圖並跨平台儲存至相簿或下載資料夾
  Future<void> _generateAndSaveImage(
      List<String> bannerNames,
      bool showTime,
      bool showAccount,
      String accountName,
      ) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: Color(0xFFFFCC00))),
    );

    try {
      setState(() {
        _exportBanners = poolBannersData[selectedPool]!
            .where((b) => bannerNames.contains(b.bannerName))
            .toList();
        _exportShowTime = showTime;
        _exportShowAccount = showAccount;
        _exportAccountName = accountName;
      });

      await Future.delayed(const Duration(milliseconds: 500));
      Uint8List? capturedImage = await _exportController.capture(pixelRatio: 3.0);
      if (capturedImage == null) throw Exception('圖片產生失敗');

      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      String resultMessage = '';

      if (Platform.isAndroid || Platform.isIOS) {
        final result = await ImageGallerySaverPlus.saveImage(
          capturedImage,
          name: "Endfield_Record_$timestamp",
        );
        if (result['isSuccess'] == true) {
          resultMessage = '✅ 圖片導出成功！\n已儲存至您的「手機相簿」中。';
        } else {
          throw Exception('儲存至相簿失敗，請確認是否授權儲存權限');
        }
      } else {
        final directory = await getDownloadsDirectory();
        final String filePath = '${directory!.path}${Platform.pathSeparator}Endfield_Record_$timestamp.png';
        final file = File(filePath);
        await file.writeAsBytes(capturedImage);
        resultMessage = '✅ 圖片導出成功！已儲存至：\n$filePath';
      }

      if (!context.mounted) return;
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(resultMessage),
          backgroundColor: const Color(0xFF10B981),
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ 圖片導出失敗：$e'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  // ==========================================================================
  // 5. 對話框彈出管理 (Dialog Triggers)
  // ==========================================================================

  /// 彈出 Token 同步對話框
  void _showTokenSyncDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => SyncDialog(
        savedAccountToken: savedAccountToken,
        bannerUpMap: bannerUpMap,
        autoBackupEnabled: _autoBackupEnabled,
        onStatusChanged: (status) {
          setState(() { _syncStatus = status; });
        },
        onSyncingChanged: (syncing) {
          setState(() { _isSyncing = syncing; });
        },
        onSyncCompleted: (newUid, newPools) async {
          // 確保 newUid 一定帶有伺服器後綴
          final normalizedUid = newUid.contains('_') ? newUid : '${newUid}_2';
          setState(() {
            if (!accountUids.contains(normalizedUid)) {
              accountUids.add(normalizedUid);
            }
            currentUid = normalizedUid;
            poolBannersData = newPools;
            selectedPool = 'Special';
          });
        },
      ),
    );
  }

  /// 彈出圖片匯出設定對話框
  void _showExportDialog() {
    final currentSubBanners = poolBannersData[selectedPool] ?? [];
    if (currentSubBanners.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('此分類目前沒有尋訪紀錄可供導出。')));
      return;
    }

    final bannerNames = currentSubBanners.map((b) => b.bannerName).toList();

    final String initialNameForThisUid = currentUid != null ? (_savedAccountNames[currentUid!] ?? '') : '';

    showDialog(
      context: context,
      builder: (context) => ExportDialog(
        poolTitle: poolTypes[selectedPool]!,
        bannerNames: bannerNames,
        initialShowTime: _exportShowTime,
        initialShowAccount: _exportShowAccount,
        initialAccountName: initialNameForThisUid,
        exportConfig: _exportBadgeConfig,
        onConfigSaved: _saveExportConfig,
        onExport: (toExport, showTime, showAccount, accountName) {
          if (currentUid != null && showAccount) {
            _saveAccountName(currentUid!, accountName);
          }
          _generateAndSaveImage(toExport, showTime, showAccount, accountName);
        },
      ),
    );
  }

  // ==========================================================================
  // 6. 主畫面 UI 渲染與佈局 (Main UI Build & Layout)
  // ==========================================================================
  @override
  Widget build(BuildContext context) {
    final currentSubBanners = poolBannersData[selectedPool] ?? [];

    final isMobile = MediaQuery.of(context).size.width < 600;
    final hasAnyData = poolBannersData.values.any((list) => list.isNotEmpty);

    return Scaffold(
      drawer: isMobile ? AppDrawer(
        currentUid: currentUid,
        accountUids: accountUids,
        isSyncing: _isSyncing,
        autoBackupEnabled: _autoBackupEnabled,
        onUidChanged: (newUid) async {
          setState(() { currentUid = newUid; });
          await _loadLocalDataForCurrentUid();
        },
        onExportPressed: _isSyncing ? () {} : _showExportDialog,
        onSyncPressed: _isSyncing ? () {} : _showTokenSyncDialog,
        onAutoBackupChanged: _saveAutoBackupPreference,
        onReloadRequested: () async {
          await _loadLocalDataForCurrentUid();
        },
      ) : null,
      appBar: AppBar(
        backgroundColor: const Color(0xFF14151B),
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 6,
              height: 20,
              margin: const EdgeInsets.only(right: 10),
              color: const Color(0xFFFFCC00),
            ),
            const Flexible(
              child: Text(
                'ENDFIELD // 尋訪紀錄終端',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, letterSpacing: 1.1),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              margin: const EdgeInsets.only(left: 12),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => InfoDialogs.showInstructionsDialog(context),
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E2029),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFF60A5FA).withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.menu_book, color: Color(0xFF60A5FA), size: 14),
                        if (!isMobile) ...[
                          const SizedBox(width: 4),
                          const Text('使用說明', style: TextStyle(color: Color(0xFF60A5FA), fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: isMobile ? null : [
          IconButton(
            tooltip: '免責聲明',
            icon: const Icon(Icons.info_outline, color: Colors.white54, size: 20),
            onPressed: () => InfoDialogs.showDisclaimerDialog(context),
          ),
          IconButton(
            tooltip: '資料備份與設定',
            icon: const Icon(Icons.storage, color: Colors.white54, size: 20),
            onPressed: _showBackupSettingsDialog,
          ),
          const SizedBox(width: 8),
          // 電腦版帳號切換下拉選單 (類似 Google 搜尋欄)
          if (accountUids.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: PopupMenuButton<String>(
                initialValue: currentUid,
                tooltip: '帳號切換',
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
                  child: Center( // 讓選單裡的每個選項都置中對齊
                    child: Text(
                      'UID: $uid',
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ),
                )).toList(),
                onSelected: (newUid) async {
                  final normalizedUid = newUid.contains('_') ? newUid : '${newUid}_2';
                  if (normalizedUid != currentUid) {
                    setState(() { currentUid = normalizedUid; });
                    await _loadLocalDataForCurrentUid();
                  }
                },
              ),
            ),
          TextButton.icon(
            onPressed: _isSyncing ? null : _showExportDialog,
            icon: Icon(Icons.download, color: _isSyncing ? Colors.white24 : const Color(0xFF60A5FA), size: 18),
            label: Text(
              '導出圖片',
              style: TextStyle(color: _isSyncing ? Colors.white24 : const Color(0xFF60A5FA), fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: _isSyncing ? null : _showTokenSyncDialog,
            icon: Icon(Icons.sync, color: _isSyncing ? Colors.white24 : const Color(0xFFFFCC00), size: 18),
            label: Text(
              '同步尋訪紀錄',
              style: TextStyle(color: _isSyncing ? Colors.white24 : const Color(0xFFFFCC00), fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          // 隱藏的截圖渲染區塊
          Positioned(
            top: -10000,
            left: -10000,
            child: Screenshot(
              controller: _exportController,
              child: Container(
                width: 850,
                color: const Color(0xFF14151B),
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(width: 8, height: 28, color: const Color(0xFFFFCC00), margin: const EdgeInsets.only(right: 12)),
                        Expanded(
                          child: Text(
                            'ENDFIELD 尋訪紀錄 // ${poolTypes[selectedPool]}',
                            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (_exportShowAccount) ...[
                              if (_exportAccountName.trim().isNotEmpty) ...[
                                Text(
                                  _exportAccountName,
                                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                                ),
                                const SizedBox(height: 2),
                              ],
                              Text(
                                'UID: ${currentUid?.split('_').first ?? "未知"}',
                                style: const TextStyle(color: Color(0xFFFFCC00), fontSize: 13, fontWeight: FontWeight.w900),
                              ),
                              const SizedBox(height: 6),
                            ],
                            if (_exportShowTime)
                              Text(
                                '生成時間：${DateTime.now().toString().substring(0, 16)}',
                                style: const TextStyle(color: Colors.white54, fontSize: 13),
                              ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    ..._exportBanners.map((banner) => Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: SubBannerCard(
                        banner: banner,
                        forceDesktop: true,
                        exportConfig: _exportBadgeConfig,
                        characterAvatarMap: characterAvatarMap,
                        weaponAvatarMap: weaponAvatarMap,
                      ),
                    )),
                  ],
                ),
              ),
            ),
          ),
          // 主畫面捲動列表
          Positioned.fill(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 880),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: currentSubBanners.isEmpty ? 3 : currentSubBanners.length + 2,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildPoolTypeSelector(),
                      );
                    }
                    if (index == 1) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 18),
                        child: _buildCategorySummaryBar(
                          poolTitle: poolTypes[selectedPool]!,
                          banners: currentSubBanners, // 修改：直接傳入整個卡池列表
                        ),
                      );
                    }
                    if (currentSubBanners.isEmpty && index == 2) {
                      if (!hasAnyData) {
                        return Container(
                          width: double.infinity,
                          margin: const EdgeInsets.symmetric(vertical: 30),
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: const Color(0xFF181920),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.folder_open_outlined, color: Color(0xFFFFCC00), size: 48),
                              const SizedBox(height: 16),
                              const Text(
                                '目前尚無尋訪紀錄',
                                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                '第一次使用嗎？您可以點擊下方按鈕查看詳細的教學，\n了解如何獲取 Token 並同步資料。',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white54, fontSize: 13, height: 1.4),
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFFCC00),
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                icon: const Icon(Icons.menu_book, size: 18),
                                label: const Text('查看新手使用說明', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                onPressed: () => InfoDialogs.showInstructionsDialog(context),
                              ),
                            ],
                          ),
                        );
                      } else {
                        return Container(
                          width: double.infinity,
                          margin: const EdgeInsets.symmetric(vertical: 30),
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: const Color(0xFF181920),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: const Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.inbox, color: Colors.white38, size: 48),
                              SizedBox(height: 16),
                              Text(
                                '此分類目前無尋訪紀錄',
                                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 8),
                              Text(
                                '您可能尚未在此類型的卡池中進行尋訪，\n或紀錄已超過官方伺服器的保存期限。',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white54, fontSize: 13, height: 1.4),
                              ),
                            ],
                          ),
                        );
                      }
                    }
                    final banner = currentSubBanners[index - 2];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: SubBannerCard(
                        banner: banner,
                        characterAvatarMap: characterAvatarMap,
                        weaponAvatarMap: weaponAvatarMap,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          // 全螢幕載入遮罩
          if (_isSyncing)
            Container(
              color: Colors.black.withValues(alpha: 0.75),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF181920),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFFCC00).withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(color: Color(0xFFFFCC00)),
                      const SizedBox(height: 20),
                      Text(
                        _syncStatus,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ==========================================================================
  // 7. 內部輔助 UI 元件與對話框 (Helper Widgets & Dialogs)
  // ==========================================================================

  /// 構建頂部的卡池分類切換按鈕列
  Widget _buildPoolTypeSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: poolTypes.entries.map((e) {
          final isSel = selectedPool == e.key;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: InkWell(
              onTap: () => setState(() => selectedPool = e.key),
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  color: isSel ? const Color(0xFFFFCC00) : const Color(0xFF181920),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isSel ? const Color(0xFFFFCC00) : Colors.white12,
                  ),
                ),
                child: Text(
                  e.value,
                  style: TextStyle(
                    color: isSel ? Colors.black : Colors.white70,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// 構建大類統計資訊條 (顯示當前分類的常規總和，並提供詳細數據面板)
  Widget _buildCategorySummaryBar({
    required String poolTitle,
    required List<SubBannerGroup> banners,
  }) {
    // 判斷此大類是否有免費機制
    final bool hasFreeMechanic = poolTitle == '特許尋訪' || poolTitle == '重構尋訪';
    final String pullLabel = hasFreeMechanic ? '常規總抽數' : '累計總抽數';
    final String starLabel = hasFreeMechanic ? '常規 6★' : '累計 6★';
    // 計算常規數據加總
    final int totalRegularPulls = banners.fold(0, (sum, b) => sum + b.regularPulls);
    final int totalRegularSixStars = banners.fold(0, (sum, b) => sum + b.regularSixStarCount);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF14151B),
        borderRadius: BorderRadius.circular(8),
        border: const Border(
          left: BorderSide(color: Color(0xFFFFCC00), width: 4),
        ),
      ),
      child: Wrap(
        spacing: 24,
        runSpacing: 8,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            '$poolTitle // 共收錄 ${banners.length} 個獨立卡池區塊',
            style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildMiniStat(pullLabel, '$totalRegularPulls 抽', const Color(0xFFFFCC00)),
              const SizedBox(width: 20),
              _buildMiniStat(starLabel, '$totalRegularSixStars 個', const Color(0xFF10B981)),
              const SizedBox(width: 20),
              // 大類別的數據面板按鈕
              GestureDetector(
                onTap: () => _showCategoryStatsDialog(context, poolTitle, banners),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFA855F7).withAlpha(38),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFA855F7)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bar_chart, color: Color(0xFFD8B4FE), size: 14),
                      SizedBox(width: 4),
                      Text('全部數據', style: TextStyle(color: Color(0xFFD8B4FE), fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 構建統計資訊條內部的單一數據項目
  Widget _buildMiniStat(String label, String value, Color valueColor) {
    return Row(
      children: [
        Text('$label：', style: const TextStyle(color: Colors.white54, fontSize: 12)),
        Text(value, style: TextStyle(color: valueColor, fontWeight: FontWeight.w900, fontSize: 14)),
      ],
    );
  }

  /// 彈出電腦版專屬的資料備份與管理對話框
  void _showBackupSettingsDialog() {
    final mainSetState = setState;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (innerContext, dialogSetState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF181920),
              title: const Row(
                children: [
                  Icon(Icons.storage, color: Color(0xFF60A5FA), size: 22),
                  SizedBox(width: 8),
                  Text('資料備份與管理', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
                ],
              ),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.upload_file, color: Color(0xFF60A5FA)),
                      title: const Text('匯出資料備份 (JSON)', style: TextStyle(color: Colors.white70, fontSize: 13)),
                      onTap: () async {
                        // 1. 先關閉外層的「資料備份與管理」設定對話框
                        Navigator.pop(innerContext);

                        // 2. 判斷是否有超過一個帳號，彈出選擇對話框
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
                                          color: uid == currentUid ? const Color(0xFFFFCC00) : Colors.white,
                                          fontWeight: uid == currentUid ? FontWeight.bold : FontWeight.normal
                                      )
                                  ),
                                  subtitle: uid == currentUid ? const Text('當前畫面顯示中', style: TextStyle(color: Colors.white54, fontSize: 12)) : null,
                                  trailing: const Icon(Icons.upload_file, color: Colors.white54, size: 18),
                                  onTap: () => Navigator.pop(dialogContext, uid),
                                )).toList(),
                              ),
                            ),
                          );

                          // 3. 取得玩家選擇的 UID 並執行匯出
                          if (selectedUid != null && context.mounted) {
                            await BackupService.exportBackupJson(context, selectedUid);
                          }
                        } else {
                          await BackupService.exportBackupJson(context, currentUid);
                        }
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.folder_open, color: Color(0xFF34D399)),
                      title: const Text('導入歷史備份 (JSON)', style: TextStyle(color: Colors.white70, fontSize: 13)),
                      onTap: () async {
                        Navigator.pop(innerContext);

                        await BackupService.importBackupFromFile(context, currentUid, accountUids, (newUid) async {
                          mainSetState(() { currentUid = newUid; });
                          await _loadLocalDataForCurrentUid();
                        });
                      },
                    ),
                    const Divider(color: Colors.white12, height: 16),
                    SwitchListTile(
                      secondary: const Icon(Icons.security_update_good, color: Color(0xFF34D399), size: 22),
                      title: const Text('每次同步後自動備份', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                      subtitle: const Text('覆蓋舊檔，防止資料遺失', style: TextStyle(color: Colors.white54, fontSize: 11)),
                      value: _autoBackupEnabled,
                      activeThumbColor: const Color(0xFFFFCC00),
                      onChanged: (val) {
                        dialogSetState(() => _autoBackupEnabled = val);
                        _saveAutoBackupPreference(val);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(val ? '✅ 已開啟：每次同步後將自動備份' : '❌ 已關閉自動備份功能'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.restore, color: Color(0xFFF59E0B)),
                      title: const Text('從最新的自動備份還原', style: TextStyle(color: Colors.white70, fontSize: 13)),
                      onTap: () {
                        Navigator.pop(context);
                        BackupService.restoreFromAutoBackup(context, currentUid, () async {
                          await _loadLocalDataForCurrentUid();
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(innerContext),
                  child: const Text('關閉', style: TextStyle(color: Colors.white54)),
                ),
              ],
            );
          },
        );
      },
    );
  }
  /// 彈出「大類別」彙總詳細數據面板視窗
  void _showCategoryStatsDialog(BuildContext context, String poolTitle, List<SubBannerGroup> banners) {
    // --- 加總常規數據 ---
    final int regPulls = banners.fold(0, (sum, b) => sum + b.regularPulls);
    final int regSixStars = banners.fold(0, (sum, b) => sum + b.regularSixStarCount);
    final int regUp = banners.fold(0, (sum, b) => sum + b.regularUpCount);
    final int regOff = banners.fold(0, (sum, b) => sum + b.regularOffCount);
    final double regAvg = regSixStars > 0 ? (regPulls / regSixStars) : 0.0;
    final double regRate = regPulls > 0 ? ((regSixStars / regPulls) * 100) : 0.0;
    final int regFiveStars = banners.fold(0, (sum, b) => sum + b.regularFiveStarCount);
    final int regFourStars = banners.fold(0, (sum, b) => sum + b.regularFourStarCount);

    // --- 加總免費數據 ---
    final int freePulls = banners.fold(0, (sum, b) => sum + b.freePulls);
    final int freeSixStars = banners.fold(0, (sum, b) => sum + b.freeSixStarCount);
    final int freeUp = banners.fold(0, (sum, b) => sum + b.freeUpCount);
    final int freeOff = banners.fold(0, (sum, b) => sum + b.freeOffCount);
    final double freeAvg = freeSixStars > 0 ? (freePulls / freeSixStars) : 0.0;
    final double freeRate = freePulls > 0 ? ((freeSixStars / freePulls) * 100) : 0.0;
    final int freeFiveStars = banners.fold(0, (sum, b) => sum + b.freeFiveStarCount);
    final int freeFourStars = banners.fold(0, (sum, b) => sum + b.freeFourStarCount);

    final bool hasFreeMechanic = poolTitle == '特許尋訪' || poolTitle == '重構尋訪';
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF181920),
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Colors.white12),
          ),
          title: Text(
            '【$poolTitle】總和統計',
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 常規彙總區塊
              Text(
                  hasFreeMechanic ? '🔸 歷史常規尋訪' : '🔸 歷史尋訪統計',
                  style: const TextStyle(color: Color(0xFFFFCC00), fontSize: 13, fontWeight: FontWeight.bold)
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
                _buildRarityBar(regPulls, regSixStars, regFiveStars, regFourStars),

              // 免費彙總區塊 (只有在該大類有免費抽時才顯示)
              if (freePulls > 0) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(color: Colors.white12, height: 1),
                ),
                const Text('🔹 歷史免費尋訪', style: TextStyle(color: Color(0xFF60A5FA), fontSize: 13, fontWeight: FontWeight.bold)),
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
                _buildRarityBar(freePulls, freeSixStars, freeFiveStars, freeFourStars),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('關閉', style: TextStyle(color: Colors.white70)),
            ),
          ],
        );
      },
    );
  }

  // 小視窗內的排版輔助元件
  Widget _buildMiniStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
  /// 繪製橫向堆疊條形圖 (稀有度分布)
  Widget _buildRarityBar(int total, int stars6, int stars5, int stars4) {
    if (total == 0) return const SizedBox.shrink();

    // 如果有 3★ 或其他星級，算進 others
    final int others = total - stars6 - stars5 - stars4;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 6),
        const Text('稀有度分布', style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: 10,
            child: Row(
              children: [
                if (stars6 > 0) Expanded(flex: stars6, child: Container(color: const Color(0xFFFFCC00))),
                if (stars5 > 0) Expanded(flex: stars5, child: Container(color: const Color(0xFFA855F7))),
                if (stars4 > 0) Expanded(flex: stars4, child: Container(color: const Color(0xFF60A5FA))),
                if (others > 0) Expanded(flex: others, child: Container(color: Colors.white24)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('6★ ${(stars6 / total * 100).toStringAsFixed(1)}%', style: const TextStyle(color: Color(0xFFFFCC00), fontSize: 11, fontWeight: FontWeight.bold)),
            Text('5★ ${(stars5 / total * 100).toStringAsFixed(1)}%', style: const TextStyle(color: Color(0xFFA855F7), fontSize: 11, fontWeight: FontWeight.bold)),
            Text('4★ ${(stars4 / total * 100).toStringAsFixed(1)}%', style: const TextStyle(color: Color(0xFF60A5FA), fontSize: 11, fontWeight: FontWeight.bold)),
            if (others > 0)
              Text('其他 ${(others / total * 100).toStringAsFixed(1)}%', style: const TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 6),
      ],
    );
  }
}