// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gacha_record.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetGachaRecordCollection on Isar {
  IsarCollection<GachaRecord> get gachaRecords => this.collection();
}

const GachaRecordSchema = CollectionSchema(
  name: r'GachaRecord',
  id: -3654530562369257933,
  properties: {
    r'gachaTs': PropertySchema(
      id: 0,
      name: r'gachaTs',
      type: IsarType.long,
    ),
    r'kind': PropertySchema(
      id: 1,
      name: r'kind',
      type: IsarType.string,
    ),
    r'name': PropertySchema(
      id: 2,
      name: r'name',
      type: IsarType.string,
    ),
    r'poolCategory': PropertySchema(
      id: 3,
      name: r'poolCategory',
      type: IsarType.string,
    ),
    r'poolName': PropertySchema(
      id: 4,
      name: r'poolName',
      type: IsarType.string,
    ),
    r'rarity': PropertySchema(
      id: 5,
      name: r'rarity',
      type: IsarType.long,
    ),
    r'seqId': PropertySchema(
      id: 6,
      name: r'seqId',
      type: IsarType.string,
    ),
    r'uid': PropertySchema(
      id: 7,
      name: r'uid',
      type: IsarType.string,
    )
  },
  estimateSize: _gachaRecordEstimateSize,
  serialize: _gachaRecordSerialize,
  deserialize: _gachaRecordDeserialize,
  deserializeProp: _gachaRecordDeserializeProp,
  idName: r'id',
  indexes: {
    r'uid_seqId': IndexSchema(
      id: -5273547389207561274,
      name: r'uid_seqId',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'uid',
          type: IndexType.hash,
          caseSensitive: true,
        ),
        IndexPropertySchema(
          name: r'seqId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'poolCategory': IndexSchema(
      id: 6276404096594795234,
      name: r'poolCategory',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'poolCategory',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'gachaTs': IndexSchema(
      id: 5119148645434024962,
      name: r'gachaTs',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'gachaTs',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _gachaRecordGetId,
  getLinks: _gachaRecordGetLinks,
  attach: _gachaRecordAttach,
  version: '3.1.0+1',
);

int _gachaRecordEstimateSize(
  GachaRecord object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.kind.length * 3;
  bytesCount += 3 + object.name.length * 3;
  bytesCount += 3 + object.poolCategory.length * 3;
  bytesCount += 3 + object.poolName.length * 3;
  bytesCount += 3 + object.seqId.length * 3;
  bytesCount += 3 + object.uid.length * 3;
  return bytesCount;
}

void _gachaRecordSerialize(
  GachaRecord object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.gachaTs);
  writer.writeString(offsets[1], object.kind);
  writer.writeString(offsets[2], object.name);
  writer.writeString(offsets[3], object.poolCategory);
  writer.writeString(offsets[4], object.poolName);
  writer.writeLong(offsets[5], object.rarity);
  writer.writeString(offsets[6], object.seqId);
  writer.writeString(offsets[7], object.uid);
}

GachaRecord _gachaRecordDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = GachaRecord();
  object.gachaTs = reader.readLong(offsets[0]);
  object.id = id;
  object.kind = reader.readString(offsets[1]);
  object.name = reader.readString(offsets[2]);
  object.poolCategory = reader.readString(offsets[3]);
  object.poolName = reader.readString(offsets[4]);
  object.rarity = reader.readLong(offsets[5]);
  object.seqId = reader.readString(offsets[6]);
  object.uid = reader.readString(offsets[7]);
  return object;
}

P _gachaRecordDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLong(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readLong(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    case 7:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _gachaRecordGetId(GachaRecord object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _gachaRecordGetLinks(GachaRecord object) {
  return [];
}

void _gachaRecordAttach(
    IsarCollection<dynamic> col, Id id, GachaRecord object) {
  object.id = id;
}

extension GachaRecordByIndex on IsarCollection<GachaRecord> {
  Future<GachaRecord?> getByUidSeqId(String uid, String seqId) {
    return getByIndex(r'uid_seqId', [uid, seqId]);
  }

  GachaRecord? getByUidSeqIdSync(String uid, String seqId) {
    return getByIndexSync(r'uid_seqId', [uid, seqId]);
  }

  Future<bool> deleteByUidSeqId(String uid, String seqId) {
    return deleteByIndex(r'uid_seqId', [uid, seqId]);
  }

  bool deleteByUidSeqIdSync(String uid, String seqId) {
    return deleteByIndexSync(r'uid_seqId', [uid, seqId]);
  }

  Future<List<GachaRecord?>> getAllByUidSeqId(
      List<String> uidValues, List<String> seqIdValues) {
    final len = uidValues.length;
    assert(seqIdValues.length == len,
        'All index values must have the same length');
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([uidValues[i], seqIdValues[i]]);
    }

    return getAllByIndex(r'uid_seqId', values);
  }

  List<GachaRecord?> getAllByUidSeqIdSync(
      List<String> uidValues, List<String> seqIdValues) {
    final len = uidValues.length;
    assert(seqIdValues.length == len,
        'All index values must have the same length');
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([uidValues[i], seqIdValues[i]]);
    }

    return getAllByIndexSync(r'uid_seqId', values);
  }

  Future<int> deleteAllByUidSeqId(
      List<String> uidValues, List<String> seqIdValues) {
    final len = uidValues.length;
    assert(seqIdValues.length == len,
        'All index values must have the same length');
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([uidValues[i], seqIdValues[i]]);
    }

    return deleteAllByIndex(r'uid_seqId', values);
  }

  int deleteAllByUidSeqIdSync(
      List<String> uidValues, List<String> seqIdValues) {
    final len = uidValues.length;
    assert(seqIdValues.length == len,
        'All index values must have the same length');
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([uidValues[i], seqIdValues[i]]);
    }

    return deleteAllByIndexSync(r'uid_seqId', values);
  }

  Future<Id> putByUidSeqId(GachaRecord object) {
    return putByIndex(r'uid_seqId', object);
  }

  Id putByUidSeqIdSync(GachaRecord object, {bool saveLinks = true}) {
    return putByIndexSync(r'uid_seqId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByUidSeqId(List<GachaRecord> objects) {
    return putAllByIndex(r'uid_seqId', objects);
  }

  List<Id> putAllByUidSeqIdSync(List<GachaRecord> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'uid_seqId', objects, saveLinks: saveLinks);
  }
}

