// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'game_role.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types, experimental_member_use

extension GetGameRoleCollection on Isar {
  IsarCollection<GameRole> get gameRoles => this.collection();
}

const GameRoleSchema = CollectionSchema(
  name: r'GameRole',
  id: -7816631297847766254,
  properties: {
    r'accountUid': PropertySchema(
      id: 0,
      name: r'accountUid',
      type: IsarType.string,
    ),
    r'localDbUid': PropertySchema(
      id: 1,
      name: r'localDbUid',
      type: IsarType.string,
    ),
    r'nickName': PropertySchema(
      id: 2,
      name: r'nickName',
      type: IsarType.string,
    ),
    r'roleId': PropertySchema(id: 3, name: r'roleId', type: IsarType.string),
    r'serverId': PropertySchema(
      id: 4,
      name: r'serverId',
      type: IsarType.string,
    ),
    r'serverName': PropertySchema(
      id: 5,
      name: r'serverName',
      type: IsarType.string,
    ),
  },

  estimateSize: _gameRoleEstimateSize,
  serialize: _gameRoleSerialize,
  deserialize: _gameRoleDeserialize,
  deserializeProp: _gameRoleDeserializeProp,
  idName: r'id',
  indexes: {
    r'localDbUid': IndexSchema(
      id: 5526636455805319041,
      name: r'localDbUid',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'localDbUid',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},

  getId: _gameRoleGetId,
  getLinks: _gameRoleGetLinks,
  attach: _gameRoleAttach,
  version: '3.4.1',
);

int _gameRoleEstimateSize(
  GameRole object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.accountUid.length * 3;
  bytesCount += 3 + object.localDbUid.length * 3;
  {
    final value = object.nickName;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.roleId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.serverId.length * 3;
  {
    final value = object.serverName;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _gameRoleSerialize(
  GameRole object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.accountUid);
  writer.writeString(offsets[1], object.localDbUid);
  writer.writeString(offsets[2], object.nickName);
  writer.writeString(offsets[3], object.roleId);
  writer.writeString(offsets[4], object.serverId);
  writer.writeString(offsets[5], object.serverName);
}

GameRole _gameRoleDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = GameRole();
  object.accountUid = reader.readString(offsets[0]);
  object.id = id;
  object.localDbUid = reader.readString(offsets[1]);
  object.nickName = reader.readStringOrNull(offsets[2]);
  object.roleId = reader.readStringOrNull(offsets[3]);
  object.serverId = reader.readString(offsets[4]);
  object.serverName = reader.readStringOrNull(offsets[5]);
  return object;
}

P _gameRoleDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readStringOrNull(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _gameRoleGetId(GameRole object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _gameRoleGetLinks(GameRole object) {
  return [];
}

void _gameRoleAttach(IsarCollection<dynamic> col, Id id, GameRole object) {
  object.id = id;
}

extension GameRoleByIndex on IsarCollection<GameRole> {
  Future<GameRole?> getByLocalDbUid(String localDbUid) {
    return getByIndex(r'localDbUid', [localDbUid]);
  }

  GameRole? getByLocalDbUidSync(String localDbUid) {
    return getByIndexSync(r'localDbUid', [localDbUid]);
  }

  Future<bool> deleteByLocalDbUid(String localDbUid) {
    return deleteByIndex(r'localDbUid', [localDbUid]);
  }

  bool deleteByLocalDbUidSync(String localDbUid) {
    return deleteByIndexSync(r'localDbUid', [localDbUid]);
  }

  Future<List<GameRole?>> getAllByLocalDbUid(List<String> localDbUidValues) {
    final values = localDbUidValues.map((e) => [e]).toList();
    return getAllByIndex(r'localDbUid', values);
  }

  List<GameRole?> getAllByLocalDbUidSync(List<String> localDbUidValues) {
    final values = localDbUidValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'localDbUid', values);
  }

  Future<int> deleteAllByLocalDbUid(List<String> localDbUidValues) {
    final values = localDbUidValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'localDbUid', values);
  }

  int deleteAllByLocalDbUidSync(List<String> localDbUidValues) {
    final values = localDbUidValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'localDbUid', values);
  }

  Future<Id> putByLocalDbUid(GameRole object) {
    return putByIndex(r'localDbUid', object);
  }

  Id putByLocalDbUidSync(GameRole object, {bool saveLinks = true}) {
    return putByIndexSync(r'localDbUid', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByLocalDbUid(List<GameRole> objects) {
    return putAllByIndex(r'localDbUid', objects);
  }

  List<Id> putAllByLocalDbUidSync(
    List<GameRole> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(r'localDbUid', objects, saveLinks: saveLinks);
  }
}

extension GameRoleQueryWhereSort on QueryBuilder<GameRole, GameRole, QWhere> {
  QueryBuilder<GameRole, GameRole, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension GameRoleQueryWhere on QueryBuilder<GameRole, GameRole, QWhereClause> {
  QueryBuilder<GameRole, GameRole, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<GameRole, GameRole, QAfterWhereClause> idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<GameRole, GameRole, QAfterWhereClause> idGreaterThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<GameRole, GameRole, QAfterWhereClause> idLessThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<GameRole, GameRole, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.between(
          lower: lowerId,
          includeLower: includeLower,
          upper: upperId,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<GameRole, GameRole, QAfterWhereClause> localDbUidEqualTo(
    String localDbUid,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'localDbUid', value: [localDbUid]),
      );
    });
  }

  QueryBuilder<GameRole, GameRole, QAfterWhereClause> localDbUidNotEqualTo(
    String localDbUid,
  ) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'localDbUid',
                lower: [],
                upper: [localDbUid],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'localDbUid',
                lower: [localDbUid],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'localDbUid',
                lower: [localDbUid],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'localDbUid',
                lower: [],
                upper: [localDbUid],
                includeUpper: false,
              ),
            );
      }
    });
  }
}

