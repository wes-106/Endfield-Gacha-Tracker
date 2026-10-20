import 'package:flutter/material.dart';

/// 負責存放純靜態、說明性質的對話框 (免責聲明、使用說明)
class InfoDialogs {
  // ==========================================================================
  // 免責聲明對話框
  // ==========================================================================
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
              Text('免責聲明與使用條款', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
            ],
          ),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDisclaimerItem('1. 適用伺服器與無關聯聲明', '本程式為玩家自製的免費輔助工具，目前僅支援「國際服 (Gryphline)」的資料解析，與《明日方舟：終末地》官方無任何附屬、授權或合作關係。'),
                  _buildDisclaimerItem('2. 圖片版權與非商業用途', '程式內使用的遊戲圖像、角色名稱等相關素材，版權皆屬官方所有。本工具僅供玩家個人紀錄與交流使用，嚴禁任何形式的商業用途。'),
                  _buildDisclaimerItem('3. 帳號與資安保證', '本程式採用「零信任設計」，絕對不會在本地或雲端儲存您的登入憑證 (Token)。Token 僅於同步當下在記憶體中運作，用完即毀，無盜帳號風險。但請妥善保管您的 Token，切勿隨意分享。'),
                  _buildDisclaimerItem('4. 資料準確性', '數據取自官方 API。若官方未來修改規則導致程式無法同步或數據遺失，開發者不承擔相關責任。'),
                  _buildDisclaimerItem('5. 隱私安全與無雲端設計', '基於保護隱私最高原則，本程式刻意不提供「雲端同步」功能，亦不會追蹤、收集或向外傳送任何設備資訊。您的尋訪紀錄與 UID 均「僅單純儲存於設備本地端」。這也是為何本程式採用實體 JSON 檔案作為跨設備轉移資料的唯一手段，將資料的完整控制權完全交還給您。'),
                  const Padding(
                    padding: EdgeInsets.only(top: 8, bottom: 16),
                    child: Divider(color: Colors.white12),
                  ),
                  const Center(
                    child: Text(
                      'Made by wes-106  |  v1.0.0',
                      style: TextStyle(color: Colors.white38, fontSize: 12, letterSpacing: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6)),
              onPressed: () => Navigator.pop(context),
              child: const Text('我已了解', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  // ==========================================================================
  // 使用說明對話框
  // ==========================================================================
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
              Text('使用說明與常見問題', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
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
                    '1. 尋訪紀錄保存機制',
                    '官方伺服器僅保留特定時間內的尋訪紀錄，若無法顯示更早之前的歷史數據為正常現象。\n'
                        '只要將紀錄導入本程式，數據便會交由您的本地設備保存。請注意：若設備損毀、遺失，或您主動解除安裝本程式、清除應用程式資料，本地的歷史紀錄將會隨之消失。',
                  ),
                  _buildDisclaimerItem(
                    '2. 如何導入資料',
                    '① 點選右上角或側邊欄的「同步尋訪紀錄」\n'
                        '② 點選「1. 登入官網」，在手機或系統預設瀏覽器內完成登入\n'
                        '③ 【重要】請勿滑掉或關閉該瀏覽器，直接切回本程式\n'
                        '④ 點選「2. 獲取 Token」，複製畫面上出現的整段代碼\n'
                        '⑤ 將代碼貼入下方輸入框並點選「開始同步」即可',
                  ),
                  _buildDisclaimerItem(
                    '3. 閱讀數據與圖表',
                    '• 卡池分類：提供「特許、武庫、常駐、重構、啟程」五大類別，手機版可透過上方選單左右滑動查看。\n'
                        '• 數據計算：「本池投入抽數」已包含 30 抽後贈送的十連尋訪；「平均出彩」的計算方式為（本池總投入抽數 ÷ 本池獲得 6★ 總數）。',
                  ),
                  _buildDisclaimerItem(
                    '4. 多帳號切換',
                    '每次同步時，程式會自動識別該次登入的遊戲 UID。每組 UID 皆有獨立的本地資料庫，您可以直接點選畫面上方的 UID 下拉選單快速切換帳號，無須重新登入。',
                  ),
                  _buildRichDisclaimerItem(
                    '5. 雙重資料保護機制',
                    [
                      const TextSpan(
                        text: '為防止設備損壞導致資料遺失，本程式提供兩套獨立的備份系統：\n\n'
                            '【自動備份】\n'
                            '開啟開關後，每次同步都會在系統內部或隱藏資料夾中默默寫入最新的備份（電腦版存於下載資料夾或應用程式目錄，手機版存於內部私有目錄）。\n'
                            '由於每次都是自動覆蓋舊檔不佔空間，此功能「主要用於應對日常同步異常或操作上的小差錯」，若不慎導致資料錯亂，可點擊「從最新的自動備份還原」快速復原。\n',
                      ),
                      const WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: Padding(
                          padding: EdgeInsets.only(right: 4.0),
                          child: Icon(Icons.warning_rounded, color: Color(0xFFF59E0B), size: 16),
                        ),
                      ),
                      const TextSpan(
                        text: '注意：',
                        style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold),
                      ),
                      const TextSpan(
                        text: '手機版（APK）若將應用程式解除安裝或清除 App 資料，內部的自動備份檔將會隨之被系統刪除，無法作為永久保存之用。\n\n',
                      ),
                      const TextSpan(
                        text: '【手動匯出】\n'
                            '點擊「匯出資料備份」會將當下紀錄存成專屬的 JSON 實體檔案，並讓您自選儲存位置。若要跨設備轉移資料或長期防護，請務必使用此功能。',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
              onPressed: () => Navigator.pop(context),
              child: const Text('開始使用', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  // 輔助排版文字的私有 Widget
  static Widget _buildDisclaimerItem(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Color(0xFFFFCC00), fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 4),
          Text(content, style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.5)),
        ],
      ),
    );
  }
  // 專門用來處理帶有顏色與特效的免責聲明區塊
  static Widget _buildRichDisclaimerItem(String title, List<InlineSpan> spans) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(color: Color(0xFFFFCC00), fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 6),
          Text.rich(
            TextSpan(
              style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
              children: spans,
            ),
          ),
        ],
      ),
    );
  }
}