extension GachaRecordQueryWhereSort
    on QueryBuilder<GachaRecord, GachaRecord, QWhere> {
  QueryBuilder<GachaRecord, GachaRecord, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<GachaRecord, GachaRecord, QAfterWhere> anyGachaTs() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'gachaTs'),
      );
    });
  }
}

extension GachaRecordQueryWhere
    on QueryBuilder<GachaRecord, GachaRecord, QWhereClause> {
  QueryBuilder<GachaRecord, GachaRecord, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<GachaRecord, GachaRecord, QAfterWhereClause> idNotEqualTo(
      Id id) {
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

  QueryBuilder<GachaRecord, GachaRecord, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<GachaRecord, GachaRecord, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<GachaRecord, GachaRecord, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<GachaRecord, GachaRecord, QAfterWhereClause> uidEqualToAnySeqId(
      String uid) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'uid_seqId',
        value: [uid],
      ));
    });
  }

  QueryBuilder<GachaRecord, GachaRecord, QAfterWhereClause>
      uidNotEqualToAnySeqId(String uid) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'uid_seqId',
              lower: [],
              upper: [uid],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'uid_seqId',
              lower: [uid],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'uid_seqId',
              lower: [uid],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'uid_seqId',
              lower: [],
              upper: [uid],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<GachaRecord, GachaRecord, QAfterWhereClause> uidSeqIdEqualTo(
      String uid, String seqId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'uid_seqId',
        value: [uid, seqId],
      ));
    });
  }

  QueryBuilder<GachaRecord, GachaRecord, QAfterWhereClause>
      uidEqualToSeqIdNotEqualTo(String uid, String seqId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'uid_seqId',
              lower: [uid],
              upper: [uid, seqId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'uid_seqId',
              lower: [uid, seqId],
              includeLower: false,
              upper: [uid],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'uid_seqId',
              lower: [uid, seqId],
              includeLower: false,
              upper: [uid],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'uid_seqId',
              lower: [uid],
              upper: [uid, seqId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<GachaRecord, GachaRecord, QAfterWhereClause> poolCategoryEqualTo(
      String poolCategory) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'poolCategory',
        value: [poolCategory],
      ));
    });
  }

  QueryBuilder<GachaRecord, GachaRecord, QAfterWhereClause>
      poolCategoryNotEqualTo(String poolCategory) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'poolCategory',
              lower: [],
              upper: [poolCategory],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'poolCategory',
              lower: [poolCategory],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'poolCategory',
              lower: [poolCategory],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'poolCategory',
              lower: [],
              upper: [poolCategory],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<GachaRecord, GachaRecord, QAfterWhereClause> gachaTsEqualTo(
      int gachaTs) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'gachaTs',
        value: [gachaTs],
      ));
    });
  }

  QueryBuilder<GachaRecord, GachaRecord, QAfterWhereClause> gachaTsNotEqualTo(
      int gachaTs) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'gachaTs',
              lower: [],
              upper: [gachaTs],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'gachaTs',
              lower: [gachaTs],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'gachaTs',
              lower: [gachaTs],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'gachaTs',
              lower: [],
              upper: [gachaTs],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<GachaRecord, GachaRecord, QAfterWhereClause> gachaTsGreaterThan(
    int gachaTs, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'gachaTs',
        lower: [gachaTs],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<GachaRecord, GachaRecord, QAfterWhereClause> gachaTsLessThan(
    int gachaTs, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'gachaTs',
        lower: [],
        upper: [gachaTs],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<GachaRecord, GachaRecord, QAfterWhereClause> gachaTsBetween(
    int lowerGachaTs,
    int upperGachaTs, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'gachaTs',
        lower: [lowerGachaTs],
        includeLower: includeLower,
        upper: [upperGachaTs],
        includeUpper: includeUpper,
      ));
    });
  }
}

