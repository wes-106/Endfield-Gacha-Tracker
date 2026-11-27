import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

/// 集中管理應用程式中的靜態說明對話框，
/// 包含免責聲明、使用說明與常見問題。
class InfoDialogs {
  /// 顯示免責聲明與使用條款。
  static void showDisclaimerDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF181920),
          title: const Row(
            children: [
              Icon(Icons.info_outline, color: Color(0xFF60A5FA), size: 22),
              SizedBox(width: 8),
              Text(
                '免責聲明與使用條款',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDisclaimerItem(
                    '1. 適用伺服器與無關聯聲明',
                    '本程式為玩家自製的免費輔助工具，目前僅支援「國際服 (Gryphline)」的資料解析，與《明日方舟：終末地》官方無任何附屬、授權或合作關係。',
                  ),
                  _buildDisclaimerItem(
                    '2. 圖片版權與非商業用途',
                    '程式內使用的遊戲圖像、角色名稱等相關素材，版權皆屬官方所有。本工具僅供玩家個人紀錄與交流使用，嚴禁提取本專案中的「官方素材」進行任何形式的商業用途。',
                  ),
                  _buildDisclaimerItem(
                    '3. 帳號與資安保證',
                    '本程式不會刻意將您的登入憑證（Token）寫入本機設定或備份檔。同步時，Token 僅在程式記憶體中暫時使用，並傳送至 Gryphline 官方 API 進行帳號驗證及尋訪紀錄取得。本程式目前未將帳號 Token 傳送至第三方字典服務。儘管如此，仍請您妥善保管 Token，切勿截圖分享或張貼於公共空間。',
                  ),
                  _buildDisclaimerItem(
                    '4. 資料準確性',
                    '數據取自官方 API。若官方未來修改規則導致程式無法同步或數據遺失，開發者不承擔相關責任。',
                  ),
                  _buildDisclaimerItem(
                    '5. 隱私安全',
                    '本程式不提供雲端帳號同步功能，尋訪紀錄與 UID 均儲存於設備本地端。為取得遊戲尋訪紀錄，程式會與 Gryphline 官方 API 通訊；此外，程式也會連線至 GitHub 下載遊戲資料字典。上述網路連線可能涉及一般連線資訊（例如 IP 位址）。本程式不會刻意收集或向第三方字典服務傳送您的帳號 Token 或尋訪紀錄。',
                  ),
                  const Padding(
                    padding: EdgeInsets.only(top: 8, bottom: 16),
                    child: Divider(color: Colors.white12),
                  ),
                  const Center(
                    child: Text(
                      'Made by wes-106  |  v1.3.0',
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 12,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),

                  // GitHub 專案連結。
                  Center(
                    child: InkWell(
                      onTap: () async {
                        final Uri url = Uri.parse(
                          'https://github.com/wes-106/Endfield-Gacha-Tracker',
                        );

                        try {
                          final messenger = ScaffoldMessenger.of(context);

                          final bool launched = await launchUrl(
                            url,
                            mode: LaunchMode.externalApplication,
                          );

                          if (!launched && context.mounted) {
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('無法開啟網頁，請確認是否安裝或設定預設瀏覽器！'),
                                backgroundColor: Color(0xFFEF4444),
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('無法開啟網頁，發生預期外的系統錯誤！'),
                                backgroundColor: Color(0xFFEF4444),
                              ),
                            );
                          }

                          debugPrint('GitHub 網址開啟失敗：$e');
                        }
                      },
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.code,
                              color: Color(0xFF60A5FA),
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              '前往 GitHub 專案與檢查更新',
                              style: TextStyle(
                                color: Color(0xFF60A5FA),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text(
                '我已了解',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// 顯示應用程式使用說明與常見問題（折疊式呈現）。
  static void showInstructionsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF181920),
          title: const Row(
            children: [
              Icon(Icons.menu_book, color: Color(0xFF10B981), size: 22),
              SizedBox(width: 8),
              Text(
                '使用說明與常見問題',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildExpandableItem(
                    context: context,
                    title: '1. 尋訪紀錄保存機制',
                    initiallyExpanded: false,
                    children: [
                      const Text(
                        '官方伺服器僅保留「最近 90 天內」的尋訪紀錄，超過期限的歷史數據便無法再從官方獲取。\n'
                        '同步後，紀錄會保存在您的本機設備，不再受官方 90 天保存期限限制。\n'
                        '但若設備損毀、遺失，或您清除應用程式資料，本機紀錄仍可能消失，重要資料請務必手動匯出備份。',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                  _buildExpandableItem(
                    context: context,
                    title: '2. 如何導入資料',
                    initiallyExpanded: true,
                    children: [
                      const Text(
                        '① 點選右上角或側邊欄的「同步尋訪紀錄」\n'
                        '② 點選「1. 登入官網」並在瀏覽器內完成登入\n'
                        '③ 【重要】勿關閉瀏覽器，直接切回本程式\n'
                        '④ 點選「2. 獲取 Token」複製畫面上完整代碼\n'
                        '⑤ 貼入下方輸入框並點選「開始同步」',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          height: 1.55,
                        ),
                      ),
                    ],
                  ),
                  _buildExpandableItem(
                    context: context,
                    title: '3. 閱讀數據與圖表',
                    initiallyExpanded: false,
                    children: [
                      const Text(
                        '卡池分類：提供「特許、武庫、重構、常駐、啟程」五大類別，手機版可透過上方選單左右滑動查看。\n'
                        '• 獨立計算：常規尋訪與階段免費十連分開統計，避免無保底的免費十連紀錄影響常規尋訪的保底與抽數統計。\n'
                        '• 全部數據：點擊「全部數據」可查看 UP/歪明細、彩率與稀有度分布圖等。',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                  _buildExpandableItem(
                    context: context,
                    title: '4. 客製化圖片導出',
                    initiallyExpanded: false,
                    children: [
                      const Text(
                        '在「導出圖片」視窗右上角點選「齒輪圖示」，可自訂要顯示的數據項目；系統會自動記住排版設定。\n'
                        '此外，也可以分別選擇是否在圖片中顯示生成時間、遊戲 UID 與帳號名稱。',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                  _buildExpandableItem(
                    context: context,
                    title: '5. 多帳號切換',
                    initiallyExpanded: false,
                    children: [
                      const Text(
                        '每次同步時，程式會自動取得目前登入帳號所對應的遊戲 UID，並依所屬伺服器分別保存尋訪紀錄。\n'
                        '您可以透過畫面上方或側邊欄的「遊戲 UID」選單，直接切換已同步過的帳號紀錄。',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                  _buildExpandableItem(
                    context: context,
                    title: '6. 雙重資料保護機制',
                    initiallyExpanded: false,
                    children: [
                      Text.rich(
                        TextSpan(
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            height: 1.5,
                          ),
                          children: [
                            const TextSpan(
                              text: '• 自動備份：開啟後，每次同步都會自動更新最新備份。電腦版儲存於下載資料夾或應用程式目錄，手機版則儲存於 App 內部私有目錄。此功能主要用於應對日常同步異常或操作失誤，可透過「從最新的自動備份還原」快速復原。\n',
                            ),
                            const WidgetSpan(
                              alignment: PlaceholderAlignment.middle,
                              child: Padding(
                                padding: EdgeInsets.only(right: 4.0),
                                child: Icon(
                                  Icons.warning_rounded,
                                  color: Color(0xFFF59E0B),
                                  size: 15,
                                ),
                              ),
                            ),
                            const TextSpan(
                              text: '注意：',
                              style: TextStyle(
                                color: Color(0xFFEF4444),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const TextSpan(
                              text: '手機版解除安裝或清除 App 資料，可能會使內部的自動備份一併被系統刪除，因此不能將其視為永久保存的備份。\n\n',
                            ),
                            const TextSpan(
                              text: '• 手動匯出：點擊「匯出資料備份」可將紀錄儲存為獨立的 JSON 檔案，並自行選擇保存位置。若要跨設備轉移資料或長期保存，請務必使用此功能。',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  _buildExpandableItem(
                    context: context,
                    title: '7. 重置與解除安裝',
                    initiallyExpanded: false,
                    children: [
                      const Text(
                        '• 電腦版：於「資料備份與設定」點選「清除本機資料」，關閉程式後即可刪除應用程式資料夾，完成乾淨卸載（不影響手動匯出的備份檔）。\n'
                        '• 手機版：可透過系統設定中的「清除資料」重置應用程式。',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text(
                '開始使用',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// 顯示舊版備份未包含遊戲角色 UID 時的提示對話框。
  static Future<void> showLegacyBackupNoticeDialog(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF181920),
        title: const Text(
          '舊版備份匯入完成',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          '舊版備份未包含遊戲角色 UID，因此帳號選單暫時顯示「UID: 未知」，'
          '這是正常現象，並非資料匯入失敗。\n\n'
          '請執行一次「同步尋訪紀錄」，系統便會自動取得並補齊遊戲角色資訊。',
          style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              '我知道了',
              style: TextStyle(
                color: Color(0xFFFFCC00),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 建立折疊式說明項目。
  static Widget _buildExpandableItem({
    required BuildContext context,
    required String title,
    required List<Widget> children,
    bool initiallyExpanded = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: const Color(0xFF1E2029),
        borderRadius: BorderRadius.circular(8),
        clipBehavior: Clip.antiAlias,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white10),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              initiallyExpanded: initiallyExpanded,
              tilePadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 0,
              ),
              childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              expandedAlignment: Alignment.centerLeft,
              expandedCrossAxisAlignment: CrossAxisAlignment.start,
              iconColor: const Color(0xFFFFCC00),
              collapsedIconColor: Colors.white54,
              title: Text(
                title,
                style: const TextStyle(
                  color: Color(0xFFFFCC00),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              children: children,
            ),
          ),
        ),
      ),
    );
  }

  /// 建立一般說明項目，包含標題與純文字內容。
  static Widget _buildDisclaimerItem(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFFFFCC00),
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
