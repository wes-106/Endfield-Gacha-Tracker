import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class GachaApiService {
  final String _baseUrl = 'ef-webview.gryphline.com';

  /// 提取所有角色卡池的原始資料並直接分類
  Future<Map<String, List<dynamic>>> fetchAllCharacters(String token, Set<String> knownSeqIds) async {
    Map<String, List<dynamic>> categorizedRecords = {
      'Special': [], 'Refactor': [], 'Standard': [], 'Beginner': []
    };

    Future<void> fetchSinglePool(String poolType, String category) async {
      bool hasMore = true;
      String? nextSeqId;

      while (hasMore) {
        Map<String, String> params = {
          'server_id': '2',
          'pool_type': poolType,
          'lang': 'zh-tw',
          'token': token,
        };
        if (nextSeqId != null) params['seq_id'] = nextSeqId;

        final uri = Uri.https(_baseUrl, '/api/record/char', params);

        try {
          final response = await http.get(uri);
          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            if (data['code'] != 0) break;

            final list = data['data']['list'] as List<dynamic>? ?? [];

            // 若回傳空陣列，代表該池未曾抽取或已達末端，直接中斷請求
            if (list.isEmpty) break;

            bool hitLocalRecord = false;
            List<dynamic> newRecords = [];

            for (var item in list) {
              if (knownSeqIds.contains(item['seqId'].toString())) {
                hitLocalRecord = true;
              } else {
                newRecords.add(item);
              }
            }

            categorizedRecords[category]!.addAll(newRecords);

            // 若遇到已存在本地的資料，停止後續分頁請求
            if (hitLocalRecord) break;

            hasMore = data['data']['hasMore'] ?? false;
            if (hasMore) {
              nextSeqId = list.last['seqId'].toString();
              await Future.delayed(const Duration(milliseconds: 150));
            }
          } else {
            hasMore = false;
          }
        } catch (e) {
          debugPrint("抓取角色池 $poolType 發生錯誤: $e");
          break;
        }
      }
    }

    await Future.wait([
      fetchSinglePool('E_CharacterGachaPoolType_Special', 'Special'),
      fetchSinglePool('E_CharacterGachaPoolType_Rerun', 'Refactor'),
      fetchSinglePool('E_CharacterGachaPoolType_Standard', 'Standard'),
      fetchSinglePool('E_CharacterGachaPoolType_Beginner', 'Beginner'),
    ]);

    return categorizedRecords;
  }

  /// 提取所有武器卡池的原始資料
  Future<List<dynamic>> fetchWeaponRecords(String token, Set<String> knownSeqIds) async {
    List<dynamic> allRecords = [];

    final poolUri = Uri.https(_baseUrl, '/api/record/weapon/pool', {
      'server_id': '2', 'lang': 'zh-tw', 'token': token,
    });

    try {
      final poolResponse = await http.get(poolUri);
      if (poolResponse.statusCode != 200) return allRecords;

      final poolData = json.decode(poolResponse.body);
      if (poolData['code'] != 0) return allRecords;

      final List<dynamic> weaponPools = poolData['data'] ?? [];

      for (var pool in weaponPools) {
        String poolId = pool['poolId'];
        bool hasMore = true;
        String? nextSeqId;

        while (hasMore) {
          Map<String, String> params = {
            'server_id': '2',
            'lang': 'zh-tw',
            'token': token,
            'pool_id': poolId,
          };
          if (nextSeqId != null) params['seq_id'] = nextSeqId;

          final recordUri = Uri.https(_baseUrl, '/api/record/weapon', params);
          final recordResponse = await http.get(recordUri);

          if (recordResponse.statusCode == 200) {
            final recordData = json.decode(recordResponse.body);
            if (recordData['code'] != 0) break;

            final currentList = recordData['data']['list'] as List<dynamic>? ?? [];

            // 若該武器池無抽取紀錄，跳至下一個子卡池
            if (currentList.isEmpty) break;

            bool hitLocalRecord = false;
            List<dynamic> newRecords = [];

            for (var item in currentList) {
              if (knownSeqIds.contains(item['seqId'].toString())) {
                hitLocalRecord = true;
              } else {
                newRecords.add(item);
              }
            }

            allRecords.addAll(newRecords);

            if (hitLocalRecord) break;

            hasMore = recordData['data']['hasMore'] ?? false;
            if (hasMore) {
              nextSeqId = currentList.last['seqId'].toString();
              await Future.delayed(const Duration(milliseconds: 150));
            }
          } else {
            hasMore = false;
          }
        }
      }
    } catch (e) {
      debugPrint("武器池抓取發生錯誤: $e");
    }

    return allRecords;
  }
}