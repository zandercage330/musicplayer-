// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $FavoriteTracksTable extends FavoriteTracks
    with TableInfo<$FavoriteTracksTable, FavoriteTrackEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FavoriteTracksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _trackIdMeta =
      const VerificationMeta('trackId');
  @override
  late final GeneratedColumn<int> trackId = GeneratedColumn<int>(
      'track_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _dateFavoritedMeta =
      const VerificationMeta('dateFavorited');
  @override
  late final GeneratedColumn<DateTime> dateFavorited =
      GeneratedColumn<DateTime>('date_favorited', aliasedName, false,
          type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isSyncedMeta =
      const VerificationMeta('isSynced');
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
      'is_synced', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_synced" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _customOrderMeta =
      const VerificationMeta('customOrder');
  @override
  late final GeneratedColumn<int> customOrder = GeneratedColumn<int>(
      'custom_order', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, trackId, dateFavorited, userId, isSynced, customOrder];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'favorite_tracks';
  @override
  VerificationContext validateIntegrity(Insertable<FavoriteTrackEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('track_id')) {
      context.handle(_trackIdMeta,
          trackId.isAcceptableOrUnknown(data['track_id']!, _trackIdMeta));
    } else if (isInserting) {
      context.missing(_trackIdMeta);
    }
    if (data.containsKey('date_favorited')) {
      context.handle(
          _dateFavoritedMeta,
          dateFavorited.isAcceptableOrUnknown(
              data['date_favorited']!, _dateFavoritedMeta));
    } else if (isInserting) {
      context.missing(_dateFavoritedMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    }
    if (data.containsKey('is_synced')) {
      context.handle(_isSyncedMeta,
          isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta));
    }
    if (data.containsKey('custom_order')) {
      context.handle(
          _customOrderMeta,
          customOrder.isAcceptableOrUnknown(
              data['custom_order']!, _customOrderMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FavoriteTrackEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FavoriteTrackEntry(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      trackId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}track_id'])!,
      dateFavorited: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}date_favorited'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id']),
      isSynced: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_synced'])!,
      customOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}custom_order']),
    );
  }

  @override
  $FavoriteTracksTable createAlias(String alias) {
    return $FavoriteTracksTable(attachedDatabase, alias);
  }
}