extension GachaRecordQueryFilter
    on QueryBuilder<GachaRecord, GachaRecord, QFilterCondition> {
  QueryBuilder<GachaRecord, GachaRecord, QAfterFilterCondition> gachaTsEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'gachaTs',
        value: value,
      ));
    });
  }

  QueryBuilder<GachaRecord, GachaRecord, QAfterFilterCondition>
      gachaTsGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'gachaTs',
        value: value,
      ));
    });
  }

  QueryBuilder<GachaRecord, GachaRecord, QAfterFilterCondition> gachaTsLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'gachaTs',
        value: value,
      ));
    });
  }

  QueryBuilder<GachaRecord, GachaRecord, QAfterFilterCondition> gachaTsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'gachaTs',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<GachaRecord, GachaRecord, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<GachaRecord, GachaRecord, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<GachaRecord, GachaRecord, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<GachaRecord, GachaRecord, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<GachaRecord, GachaRecord, QAfterFilterCondition> kindEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'kind',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GachaRecord, GachaRecord, QAfterFilterCondition> kindGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'kind',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GachaRecord, GachaRecord, QAfterFilterCondition> kindLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'kind',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GachaRecord, GachaRecord, QAfterFilterCondition> kindBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'kind',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GachaRecord, GachaRecord, QAfterFilterCondition> kindStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'kind',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GachaRecord, GachaRecord, QAfterFilterCondition> kindEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'kind',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GachaRecord, GachaRecord, QAfterFilterCondition> kindContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'kind',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GachaRecord, GachaRecord, QAfterFilterCondition> kindMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'kind',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GachaRecord, GachaRecord, QAfterFilterCondition> kindIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'kind',
        value: '',
      ));
    });
  }

  QueryBuilder<GachaRecord, GachaRecord, QAfterFilterCondition>
      kindIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'kind',
        value: '',
      ));
    });
  }

  QueryBuilder<GachaRecord, GachaRecord, QAfterFilterCondition> nameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GachaRecord, GachaRecord, QAfterFilterCondition> nameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GachaRecord, GachaRecord, QAfterFilterCondition> nameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GachaRecord, GachaRecord, QAfterFilterCondition> nameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'name',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GachaRecord, GachaRecord, QAfterFilterCondition> nameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GachaRecord, GachaRecord, QAfterFilterCondition> nameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GachaRecord, GachaRecord, QAfterFilterCondition> nameContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GachaRecord, GachaRecord, QAfterFilterCondition> nameMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'name',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GachaRecord, GachaRecord, QAfterFilterCondition> nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<GachaRecord, GachaRecord, QAfterFilterCondition>
      nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<GachaRecord, GachaRecord, QAfterFilterCondition>
      poolCategoryEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'poolCategory',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GachaRecord, GachaRecord, QAfterFilterCondition>
      poolCategoryGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'poolCategory',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GachaRecord, GachaRecord, QAfterFilterCondition>
      poolCategoryLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'poolCategory',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GachaRecord, GachaRecord, QAfterFilterCondition>
      poolCategoryBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'poolCategory',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GachaRecord, GachaRecord, QAfterFilterCondition>
      poolCategoryStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'poolCategory',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GachaRecord, GachaRecord, QAfterFilterCondition>
      poolCategoryEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'poolCategory',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GachaRecord, GachaRecord, QAfterFilterCondition>
      poolCategoryContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'poolCategory',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GachaRecord, GachaRecord, QAfterFilterCondition>
      poolCategoryMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'poolCategory',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GachaRecord, GachaRecord, QAfterFilterCondition>
      poolCategoryIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'poolCategory',
        value: '',
      ));
    });
  }

  QueryBuilder<GachaRecord, GachaRecord, QAfterFilterCondition>
      poolCategoryIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'poolCategory',
        value: '',
      ));
    });
  }

  QueryBuilder<GachaRecord, GachaRecord, QAfterFilterCondition> poolNameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'poolName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GachaRecord, GachaRecord, QAfterFilterCondition>
      poolNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'poolName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GachaRecord, GachaRecord, QAfterFilterCondition>
      poolNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'poolName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GachaRecord, GachaRecord, QAfterFilterCondition> poolNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'poolName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GachaRecord, GachaRecord, QAfterFilterCondition>
      poolNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'poolName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GachaRecord, GachaRecord, QAfterFilterCondition>
      poolNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'poolName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GachaRecord, GachaRecord, QAfterFilterCondition>
      poolNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'poolName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GachaRecord, GachaRecord, QAfterFilterCondition> poolNameMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'poolName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GachaRecord, GachaRecord, QAfterFilterCondition>
      poolNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'poolName',
        value: '',
      ));
    });
  }

  QueryBuilder<GachaRecord, GachaRecord, QAfterFilterCondition>
      poolNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'poolName',
        value: '',
      ));
    });
  }

  QueryBuilder<GachaRecord, GachaRecord, QAfterFilterCondition> rarityEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'rarity',
        value: value,
      ));
    });
  }

  QueryBuilder<GachaRecord, GachaRecord, QAfterFilterCondition>
      rarityGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'rarity',
        value: value,
      ));
    });
  }

  QueryBuilder<GachaRecord, GachaRecord, QAfterFilterCondition> rarityLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'rarity',
        value: value,
      ));
    });
  }

  QueryBuilder<GachaRecord, GachaRecord, QAfterFilterCondition> rarityBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'rarity',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<GachaRecord, GachaRecord, QAfterFilterCondition> seqIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'seqId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GachaRecord, GachaRecord, QAfterFilterCondition>
      seqIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'seqId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GachaRecord, GachaRecord, QAfterFilterCondition> seqIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'seqId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GachaRecord, GachaRecord, QAfterFilterCondition> seqIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'seqId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GachaRecord, GachaRecord, QAfterFilterCondition> seqIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'seqId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GachaRecord, GachaRecord, QAfterFilterCondition> seqIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'seqId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GachaRecord, GachaRecord, QAfterFilterCondition> seqIdContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'seqId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GachaRecord, GachaRecord, QAfterFilterCondition> seqIdMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'seqId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GachaRecord, GachaRecord, QAfterFilterCondition> seqIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'seqId',
        value: '',
      ));
    });
  }

  QueryBuilder<GachaRecord, GachaRecord, QAfterFilterCondition>
      seqIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'seqId',
        value: '',
      ));
    });
  }

  QueryBuilder<GachaRecord, GachaRecord, QAfterFilterCondition> uidEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'uid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GachaRecord, GachaRecord, QAfterFilterCondition> uidGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'uid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GachaRecord, GachaRecord, QAfterFilterCondition> uidLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'uid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GachaRecord, GachaRecord, QAfterFilterCondition> uidBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'uid',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GachaRecord, GachaRecord, QAfterFilterCondition> uidStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'uid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GachaRecord, GachaRecord, QAfterFilterCondition> uidEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'uid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GachaRecord, GachaRecord, QAfterFilterCondition> uidContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'uid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GachaRecord, GachaRecord, QAfterFilterCondition> uidMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'uid',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GachaRecord, GachaRecord, QAfterFilterCondition> uidIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'uid',
        value: '',
      ));
    });
  }

  QueryBuilder<GachaRecord, GachaRecord, QAfterFilterCondition>
      uidIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'uid',
        value: '',
      ));
    });
  }
}

