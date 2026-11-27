import 'package:isar_community/isar.dart';

part 'game_role.g.dart';

/// 遊戲角色資料。
///
/// 以 localDbUid 對應既有的本機帳號與伺服器識別鍵，
/// 儲存該識別鍵所對應的遊戲內角色資訊。
@collection
class GameRole {
  Id id = Isar.autoIncrement;

  // 本機識別鍵，格式為 accountUid_serverId，與 GachaRecord.uid 使用相同規則。
  @Index(unique: true)
  late String localDbUid;

  // 帳號綁定層級的 UID。
  late String accountUid;

  // 遊戲內實際 UID。
  String? roleId;

  // 遊戲內角色名稱。
  String? nickName;

  // 遊戲伺服器 ID。
  late String serverId;

  // 遊戲伺服器名稱。
  String? serverName;
}
