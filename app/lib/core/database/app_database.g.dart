// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $KeyValuesTable extends KeyValues
    with TableInfo<$KeyValuesTable, KeyValue> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $KeyValuesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'key_values';
  @override
  VerificationContext validateIntegrity(
    Insertable<KeyValue> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  KeyValue map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return KeyValue(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $KeyValuesTable createAlias(String alias) {
    return $KeyValuesTable(attachedDatabase, alias);
  }
}

class KeyValue extends DataClass implements Insertable<KeyValue> {
  final String key;
  final String value;
  const KeyValue({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  KeyValuesCompanion toCompanion(bool nullToAbsent) {
    return KeyValuesCompanion(key: Value(key), value: Value(value));
  }

  factory KeyValue.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return KeyValue(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  KeyValue copyWith({String? key, String? value}) =>
      KeyValue(key: key ?? this.key, value: value ?? this.value);
  KeyValue copyWithCompanion(KeyValuesCompanion data) {
    return KeyValue(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('KeyValue(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is KeyValue && other.key == this.key && other.value == this.value);
}

class KeyValuesCompanion extends UpdateCompanion<KeyValue> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const KeyValuesCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  KeyValuesCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<KeyValue> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  KeyValuesCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return KeyValuesCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('KeyValuesCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OfflineQueueItemsTable extends OfflineQueueItems
    with TableInfo<$OfflineQueueItemsTable, OfflineQueueItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OfflineQueueItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _attemptsMeta = const VerificationMeta(
    'attempts',
  );
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
    'attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _doneMeta = const VerificationMeta('done');
  @override
  late final GeneratedColumn<bool> done = GeneratedColumn<bool>(
    'done',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("done" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    type,
    payload,
    createdAt,
    attempts,
    lastError,
    done,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'offline_queue_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<OfflineQueueItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('attempts')) {
      context.handle(
        _attemptsMeta,
        attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    if (data.containsKey('done')) {
      context.handle(
        _doneMeta,
        done.isAcceptableOrUnknown(data['done']!, _doneMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OfflineQueueItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OfflineQueueItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      attempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempts'],
      )!,
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
      done: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}done'],
      )!,
    );
  }

  @override
  $OfflineQueueItemsTable createAlias(String alias) {
    return $OfflineQueueItemsTable(attachedDatabase, alias);
  }
}

class OfflineQueueItem extends DataClass
    implements Insertable<OfflineQueueItem> {
  final int id;
  final String type;
  final String payload;
  final DateTime createdAt;
  final int attempts;
  final String? lastError;
  final bool done;
  const OfflineQueueItem({
    required this.id,
    required this.type,
    required this.payload,
    required this.createdAt,
    required this.attempts,
    this.lastError,
    required this.done,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['type'] = Variable<String>(type);
    map['payload'] = Variable<String>(payload);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['attempts'] = Variable<int>(attempts);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    map['done'] = Variable<bool>(done);
    return map;
  }

  OfflineQueueItemsCompanion toCompanion(bool nullToAbsent) {
    return OfflineQueueItemsCompanion(
      id: Value(id),
      type: Value(type),
      payload: Value(payload),
      createdAt: Value(createdAt),
      attempts: Value(attempts),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
      done: Value(done),
    );
  }

  factory OfflineQueueItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OfflineQueueItem(
      id: serializer.fromJson<int>(json['id']),
      type: serializer.fromJson<String>(json['type']),
      payload: serializer.fromJson<String>(json['payload']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      attempts: serializer.fromJson<int>(json['attempts']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      done: serializer.fromJson<bool>(json['done']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'type': serializer.toJson<String>(type),
      'payload': serializer.toJson<String>(payload),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'attempts': serializer.toJson<int>(attempts),
      'lastError': serializer.toJson<String?>(lastError),
      'done': serializer.toJson<bool>(done),
    };
  }

  OfflineQueueItem copyWith({
    int? id,
    String? type,
    String? payload,
    DateTime? createdAt,
    int? attempts,
    Value<String?> lastError = const Value.absent(),
    bool? done,
  }) => OfflineQueueItem(
    id: id ?? this.id,
    type: type ?? this.type,
    payload: payload ?? this.payload,
    createdAt: createdAt ?? this.createdAt,
    attempts: attempts ?? this.attempts,
    lastError: lastError.present ? lastError.value : this.lastError,
    done: done ?? this.done,
  );
  OfflineQueueItem copyWithCompanion(OfflineQueueItemsCompanion data) {
    return OfflineQueueItem(
      id: data.id.present ? data.id.value : this.id,
      type: data.type.present ? data.type.value : this.type,
      payload: data.payload.present ? data.payload.value : this.payload,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      done: data.done.present ? data.done.value : this.done,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OfflineQueueItem(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('payload: $payload, ')
          ..write('createdAt: $createdAt, ')
          ..write('attempts: $attempts, ')
          ..write('lastError: $lastError, ')
          ..write('done: $done')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, type, payload, createdAt, attempts, lastError, done);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OfflineQueueItem &&
          other.id == this.id &&
          other.type == this.type &&
          other.payload == this.payload &&
          other.createdAt == this.createdAt &&
          other.attempts == this.attempts &&
          other.lastError == this.lastError &&
          other.done == this.done);
}

class OfflineQueueItemsCompanion extends UpdateCompanion<OfflineQueueItem> {
  final Value<int> id;
  final Value<String> type;
  final Value<String> payload;
  final Value<DateTime> createdAt;
  final Value<int> attempts;
  final Value<String?> lastError;
  final Value<bool> done;
  const OfflineQueueItemsCompanion({
    this.id = const Value.absent(),
    this.type = const Value.absent(),
    this.payload = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.attempts = const Value.absent(),
    this.lastError = const Value.absent(),
    this.done = const Value.absent(),
  });
  OfflineQueueItemsCompanion.insert({
    this.id = const Value.absent(),
    required String type,
    required String payload,
    this.createdAt = const Value.absent(),
    this.attempts = const Value.absent(),
    this.lastError = const Value.absent(),
    this.done = const Value.absent(),
  }) : type = Value(type),
       payload = Value(payload);
  static Insertable<OfflineQueueItem> custom({
    Expression<int>? id,
    Expression<String>? type,
    Expression<String>? payload,
    Expression<DateTime>? createdAt,
    Expression<int>? attempts,
    Expression<String>? lastError,
    Expression<bool>? done,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (type != null) 'type': type,
      if (payload != null) 'payload': payload,
      if (createdAt != null) 'created_at': createdAt,
      if (attempts != null) 'attempts': attempts,
      if (lastError != null) 'last_error': lastError,
      if (done != null) 'done': done,
    });
  }

  OfflineQueueItemsCompanion copyWith({
    Value<int>? id,
    Value<String>? type,
    Value<String>? payload,
    Value<DateTime>? createdAt,
    Value<int>? attempts,
    Value<String?>? lastError,
    Value<bool>? done,
  }) {
    return OfflineQueueItemsCompanion(
      id: id ?? this.id,
      type: type ?? this.type,
      payload: payload ?? this.payload,
      createdAt: createdAt ?? this.createdAt,
      attempts: attempts ?? this.attempts,
      lastError: lastError ?? this.lastError,
      done: done ?? this.done,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (done.present) {
      map['done'] = Variable<bool>(done.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OfflineQueueItemsCompanion(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('payload: $payload, ')
          ..write('createdAt: $createdAt, ')
          ..write('attempts: $attempts, ')
          ..write('lastError: $lastError, ')
          ..write('done: $done')
          ..write(')'))
        .toString();
  }
}

class $RecordingsTable extends Recordings
    with TableInfo<$RecordingsTable, Recording> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecordingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _filePathMeta = const VerificationMeta(
    'filePath',
  );
  @override
  late final GeneratedColumn<String> filePath = GeneratedColumn<String>(
    'file_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sizeBytesMeta = const VerificationMeta(
    'sizeBytes',
  );
  @override
  late final GeneratedColumn<int> sizeBytes = GeneratedColumn<int>(
    'size_bytes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _formatMeta = const VerificationMeta('format');
  @override
  late final GeneratedColumn<String> format = GeneratedColumn<String>(
    'format',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _durationMsMeta = const VerificationMeta(
    'durationMs',
  );
  @override
  late final GeneratedColumn<int> durationMs = GeneratedColumn<int>(
    'duration_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _indexedAtMeta = const VerificationMeta(
    'indexedAt',
  );
  @override
  late final GeneratedColumn<DateTime> indexedAt = GeneratedColumn<DateTime>(
    'indexed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    filePath,
    name,
    createdAt,
    sizeBytes,
    format,
    durationMs,
    indexedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'recordings';
  @override
  VerificationContext validateIntegrity(
    Insertable<Recording> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('file_path')) {
      context.handle(
        _filePathMeta,
        filePath.isAcceptableOrUnknown(data['file_path']!, _filePathMeta),
      );
    } else if (isInserting) {
      context.missing(_filePathMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('size_bytes')) {
      context.handle(
        _sizeBytesMeta,
        sizeBytes.isAcceptableOrUnknown(data['size_bytes']!, _sizeBytesMeta),
      );
    } else if (isInserting) {
      context.missing(_sizeBytesMeta);
    }
    if (data.containsKey('format')) {
      context.handle(
        _formatMeta,
        format.isAcceptableOrUnknown(data['format']!, _formatMeta),
      );
    } else if (isInserting) {
      context.missing(_formatMeta);
    }
    if (data.containsKey('duration_ms')) {
      context.handle(
        _durationMsMeta,
        durationMs.isAcceptableOrUnknown(data['duration_ms']!, _durationMsMeta),
      );
    }
    if (data.containsKey('indexed_at')) {
      context.handle(
        _indexedAtMeta,
        indexedAt.isAcceptableOrUnknown(data['indexed_at']!, _indexedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {filePath},
  ];
  @override
  Recording map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Recording(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      filePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_path'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      sizeBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}size_bytes'],
      )!,
      format: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}format'],
      )!,
      durationMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_ms'],
      ),
      indexedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}indexed_at'],
      )!,
    );
  }

  @override
  $RecordingsTable createAlias(String alias) {
    return $RecordingsTable(attachedDatabase, alias);
  }
}

class Recording extends DataClass implements Insertable<Recording> {
  final int id;
  final String filePath;
  final String name;
  final DateTime createdAt;
  final int sizeBytes;
  final String format;
  final int? durationMs;
  final DateTime indexedAt;
  const Recording({
    required this.id,
    required this.filePath,
    required this.name,
    required this.createdAt,
    required this.sizeBytes,
    required this.format,
    this.durationMs,
    required this.indexedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['file_path'] = Variable<String>(filePath);
    map['name'] = Variable<String>(name);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['size_bytes'] = Variable<int>(sizeBytes);
    map['format'] = Variable<String>(format);
    if (!nullToAbsent || durationMs != null) {
      map['duration_ms'] = Variable<int>(durationMs);
    }
    map['indexed_at'] = Variable<DateTime>(indexedAt);
    return map;
  }

  RecordingsCompanion toCompanion(bool nullToAbsent) {
    return RecordingsCompanion(
      id: Value(id),
      filePath: Value(filePath),
      name: Value(name),
      createdAt: Value(createdAt),
      sizeBytes: Value(sizeBytes),
      format: Value(format),
      durationMs: durationMs == null && nullToAbsent
          ? const Value.absent()
          : Value(durationMs),
      indexedAt: Value(indexedAt),
    );
  }

  factory Recording.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Recording(
      id: serializer.fromJson<int>(json['id']),
      filePath: serializer.fromJson<String>(json['filePath']),
      name: serializer.fromJson<String>(json['name']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      sizeBytes: serializer.fromJson<int>(json['sizeBytes']),
      format: serializer.fromJson<String>(json['format']),
      durationMs: serializer.fromJson<int?>(json['durationMs']),
      indexedAt: serializer.fromJson<DateTime>(json['indexedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'filePath': serializer.toJson<String>(filePath),
      'name': serializer.toJson<String>(name),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'sizeBytes': serializer.toJson<int>(sizeBytes),
      'format': serializer.toJson<String>(format),
      'durationMs': serializer.toJson<int?>(durationMs),
      'indexedAt': serializer.toJson<DateTime>(indexedAt),
    };
  }

  Recording copyWith({
    int? id,
    String? filePath,
    String? name,
    DateTime? createdAt,
    int? sizeBytes,
    String? format,
    Value<int?> durationMs = const Value.absent(),
    DateTime? indexedAt,
  }) => Recording(
    id: id ?? this.id,
    filePath: filePath ?? this.filePath,
    name: name ?? this.name,
    createdAt: createdAt ?? this.createdAt,
    sizeBytes: sizeBytes ?? this.sizeBytes,
    format: format ?? this.format,
    durationMs: durationMs.present ? durationMs.value : this.durationMs,
    indexedAt: indexedAt ?? this.indexedAt,
  );
  Recording copyWithCompanion(RecordingsCompanion data) {
    return Recording(
      id: data.id.present ? data.id.value : this.id,
      filePath: data.filePath.present ? data.filePath.value : this.filePath,
      name: data.name.present ? data.name.value : this.name,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      sizeBytes: data.sizeBytes.present ? data.sizeBytes.value : this.sizeBytes,
      format: data.format.present ? data.format.value : this.format,
      durationMs: data.durationMs.present
          ? data.durationMs.value
          : this.durationMs,
      indexedAt: data.indexedAt.present ? data.indexedAt.value : this.indexedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Recording(')
          ..write('id: $id, ')
          ..write('filePath: $filePath, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('format: $format, ')
          ..write('durationMs: $durationMs, ')
          ..write('indexedAt: $indexedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    filePath,
    name,
    createdAt,
    sizeBytes,
    format,
    durationMs,
    indexedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Recording &&
          other.id == this.id &&
          other.filePath == this.filePath &&
          other.name == this.name &&
          other.createdAt == this.createdAt &&
          other.sizeBytes == this.sizeBytes &&
          other.format == this.format &&
          other.durationMs == this.durationMs &&
          other.indexedAt == this.indexedAt);
}

class RecordingsCompanion extends UpdateCompanion<Recording> {
  final Value<int> id;
  final Value<String> filePath;
  final Value<String> name;
  final Value<DateTime> createdAt;
  final Value<int> sizeBytes;
  final Value<String> format;
  final Value<int?> durationMs;
  final Value<DateTime> indexedAt;
  const RecordingsCompanion({
    this.id = const Value.absent(),
    this.filePath = const Value.absent(),
    this.name = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.sizeBytes = const Value.absent(),
    this.format = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.indexedAt = const Value.absent(),
  });
  RecordingsCompanion.insert({
    this.id = const Value.absent(),
    required String filePath,
    required String name,
    required DateTime createdAt,
    required int sizeBytes,
    required String format,
    this.durationMs = const Value.absent(),
    this.indexedAt = const Value.absent(),
  }) : filePath = Value(filePath),
       name = Value(name),
       createdAt = Value(createdAt),
       sizeBytes = Value(sizeBytes),
       format = Value(format);
  static Insertable<Recording> custom({
    Expression<int>? id,
    Expression<String>? filePath,
    Expression<String>? name,
    Expression<DateTime>? createdAt,
    Expression<int>? sizeBytes,
    Expression<String>? format,
    Expression<int>? durationMs,
    Expression<DateTime>? indexedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (filePath != null) 'file_path': filePath,
      if (name != null) 'name': name,
      if (createdAt != null) 'created_at': createdAt,
      if (sizeBytes != null) 'size_bytes': sizeBytes,
      if (format != null) 'format': format,
      if (durationMs != null) 'duration_ms': durationMs,
      if (indexedAt != null) 'indexed_at': indexedAt,
    });
  }

  RecordingsCompanion copyWith({
    Value<int>? id,
    Value<String>? filePath,
    Value<String>? name,
    Value<DateTime>? createdAt,
    Value<int>? sizeBytes,
    Value<String>? format,
    Value<int?>? durationMs,
    Value<DateTime>? indexedAt,
  }) {
    return RecordingsCompanion(
      id: id ?? this.id,
      filePath: filePath ?? this.filePath,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      format: format ?? this.format,
      durationMs: durationMs ?? this.durationMs,
      indexedAt: indexedAt ?? this.indexedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (filePath.present) {
      map['file_path'] = Variable<String>(filePath.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (sizeBytes.present) {
      map['size_bytes'] = Variable<int>(sizeBytes.value);
    }
    if (format.present) {
      map['format'] = Variable<String>(format.value);
    }
    if (durationMs.present) {
      map['duration_ms'] = Variable<int>(durationMs.value);
    }
    if (indexedAt.present) {
      map['indexed_at'] = Variable<DateTime>(indexedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecordingsCompanion(')
          ..write('id: $id, ')
          ..write('filePath: $filePath, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('format: $format, ')
          ..write('durationMs: $durationMs, ')
          ..write('indexedAt: $indexedAt')
          ..write(')'))
        .toString();
  }
}

class $ReviewEventsTable extends ReviewEvents
    with TableInfo<$ReviewEventsTable, ReviewEvent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReviewEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _recordingIdMeta = const VerificationMeta(
    'recordingId',
  );
  @override
  late final GeneratedColumn<int> recordingId = GeneratedColumn<int>(
    'recording_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES recordings (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _milestoneIndexMeta = const VerificationMeta(
    'milestoneIndex',
  );
  @override
  late final GeneratedColumn<int> milestoneIndex = GeneratedColumn<int>(
    'milestone_index',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    recordingId,
    milestoneIndex,
    completedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'review_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReviewEvent> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('recording_id')) {
      context.handle(
        _recordingIdMeta,
        recordingId.isAcceptableOrUnknown(
          data['recording_id']!,
          _recordingIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_recordingIdMeta);
    }
    if (data.containsKey('milestone_index')) {
      context.handle(
        _milestoneIndexMeta,
        milestoneIndex.isAcceptableOrUnknown(
          data['milestone_index']!,
          _milestoneIndexMeta,
        ),
      );
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_completedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReviewEvent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReviewEvent(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      recordingId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}recording_id'],
      )!,
      milestoneIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}milestone_index'],
      ),
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      )!,
    );
  }

  @override
  $ReviewEventsTable createAlias(String alias) {
    return $ReviewEventsTable(attachedDatabase, alias);
  }
}

class ReviewEvent extends DataClass implements Insertable<ReviewEvent> {
  final int id;

  /// The recording this review counts toward. Cascade-deleted with the
  /// recording so a (future) recording delete cleans its history.
  final int recordingId;

  /// The GPA milestone (0..7) this event satisfied, or null for a play that
  /// earned no milestone. Nullable by design — see file header.
  final int? milestoneIndex;

  /// When the 80%-threshold was crossed (auto) or the correction was made
  /// (manual). Day-granularity drives milestone assignment (see gpa_review).
  final DateTime completedAt;
  const ReviewEvent({
    required this.id,
    required this.recordingId,
    this.milestoneIndex,
    required this.completedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['recording_id'] = Variable<int>(recordingId);
    if (!nullToAbsent || milestoneIndex != null) {
      map['milestone_index'] = Variable<int>(milestoneIndex);
    }
    map['completed_at'] = Variable<DateTime>(completedAt);
    return map;
  }

  ReviewEventsCompanion toCompanion(bool nullToAbsent) {
    return ReviewEventsCompanion(
      id: Value(id),
      recordingId: Value(recordingId),
      milestoneIndex: milestoneIndex == null && nullToAbsent
          ? const Value.absent()
          : Value(milestoneIndex),
      completedAt: Value(completedAt),
    );
  }

  factory ReviewEvent.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReviewEvent(
      id: serializer.fromJson<int>(json['id']),
      recordingId: serializer.fromJson<int>(json['recordingId']),
      milestoneIndex: serializer.fromJson<int?>(json['milestoneIndex']),
      completedAt: serializer.fromJson<DateTime>(json['completedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'recordingId': serializer.toJson<int>(recordingId),
      'milestoneIndex': serializer.toJson<int?>(milestoneIndex),
      'completedAt': serializer.toJson<DateTime>(completedAt),
    };
  }

  ReviewEvent copyWith({
    int? id,
    int? recordingId,
    Value<int?> milestoneIndex = const Value.absent(),
    DateTime? completedAt,
  }) => ReviewEvent(
    id: id ?? this.id,
    recordingId: recordingId ?? this.recordingId,
    milestoneIndex: milestoneIndex.present
        ? milestoneIndex.value
        : this.milestoneIndex,
    completedAt: completedAt ?? this.completedAt,
  );
  ReviewEvent copyWithCompanion(ReviewEventsCompanion data) {
    return ReviewEvent(
      id: data.id.present ? data.id.value : this.id,
      recordingId: data.recordingId.present
          ? data.recordingId.value
          : this.recordingId,
      milestoneIndex: data.milestoneIndex.present
          ? data.milestoneIndex.value
          : this.milestoneIndex,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReviewEvent(')
          ..write('id: $id, ')
          ..write('recordingId: $recordingId, ')
          ..write('milestoneIndex: $milestoneIndex, ')
          ..write('completedAt: $completedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, recordingId, milestoneIndex, completedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReviewEvent &&
          other.id == this.id &&
          other.recordingId == this.recordingId &&
          other.milestoneIndex == this.milestoneIndex &&
          other.completedAt == this.completedAt);
}

class ReviewEventsCompanion extends UpdateCompanion<ReviewEvent> {
  final Value<int> id;
  final Value<int> recordingId;
  final Value<int?> milestoneIndex;
  final Value<DateTime> completedAt;
  const ReviewEventsCompanion({
    this.id = const Value.absent(),
    this.recordingId = const Value.absent(),
    this.milestoneIndex = const Value.absent(),
    this.completedAt = const Value.absent(),
  });
  ReviewEventsCompanion.insert({
    this.id = const Value.absent(),
    required int recordingId,
    this.milestoneIndex = const Value.absent(),
    required DateTime completedAt,
  }) : recordingId = Value(recordingId),
       completedAt = Value(completedAt);
  static Insertable<ReviewEvent> custom({
    Expression<int>? id,
    Expression<int>? recordingId,
    Expression<int>? milestoneIndex,
    Expression<DateTime>? completedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (recordingId != null) 'recording_id': recordingId,
      if (milestoneIndex != null) 'milestone_index': milestoneIndex,
      if (completedAt != null) 'completed_at': completedAt,
    });
  }

  ReviewEventsCompanion copyWith({
    Value<int>? id,
    Value<int>? recordingId,
    Value<int?>? milestoneIndex,
    Value<DateTime>? completedAt,
  }) {
    return ReviewEventsCompanion(
      id: id ?? this.id,
      recordingId: recordingId ?? this.recordingId,
      milestoneIndex: milestoneIndex ?? this.milestoneIndex,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (recordingId.present) {
      map['recording_id'] = Variable<int>(recordingId.value);
    }
    if (milestoneIndex.present) {
      map['milestone_index'] = Variable<int>(milestoneIndex.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReviewEventsCompanion(')
          ..write('id: $id, ')
          ..write('recordingId: $recordingId, ')
          ..write('milestoneIndex: $milestoneIndex, ')
          ..write('completedAt: $completedAt')
          ..write(')'))
        .toString();
  }
}

class $WordLogsTable extends WordLogs with TableInfo<$WordLogsTable, WordLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WordLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _recordingIdMeta = const VerificationMeta(
    'recordingId',
  );
  @override
  late final GeneratedColumn<int> recordingId = GeneratedColumn<int>(
    'recording_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES recordings (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    recordingId,
    kind,
    body,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'word_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<WordLog> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('recording_id')) {
      context.handle(
        _recordingIdMeta,
        recordingId.isAcceptableOrUnknown(
          data['recording_id']!,
          _recordingIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_recordingIdMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WordLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WordLog(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      recordingId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}recording_id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $WordLogsTable createAlias(String alias) {
    return $WordLogsTable(attachedDatabase, alias);
  }
}

class WordLog extends DataClass implements Insertable<WordLog> {
  final int id;

  /// The recording this artifact belongs to. Cascade-deleted with the
  /// recording so no orphaned text/images survive a recording delete.
  final int recordingId;
  final String kind;
  final String body;
  final DateTime createdAt;
  const WordLog({
    required this.id,
    required this.recordingId,
    required this.kind,
    required this.body,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['recording_id'] = Variable<int>(recordingId);
    map['kind'] = Variable<String>(kind);
    map['body'] = Variable<String>(body);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  WordLogsCompanion toCompanion(bool nullToAbsent) {
    return WordLogsCompanion(
      id: Value(id),
      recordingId: Value(recordingId),
      kind: Value(kind),
      body: Value(body),
      createdAt: Value(createdAt),
    );
  }

  factory WordLog.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WordLog(
      id: serializer.fromJson<int>(json['id']),
      recordingId: serializer.fromJson<int>(json['recordingId']),
      kind: serializer.fromJson<String>(json['kind']),
      body: serializer.fromJson<String>(json['body']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'recordingId': serializer.toJson<int>(recordingId),
      'kind': serializer.toJson<String>(kind),
      'body': serializer.toJson<String>(body),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  WordLog copyWith({
    int? id,
    int? recordingId,
    String? kind,
    String? body,
    DateTime? createdAt,
  }) => WordLog(
    id: id ?? this.id,
    recordingId: recordingId ?? this.recordingId,
    kind: kind ?? this.kind,
    body: body ?? this.body,
    createdAt: createdAt ?? this.createdAt,
  );
  WordLog copyWithCompanion(WordLogsCompanion data) {
    return WordLog(
      id: data.id.present ? data.id.value : this.id,
      recordingId: data.recordingId.present
          ? data.recordingId.value
          : this.recordingId,
      kind: data.kind.present ? data.kind.value : this.kind,
      body: data.body.present ? data.body.value : this.body,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WordLog(')
          ..write('id: $id, ')
          ..write('recordingId: $recordingId, ')
          ..write('kind: $kind, ')
          ..write('body: $body, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, recordingId, kind, body, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WordLog &&
          other.id == this.id &&
          other.recordingId == this.recordingId &&
          other.kind == this.kind &&
          other.body == this.body &&
          other.createdAt == this.createdAt);
}

class WordLogsCompanion extends UpdateCompanion<WordLog> {
  final Value<int> id;
  final Value<int> recordingId;
  final Value<String> kind;
  final Value<String> body;
  final Value<DateTime> createdAt;
  const WordLogsCompanion({
    this.id = const Value.absent(),
    this.recordingId = const Value.absent(),
    this.kind = const Value.absent(),
    this.body = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  WordLogsCompanion.insert({
    this.id = const Value.absent(),
    required int recordingId,
    required String kind,
    required String body,
    this.createdAt = const Value.absent(),
  }) : recordingId = Value(recordingId),
       kind = Value(kind),
       body = Value(body);
  static Insertable<WordLog> custom({
    Expression<int>? id,
    Expression<int>? recordingId,
    Expression<String>? kind,
    Expression<String>? body,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (recordingId != null) 'recording_id': recordingId,
      if (kind != null) 'kind': kind,
      if (body != null) 'body': body,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  WordLogsCompanion copyWith({
    Value<int>? id,
    Value<int>? recordingId,
    Value<String>? kind,
    Value<String>? body,
    Value<DateTime>? createdAt,
  }) {
    return WordLogsCompanion(
      id: id ?? this.id,
      recordingId: recordingId ?? this.recordingId,
      kind: kind ?? this.kind,
      body: body ?? this.body,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (recordingId.present) {
      map['recording_id'] = Variable<int>(recordingId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WordLogsCompanion(')
          ..write('id: $id, ')
          ..write('recordingId: $recordingId, ')
          ..write('kind: $kind, ')
          ..write('body: $body, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $KeyValuesTable keyValues = $KeyValuesTable(this);
  late final $OfflineQueueItemsTable offlineQueueItems =
      $OfflineQueueItemsTable(this);
  late final $RecordingsTable recordings = $RecordingsTable(this);
  late final $ReviewEventsTable reviewEvents = $ReviewEventsTable(this);
  late final $WordLogsTable wordLogs = $WordLogsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    keyValues,
    offlineQueueItems,
    recordings,
    reviewEvents,
    wordLogs,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'recordings',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('review_events', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'recordings',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('word_logs', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$KeyValuesTableCreateCompanionBuilder =
    KeyValuesCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$KeyValuesTableUpdateCompanionBuilder =
    KeyValuesCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$KeyValuesTableFilterComposer
    extends Composer<_$AppDatabase, $KeyValuesTable> {
  $$KeyValuesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$KeyValuesTableOrderingComposer
    extends Composer<_$AppDatabase, $KeyValuesTable> {
  $$KeyValuesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$KeyValuesTableAnnotationComposer
    extends Composer<_$AppDatabase, $KeyValuesTable> {
  $$KeyValuesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$KeyValuesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $KeyValuesTable,
          KeyValue,
          $$KeyValuesTableFilterComposer,
          $$KeyValuesTableOrderingComposer,
          $$KeyValuesTableAnnotationComposer,
          $$KeyValuesTableCreateCompanionBuilder,
          $$KeyValuesTableUpdateCompanionBuilder,
          (KeyValue, BaseReferences<_$AppDatabase, $KeyValuesTable, KeyValue>),
          KeyValue,
          PrefetchHooks Function()
        > {
  $$KeyValuesTableTableManager(_$AppDatabase db, $KeyValuesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$KeyValuesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$KeyValuesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$KeyValuesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => KeyValuesCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => KeyValuesCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$KeyValuesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $KeyValuesTable,
      KeyValue,
      $$KeyValuesTableFilterComposer,
      $$KeyValuesTableOrderingComposer,
      $$KeyValuesTableAnnotationComposer,
      $$KeyValuesTableCreateCompanionBuilder,
      $$KeyValuesTableUpdateCompanionBuilder,
      (KeyValue, BaseReferences<_$AppDatabase, $KeyValuesTable, KeyValue>),
      KeyValue,
      PrefetchHooks Function()
    >;
typedef $$OfflineQueueItemsTableCreateCompanionBuilder =
    OfflineQueueItemsCompanion Function({
      Value<int> id,
      required String type,
      required String payload,
      Value<DateTime> createdAt,
      Value<int> attempts,
      Value<String?> lastError,
      Value<bool> done,
    });
typedef $$OfflineQueueItemsTableUpdateCompanionBuilder =
    OfflineQueueItemsCompanion Function({
      Value<int> id,
      Value<String> type,
      Value<String> payload,
      Value<DateTime> createdAt,
      Value<int> attempts,
      Value<String?> lastError,
      Value<bool> done,
    });

class $$OfflineQueueItemsTableFilterComposer
    extends Composer<_$AppDatabase, $OfflineQueueItemsTable> {
  $$OfflineQueueItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get done => $composableBuilder(
    column: $table.done,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OfflineQueueItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $OfflineQueueItemsTable> {
  $$OfflineQueueItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get done => $composableBuilder(
    column: $table.done,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OfflineQueueItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $OfflineQueueItemsTable> {
  $$OfflineQueueItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  GeneratedColumn<bool> get done =>
      $composableBuilder(column: $table.done, builder: (column) => column);
}

class $$OfflineQueueItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OfflineQueueItemsTable,
          OfflineQueueItem,
          $$OfflineQueueItemsTableFilterComposer,
          $$OfflineQueueItemsTableOrderingComposer,
          $$OfflineQueueItemsTableAnnotationComposer,
          $$OfflineQueueItemsTableCreateCompanionBuilder,
          $$OfflineQueueItemsTableUpdateCompanionBuilder,
          (
            OfflineQueueItem,
            BaseReferences<
              _$AppDatabase,
              $OfflineQueueItemsTable,
              OfflineQueueItem
            >,
          ),
          OfflineQueueItem,
          PrefetchHooks Function()
        > {
  $$OfflineQueueItemsTableTableManager(
    _$AppDatabase db,
    $OfflineQueueItemsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OfflineQueueItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OfflineQueueItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OfflineQueueItemsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<bool> done = const Value.absent(),
              }) => OfflineQueueItemsCompanion(
                id: id,
                type: type,
                payload: payload,
                createdAt: createdAt,
                attempts: attempts,
                lastError: lastError,
                done: done,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String type,
                required String payload,
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<bool> done = const Value.absent(),
              }) => OfflineQueueItemsCompanion.insert(
                id: id,
                type: type,
                payload: payload,
                createdAt: createdAt,
                attempts: attempts,
                lastError: lastError,
                done: done,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OfflineQueueItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OfflineQueueItemsTable,
      OfflineQueueItem,
      $$OfflineQueueItemsTableFilterComposer,
      $$OfflineQueueItemsTableOrderingComposer,
      $$OfflineQueueItemsTableAnnotationComposer,
      $$OfflineQueueItemsTableCreateCompanionBuilder,
      $$OfflineQueueItemsTableUpdateCompanionBuilder,
      (
        OfflineQueueItem,
        BaseReferences<
          _$AppDatabase,
          $OfflineQueueItemsTable,
          OfflineQueueItem
        >,
      ),
      OfflineQueueItem,
      PrefetchHooks Function()
    >;
typedef $$RecordingsTableCreateCompanionBuilder =
    RecordingsCompanion Function({
      Value<int> id,
      required String filePath,
      required String name,
      required DateTime createdAt,
      required int sizeBytes,
      required String format,
      Value<int?> durationMs,
      Value<DateTime> indexedAt,
    });
typedef $$RecordingsTableUpdateCompanionBuilder =
    RecordingsCompanion Function({
      Value<int> id,
      Value<String> filePath,
      Value<String> name,
      Value<DateTime> createdAt,
      Value<int> sizeBytes,
      Value<String> format,
      Value<int?> durationMs,
      Value<DateTime> indexedAt,
    });

final class $$RecordingsTableReferences
    extends BaseReferences<_$AppDatabase, $RecordingsTable, Recording> {
  $$RecordingsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ReviewEventsTable, List<ReviewEvent>>
  _reviewEventsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.reviewEvents,
    aliasName: 'recordings__id__review_events__recording_id',
  );

  $$ReviewEventsTableProcessedTableManager get reviewEventsRefs {
    final manager = $$ReviewEventsTableTableManager(
      $_db,
      $_db.reviewEvents,
    ).filter((f) => f.recordingId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_reviewEventsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$WordLogsTable, List<WordLog>> _wordLogsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.wordLogs,
    aliasName: 'recordings__id__word_logs__recording_id',
  );

  $$WordLogsTableProcessedTableManager get wordLogsRefs {
    final manager = $$WordLogsTableTableManager(
      $_db,
      $_db.wordLogs,
    ).filter((f) => f.recordingId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_wordLogsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$RecordingsTableFilterComposer
    extends Composer<_$AppDatabase, $RecordingsTable> {
  $$RecordingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get format => $composableBuilder(
    column: $table.format,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get indexedAt => $composableBuilder(
    column: $table.indexedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> reviewEventsRefs(
    Expression<bool> Function($$ReviewEventsTableFilterComposer f) f,
  ) {
    final $$ReviewEventsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.reviewEvents,
      getReferencedColumn: (t) => t.recordingId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReviewEventsTableFilterComposer(
            $db: $db,
            $table: $db.reviewEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> wordLogsRefs(
    Expression<bool> Function($$WordLogsTableFilterComposer f) f,
  ) {
    final $$WordLogsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.wordLogs,
      getReferencedColumn: (t) => t.recordingId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WordLogsTableFilterComposer(
            $db: $db,
            $table: $db.wordLogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$RecordingsTableOrderingComposer
    extends Composer<_$AppDatabase, $RecordingsTable> {
  $$RecordingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get format => $composableBuilder(
    column: $table.format,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get indexedAt => $composableBuilder(
    column: $table.indexedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RecordingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RecordingsTable> {
  $$RecordingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get filePath =>
      $composableBuilder(column: $table.filePath, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get sizeBytes =>
      $composableBuilder(column: $table.sizeBytes, builder: (column) => column);

  GeneratedColumn<String> get format =>
      $composableBuilder(column: $table.format, builder: (column) => column);

  GeneratedColumn<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get indexedAt =>
      $composableBuilder(column: $table.indexedAt, builder: (column) => column);

  Expression<T> reviewEventsRefs<T extends Object>(
    Expression<T> Function($$ReviewEventsTableAnnotationComposer a) f,
  ) {
    final $$ReviewEventsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.reviewEvents,
      getReferencedColumn: (t) => t.recordingId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReviewEventsTableAnnotationComposer(
            $db: $db,
            $table: $db.reviewEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> wordLogsRefs<T extends Object>(
    Expression<T> Function($$WordLogsTableAnnotationComposer a) f,
  ) {
    final $$WordLogsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.wordLogs,
      getReferencedColumn: (t) => t.recordingId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WordLogsTableAnnotationComposer(
            $db: $db,
            $table: $db.wordLogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$RecordingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RecordingsTable,
          Recording,
          $$RecordingsTableFilterComposer,
          $$RecordingsTableOrderingComposer,
          $$RecordingsTableAnnotationComposer,
          $$RecordingsTableCreateCompanionBuilder,
          $$RecordingsTableUpdateCompanionBuilder,
          (Recording, $$RecordingsTableReferences),
          Recording,
          PrefetchHooks Function({bool reviewEventsRefs, bool wordLogsRefs})
        > {
  $$RecordingsTableTableManager(_$AppDatabase db, $RecordingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RecordingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RecordingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RecordingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> filePath = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> sizeBytes = const Value.absent(),
                Value<String> format = const Value.absent(),
                Value<int?> durationMs = const Value.absent(),
                Value<DateTime> indexedAt = const Value.absent(),
              }) => RecordingsCompanion(
                id: id,
                filePath: filePath,
                name: name,
                createdAt: createdAt,
                sizeBytes: sizeBytes,
                format: format,
                durationMs: durationMs,
                indexedAt: indexedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String filePath,
                required String name,
                required DateTime createdAt,
                required int sizeBytes,
                required String format,
                Value<int?> durationMs = const Value.absent(),
                Value<DateTime> indexedAt = const Value.absent(),
              }) => RecordingsCompanion.insert(
                id: id,
                filePath: filePath,
                name: name,
                createdAt: createdAt,
                sizeBytes: sizeBytes,
                format: format,
                durationMs: durationMs,
                indexedAt: indexedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$RecordingsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({reviewEventsRefs = false, wordLogsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (reviewEventsRefs) db.reviewEvents,
                    if (wordLogsRefs) db.wordLogs,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (reviewEventsRefs)
                        await $_getPrefetchedData<
                          Recording,
                          $RecordingsTable,
                          ReviewEvent
                        >(
                          currentTable: table,
                          referencedTable: $$RecordingsTableReferences
                              ._reviewEventsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$RecordingsTableReferences(
                                db,
                                table,
                                p0,
                              ).reviewEventsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.recordingId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (wordLogsRefs)
                        await $_getPrefetchedData<
                          Recording,
                          $RecordingsTable,
                          WordLog
                        >(
                          currentTable: table,
                          referencedTable: $$RecordingsTableReferences
                              ._wordLogsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$RecordingsTableReferences(
                                db,
                                table,
                                p0,
                              ).wordLogsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.recordingId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$RecordingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RecordingsTable,
      Recording,
      $$RecordingsTableFilterComposer,
      $$RecordingsTableOrderingComposer,
      $$RecordingsTableAnnotationComposer,
      $$RecordingsTableCreateCompanionBuilder,
      $$RecordingsTableUpdateCompanionBuilder,
      (Recording, $$RecordingsTableReferences),
      Recording,
      PrefetchHooks Function({bool reviewEventsRefs, bool wordLogsRefs})
    >;
typedef $$ReviewEventsTableCreateCompanionBuilder =
    ReviewEventsCompanion Function({
      Value<int> id,
      required int recordingId,
      Value<int?> milestoneIndex,
      required DateTime completedAt,
    });
typedef $$ReviewEventsTableUpdateCompanionBuilder =
    ReviewEventsCompanion Function({
      Value<int> id,
      Value<int> recordingId,
      Value<int?> milestoneIndex,
      Value<DateTime> completedAt,
    });

final class $$ReviewEventsTableReferences
    extends BaseReferences<_$AppDatabase, $ReviewEventsTable, ReviewEvent> {
  $$ReviewEventsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $RecordingsTable _recordingIdTable(_$AppDatabase db) =>
      db.recordings.createAlias('review_events__recording_id__recordings__id');

  $$RecordingsTableProcessedTableManager get recordingId {
    final $_column = $_itemColumn<int>('recording_id')!;

    final manager = $$RecordingsTableTableManager(
      $_db,
      $_db.recordings,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_recordingIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ReviewEventsTableFilterComposer
    extends Composer<_$AppDatabase, $ReviewEventsTable> {
  $$ReviewEventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get milestoneIndex => $composableBuilder(
    column: $table.milestoneIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$RecordingsTableFilterComposer get recordingId {
    final $$RecordingsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recordingId,
      referencedTable: $db.recordings,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecordingsTableFilterComposer(
            $db: $db,
            $table: $db.recordings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReviewEventsTableOrderingComposer
    extends Composer<_$AppDatabase, $ReviewEventsTable> {
  $$ReviewEventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get milestoneIndex => $composableBuilder(
    column: $table.milestoneIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$RecordingsTableOrderingComposer get recordingId {
    final $$RecordingsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recordingId,
      referencedTable: $db.recordings,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecordingsTableOrderingComposer(
            $db: $db,
            $table: $db.recordings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReviewEventsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReviewEventsTable> {
  $$ReviewEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get milestoneIndex => $composableBuilder(
    column: $table.milestoneIndex,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  $$RecordingsTableAnnotationComposer get recordingId {
    final $$RecordingsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recordingId,
      referencedTable: $db.recordings,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecordingsTableAnnotationComposer(
            $db: $db,
            $table: $db.recordings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReviewEventsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReviewEventsTable,
          ReviewEvent,
          $$ReviewEventsTableFilterComposer,
          $$ReviewEventsTableOrderingComposer,
          $$ReviewEventsTableAnnotationComposer,
          $$ReviewEventsTableCreateCompanionBuilder,
          $$ReviewEventsTableUpdateCompanionBuilder,
          (ReviewEvent, $$ReviewEventsTableReferences),
          ReviewEvent,
          PrefetchHooks Function({bool recordingId})
        > {
  $$ReviewEventsTableTableManager(_$AppDatabase db, $ReviewEventsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReviewEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReviewEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReviewEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> recordingId = const Value.absent(),
                Value<int?> milestoneIndex = const Value.absent(),
                Value<DateTime> completedAt = const Value.absent(),
              }) => ReviewEventsCompanion(
                id: id,
                recordingId: recordingId,
                milestoneIndex: milestoneIndex,
                completedAt: completedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int recordingId,
                Value<int?> milestoneIndex = const Value.absent(),
                required DateTime completedAt,
              }) => ReviewEventsCompanion.insert(
                id: id,
                recordingId: recordingId,
                milestoneIndex: milestoneIndex,
                completedAt: completedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ReviewEventsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({recordingId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (recordingId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.recordingId,
                                referencedTable: $$ReviewEventsTableReferences
                                    ._recordingIdTable(db),
                                referencedColumn: $$ReviewEventsTableReferences
                                    ._recordingIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ReviewEventsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReviewEventsTable,
      ReviewEvent,
      $$ReviewEventsTableFilterComposer,
      $$ReviewEventsTableOrderingComposer,
      $$ReviewEventsTableAnnotationComposer,
      $$ReviewEventsTableCreateCompanionBuilder,
      $$ReviewEventsTableUpdateCompanionBuilder,
      (ReviewEvent, $$ReviewEventsTableReferences),
      ReviewEvent,
      PrefetchHooks Function({bool recordingId})
    >;
typedef $$WordLogsTableCreateCompanionBuilder =
    WordLogsCompanion Function({
      Value<int> id,
      required int recordingId,
      required String kind,
      required String body,
      Value<DateTime> createdAt,
    });
typedef $$WordLogsTableUpdateCompanionBuilder =
    WordLogsCompanion Function({
      Value<int> id,
      Value<int> recordingId,
      Value<String> kind,
      Value<String> body,
      Value<DateTime> createdAt,
    });

final class $$WordLogsTableReferences
    extends BaseReferences<_$AppDatabase, $WordLogsTable, WordLog> {
  $$WordLogsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $RecordingsTable _recordingIdTable(_$AppDatabase db) =>
      db.recordings.createAlias('word_logs__recording_id__recordings__id');

  $$RecordingsTableProcessedTableManager get recordingId {
    final $_column = $_itemColumn<int>('recording_id')!;

    final manager = $$RecordingsTableTableManager(
      $_db,
      $_db.recordings,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_recordingIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$WordLogsTableFilterComposer
    extends Composer<_$AppDatabase, $WordLogsTable> {
  $$WordLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$RecordingsTableFilterComposer get recordingId {
    final $$RecordingsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recordingId,
      referencedTable: $db.recordings,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecordingsTableFilterComposer(
            $db: $db,
            $table: $db.recordings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WordLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $WordLogsTable> {
  $$WordLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$RecordingsTableOrderingComposer get recordingId {
    final $$RecordingsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recordingId,
      referencedTable: $db.recordings,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecordingsTableOrderingComposer(
            $db: $db,
            $table: $db.recordings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WordLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WordLogsTable> {
  $$WordLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$RecordingsTableAnnotationComposer get recordingId {
    final $$RecordingsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recordingId,
      referencedTable: $db.recordings,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecordingsTableAnnotationComposer(
            $db: $db,
            $table: $db.recordings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WordLogsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WordLogsTable,
          WordLog,
          $$WordLogsTableFilterComposer,
          $$WordLogsTableOrderingComposer,
          $$WordLogsTableAnnotationComposer,
          $$WordLogsTableCreateCompanionBuilder,
          $$WordLogsTableUpdateCompanionBuilder,
          (WordLog, $$WordLogsTableReferences),
          WordLog,
          PrefetchHooks Function({bool recordingId})
        > {
  $$WordLogsTableTableManager(_$AppDatabase db, $WordLogsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WordLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WordLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WordLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> recordingId = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> body = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => WordLogsCompanion(
                id: id,
                recordingId: recordingId,
                kind: kind,
                body: body,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int recordingId,
                required String kind,
                required String body,
                Value<DateTime> createdAt = const Value.absent(),
              }) => WordLogsCompanion.insert(
                id: id,
                recordingId: recordingId,
                kind: kind,
                body: body,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$WordLogsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({recordingId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (recordingId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.recordingId,
                                referencedTable: $$WordLogsTableReferences
                                    ._recordingIdTable(db),
                                referencedColumn: $$WordLogsTableReferences
                                    ._recordingIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$WordLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WordLogsTable,
      WordLog,
      $$WordLogsTableFilterComposer,
      $$WordLogsTableOrderingComposer,
      $$WordLogsTableAnnotationComposer,
      $$WordLogsTableCreateCompanionBuilder,
      $$WordLogsTableUpdateCompanionBuilder,
      (WordLog, $$WordLogsTableReferences),
      WordLog,
      PrefetchHooks Function({bool recordingId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$KeyValuesTableTableManager get keyValues =>
      $$KeyValuesTableTableManager(_db, _db.keyValues);
  $$OfflineQueueItemsTableTableManager get offlineQueueItems =>
      $$OfflineQueueItemsTableTableManager(_db, _db.offlineQueueItems);
  $$RecordingsTableTableManager get recordings =>
      $$RecordingsTableTableManager(_db, _db.recordings);
  $$ReviewEventsTableTableManager get reviewEvents =>
      $$ReviewEventsTableTableManager(_db, _db.reviewEvents);
  $$WordLogsTableTableManager get wordLogs =>
      $$WordLogsTableTableManager(_db, _db.wordLogs);
}