class FavoriteTrackEntry extends DataClass
    implements Insertable<FavoriteTrackEntry> {
  final int id;
  final int trackId;
  final DateTime dateFavorited;
  final String? userId;
  final bool isSynced;
  final int? customOrder;
  const FavoriteTrackEntry(
      {required this.id,
      required this.trackId,
      required this.dateFavorited,
      this.userId,
      required this.isSynced,
      this.customOrder});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['track_id'] = Variable<int>(trackId);
    map['date_favorited'] = Variable<DateTime>(dateFavorited);
    if (!nullToAbsent || userId != null) {
      map['user_id'] = Variable<String>(userId);
    }
    map['is_synced'] = Variable<bool>(isSynced);
    if (!nullToAbsent || customOrder != null) {
      map['custom_order'] = Variable<int>(customOrder);
    }
    return map;
  }

  FavoriteTracksCompanion toCompanion(bool nullToAbsent) {
    return FavoriteTracksCompanion(
      id: Value(id),
      trackId: Value(trackId),
      dateFavorited: Value(dateFavorited),
      userId:
          userId == null && nullToAbsent ? const Value.absent() : Value(userId),
      isSynced: Value(isSynced),
      customOrder: customOrder == null && nullToAbsent
          ? const Value.absent()
          : Value(customOrder),
    );
  }

  factory FavoriteTrackEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FavoriteTrackEntry(
      id: serializer.fromJson<int>(json['id']),
      trackId: serializer.fromJson<int>(json['trackId']),
      dateFavorited: serializer.fromJson<DateTime>(json['dateFavorited']),
      userId: serializer.fromJson<String?>(json['userId']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
      customOrder: serializer.fromJson<int?>(json['customOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'trackId': serializer.toJson<int>(trackId),
      'dateFavorited': serializer.toJson<DateTime>(dateFavorited),
      'userId': serializer.toJson<String?>(userId),
      'isSynced': serializer.toJson<bool>(isSynced),
      'customOrder': serializer.toJson<int?>(customOrder),
    };
  }

  FavoriteTrackEntry copyWith(
          {int? id,
          int? trackId,
          DateTime? dateFavorited,
          Value<String?> userId = const Value.absent(),
          bool? isSynced,
          Value<int?> customOrder = const Value.absent()}) =>
      FavoriteTrackEntry(
        id: id ?? this.id,
        trackId: trackId ?? this.trackId,
        dateFavorited: dateFavorited ?? this.dateFavorited,
        userId: userId.present ? userId.value : this.userId,
        isSynced: isSynced ?? this.isSynced,
        customOrder: customOrder.present ? customOrder.value : this.customOrder,
      );
  FavoriteTrackEntry copyWithCompanion(FavoriteTracksCompanion data) {
    return FavoriteTrackEntry(
      id: data.id.present ? data.id.value : this.id,
      trackId: data.trackId.present ? data.trackId.value : this.trackId,
      dateFavorited: data.dateFavorited.present
          ? data.dateFavorited.value
          : this.dateFavorited,
      userId: data.userId.present ? data.userId.value : this.userId,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
      customOrder:
          data.customOrder.present ? data.customOrder.value : this.customOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FavoriteTrackEntry(')
          ..write('id: $id, ')
          ..write('trackId: $trackId, ')
          ..write('dateFavorited: $dateFavorited, ')
          ..write('userId: $userId, ')
          ..write('isSynced: $isSynced, ')
          ..write('customOrder: $customOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, trackId, dateFavorited, userId, isSynced, customOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FavoriteTrackEntry &&
          other.id == this.id &&
          other.trackId == this.trackId &&
          other.dateFavorited == this.dateFavorited &&
          other.userId == this.userId &&
          other.isSynced == this.isSynced &&
          other.customOrder == this.customOrder);
}

class FavoriteTracksCompanion extends UpdateCompanion<FavoriteTrackEntry> {
  final Value<int> id;
  final Value<int> trackId;
  final Value<DateTime> dateFavorited;
  final Value<String?> userId;
  final Value<bool> isSynced;
  final Value<int?> customOrder;
  const FavoriteTracksCompanion({
    this.id = const Value.absent(),
    this.trackId = const Value.absent(),
    this.dateFavorited = const Value.absent(),
    this.userId = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.customOrder = const Value.absent(),
  });
  FavoriteTracksCompanion.insert({
    this.id = const Value.absent(),
    required int trackId,
    required DateTime dateFavorited,
    this.userId = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.customOrder = const Value.absent(),
  })  : trackId = Value(trackId),
        dateFavorited = Value(dateFavorited);
  static Insertable<FavoriteTrackEntry> custom({
    Expression<int>? id,
    Expression<int>? trackId,
    Expression<DateTime>? dateFavorited,
    Expression<String>? userId,
    Expression<bool>? isSynced,
    Expression<int>? customOrder,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (trackId != null) 'track_id': trackId,
      if (dateFavorited != null) 'date_favorited': dateFavorited,
      if (userId != null) 'user_id': userId,
      if (isSynced != null) 'is_synced': isSynced,
      if (customOrder != null) 'custom_order': customOrder,
    });
  }

  FavoriteTracksCompanion copyWith(
      {Value<int>? id,
      Value<int>? trackId,
      Value<DateTime>? dateFavorited,
      Value<String?>? userId,
      Value<bool>? isSynced,
      Value<int?>? customOrder}) {
    return FavoriteTracksCompanion(
      id: id ?? this.id,
      trackId: trackId ?? this.trackId,
      dateFavorited: dateFavorited ?? this.dateFavorited,
      userId: userId ?? this.userId,
      isSynced: isSynced ?? this.isSynced,
      customOrder: customOrder ?? this.customOrder,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (trackId.present) {
      map['track_id'] = Variable<int>(trackId.value);
    }
    if (dateFavorited.present) {
      map['date_favorited'] = Variable<DateTime>(dateFavorited.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (customOrder.present) {
      map['custom_order'] = Variable<int>(customOrder.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FavoriteTracksCompanion(')
          ..write('id: $id, ')
          ..write('trackId: $trackId, ')
          ..write('dateFavorited: $dateFavorited, ')
          ..write('userId: $userId, ')
          ..write('isSynced: $isSynced, ')
          ..write('customOrder: $customOrder')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $FavoriteTracksTable favoriteTracks = $FavoriteTracksTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [favoriteTracks];
}

typedef $$FavoriteTracksTableCreateCompanionBuilder = FavoriteTracksCompanion
    Function({
  Value<int> id,
  required int trackId,
  required DateTime dateFavorited,
  Value<String?> userId,
  Value<bool> isSynced,
  Value<int?> customOrder,
});
typedef $$FavoriteTracksTableUpdateCompanionBuilder = FavoriteTracksCompanion
    Function({
  Value<int> id,
  Value<int> trackId,
  Value<DateTime> dateFavorited,
  Value<String?> userId,
  Value<bool> isSynced,
  Value<int?> customOrder,
});

class $$FavoriteTracksTableTableManager extends RootTableManager<
    _$AppDatabase,
    $FavoriteTracksTable,
    FavoriteTrackEntry,
    $$FavoriteTracksTableFilterComposer,
    $$FavoriteTracksTableOrderingComposer,
    $$FavoriteTracksTableCreateCompanionBuilder,
    $$FavoriteTracksTableUpdateCompanionBuilder> {
  $$FavoriteTracksTableTableManager(
      _$AppDatabase db, $FavoriteTracksTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$FavoriteTracksTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$FavoriteTracksTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> trackId = const Value.absent(),
            Value<DateTime> dateFavorited = const Value.absent(),
            Value<String?> userId = const Value.absent(),
            Value<bool> isSynced = const Value.absent(),
            Value<int?> customOrder = const Value.absent(),
          }) =>
              FavoriteTracksCompanion(
            id: id,
            trackId: trackId,
            dateFavorited: dateFavorited,
            userId: userId,
            isSynced: isSynced,
            customOrder: customOrder,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int trackId,
            required DateTime dateFavorited,
            Value<String?> userId = const Value.absent(),
            Value<bool> isSynced = const Value.absent(),
            Value<int?> customOrder = const Value.absent(),
          }) =>
              FavoriteTracksCompanion.insert(
            id: id,
            trackId: trackId,
            dateFavorited: dateFavorited,
            userId: userId,
            isSynced: isSynced,
            customOrder: customOrder,
          ),
        ));
}

class $$FavoriteTracksTableFilterComposer
    extends FilterComposer<_$AppDatabase, $FavoriteTracksTable> {
  $$FavoriteTracksTableFilterComposer(super.$state);
  ColumnFilters<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get trackId => $state.composableBuilder(
      column: $state.table.trackId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get dateFavorited => $state.composableBuilder(
      column: $state.table.dateFavorited,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get userId => $state.composableBuilder(
      column: $state.table.userId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get isSynced => $state.composableBuilder(
      column: $state.table.isSynced,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get customOrder => $state.composableBuilder(
      column: $state.table.customOrder,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$FavoriteTracksTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $FavoriteTracksTable> {
  $$FavoriteTracksTableOrderingComposer(super.$state);
  ColumnOrderings<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get trackId => $state.composableBuilder(
      column: $state.table.trackId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get dateFavorited => $state.composableBuilder(
      column: $state.table.dateFavorited,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get userId => $state.composableBuilder(
      column: $state.table.userId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get isSynced => $state.composableBuilder(
      column: $state.table.isSynced,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get customOrder => $state.composableBuilder(
      column: $state.table.customOrder,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$FavoriteTracksTableTableManager get favoriteTracks =>
      $$FavoriteTracksTableTableManager(_db, _db.favoriteTracks);
}
