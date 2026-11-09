import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';

class ImageExportService {
  /// 將 Uint8List 圖片跨平台儲存至設備
  /// 回傳值為成功儲存後的提示文字
  static Future<String> saveImage(Uint8List capturedImage) async {
    final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();

    if (Platform.isAndroid || Platform.isIOS) {
      final result = await ImageGallerySaverPlus.saveImage(
        capturedImage,
        name: "Endfield_Record_$timestamp",
      );
      if (result['isSuccess'] == true) {
        return '✅ 圖片導出成功！\n已儲存至您的「手機相簿」中。';
      } else {
        throw Exception('儲存至相簿失敗，請確認是否授權儲存權限');
      }
    } else {
      final directory = await getDownloadsDirectory();

      // 增加防呆：確保桌面版環境能抓到下載目錄
      if (directory == null) {
        throw Exception('無法取得系統下載資料夾路徑');
      }

      final String filePath =
          '${directory.path}${Platform.pathSeparator}Endfield_Record_$timestamp.png';
      final file = File(filePath);
      await file.writeAsBytes(capturedImage);
      return '✅ 圖片導出成功！已儲存至：\n$filePath';
    }
  }
}
