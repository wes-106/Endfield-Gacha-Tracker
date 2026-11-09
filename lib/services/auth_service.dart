import 'dart:convert';

import 'package:http/http.dart' as http;

/// 負責帳號驗證、角色清單取得，以及抽卡 API Token 的換取。
class AuthService {
  /// Gryphline API 請求使用的基本標頭。
  static final Map<String, String> baseHeaders = {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
    'Accept': 'application/json, text/plain, */*',
    'Origin': 'https://user.gryphline.com',
    'Referer': 'https://user.gryphline.com/',
  };

  /// 安全解析 JSON，避免非 JSON 回應造成 FormatException。
  static Map<String, dynamic>? safeJsonDecode(String body) {
    try {
      final decoded = jsonDecode(body);

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  /// 清理使用者輸入的帳號 Token。
  static String extractCleanToken(String rawStr) {
    final str = rawStr.trim();

    if (str.startsWith('{')) {
      try {
        final map = jsonDecode(str);

        if (map is Map<String, dynamic>) {
          final data = map['data'];

          if (data is Map<String, dynamic>) {
            return data['content']?.toString() ?? str;
          }
        }
      } catch (_) {}
    }

    return str;
  }

  /// 第一階段：驗證帳號並取得該帳號綁定的所有伺服器角色。
  static Future<Map<String, dynamic>> getAccountRoles(String rawInput) async {
    final accountToken = extractCleanToken(rawInput);

    if (accountToken.isEmpty) {
      throw Exception('請輸入有效的帳號 Token。');
    }

    // 依序嘗試可用的 AppCode。
    final appCodes = [
      '3dacefa138426cfe',
      '6eb76d4e13aa36e6',
      'be36d44aa36bfb5b',
      'endfield',
    ];

    String? workingOauthToken;
    Map<String, dynamic>? bindData;

    for (final code in appCodes) {
      for (final grantType in [1, 0]) {
        try {
          // 使用帳號 Token 換取 OAuth 中繼 Token。
          final grantRes = await http
              .post(
                Uri.parse('https://as.gryphline.com/user/oauth2/v2/grant'),
                headers: {...baseHeaders, 'Content-Type': 'application/json'},
                body: jsonEncode({
                  'token': accountToken,
                  'appCode': code,
                  'type': grantType,
                }),
              )
              .timeout(const Duration(seconds: 15));

          if (grantRes.statusCode != 200) {
            continue;
          }

          final grantJson = safeJsonDecode(grantRes.body);

          if (grantJson == null || grantJson['status'] != 0) {
            continue;
          }

          final grantResult = grantJson['data'];

          if (grantResult is! Map<String, dynamic>) {
            continue;
          }

          final oauthVal = grantResult['token'] ?? grantResult['code'];

          if (oauthVal == null) {
            continue;
          }

          // 使用 OAuth 中繼 Token 查詢帳號綁定的角色資料。
          final bindUri =
              Uri.parse(
                'https://binding-api-account-prod.gryphline.com/account/binding/v1/binding_list',
              ).replace(
                queryParameters: {
                  'token': oauthVal.toString(),
                  'appCode': 'endfield',
                },
              );

          final bindRes = await http
              .get(bindUri, headers: baseHeaders)
              .timeout(const Duration(seconds: 15));

          if (bindRes.statusCode != 200) {
            continue;
          }

          final bindJson = safeJsonDecode(bindRes.body);

          if (bindJson == null || bindJson['status'] != 0) {
            continue;
          }

          workingOauthToken = oauthVal.toString();
          bindData = bindJson;

          break;
        } catch (_) {
          // 單次請求失敗時，繼續嘗試其他 AppCode 或 Grant Type。
          continue;
        }
      }

      // 已取得綁定資料時，不再嘗試其他 AppCode。
      if (bindData != null) {
        break;
      }
    }

    if (bindData == null || workingOauthToken == null) {
      throw Exception('無法驗證帳號，請確認您貼上的 Token 是否有效或已過期。');
    }

    // 解析帳號綁定資料。
    final bindResult = bindData['data'];

    if (bindResult is! Map<String, dynamic>) {
      throw Exception('帳號綁定資料格式異常。');
    }

    final appList = bindResult['list'] is List
        ? bindResult['list'] as List<dynamic>
        : <dynamic>[];

    // 將巢狀的伺服器與角色資料整理成扁平清單。
    final List<Map<String, dynamic>> flatRoles = [];

    for (final item in appList) {
      if (item is! Map) continue;

      final bindingList = item['bindingList'];

      if (bindingList is! List) continue;

      for (final binding in bindingList) {
        if (binding is! Map) continue;

        final uid = binding['uid']?.toString();

        if (uid == null || uid.isEmpty) {
          continue;
        }

        final innerRoles = binding['roles'];

        if (innerRoles is List && innerRoles.isNotEmpty) {
          // 有內層角色資料時，逐一整理各伺服器角色。
          for (final innerRole in innerRoles) {
            if (innerRole is! Map) continue;

            flatRoles.add({
              'uid': uid,
              'serverId': innerRole['serverId']?.toString() ?? '2',
              'serverName': innerRole['serverName']?.toString() ?? '未知伺服器',
              'nickName': innerRole['nickName']?.toString() ?? '未知角色',
            });
          }
        } else {
          // 沒有內層角色資料時，改用外層綁定資料。
          flatRoles.add({
            'uid': uid,
            'serverId':
                binding['channelMasterId']?.toString() ??
                binding['serverId']?.toString() ??
                '2',
            'serverName': binding['channelName']?.toString() ?? '未知伺服器',
            'nickName': binding['nickName']?.toString() ?? '未知角色',
          });
        }
      }
    }

    if (flatRoles.isEmpty) {
      throw Exception('驗證成功，但該帳號內未找到任何《終末地》角色資料！');
    }

    return {'oauthToken': workingOauthToken, 'roles': flatRoles};
  }

  /// 第二階段：根據使用者選定的 UID 與 OAuth Token，取得最終抽卡 Token。
  static Future<String> fetchU8Token(String uid, String oauthToken) async {
    if (uid.isEmpty || oauthToken.isEmpty) {
      throw Exception('UID 或 OAuth Token 不可為空。');
    }

    final u8Uri = Uri.parse(
      'https://binding-api-account-prod.gryphline.com/account/binding/v1/u8_token_by_uid',
    );

    Map<String, dynamic>? u8Json;

    // 優先使用 POST 取得抽卡 Token。
    try {
      final u8Res = await http
          .post(
            u8Uri,
            headers: {...baseHeaders, 'Content-Type': 'application/json'},
            body: jsonEncode({'uid': uid, 'token': oauthToken}),
          )
          .timeout(const Duration(seconds: 15));

      if (u8Res.statusCode == 200) {
        u8Json = safeJsonDecode(u8Res.body);
      }
    } catch (_) {
      // POST 失敗時，交由後續 GET 請求備援。
    }

    // POST 請求失敗或 API 回傳狀態不成功時，改用 GET。
    if (u8Json == null || u8Json['status'] != 0) {
      try {
        final getRes = await http
            .get(
              u8Uri.replace(queryParameters: {'uid': uid, 'token': oauthToken}),
              headers: baseHeaders,
            )
            .timeout(const Duration(seconds: 15));

        if (getRes.statusCode != 200) {
          throw Exception('伺服器無回應或維護中 (HTTP ${getRes.statusCode})');
        }

        u8Json = safeJsonDecode(getRes.body);

        if (u8Json == null) {
          throw Exception('伺服器回傳的資料格式異常，無法解析 JSON。');
        }
      } catch (e) {
        if (e is Exception) rethrow;

        throw Exception('取得抽卡金鑰時發生網路錯誤：$e');
      }
    }

    // 確認 API 成功回傳，並提取最終抽卡 Token。
    if (u8Json['status'] == 0 && u8Json['data'] is Map) {
      final token = u8Json['data']['token'];

      if (token != null && token.toString().isNotEmpty) {
        return token.toString();
      }
    }

    throw Exception('獲取抽卡金鑰失敗：${u8Json['msg'] ?? '未知錯誤'}');
  }
}