extension GachaRecordQueryObject
    on QueryBuilder<GachaRecord, GachaRecord, QFilterCondition> {}

extension GachaRecordQueryLinks
    on QueryBuilder<GachaRecord, GachaRecord, QFilterCondition> {}

extension GachaRecordQuerySortBy
    on QueryBuilder<GachaRecord, GachaRecord, QSortBy> {
  QueryBuilder<GachaRecord, GachaRecord, QAfterSortBy> sortByGachaTs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'gachaTs', Sort.asc);
    });
  }

  QueryBuilder<GachaRecord, GachaRecord, QAfterSortBy> sortByGachaTsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'gachaTs', Sort.desc);
    });
  }

  QueryBuilder<GachaRecord, GachaRecord, QAfterSortBy> sortByKind() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'kind', Sort.asc);
    });
  }

  QueryBuilder<GachaRecord, GachaRecord, QAfterSortBy> sortByKindDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'kind', Sort.desc);
    });
  }

  QueryBuilder<GachaRecord, GachaRecord, QAfterSortBy> sortByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<GachaRecord, GachaRecord, QAfterSortBy> sortByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<GachaRecord, GachaRecord, QAfterSortBy> sortByPoolCategory() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'poolCategory', Sort.asc);
    });
  }

  QueryBuilder<GachaRecord, GachaRecord, QAfterSortBy>
      sortByPoolCategoryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'poolCategory', Sort.desc);
    });
  }

  QueryBuilder<GachaRecord, GachaRecord, QAfterSortBy> sortByPoolName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'poolName', Sort.asc);
    });
  }

  QueryBuilder<GachaRecord, GachaRecord, QAfterSortBy> sortByPoolNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'poolName', Sort.desc);
    });
  }

  QueryBuilder<GachaRecord, GachaRecord, QAfterSortBy> sortByRarity() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rarity', Sort.asc);
    });
  }

  QueryBuilder<GachaRecord, GachaRecord, QAfterSortBy> sortByRarityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rarity', Sort.desc);
    });
  }

  QueryBuilder<GachaRecord, GachaRecord, QAfterSortBy> sortBySeqId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'seqId', Sort.asc);
    });
  }

  QueryBuilder<GachaRecord, GachaRecord, QAfterSortBy> sortBySeqIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'seqId', Sort.desc);
    });
  }

  QueryBuilder<GachaRecord, GachaRecord, QAfterSortBy> sortByUid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uid', Sort.asc);
    });
  }

  QueryBuilder<GachaRecord, GachaRecord, QAfterSortBy> sortByUidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uid', Sort.desc);
    });
  }
}

