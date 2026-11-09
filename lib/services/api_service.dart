import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/pool_config.dart';

/// 負責向 Gryphline 官方 API 取得角色與武器尋訪紀錄。
class GachaApiService {
  final String _baseUrl = 'ef-webview.gryphline.com';

  /// 取得所有角色卡池的尋訪紀錄，並依照卡池設定分類。
  Future<Map<String, List<dynamic>>> fetchAllCharacters(
    String token,
    String serverId,
    Set<String> knownSeqIds,
  ) async {
    // 先依照設定建立角色卡池分類，確保每個分類都有對應的空清單。
    Map<String, List<dynamic>> categorizedRecords = {
      for (var config in appPoolConfigs.where((c) => !c.isWeapon))
        config.uiKey: [],
    };

    /// 分頁取得單一角色卡池的紀錄。
    Future<void> fetchSinglePool(String poolType, String category) async {
      bool hasMore = true;
      String? nextSeqId;

      while (hasMore) {
        Map<String, String> params = {
          'server_id': serverId,
          'pool_type': poolType,
          'lang': 'zh-tw',
          'token': token,
        };

        // 有下一頁游標時，才加入 seq_id 參數。
        if (nextSeqId != null) params['seq_id'] = nextSeqId;

        final uri = Uri.https(_baseUrl, '/api/record/char', params);

        try {
          final response = await http
              .get(uri)
              .timeout(const Duration(seconds: 15));

          if (response.statusCode == 200) {
            final data = json.decode(response.body);

            if (data['code'] != 0) {
              throw Exception(
                data['msg'] ??
                    data['message'] ??
                    'API 回傳錯誤 (Code: ${data['code']})',
              );
            }

            final list = data['data']['list'] as List<dynamic>? ?? [];

            // 沒有紀錄代表此卡池已無資料可取得。
            if (list.isEmpty) break;

            bool hitLocalRecord = false;
            List<dynamic> newRecords = [];

            for (var item in list) {
              final seqId = item['seqId'].toString();

              if (knownSeqIds.contains(seqId)) {
                hitLocalRecord = true;
              } else {
                newRecords.add(item);
              }
            }

            categorizedRecords[category]!.addAll(newRecords);

            // 已遇到本機紀錄，代表已追上既有資料，不必再往更舊的頁面查詢。
            if (hitLocalRecord) break;

            hasMore = data['data']['hasMore'] ?? false;

            if (hasMore) {
              nextSeqId = list.last['seqId'].toString();

              // 稍微延遲下一次請求，避免連續發送過於密集的請求。
              await Future.delayed(const Duration(milliseconds: 150));
            }
          } else {
            throw Exception('HTTP 狀態碼錯誤: ${response.statusCode}');
          }
        } catch (e) {
          final errorMessage = e.toString();
          final safeErrorMsg = token.isNotEmpty
              ? errorMessage.replaceAll(token, '***')
              : errorMessage;

          debugPrint('抓取角色池 $poolType 發生錯誤: $safeErrorMsg');

          if (e is TimeoutException) {
            throw Exception('伺服器回應超時，請檢查網路狀態或稍後再試。');
          }

          throw Exception('抓取角色池失敗: $safeErrorMsg');
        }
      }
    }

    // 各角色卡池互相獨立，因此可以平行執行抓取。
    await Future.wait(
      appPoolConfigs
          .where((c) => !c.isWeapon && c.apiPoolType != null)
          .map((config) => fetchSinglePool(config.apiPoolType!, config.uiKey)),
    );

    return categorizedRecords;
  }

  /// 取得所有武器卡池的尋訪紀錄。
  Future<List<dynamic>> fetchWeaponRecords(
    String token,
    String serverId,
    Set<String> knownSeqIds,
  ) async {
    List<dynamic> allRecords = [];

    // 先取得目前可查詢的武器卡池清單。
    final poolUri = Uri.https(_baseUrl, '/api/record/weapon/pool', {
      'server_id': serverId,
      'lang': 'zh-tw',
      'token': token,
    });

    try {
      final poolResponse = await http
          .get(poolUri)
          .timeout(const Duration(seconds: 15));

      if (poolResponse.statusCode != 200) {
        throw Exception('HTTP 狀態碼錯誤: ${poolResponse.statusCode}');
      }

      final poolData = json.decode(poolResponse.body);

      if (poolData['code'] != 0) {
        throw Exception(poolData['message'] ?? 'API 回傳錯誤');
      }

      final List<dynamic> weaponPools = poolData['data'] ?? [];

      // 逐一處理每個武器卡池。
      for (var pool in weaponPools) {
        String poolId = pool['poolId'];
        bool hasMore = true;
        String? nextSeqId;

        // 目前卡池仍有下一頁資料時，持續取得紀錄。
        while (hasMore) {
          Map<String, String> params = {
            'server_id': serverId,
            'lang': 'zh-tw',
            'token': token,
            'pool_id': poolId,
          };

          if (nextSeqId != null) params['seq_id'] = nextSeqId;

          final recordUri = Uri.https(_baseUrl, '/api/record/weapon', params);

          final recordResponse = await http
              .get(recordUri)
              .timeout(const Duration(seconds: 15));

          if (recordResponse.statusCode == 200) {
            final recordData = json.decode(recordResponse.body);

            if (recordData['code'] != 0) {
              throw Exception(recordData['message'] ?? 'API 回傳錯誤');
            }

            final currentList =
                recordData['data']['list'] as List<dynamic>? ?? [];

            if (currentList.isEmpty) break;

            bool hitLocalRecord = false;
            List<dynamic> newRecords = [];

            for (var item in currentList) {
              final seqId = item['seqId'].toString();

              if (knownSeqIds.contains(seqId)) {
                hitLocalRecord = true;
              } else {
                newRecords.add(item);
              }
            }

            allRecords.addAll(newRecords);

            // 已遇到本機紀錄，代表已追上既有資料，不必繼續查詢更舊的紀錄。
            if (hitLocalRecord) break;

            hasMore = recordData['data']['hasMore'] ?? false;

            if (hasMore) {
              nextSeqId = currentList.last['seqId'].toString();

              await Future.delayed(const Duration(milliseconds: 150));
            }
          } else {
            throw Exception('HTTP 狀態碼錯誤: ${recordResponse.statusCode}');
          }
        }
      }
    } catch (e) {
      final errorMessage = e.toString();
      final safeErrorMsg = token.isNotEmpty
          ? errorMessage.replaceAll(token, '***')
          : errorMessage;

      debugPrint('武器池抓取發生錯誤: $safeErrorMsg');

      if (e is TimeoutException) {
        throw Exception('伺服器回應超時，請檢查網路狀態或稍後再試。');
      }

      throw Exception('抓取武器池失敗: $safeErrorMsg');
    }

    return allRecords;
  }
}
