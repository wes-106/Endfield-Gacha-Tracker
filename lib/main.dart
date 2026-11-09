import 'dart:typed_data';

import 'package:screenshot/screenshot.dart';

import 'package:flutter/material.dart';

import 'models/gacha_record.dart';
import 'models/pool_config.dart';
import 'services/local_storage.dart';
import 'services/data_parser.dart';
import 'services/settings_service.dart';
import 'services/image_export_service.dart';
import 'services/dictionary_service.dart';
import 'dialogs/info_dialogs.dart';
import 'dialogs/export_dialog.dart';
import 'dialogs/sync_dialog.dart';
import 'dialogs/category_stats_dialog.dart';
import 'dialogs/backup_settings_dialog.dart';
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
  // 1. 狀態變數與資料初始化
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

  late Map<String, List<SubBannerGroup>> poolBannersData = {
    for (var config in appPoolConfigs) config.uiKey: [],
  };

  // ==========================================================================
  // 2. 生命週期與偏好設定
  // ==========================================================================
  @override
  void initState() {
    super.initState();
    _initializePreferencesAndData();
  }

  /// 依序初始化本機設定與應用程式資料。
  ///
  /// 設定檔讀取失敗時，仍繼續執行後續初始化，
  /// 避免設定檔損壞影響抽卡紀錄及其他資料的載入。
  Future<void> _initializePreferencesAndData() async {
    try {
      await _loadSettings();
    } catch (e) {
      debugPrint('初始化設定檔失敗，將使用預設設定：$e');
    }

    await _fetchRemoteAvatarMap();
  }

  /// 從 Service 讀取本地設定並更新 State
  Future<void> _loadSettings() async {
    final data = await SettingsService.loadSettings();

    if (!mounted) return;

    setState(() {
      _autoBackupEnabled = data['auto_backup_enabled'] == true;

      if (data['export_config'] is Map) {
        _exportBadgeConfig = (data['export_config'] as Map).map(
          // 強制將 Key 轉字串，Value 嚴格判斷是否為 true
          (key, value) => MapEntry(key.toString(), value == true),
        );
      }

      if (data['account_names'] is Map) {
        _savedAccountNames = (data['account_names'] as Map).map(
          // 強制將 Key 與 Value 都轉為字串，避免 null 或數字造成崩潰
          (key, value) => MapEntry(key.toString(), value.toString()),
        );
      }
    });
  }

  /// 更新自動備份設定，並同步儲存至本機設定檔。
  ///
  /// 採用樂觀更新：先更新畫面，再寫入設定檔。
  /// 若儲存失敗，則還原原本的開關狀態，並將錯誤交由呼叫端處理。
  Future<void> _updateAutoBackupPreference(bool enabled) async {
    final previousValue = _autoBackupEnabled;

    setState(() {
      _autoBackupEnabled = enabled;
    });

    final success = await SettingsService.saveAutoBackupPreference(enabled);

    if (!success) {
      if (mounted) {
        setState(() {
          _autoBackupEnabled = previousValue;
        });
      }

      throw Exception('自動備份設定儲存失敗');
    }
  }

  // ==========================================================================
  // 3. 本機資料載入與遠端資源同步
  // ==========================================================================

  /// 載入指定帳號的本機卡池紀錄，並轉換為 UI 使用的資料模型。
  ///
  /// 使用 Future.wait 併發讀取各卡池資料。
  /// 載入完成後再次確認 Widget 仍存在，且帳號未被切換，
  /// 避免非同步結果覆蓋其他帳號的資料。
  Future<void> _loadLocalDataForCurrentUid() async {
    final uid = currentUid;
    if (uid == null) return;
    final newPoolBanners = <String, List<SubBannerGroup>>{};
    await Future.wait(
      appPoolConfigs.map((config) async {
        final localData = await LocalStorage.loadRecords(uid, config.dbKey);
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

  /// 初始化帳號資料與圖庫字典。
  ///
  /// 先載入本機帳號及卡池紀錄，再取得角色、武器頭像與 UP 對照資料，
  /// 最後重新解析卡池紀錄以套用最新字典。
  Future<void> _fetchRemoteAvatarMap() async {
    if (!mounted) return;

    final rawUids = await LocalStorage.getAllUids();
    if (rawUids.isNotEmpty) {
      setState(() {
        // 舊版 UID 若未包含伺服器後綴，統一補上預設後綴。
        accountUids = rawUids
            .map((id) => id.contains('_') ? id : '${id}_2')
            .toList();
        currentUid = accountUids.first;
      });
      await _loadLocalDataForCurrentUid();
    }

    final dictData = await DictionaryService.loadDictionaries();

    if (!mounted) return;

    setState(() {
      characterAvatarMap = dictData['avatar'];
      weaponAvatarMap = dictData['weapon'];
      bannerUpMap = dictData['bannerUp'];
    });

    await _loadLocalDataForCurrentUid();
  }

  // ==========================================================================
  // 4. 圖片截圖與匯出
  // ==========================================================================

  /// 執行卡池畫面的截圖並跨平台儲存至相簿或下載資料夾
  Future<void> _generateAndSaveImage(
    List<String> bannerNames,
    bool showTime,
    bool showAccount,
    String accountName,
  ) async {
    bool isDialogShowing = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      // 防止使用者在圖片產生期間手動關閉載入畫面。
      builder: (_) => const PopScope(
        canPop: false,
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFFFFCC00)),
        ),
      ),
    ).then((_) {
      isDialogShowing = false;
    });

    try {
      setState(() {
        _exportBanners = poolBannersData[selectedPool]!
            .where((b) => bannerNames.contains(b.bannerName))
            .toList();
        _exportShowTime = showTime;
        _exportShowAccount = showAccount;
        _exportAccountName = accountName;
      });

      await WidgetsBinding.instance.endOfFrame;
      await Future.delayed(const Duration(milliseconds: 150));
      Uint8List? capturedImage = await _exportController.capture(
        pixelRatio: 3.0,
      );
      if (capturedImage == null) throw Exception('圖片產生失敗');

      final String resultMessage = await ImageExportService.saveImage(
        capturedImage,
      );

      if (!context.mounted) return;

      if (isDialogShowing) {
        Navigator.pop(context);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(resultMessage),
          backgroundColor: const Color(0xFF10B981),
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      if (isDialogShowing) {
        Navigator.pop(context);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ 圖片導出失敗：$e'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  // ==========================================================================
  // 5. 對話框與操作事件
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
          setState(() {
            _syncStatus = status;
          });
        },
        onSyncingChanged: (syncing) {
          setState(() {
            _isSyncing = syncing;
          });
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
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('此分類目前沒有尋訪紀錄可供導出。')));
      return;
    }

    final bannerNames = currentSubBanners.map((b) => b.bannerName).toList();

    final String initialNameForThisUid = currentUid != null
        ? (_savedAccountNames[currentUid!] ?? '')
        : '';

    showDialog(
      context: context,
      builder: (context) => ExportDialog(
        poolTitle: appPoolConfigs
            .firstWhere((c) => c.uiKey == selectedPool)
            .displayName,
        bannerNames: bannerNames,
        initialShowTime: _exportShowTime,
        initialShowAccount: _exportShowAccount,
        initialAccountName: initialNameForThisUid,
        exportConfig: _exportBadgeConfig,
        onConfigSaved: (newConfig) async {
          setState(() {
            _exportBadgeConfig = newConfig;
          });
          await SettingsService.saveExportConfig(newConfig);
        },
        onExport: (toExport, showTime, showAccount, accountName) async {
          if (currentUid != null && showAccount) {
            final String trimmedName = accountName.trim();
            final String previousName = _savedAccountNames[currentUid!] ?? '';

            // 先更新畫面與記憶體中的帳號名稱。
            setState(() {
              _savedAccountNames[currentUid!] = trimmedName;
            });

            // 寫入本機設定檔。
            final success = await SettingsService.saveAccountName(
              currentUid!,
              trimmedName,
            );

            // 寫入失敗時還原原始狀態並通知使用者。
            if (!success && mounted) {
              setState(() {
                if (previousName.isEmpty) {
                  _savedAccountNames.remove(currentUid!);
                } else {
                  _savedAccountNames[currentUid!] = previousName;
                }
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('⚠️ 帳號名稱儲存失敗，下次啟動將恢復原狀'),
                  backgroundColor: Color(0xFFEF4444),
                  duration: Duration(seconds: 3),
                ),
              );
            }
          }

          // 無論名稱是否成功存入實體檔案，當下的圖片生成依然可以繼續執行
          await _generateAndSaveImage(
            toExport,
            showTime,
            showAccount,
            accountName,
          );
        },
      ),
    );
  }

  // ==========================================================================
  // 6. 主畫面 UI 與佈局
  // ==========================================================================
  @override
  Widget build(BuildContext context) {
    final currentSubBanners = poolBannersData[selectedPool] ?? [];

    final isMobile = MediaQuery.of(context).size.width < 600;
    final hasAnyData = poolBannersData.values.any((list) => list.isNotEmpty);

    return Scaffold(
      drawer: isMobile
          ? AppDrawer(
              currentUid: currentUid,
              accountUids: accountUids,
              isSyncing: _isSyncing,
              autoBackupEnabled: _autoBackupEnabled,
              onUidChanged: (newUid) async {
                setState(() {
                  currentUid = newUid;
                });
                await _loadLocalDataForCurrentUid();
              },
              onExportPressed: _isSyncing ? () {} : _showExportDialog,
              onSyncPressed: _isSyncing ? () {} : _showTokenSyncDialog,
              onAutoBackupChanged: _updateAutoBackupPreference,
              onReloadRequested: () async {
                await _loadLocalDataForCurrentUid();
              },
            )
          : null,
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
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                  letterSpacing: 1.1,
                ),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E2029),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: const Color(0xFF60A5FA).withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.menu_book,
                          color: Color(0xFF60A5FA),
                          size: 14,
                        ),
                        if (!isMobile) ...[
                          const SizedBox(width: 4),
                          const Text(
                            '使用說明',
                            style: TextStyle(
                              color: Color(0xFF60A5FA),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: isMobile
            ? null
            : [
                IconButton(
                  tooltip: '免責聲明',
                  icon: const Icon(
                    Icons.info_outline,
                    color: Colors.white54,
                    size: 20,
                  ),
                  onPressed: () => InfoDialogs.showDisclaimerDialog(context),
                ),
                IconButton(
                  tooltip: '資料備份與設定',
                  icon: const Icon(
                    Icons.storage,
                    color: Colors.white54,
                    size: 20,
                  ),
                  onPressed: () => showDialog(
                    context: context,
                    builder: (_) => BackupSettingsDialog(
                      accountUids: accountUids,
                      currentUid: currentUid,
                      initialAutoBackupEnabled: _autoBackupEnabled,
                      onAutoBackupChanged: _updateAutoBackupPreference,
                      onReloadData: (newUid) async {
                        setState(() => currentUid = newUid);
                        await _loadLocalDataForCurrentUid();
                      },
                    ),
                  ),
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
                      constraints: const BoxConstraints(
                        minWidth: 170,
                        maxWidth: 170,
                      ),
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
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.arrow_drop_down,
                              color: Color(0xFFFFCC00),
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                      itemBuilder: (context) => accountUids
                          .map(
                            (uid) => PopupMenuItem<String>(
                              value: uid,
                              height: 40,
                              padding: EdgeInsets.zero,
                              child: Center(
                                child: Text(
                                  'UID: $uid',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                      onSelected: (newUid) async {
                        final normalizedUid = newUid.contains('_')
                            ? newUid
                            : '${newUid}_2';
                        if (normalizedUid != currentUid) {
                          setState(() {
                            currentUid = normalizedUid;
                          });
                          await _loadLocalDataForCurrentUid();
                        }
                      },
                    ),
                  ),
                TextButton.icon(
                  onPressed: _isSyncing ? null : _showExportDialog,
                  icon: Icon(
                    Icons.download,
                    color: _isSyncing
                        ? Colors.white24
                        : const Color(0xFF60A5FA),
                    size: 18,
                  ),
                  label: Text(
                    '導出圖片',
                    style: TextStyle(
                      color: _isSyncing
                          ? Colors.white24
                          : const Color(0xFF60A5FA),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: _isSyncing ? null : _showTokenSyncDialog,
                  icon: Icon(
                    Icons.sync,
                    color: _isSyncing
                        ? Colors.white24
                        : const Color(0xFFFFCC00),
                    size: 18,
                  ),
                  label: Text(
                    '同步尋訪紀錄',
                    style: TextStyle(
                      color: _isSyncing
                          ? Colors.white24
                          : const Color(0xFFFFCC00),
                      fontWeight: FontWeight.bold,
                    ),
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
                        Container(
                          width: 8,
                          height: 28,
                          color: const Color(0xFFFFCC00),
                          margin: const EdgeInsets.only(right: 12),
                        ),
                        Expanded(
                          child: Text(
                            'ENDFIELD 尋訪紀錄 // ${appPoolConfigs.firstWhere((c) => c.uiKey == selectedPool).displayName}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (_exportShowAccount) ...[
                              if (_exportAccountName.trim().isNotEmpty) ...[
                                Text(
                                  _exportAccountName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 2),
                              ],
                              Text(
                                'UID: ${currentUid?.split('_').first ?? "未知"}',
                                style: const TextStyle(
                                  color: Color(0xFFFFCC00),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 6),
                            ],
                            if (_exportShowTime)
                              Text(
                                '生成時間：${DateTime.now().toString().substring(0, 16)}',
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 13,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    ..._exportBanners.map(
                      (banner) => Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: SubBannerCard(
                          banner: banner,
                          forceDesktop: true,
                          exportConfig: _exportBadgeConfig,
                          characterAvatarMap: characterAvatarMap,
                          weaponAvatarMap: weaponAvatarMap,
                        ),
                      ),
                    ),
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
                  itemCount: currentSubBanners.isEmpty
                      ? 3
                      : currentSubBanners.length + 2,
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
                          poolTitle: appPoolConfigs
                              .firstWhere((c) => c.uiKey == selectedPool)
                              .displayName,
                          banners: currentSubBanners,
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
                              const Icon(
                                Icons.folder_open_outlined,
                                color: Color(0xFFFFCC00),
                                size: 48,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                '目前尚無尋訪紀錄',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                '第一次使用嗎？您可以點擊下方按鈕查看詳細的教學，\n了解如何獲取 Token 並同步資料。',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFFCC00),
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                icon: const Icon(Icons.menu_book, size: 18),
                                label: const Text(
                                  '查看新手使用說明',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                onPressed: () =>
                                    InfoDialogs.showInstructionsDialog(context),
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
                              Icon(
                                Icons.inbox,
                                color: Colors.white38,
                                size: 48,
                              ),
                              SizedBox(height: 16),
                              Text(
                                '此分類目前無尋訪紀錄',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                '您可能尚未在此類型的卡池中進行尋訪，\n或紀錄已超過官方伺服器的保存期限。',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 13,
                                  height: 1.4,
                                ),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 24,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF181920),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFFFCC00).withValues(alpha: 0.3),
                    ),
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
  // 7. 輔助 UI 元件與統計面板
  // ==========================================================================

  /// 構建頂部的卡池分類切換按鈕列
  Widget _buildPoolTypeSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: appPoolConfigs.map((config) {
          final isSel = selectedPool == config.uiKey;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: InkWell(
              onTap: () => setState(() => selectedPool = config.uiKey),
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSel
                      ? const Color(0xFFFFCC00)
                      : const Color(0xFF181920),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isSel ? const Color(0xFFFFCC00) : Colors.white12,
                  ),
                ),
                child: Text(
                  config.displayName,
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
    final int totalRegularPulls = banners.fold(
      0,
      (sum, b) => sum + b.regularPulls,
    );
    final int totalRegularSixStars = banners.fold(
      0,
      (sum, b) => sum + b.regularSixStarCount,
    );

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
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildMiniStat(
                pullLabel,
                '$totalRegularPulls 抽',
                const Color(0xFFFFCC00),
              ),
              const SizedBox(width: 20),
              _buildMiniStat(
                starLabel,
                '$totalRegularSixStars 個',
                const Color(0xFF10B981),
              ),
              const SizedBox(width: 20),
              // 大類別的數據面板按鈕
              GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (_) => CategoryStatsDialog(
                      poolTitle: poolTitle,
                      banners: banners,
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
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
                      Text(
                        '全部數據',
                        style: TextStyle(
                          color: Color(0xFFD8B4FE),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
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
        Text(
          '$label：',
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontWeight: FontWeight.w900,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