extension GachaRecordQuerySortThenBy
    on QueryBuilder<GachaRecord, GachaRecord, QSortThenBy> {
  QueryBuilder<GachaRecord, GachaRecord, QAfterSortBy> thenByGachaTs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'gachaTs', Sort.asc);
    });
  }

  QueryBuilder<GachaRecord, GachaRecord, QAfterSortBy> thenByGachaTsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'gachaTs', Sort.desc);
    });
  }

  QueryBuilder<GachaRecord, GachaRecord, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<GachaRecord, GachaRecord, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<GachaRecord, GachaRecord, QAfterSortBy> thenByKind() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'kind', Sort.asc);
    });
  }

  QueryBuilder<GachaRecord, GachaRecord, QAfterSortBy> thenByKindDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'kind', Sort.desc);
    });
  }

  QueryBuilder<GachaRecord, GachaRecord, QAfterSortBy> thenByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<GachaRecord, GachaRecord, QAfterSortBy> thenByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<GachaRecord, GachaRecord, QAfterSortBy> thenByPoolCategory() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'poolCategory', Sort.asc);
    });
  }

  QueryBuilder<GachaRecord, GachaRecord, QAfterSortBy>
      thenByPoolCategoryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'poolCategory', Sort.desc);
    });
  }

  QueryBuilder<GachaRecord, GachaRecord, QAfterSortBy> thenByPoolName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'poolName', Sort.asc);
    });
  }

  QueryBuilder<GachaRecord, GachaRecord, QAfterSortBy> thenByPoolNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'poolName', Sort.desc);
    });
  }

  QueryBuilder<GachaRecord, GachaRecord, QAfterSortBy> thenByRarity() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rarity', Sort.asc);
    });
  }

  QueryBuilder<GachaRecord, GachaRecord, QAfterSortBy> thenByRarityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rarity', Sort.desc);
    });
  }

  QueryBuilder<GachaRecord, GachaRecord, QAfterSortBy> thenBySeqId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'seqId', Sort.asc);
    });
  }

  QueryBuilder<GachaRecord, GachaRecord, QAfterSortBy> thenBySeqIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'seqId', Sort.desc);
    });
  }

  QueryBuilder<GachaRecord, GachaRecord, QAfterSortBy> thenByUid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uid', Sort.asc);
    });
  }

  QueryBuilder<GachaRecord, GachaRecord, QAfterSortBy> thenByUidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uid', Sort.desc);
    });
  }
}