extension GameRoleQueryFilter
    on QueryBuilder<GameRole, GameRole, QFilterCondition> {
  QueryBuilder<GameRole, GameRole, QAfterFilterCondition> accountUidEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'accountUid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<GameRole, GameRole, QAfterFilterCondition> accountUidGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'accountUid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<GameRole, GameRole, QAfterFilterCondition> accountUidLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'accountUid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<GameRole, GameRole, QAfterFilterCondition> accountUidBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'accountUid',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<GameRole, GameRole, QAfterFilterCondition> accountUidStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'accountUid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<GameRole, GameRole, QAfterFilterCondition> accountUidEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'accountUid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<GameRole, GameRole, QAfterFilterCondition> accountUidContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'accountUid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<GameRole, GameRole, QAfterFilterCondition> accountUidMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'accountUid',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<GameRole, GameRole, QAfterFilterCondition> accountUidIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'accountUid', value: ''),
      );
    });
  }

  QueryBuilder<GameRole, GameRole, QAfterFilterCondition>
  accountUidIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'accountUid', value: ''),
      );
    });
  }

  QueryBuilder<GameRole, GameRole, QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<GameRole, GameRole, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<GameRole, GameRole, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<GameRole, GameRole, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'id',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<GameRole, GameRole, QAfterFilterCondition> localDbUidEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'localDbUid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<GameRole, GameRole, QAfterFilterCondition> localDbUidGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'localDbUid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<GameRole, GameRole, QAfterFilterCondition> localDbUidLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'localDbUid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<GameRole, GameRole, QAfterFilterCondition> localDbUidBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'localDbUid',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<GameRole, GameRole, QAfterFilterCondition> localDbUidStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'localDbUid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<GameRole, GameRole, QAfterFilterCondition> localDbUidEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'localDbUid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<GameRole, GameRole, QAfterFilterCondition> localDbUidContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'localDbUid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<GameRole, GameRole, QAfterFilterCondition> localDbUidMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'localDbUid',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<GameRole, GameRole, QAfterFilterCondition> localDbUidIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'localDbUid', value: ''),
      );
    });
  }

  QueryBuilder<GameRole, GameRole, QAfterFilterCondition>
  localDbUidIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'localDbUid', value: ''),
      );
    });
  }

  QueryBuilder<GameRole, GameRole, QAfterFilterCondition> nickNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'nickName'),
      );
    });
  }

  QueryBuilder<GameRole, GameRole, QAfterFilterCondition> nickNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'nickName'),
      );
    });
  }

  QueryBuilder<GameRole, GameRole, QAfterFilterCondition> nickNameEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'nickName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<GameRole, GameRole, QAfterFilterCondition> nickNameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'nickName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<GameRole, GameRole, QAfterFilterCondition> nickNameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'nickName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<GameRole, GameRole, QAfterFilterCondition> nickNameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'nickName',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<GameRole, GameRole, QAfterFilterCondition> nickNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'nickName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<GameRole, GameRole, QAfterFilterCondition> nickNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'nickName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<GameRole, GameRole, QAfterFilterCondition> nickNameContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'nickName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<GameRole, GameRole, QAfterFilterCondition> nickNameMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'nickName',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<GameRole, GameRole, QAfterFilterCondition> nickNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'nickName', value: ''),
      );
    });
  }

  QueryBuilder<GameRole, GameRole, QAfterFilterCondition> nickNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'nickName', value: ''),
      );
    });
  }

  QueryBuilder<GameRole, GameRole, QAfterFilterCondition> roleIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'roleId'),
      );
    });
  }

  QueryBuilder<GameRole, GameRole, QAfterFilterCondition> roleIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'roleId'),
      );
    });
  }

  QueryBuilder<GameRole, GameRole, QAfterFilterCondition> roleIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'roleId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<GameRole, GameRole, QAfterFilterCondition> roleIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'roleId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<GameRole, GameRole, QAfterFilterCondition> roleIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'roleId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<GameRole, GameRole, QAfterFilterCondition> roleIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'roleId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<GameRole, GameRole, QAfterFilterCondition> roleIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'roleId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<GameRole, GameRole, QAfterFilterCondition> roleIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'roleId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<GameRole, GameRole, QAfterFilterCondition> roleIdContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'roleId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<GameRole, GameRole, QAfterFilterCondition> roleIdMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'roleId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<GameRole, GameRole, QAfterFilterCondition> roleIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'roleId', value: ''),
      );
    });
  }

  QueryBuilder<GameRole, GameRole, QAfterFilterCondition> roleIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'roleId', value: ''),
      );
    });
  }

  QueryBuilder<GameRole, GameRole, QAfterFilterCondition> serverIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'serverId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<GameRole, GameRole, QAfterFilterCondition> serverIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'serverId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<GameRole, GameRole, QAfterFilterCondition> serverIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'serverId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<GameRole, GameRole, QAfterFilterCondition> serverIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'serverId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<GameRole, GameRole, QAfterFilterCondition> serverIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'serverId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<GameRole, GameRole, QAfterFilterCondition> serverIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'serverId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<GameRole, GameRole, QAfterFilterCondition> serverIdContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'serverId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<GameRole, GameRole, QAfterFilterCondition> serverIdMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'serverId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<GameRole, GameRole, QAfterFilterCondition> serverIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'serverId', value: ''),
      );
    });
  }

  QueryBuilder<GameRole, GameRole, QAfterFilterCondition> serverIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'serverId', value: ''),
      );
    });
  }

  QueryBuilder<GameRole, GameRole, QAfterFilterCondition> serverNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'serverName'),
      );
    });
  }

  QueryBuilder<GameRole, GameRole, QAfterFilterCondition>
  serverNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'serverName'),
      );
    });
  }

  QueryBuilder<GameRole, GameRole, QAfterFilterCondition> serverNameEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'serverName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<GameRole, GameRole, QAfterFilterCondition> serverNameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'serverName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<GameRole, GameRole, QAfterFilterCondition> serverNameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'serverName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<GameRole, GameRole, QAfterFilterCondition> serverNameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'serverName',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<GameRole, GameRole, QAfterFilterCondition> serverNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'serverName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<GameRole, GameRole, QAfterFilterCondition> serverNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'serverName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<GameRole, GameRole, QAfterFilterCondition> serverNameContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'serverName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<GameRole, GameRole, QAfterFilterCondition> serverNameMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'serverName',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<GameRole, GameRole, QAfterFilterCondition> serverNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'serverName', value: ''),
      );
    });
  }

  QueryBuilder<GameRole, GameRole, QAfterFilterCondition>
  serverNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'serverName', value: ''),
      );
    });
  }
}

