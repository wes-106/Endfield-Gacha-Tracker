/// 卡池共用設定模型
class PoolConfig {
  final String uiKey;
  final String dbKey;
  final String displayName;
  final bool isWeapon;
  final String? apiPoolType;

  const PoolConfig({
    required this.uiKey,
    required this.dbKey,
    required this.displayName,
    required this.isWeapon,
    this.apiPoolType,
  });
}

/// 全域卡池設定清單
/// 未來若遊戲新增卡池種類，直接於此陣列擴充即可套用至全專案。
const List<PoolConfig> appPoolConfigs = [
  PoolConfig(
    uiKey: 'Special',
    dbKey: 'pool_special',
    displayName: '特許尋訪',
    isWeapon: false,
    apiPoolType: 'E_CharacterGachaPoolType_Special',
  ),
  PoolConfig(
    uiKey: 'Refactor',
    dbKey: 'pool_refactor',
    displayName: '重構尋訪',
    isWeapon: false,
    apiPoolType: 'E_CharacterGachaPoolType_Rerun',
  ),
  PoolConfig(
    uiKey: 'Standard',
    dbKey: 'pool_standard',
    displayName: '常駐尋訪',
    isWeapon: false,
    apiPoolType: 'E_CharacterGachaPoolType_Standard',
  ),
  PoolConfig(
    uiKey: 'Weapon',
    dbKey: 'pool_weapon',
    displayName: '武庫申領',
    isWeapon: true,
    apiPoolType: null,
  ),
  PoolConfig(
    uiKey: 'Beginner',
    dbKey: 'pool_beginner',
    displayName: '啟程尋訪',
    isWeapon: false,
    apiPoolType: 'E_CharacterGachaPoolType_Beginner',
  ),
];
