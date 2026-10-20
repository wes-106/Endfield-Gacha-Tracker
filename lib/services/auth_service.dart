import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  static final Map<String, String> baseHeaders = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
    "Accept": "application/json, text/plain, */*",
    "Origin": "https://user.gryphline.com",
    "Referer": "https://user.gryphline.com/",
  };

  /// 處理從網頁複製的 JSON 格式，提取純淨 token
  static String extractCleanToken(String rawStr) {
    final str = rawStr.trim();
    if (str.startsWith("{")) {
      try {
        final map = jsonDecode(str);
        return map["data"]["content"]?.toString() ?? str;
      } catch (_) {}
    }
    return str;
  }

  /// 執行完整的驗證鏈：account_token -> oauth_token -> u8_token
  static Future<Map<String, String>> getU8Token(String rawInput) async {
    final accountToken = extractCleanToken(rawInput);
    final appCodes = ["3dacefa138426cfe", "6eb76d4e13aa36e6", "be36d44aa36bfb5b", "endfield"];

    String? workingOauthToken;
    Map<String, dynamic>? bindData;

    // Step 1 & 2: 嘗試換取中繼碼與角色綁定資料
    for (final code in appCodes) {
      for (final grantType in [1, 0]) {
        try {
          final grantRes = await http.post(
            Uri.parse("https://as.gryphline.com/user/oauth2/v2/grant"),
            headers: {...baseHeaders, "Content-Type": "application/json"},
            body: jsonEncode({"token": accountToken, "appCode": code, "type": grantType}),
          );

          final grantJson = jsonDecode(grantRes.body);
          if (grantJson["status"] != 0) continue;

          final oauthVal = grantJson["data"]?["token"] ?? grantJson["data"]?["code"];
          if (oauthVal == null) continue;

          // 驗證綁定狀態
          final bindUri = Uri.parse("https://binding-api-account-prod.gryphline.com/account/binding/v1/binding_list")
              .replace(queryParameters: {"token": oauthVal.toString(), "appCode": "endfield"});

          final bindRes = await http.get(bindUri, headers: baseHeaders);
          final bindJson = jsonDecode(bindRes.body);

          if (bindJson["status"] == 0) {
            workingOauthToken = oauthVal.toString();
            bindData = bindJson;
            break;
          }
        } catch (e) {
          continue;
        }
      }
      if (bindData != null) break;
    }

    if (bindData == null || workingOauthToken == null) {
      throw Exception("無法驗證帳號，請確認您貼上的 Token 是否有效或已過期。");
    }

    // 提取使用者 UID
    final appList = bindData["data"]["list"] as List<dynamic>? ?? [];
    Map<String, dynamic>? role;
    for (final item in appList) {
      final bindingList = item["bindingList"] as List<dynamic>?;
      if (bindingList != null && bindingList.isNotEmpty) {
        role = bindingList[0];
        break;
      }
    }

    if (role == null) {
      throw Exception("驗證成功，但該帳號內未找到《終末地》角色資料！");
    }

    final uid = role["uid"].toString();

    // Step 3: 換取最終的 u8_token
    final u8Uri = Uri.parse("https://binding-api-account-prod.gryphline.com/account/binding/v1/u8_token_by_uid");

    var u8Res = await http.post(
      u8Uri,
      headers: {...baseHeaders, "Content-Type": "application/json"},
      body: jsonEncode({"uid": uid, "token": workingOauthToken}),
    );
    var u8Json = jsonDecode(u8Res.body);

    // POST 失敗時降級嘗試 GET
    if (u8Json["status"] != 0) {
      u8Res = await http.get(
        u8Uri.replace(queryParameters: {"uid": uid, "token": workingOauthToken}),
        headers: baseHeaders,
      );
      u8Json = jsonDecode(u8Res.body);
    }

    if (u8Json["status"] == 0 && u8Json["data"] != null) {
      return {
        "token": u8Json["data"]["token"].toString(),
        "uid": uid
      };
    }

    throw Exception("獲取抽卡金鑰失敗：${u8Json['msg'] ?? '未知錯誤'}");
  }
}