extension GameRoleQueryObject
    on QueryBuilder<GameRole, GameRole, QFilterCondition> {}

extension GameRoleQueryLinks
    on QueryBuilder<GameRole, GameRole, QFilterCondition> {}

extension GameRoleQuerySortBy on QueryBuilder<GameRole, GameRole, QSortBy> {
  QueryBuilder<GameRole, GameRole, QAfterSortBy> sortByAccountUid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accountUid', Sort.asc);
    });
  }

  QueryBuilder<GameRole, GameRole, QAfterSortBy> sortByAccountUidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accountUid', Sort.desc);
    });
  }

  QueryBuilder<GameRole, GameRole, QAfterSortBy> sortByLocalDbUid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localDbUid', Sort.asc);
    });
  }

  QueryBuilder<GameRole, GameRole, QAfterSortBy> sortByLocalDbUidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localDbUid', Sort.desc);
    });
  }

  QueryBuilder<GameRole, GameRole, QAfterSortBy> sortByNickName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nickName', Sort.asc);
    });
  }

  QueryBuilder<GameRole, GameRole, QAfterSortBy> sortByNickNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nickName', Sort.desc);
    });
  }

  QueryBuilder<GameRole, GameRole, QAfterSortBy> sortByRoleId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'roleId', Sort.asc);
    });
  }

  QueryBuilder<GameRole, GameRole, QAfterSortBy> sortByRoleIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'roleId', Sort.desc);
    });
  }

  QueryBuilder<GameRole, GameRole, QAfterSortBy> sortByServerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.asc);
    });
  }

  QueryBuilder<GameRole, GameRole, QAfterSortBy> sortByServerIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.desc);
    });
  }

  QueryBuilder<GameRole, GameRole, QAfterSortBy> sortByServerName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverName', Sort.asc);
    });
  }

  QueryBuilder<GameRole, GameRole, QAfterSortBy> sortByServerNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverName', Sort.desc);
    });
  }
}

