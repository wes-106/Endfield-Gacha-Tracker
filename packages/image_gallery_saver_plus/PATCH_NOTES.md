# image_gallery_saver_plus 本機修改紀錄

原始套件版本：5.1.1

修改原因：
- 原始版本使用的 Kotlin Android Plugin 與 AGP 9 內建 Kotlin 發生衝突。
- 原始 Android Gradle 設定需要調整，以相容 AGP 9。

修改內容：
- 移除套件自行載入的 AGP 與 Kotlin Gradle Plugin。
- 移除 `org.jetbrains.kotlin.android` 插件套用。
- 將舊式 `kotlinOptions` 改為 `kotlin.compilerOptions`。
- 保留原有 compileSdk、minSdk、Java 版本及其他套件設定。

驗證結果：
- AGP 9.3.1
- Gradle 9.5.0
- Release APK 建置成功
- Android 實際功能測試正常

注意：
本機版本用於確保專案與 AGP 9 的相容性。未來更新上游套件時，需重新檢查並套用必要修改。
