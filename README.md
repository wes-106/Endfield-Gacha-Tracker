# Endfield Gacha Tracker (終末地尋訪紀錄終端)

為《明日方舟：終末地》國際服玩家打造的本機尋訪紀錄管理與分析工具，支援 Windows 與 Android。尋訪紀錄主要儲存於使用者裝置，不需要自行架設或使用本專案的雲端資料庫。

---

## 主要功能
* **雙平台支援**：支援 Windows 電腦版與 Android 手機版。
* **多帳號切換**：自動辨識 UID，可多帳號切換互不干擾。
* **資料備份**：支援每次同步後的自動備份與跨設備手動匯出/導入 JSON 檔。
* **輸出圖片**：可將尋訪紀錄輸出成圖片。

---

## 隱私與資訊安全聲明
- **Token 處理機制**：本程式不會刻意將您的 Token 寫入任何本地設定檔或備份檔中。Token 僅在同步過程中用於向官方 API 請求資料，不會被持久化儲存。
- **資料傳輸**：您的 Token 與抽卡資料均為「本機設備 ↔ 官方伺服器」點對點直接傳輸，不會經過或上傳至任何第三方資料庫。
- **使用者安全須知**：儘管本程式未對 Token 進行儲存，但仍強烈建議您**妥善保護您的 Token**。請勿將獲取到的字串截圖分享或張貼於公共論壇，並一律僅從官方網頁等正當管道獲取驗證碼。

---

## 下載與安裝
請前往 [Releases](../../releases) 頁面下載對應平台的安裝檔：
* **Windows 電腦版**：下載 `Endfield_Tracker.zip`，解壓縮後開啟資料夾內的 `.exe` 檔案即可執行。
* **Android 手機版**：下載 `Endfield_Tracker.apk` 直接安裝。

### 檔案安全校驗 (SHA-256)
為了確保您下載的檔案為作者本人發布且未遭惡意竄改，您可以使用以下 SHA-256 雜湊值進行核對（當前版本 v1.1.0）：

| 檔案名稱 | SHA-256 雜湊值 |
| :--- | :--- |
| `Endfield_Tracker.zip` | `A042E8E001245A081C4BDF889B9E21ECC8490E0E88527BA61EF580CFAA16ADDF` |
| `Endfield_Tracker.apk` | `6566A4D53102B52EF3F0DD094C0604B0910FB064DA67DADB038137BBF05AB924` |

> **驗證方法：**
> * Windows: 打開 PowerShell 輸入 `Get-FileHash <檔案路徑> -Algorithm SHA256`

---

## 本機開發

如果您希望親自驗證程式碼，或針對不同平台進行編譯，請參考以下步驟：

### 環境要求
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (版本 3.13.5 或以上)
- 若編譯 Windows 版：需安裝 Visual Studio 2022 (包含 C++ 桌面開發工作負載)
- 若編譯 Android 版：需安裝 Android Studio 

### 1. 取得原始碼與依賴套件
```bash
git clone https://github.com/wes-106/Endfield-Gacha-Tracker.git
cd gacha_record
flutter pub get
```

### 2. 程式碼檢查
```bash
flutter analyze
```

### 3. 編譯執行檔
建置 Windows 桌面版 (.exe):

```bash
flutter build windows
```
建置完成的檔案將位於 build\windows\x64\runner\Release\

建置 Android 手機版 (.apk):

```bash
flutter build apk --release
```
建置完成的檔案將位於 build\app\outputs\flutter-apk\

---

## 使用說明
1. 下載並開啟應用程式。
2. 點擊「同步尋訪紀錄」，根據畫面指示前往官方網站登入。
3. 獲取您的專屬 Token，並將其貼入程式的輸入框中，點擊開始同步即可。

*(詳細的圖文教學與資料備份機制，請參考程式內建的「使用說明」選項)*
> **注意事項：官方伺服器僅保留近 90 天的尋訪紀錄。** 建議玩家養成定期將資料同步至本機的習慣，避免早期紀錄因超過期限而遺失。