extension GameRoleQuerySortThenBy
    on QueryBuilder<GameRole, GameRole, QSortThenBy> {
  QueryBuilder<GameRole, GameRole, QAfterSortBy> thenByAccountUid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accountUid', Sort.asc);
    });
  }

  QueryBuilder<GameRole, GameRole, QAfterSortBy> thenByAccountUidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accountUid', Sort.desc);
    });
  }

  QueryBuilder<GameRole, GameRole, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<GameRole, GameRole, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<GameRole, GameRole, QAfterSortBy> thenByLocalDbUid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localDbUid', Sort.asc);
    });
  }

  QueryBuilder<GameRole, GameRole, QAfterSortBy> thenByLocalDbUidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localDbUid', Sort.desc);
    });
  }

  QueryBuilder<GameRole, GameRole, QAfterSortBy> thenByNickName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nickName', Sort.asc);
    });
  }

  QueryBuilder<GameRole, GameRole, QAfterSortBy> thenByNickNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nickName', Sort.desc);
    });
  }

  QueryBuilder<GameRole, GameRole, QAfterSortBy> thenByRoleId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'roleId', Sort.asc);
    });
  }

  QueryBuilder<GameRole, GameRole, QAfterSortBy> thenByRoleIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'roleId', Sort.desc);
    });
  }

  QueryBuilder<GameRole, GameRole, QAfterSortBy> thenByServerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.asc);
    });
  }

  QueryBuilder<GameRole, GameRole, QAfterSortBy> thenByServerIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.desc);
    });
  }

  QueryBuilder<GameRole, GameRole, QAfterSortBy> thenByServerName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverName', Sort.asc);
    });
  }

  QueryBuilder<GameRole, GameRole, QAfterSortBy> thenByServerNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverName', Sort.desc);
    });
  }
}

extension GameRoleQueryWhereDistinct
    on QueryBuilder<GameRole, GameRole, QDistinct> {
  QueryBuilder<GameRole, GameRole, QDistinct> distinctByAccountUid({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'accountUid', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<GameRole, GameRole, QDistinct> distinctByLocalDbUid({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'localDbUid', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<GameRole, GameRole, QDistinct> distinctByNickName({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'nickName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<GameRole, GameRole, QDistinct> distinctByRoleId({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'roleId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<GameRole, GameRole, QDistinct> distinctByServerId({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'serverId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<GameRole, GameRole, QDistinct> distinctByServerName({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'serverName', caseSensitive: caseSensitive);
    });
  }
}

extension GameRoleQueryProperty
    on QueryBuilder<GameRole, GameRole, QQueryProperty> {
  QueryBuilder<GameRole, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<GameRole, String, QQueryOperations> accountUidProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'accountUid');
    });
  }

  QueryBuilder<GameRole, String, QQueryOperations> localDbUidProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'localDbUid');
    });
  }

  QueryBuilder<GameRole, String?, QQueryOperations> nickNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'nickName');
    });
  }

  QueryBuilder<GameRole, String?, QQueryOperations> roleIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'roleId');
    });
  }

  QueryBuilder<GameRole, String, QQueryOperations> serverIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'serverId');
    });
  }

  QueryBuilder<GameRole, String?, QQueryOperations> serverNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'serverName');
    });
  }
}
