import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  static final Map<String, String> baseHeaders = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
    "Accept": "application/json, text/plain, */*",
    "Origin": "https://user.gryphline.com",
    "Referer": "https://user.gryphline.com/",
  };

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

  /// 第一階段：換取中繼碼並提取該帳號下「所有伺服器」的角色清單
  static Future<Map<String, dynamic>> getAccountRoles(String rawInput) async {
    final accountToken = extractCleanToken(rawInput);
    final appCodes = ["3dacefa138426cfe", "6eb76d4e13aa36e6", "be36d44aa36bfb5b", "endfield"];

    String? workingOauthToken;
    Map<String, dynamic>? bindData;

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

    // 展平角色清單：將綁定資料中的所有 roles 獨立提取出來
    final appList = bindData["data"]["list"] as List<dynamic>? ?? [];
    List<Map<String, dynamic>> flatRoles = [];

    for (final item in appList) {
      final bindingList = item["bindingList"] as List<dynamic>?;
      if (bindingList != null) {
        for (final binding in bindingList) {
          final uid = binding["uid"]?.toString();
          if (uid == null) continue;

          final innerRoles = binding["roles"] as List<dynamic>?;

          if (innerRoles != null && innerRoles.isNotEmpty) {
            // 如果該帳號下有多個伺服器的角色，把它們全部分開打包
            for (final innerRole in innerRoles) {
              flatRoles.add({
                "uid": uid,
                "serverId": innerRole["serverId"]?.toString() ?? "2",
                "serverName": innerRole["serverName"]?.toString() ?? "未知伺服器",
                "nickName": innerRole["nickName"]?.toString() ?? "未知角色",
              });
            }
          } else {
            // 防呆機制：如果沒有 innerRoles 陣列，退回使用外層資料
            flatRoles.add({
              "uid": uid,
              "serverId": binding["channelMasterId"]?.toString() ?? binding["serverId"]?.toString() ?? "2",
              "serverName": binding["channelName"]?.toString() ?? "未知伺服器",
              "nickName": binding["nickName"]?.toString() ?? "未知角色",
            });
          }
        }
      }
    }

    if (flatRoles.isEmpty) {
      throw Exception("驗證成功，但該帳號內未找到任何《終末地》角色資料！");
    }

    return {
      "oauthToken": workingOauthToken,
      "roles": flatRoles,
    };
  }

  /// 第二階段：透過使用者選定的 uid 與中繼碼，換取最終的抽卡金鑰
  static Future<String> fetchU8Token(String uid, String oauthToken) async {
    final u8Uri = Uri.parse("https://binding-api-account-prod.gryphline.com/account/binding/v1/u8_token_by_uid");

    var u8Res = await http.post(
      u8Uri,
      headers: {...baseHeaders, "Content-Type": "application/json"},
      body: jsonEncode({"uid": uid, "token": oauthToken}),
    );
    var u8Json = jsonDecode(u8Res.body);

    if (u8Json["status"] != 0) {
      u8Res = await http.get(
        u8Uri.replace(queryParameters: {"uid": uid, "token": oauthToken}),
        headers: baseHeaders,
      );
      u8Json = jsonDecode(u8Res.body);
    }

    if (u8Json["status"] == 0 && u8Json["data"] != null) {
      return u8Json["data"]["token"].toString();
    }

    throw Exception("獲取抽卡金鑰失敗：${u8Json['msg'] ?? '未知錯誤'}");
  }
}