---

## 專案結構

```text
Endfield-Gacha-Tracker/
│
├── android/            # Android 平台相關設定與外殼
├── windows/            # Windows 平台相關設定與外殼
├── ios / macos / ...   # 其他跨平台支援外殼 (標準 Flutter 架構)
├── assets/             # 程式圖標與靜態資源
├── lib/                # 核心程式碼目錄
│   ├── dialogs/        # 互動對話框 (匯出、資訊說明、同步操作)
│   ├── models/         # 資料模型與資料庫結構定義 (Isar)
│   ├── services/       # 核心邏輯 (API 請求、驗證、備份、本機儲存與解析)
│   ├── widgets/        # 共用 UI 元件 (側邊欄、卡片等)
│   └── main.dart       # 程式主入口
├── LICENSES/           # 第三方許可證副本
└── pubspec.yaml        # 專案相依套件設定
```

---

## 遠端字典檔與更新機制
為了在不頻繁更新應用程式 (APP/EXE) 的情況下，動態適配官方最新的卡池與角色圖片，本程式會在執行時，自動從外部專案 [endfield-dictionary](https://github.com/wes-106/endfield-dictionary) 下載以下三份 JSON 字典檔：
1. 角色名稱與圖片對照表
2. 武器名稱與圖片對照表
3. 當期 UP 卡池資訊清單

**對程式運作的影響**：
這些遠端檔案僅用於「畫面顯示」的對應（例如將代碼轉換為角色頭像），不參與帳號驗證或抽卡紀錄的本地存取邏輯。若遊戲推出新卡池時您發現圖片無法顯示，通常代表遠端字典檔尚未更新。請靜候開發者更新 `endfield-dictionary` 倉庫上的檔案，您的程式在下次開啟時即會自動載入最新圖庫。

---

## 開發技術與工具
* **Flutter & Dart**：跨平台應用程式開發框架與核心程式語言。
* **本地儲存方案**：使用實體 JSON 檔案與 Isar 資料庫。
* **AI 輔助開發**：本專案的程式碼生成、邏輯除錯與架構優化，均由 AI 協助完成。

---

## 開發初衷

製作這個小工具的出發點很單純，只是希望能把自己的尋訪紀錄，保存成自己覺得好看、適合留念的樣貌。

由於我本身對 Dart 與 Flutter 的開發經驗為零，這個專案是完全仰賴 AI 輔助摸索出來的產物。如果有人檢視原始碼，並且被裡面奇妙的變數命名、神秘的判定邏輯，或是生澀的檔案拆分與模組架構給噁心到，在此先說聲抱歉！程式碼確實還有很大的進步空間，也當作是個人學習過程的一份紀錄。

---

## 免責聲明與版權說明
* **程式碼授權**：本專案的「原始程式碼」在 MIT License 下開源，允許自由使用與修改 (見根目錄 LICENSE)。
* **遊戲素材版權**：本專案內所引用的《明日方舟：終末地》遊戲相關圖像、專有名詞與素材，其版權均歸屬官方發行商所有。詳見：[endfield-dictionary](https://github.com/wes-106/endfield-dictionary)。
* **非商業用途限制**：本工具僅供玩家個人紀錄與交流使用，嚴禁任何人提取本專案中的官方素材進行任何形式的商業營利行為。
* **無官方關聯與資料免責**：本專案為玩家自製的輔助工具，與官方無任何合作關係。本程式採本地端運行，玩家需妥善保管備份檔案。若因操作不當或官方 API 規則變動導致資料遺失，開發者不承擔相關責任。

---

## 許可與致謝
本專案在 MIT License 下開源 (見根目錄 LICENSE)。

並感謝以下開源資源：
* **Flutter 框架與官方套件**：(見 BSD-3-Clause 授權說明)
* **Google Material Symbols**：相關圖標資源 (見 Apache-2.0 授權說明)

相關協議副本置於LICENSE資料夾中。
