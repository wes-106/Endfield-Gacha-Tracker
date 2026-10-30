/// 卡池共用設定模型
class PoolConfig {
  final String uiKey;
  final String dbKey;
  final bool isWeapon;

  const PoolConfig(
      this.uiKey,
      this.dbKey,
      this.isWeapon,
      );
}

// 若未來遊戲新增卡池種類，僅需於此處新增對應的 PoolConfig 即可套用至全域。
const List<PoolConfig> appPoolConfigs = [
  PoolConfig('Special', 'pool_special', false),
  PoolConfig('Refactor', 'pool_refactor', false),
  PoolConfig('Standard', 'pool_standard', false),
  PoolConfig('Weapon', 'pool_weapon', true),
  PoolConfig('Beginner', 'pool_beginner', false),
];