extension GachaRecordQueryWhereDistinct
    on QueryBuilder<GachaRecord, GachaRecord, QDistinct> {
  QueryBuilder<GachaRecord, GachaRecord, QDistinct> distinctByGachaTs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'gachaTs');
    });
  }

  QueryBuilder<GachaRecord, GachaRecord, QDistinct> distinctByKind(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'kind', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<GachaRecord, GachaRecord, QDistinct> distinctByName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'name', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<GachaRecord, GachaRecord, QDistinct> distinctByPoolCategory(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'poolCategory', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<GachaRecord, GachaRecord, QDistinct> distinctByPoolName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'poolName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<GachaRecord, GachaRecord, QDistinct> distinctByRarity() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'rarity');
    });
  }

  QueryBuilder<GachaRecord, GachaRecord, QDistinct> distinctBySeqId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'seqId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<GachaRecord, GachaRecord, QDistinct> distinctByUid(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'uid', caseSensitive: caseSensitive);
    });
  }
}

extension GachaRecordQueryProperty
    on QueryBuilder<GachaRecord, GachaRecord, QQueryProperty> {
  QueryBuilder<GachaRecord, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<GachaRecord, int, QQueryOperations> gachaTsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'gachaTs');
    });
  }

  QueryBuilder<GachaRecord, String, QQueryOperations> kindProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'kind');
    });
  }

  QueryBuilder<GachaRecord, String, QQueryOperations> nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'name');
    });
  }

  QueryBuilder<GachaRecord, String, QQueryOperations> poolCategoryProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'poolCategory');
    });
  }

  QueryBuilder<GachaRecord, String, QQueryOperations> poolNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'poolName');
    });
  }

  QueryBuilder<GachaRecord, int, QQueryOperations> rarityProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'rarity');
    });
  }

  QueryBuilder<GachaRecord, String, QQueryOperations> seqIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'seqId');
    });
  }

  QueryBuilder<GachaRecord, String, QQueryOperations> uidProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'uid');
    });
  }
}
