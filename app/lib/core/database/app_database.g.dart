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

class $AiImageCacheItemsTable extends AiImageCacheItems
    with TableInfo<$AiImageCacheItemsTable, AiImageCacheItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AiImageCacheItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _uzbekWordMeta = const VerificationMeta(
    'uzbekWord',
  );
  @override
  late final GeneratedColumn<String> uzbekWord = GeneratedColumn<String>(
    'uzbek_word',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _relativePathMeta = const VerificationMeta(
    'relativePath',
  );
  @override
  late final GeneratedColumn<String> relativePath = GeneratedColumn<String>(
    'relative_path',
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
  List<GeneratedColumn> get $columns => [uzbekWord, relativePath, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ai_image_cache_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<AiImageCacheItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('uzbek_word')) {
      context.handle(
        _uzbekWordMeta,
        uzbekWord.isAcceptableOrUnknown(data['uzbek_word']!, _uzbekWordMeta),
      );
    } else if (isInserting) {
      context.missing(_uzbekWordMeta);
    }
    if (data.containsKey('relative_path')) {
      context.handle(
        _relativePathMeta,
        relativePath.isAcceptableOrUnknown(
          data['relative_path']!,
          _relativePathMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_relativePathMeta);
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
  Set<GeneratedColumn> get $primaryKey => const {};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {uzbekWord},
  ];
  @override
  AiImageCacheItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AiImageCacheItem(
      uzbekWord: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uzbek_word'],
      )!,
      relativePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}relative_path'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $AiImageCacheItemsTable createAlias(String alias) {
    return $AiImageCacheItemsTable(attachedDatabase, alias);
  }
}

class AiImageCacheItem extends DataClass
    implements Insertable<AiImageCacheItem> {
  final String uzbekWord;
  final String relativePath;
  final DateTime createdAt;
  const AiImageCacheItem({
    required this.uzbekWord,
    required this.relativePath,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['uzbek_word'] = Variable<String>(uzbekWord);
    map['relative_path'] = Variable<String>(relativePath);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  AiImageCacheItemsCompanion toCompanion(bool nullToAbsent) {
    return AiImageCacheItemsCompanion(
      uzbekWord: Value(uzbekWord),
      relativePath: Value(relativePath),
      createdAt: Value(createdAt),
    );
  }

  factory AiImageCacheItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AiImageCacheItem(
      uzbekWord: serializer.fromJson<String>(json['uzbekWord']),
      relativePath: serializer.fromJson<String>(json['relativePath']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'uzbekWord': serializer.toJson<String>(uzbekWord),
      'relativePath': serializer.toJson<String>(relativePath),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  AiImageCacheItem copyWith({
    String? uzbekWord,
    String? relativePath,
    DateTime? createdAt,
  }) => AiImageCacheItem(
    uzbekWord: uzbekWord ?? this.uzbekWord,
    relativePath: relativePath ?? this.relativePath,
    createdAt: createdAt ?? this.createdAt,
  );
  AiImageCacheItem copyWithCompanion(AiImageCacheItemsCompanion data) {
    return AiImageCacheItem(
      uzbekWord: data.uzbekWord.present ? data.uzbekWord.value : this.uzbekWord,
      relativePath: data.relativePath.present
          ? data.relativePath.value
          : this.relativePath,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AiImageCacheItem(')
          ..write('uzbekWord: $uzbekWord, ')
          ..write('relativePath: $relativePath, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(uzbekWord, relativePath, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AiImageCacheItem &&
          other.uzbekWord == this.uzbekWord &&
          other.relativePath == this.relativePath &&
          other.createdAt == this.createdAt);
}

class AiImageCacheItemsCompanion extends UpdateCompanion<AiImageCacheItem> {
  final Value<String> uzbekWord;
  final Value<String> relativePath;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const AiImageCacheItemsCompanion({
    this.uzbekWord = const Value.absent(),
    this.relativePath = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AiImageCacheItemsCompanion.insert({
    required String uzbekWord,
    required String relativePath,
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : uzbekWord = Value(uzbekWord),
       relativePath = Value(relativePath);
  static Insertable<AiImageCacheItem> custom({
    Expression<String>? uzbekWord,
    Expression<String>? relativePath,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (uzbekWord != null) 'uzbek_word': uzbekWord,
      if (relativePath != null) 'relative_path': relativePath,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AiImageCacheItemsCompanion copyWith({
    Value<String>? uzbekWord,
    Value<String>? relativePath,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return AiImageCacheItemsCompanion(
      uzbekWord: uzbekWord ?? this.uzbekWord,
      relativePath: relativePath ?? this.relativePath,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (uzbekWord.present) {
      map['uzbek_word'] = Variable<String>(uzbekWord.value);
    }
    if (relativePath.present) {
      map['relative_path'] = Variable<String>(relativePath.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AiImageCacheItemsCompanion(')
          ..write('uzbekWord: $uzbekWord, ')
          ..write('relativePath: $relativePath, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TasksTable extends Tasks with TableInfo<$TasksTable, Task> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TasksTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dueDateMeta = const VerificationMeta(
    'dueDate',
  );
  @override
  late final GeneratedColumn<DateTime> dueDate = GeneratedColumn<DateTime>(
    'due_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _completedMeta = const VerificationMeta(
    'completed',
  );
  @override
  late final GeneratedColumn<bool> completed = GeneratedColumn<bool>(
    'completed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("completed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
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
    title,
    description,
    dueDate,
    completed,
    completedAt,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tasks';
  @override
  VerificationContext validateIntegrity(
    Insertable<Task> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('due_date')) {
      context.handle(
        _dueDateMeta,
        dueDate.isAcceptableOrUnknown(data['due_date']!, _dueDateMeta),
      );
    }
    if (data.containsKey('completed')) {
      context.handle(
        _completedMeta,
        completed.isAcceptableOrUnknown(data['completed']!, _completedMeta),
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
  Task map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Task(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      dueDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}due_date'],
      ),
      completed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}completed'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $TasksTable createAlias(String alias) {
    return $TasksTable(attachedDatabase, alias);
  }
}

class Task extends DataClass implements Insertable<Task> {
  final int id;

  /// Short human title (FR-1.4.1). Required.
  final String title;

  /// Longer free-form notes. Optional.
  final String? description;

  /// When the task is due, or null for an undated task. Day granularity.
  final DateTime? dueDate;

  /// The completion flag (FR-1.4.1). False while pending.
  final bool completed;

  /// When the user checked the task off. Null while pending; cleared on undo.
  final DateTime? completedAt;
  final DateTime createdAt;
  const Task({
    required this.id,
    required this.title,
    this.description,
    this.dueDate,
    required this.completed,
    this.completedAt,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || dueDate != null) {
      map['due_date'] = Variable<DateTime>(dueDate);
    }
    map['completed'] = Variable<bool>(completed);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  TasksCompanion toCompanion(bool nullToAbsent) {
    return TasksCompanion(
      id: Value(id),
      title: Value(title),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      dueDate: dueDate == null && nullToAbsent
          ? const Value.absent()
          : Value(dueDate),
      completed: Value(completed),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      createdAt: Value(createdAt),
    );
  }

  factory Task.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Task(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String?>(json['description']),
      dueDate: serializer.fromJson<DateTime?>(json['dueDate']),
      completed: serializer.fromJson<bool>(json['completed']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String?>(description),
      'dueDate': serializer.toJson<DateTime?>(dueDate),
      'completed': serializer.toJson<bool>(completed),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Task copyWith({
    int? id,
    String? title,
    Value<String?> description = const Value.absent(),
    Value<DateTime?> dueDate = const Value.absent(),
    bool? completed,
    Value<DateTime?> completedAt = const Value.absent(),
    DateTime? createdAt,
  }) => Task(
    id: id ?? this.id,
    title: title ?? this.title,
    description: description.present ? description.value : this.description,
    dueDate: dueDate.present ? dueDate.value : this.dueDate,
    completed: completed ?? this.completed,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
    createdAt: createdAt ?? this.createdAt,
  );
  Task copyWithCompanion(TasksCompanion data) {
    return Task(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      description: data.description.present
          ? data.description.value
          : this.description,
      dueDate: data.dueDate.present ? data.dueDate.value : this.dueDate,
      completed: data.completed.present ? data.completed.value : this.completed,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Task(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('dueDate: $dueDate, ')
          ..write('completed: $completed, ')
          ..write('completedAt: $completedAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    description,
    dueDate,
    completed,
    completedAt,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Task &&
          other.id == this.id &&
          other.title == this.title &&
          other.description == this.description &&
          other.dueDate == this.dueDate &&
          other.completed == this.completed &&
          other.completedAt == this.completedAt &&
          other.createdAt == this.createdAt);
}

class TasksCompanion extends UpdateCompanion<Task> {
  final Value<int> id;
  final Value<String> title;
  final Value<String?> description;
  final Value<DateTime?> dueDate;
  final Value<bool> completed;
  final Value<DateTime?> completedAt;
  final Value<DateTime> createdAt;
  const TasksCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.completed = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  TasksCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    this.description = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.completed = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : title = Value(title);
  static Insertable<Task> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<String>? description,
    Expression<DateTime>? dueDate,
    Expression<bool>? completed,
    Expression<DateTime>? completedAt,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (dueDate != null) 'due_date': dueDate,
      if (completed != null) 'completed': completed,
      if (completedAt != null) 'completed_at': completedAt,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  TasksCompanion copyWith({
    Value<int>? id,
    Value<String>? title,
    Value<String?>? description,
    Value<DateTime?>? dueDate,
    Value<bool>? completed,
    Value<DateTime?>? completedAt,
    Value<DateTime>? createdAt,
  }) {
    return TasksCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      completed: completed ?? this.completed,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (dueDate.present) {
      map['due_date'] = Variable<DateTime>(dueDate.value);
    }
    if (completed.present) {
      map['completed'] = Variable<bool>(completed.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TasksCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('dueDate: $dueDate, ')
          ..write('completed: $completed, ')
          ..write('completedAt: $completedAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $CoachNotesTable extends CoachNotes
    with TableInfo<$CoachNotesTable, CoachNote> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CoachNotesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
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
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [id, title, body, createdAt, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'coach_notes';
  @override
  VerificationContext validateIntegrity(
    Insertable<CoachNote> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CoachNote map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CoachNote(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $CoachNotesTable createAlias(String alias) {
    return $CoachNotesTable(attachedDatabase, alias);
  }
}

class CoachNote extends DataClass implements Insertable<CoachNote> {
  final int id;
  final String title;
  final String? body;
  final DateTime createdAt;
  final DateTime updatedAt;
  const CoachNote({
    required this.id,
    required this.title,
    this.body,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || body != null) {
      map['body'] = Variable<String>(body);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CoachNotesCompanion toCompanion(bool nullToAbsent) {
    return CoachNotesCompanion(
      id: Value(id),
      title: Value(title),
      body: body == null && nullToAbsent ? const Value.absent() : Value(body),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory CoachNote.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CoachNote(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      body: serializer.fromJson<String?>(json['body']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'body': serializer.toJson<String?>(body),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  CoachNote copyWith({
    int? id,
    String? title,
    Value<String?> body = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => CoachNote(
    id: id ?? this.id,
    title: title ?? this.title,
    body: body.present ? body.value : this.body,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  CoachNote copyWithCompanion(CoachNotesCompanion data) {
    return CoachNote(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      body: data.body.present ? data.body.value : this.body,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CoachNote(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, title, body, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CoachNote &&
          other.id == this.id &&
          other.title == this.title &&
          other.body == this.body &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class CoachNotesCompanion extends UpdateCompanion<CoachNote> {
  final Value<int> id;
  final Value<String> title;
  final Value<String?> body;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const CoachNotesCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.body = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  CoachNotesCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    this.body = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : title = Value(title);
  static Insertable<CoachNote> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<String>? body,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (body != null) 'body': body,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  CoachNotesCompanion copyWith({
    Value<int>? id,
    Value<String>? title,
    Value<String?>? body,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return CoachNotesCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CoachNotesCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $CoachNoteRecordingsTable extends CoachNoteRecordings
    with TableInfo<$CoachNoteRecordingsTable, CoachNoteRecording> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CoachNoteRecordingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _noteIdMeta = const VerificationMeta('noteId');
  @override
  late final GeneratedColumn<int> noteId = GeneratedColumn<int>(
    'note_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES coach_notes (id) ON DELETE CASCADE',
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
  @override
  List<GeneratedColumn> get $columns => [noteId, recordingId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'coach_note_recordings';
  @override
  VerificationContext validateIntegrity(
    Insertable<CoachNoteRecording> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('note_id')) {
      context.handle(
        _noteIdMeta,
        noteId.isAcceptableOrUnknown(data['note_id']!, _noteIdMeta),
      );
    } else if (isInserting) {
      context.missing(_noteIdMeta);
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {noteId, recordingId};
  @override
  CoachNoteRecording map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CoachNoteRecording(
      noteId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}note_id'],
      )!,
      recordingId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}recording_id'],
      )!,
    );
  }

  @override
  $CoachNoteRecordingsTable createAlias(String alias) {
    return $CoachNoteRecordingsTable(attachedDatabase, alias);
  }
}

class CoachNoteRecording extends DataClass
    implements Insertable<CoachNoteRecording> {
  final int noteId;
  final int recordingId;
  const CoachNoteRecording({required this.noteId, required this.recordingId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['note_id'] = Variable<int>(noteId);
    map['recording_id'] = Variable<int>(recordingId);
    return map;
  }

  CoachNoteRecordingsCompanion toCompanion(bool nullToAbsent) {
    return CoachNoteRecordingsCompanion(
      noteId: Value(noteId),
      recordingId: Value(recordingId),
    );
  }

  factory CoachNoteRecording.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CoachNoteRecording(
      noteId: serializer.fromJson<int>(json['noteId']),
      recordingId: serializer.fromJson<int>(json['recordingId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'noteId': serializer.toJson<int>(noteId),
      'recordingId': serializer.toJson<int>(recordingId),
    };
  }

  CoachNoteRecording copyWith({int? noteId, int? recordingId}) =>
      CoachNoteRecording(
        noteId: noteId ?? this.noteId,
        recordingId: recordingId ?? this.recordingId,
      );
  CoachNoteRecording copyWithCompanion(CoachNoteRecordingsCompanion data) {
    return CoachNoteRecording(
      noteId: data.noteId.present ? data.noteId.value : this.noteId,
      recordingId: data.recordingId.present
          ? data.recordingId.value
          : this.recordingId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CoachNoteRecording(')
          ..write('noteId: $noteId, ')
          ..write('recordingId: $recordingId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(noteId, recordingId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CoachNoteRecording &&
          other.noteId == this.noteId &&
          other.recordingId == this.recordingId);
}

class CoachNoteRecordingsCompanion extends UpdateCompanion<CoachNoteRecording> {
  final Value<int> noteId;
  final Value<int> recordingId;
  final Value<int> rowid;
  const CoachNoteRecordingsCompanion({
    this.noteId = const Value.absent(),
    this.recordingId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CoachNoteRecordingsCompanion.insert({
    required int noteId,
    required int recordingId,
    this.rowid = const Value.absent(),
  }) : noteId = Value(noteId),
       recordingId = Value(recordingId);
  static Insertable<CoachNoteRecording> custom({
    Expression<int>? noteId,
    Expression<int>? recordingId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (noteId != null) 'note_id': noteId,
      if (recordingId != null) 'recording_id': recordingId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CoachNoteRecordingsCompanion copyWith({
    Value<int>? noteId,
    Value<int>? recordingId,
    Value<int>? rowid,
  }) {
    return CoachNoteRecordingsCompanion(
      noteId: noteId ?? this.noteId,
      recordingId: recordingId ?? this.recordingId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (noteId.present) {
      map['note_id'] = Variable<int>(noteId.value);
    }
    if (recordingId.present) {
      map['recording_id'] = Variable<int>(recordingId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CoachNoteRecordingsCompanion(')
          ..write('noteId: $noteId, ')
          ..write('recordingId: $recordingId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CoachNoteWordLogsTable extends CoachNoteWordLogs
    with TableInfo<$CoachNoteWordLogsTable, CoachNoteWordLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CoachNoteWordLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _noteIdMeta = const VerificationMeta('noteId');
  @override
  late final GeneratedColumn<int> noteId = GeneratedColumn<int>(
    'note_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES coach_notes (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _wordLogIdMeta = const VerificationMeta(
    'wordLogId',
  );
  @override
  late final GeneratedColumn<int> wordLogId = GeneratedColumn<int>(
    'word_log_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES word_logs (id) ON DELETE CASCADE',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [noteId, wordLogId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'coach_note_word_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<CoachNoteWordLog> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('note_id')) {
      context.handle(
        _noteIdMeta,
        noteId.isAcceptableOrUnknown(data['note_id']!, _noteIdMeta),
      );
    } else if (isInserting) {
      context.missing(_noteIdMeta);
    }
    if (data.containsKey('word_log_id')) {
      context.handle(
        _wordLogIdMeta,
        wordLogId.isAcceptableOrUnknown(data['word_log_id']!, _wordLogIdMeta),
      );
    } else if (isInserting) {
      context.missing(_wordLogIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {noteId, wordLogId};
  @override
  CoachNoteWordLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CoachNoteWordLog(
      noteId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}note_id'],
      )!,
      wordLogId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}word_log_id'],
      )!,
    );
  }

  @override
  $CoachNoteWordLogsTable createAlias(String alias) {
    return $CoachNoteWordLogsTable(attachedDatabase, alias);
  }
}

class CoachNoteWordLog extends DataClass
    implements Insertable<CoachNoteWordLog> {
  final int noteId;
  final int wordLogId;
  const CoachNoteWordLog({required this.noteId, required this.wordLogId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['note_id'] = Variable<int>(noteId);
    map['word_log_id'] = Variable<int>(wordLogId);
    return map;
  }

  CoachNoteWordLogsCompanion toCompanion(bool nullToAbsent) {
    return CoachNoteWordLogsCompanion(
      noteId: Value(noteId),
      wordLogId: Value(wordLogId),
    );
  }

  factory CoachNoteWordLog.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CoachNoteWordLog(
      noteId: serializer.fromJson<int>(json['noteId']),
      wordLogId: serializer.fromJson<int>(json['wordLogId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'noteId': serializer.toJson<int>(noteId),
      'wordLogId': serializer.toJson<int>(wordLogId),
    };
  }

  CoachNoteWordLog copyWith({int? noteId, int? wordLogId}) => CoachNoteWordLog(
    noteId: noteId ?? this.noteId,
    wordLogId: wordLogId ?? this.wordLogId,
  );
  CoachNoteWordLog copyWithCompanion(CoachNoteWordLogsCompanion data) {
    return CoachNoteWordLog(
      noteId: data.noteId.present ? data.noteId.value : this.noteId,
      wordLogId: data.wordLogId.present ? data.wordLogId.value : this.wordLogId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CoachNoteWordLog(')
          ..write('noteId: $noteId, ')
          ..write('wordLogId: $wordLogId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(noteId, wordLogId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CoachNoteWordLog &&
          other.noteId == this.noteId &&
          other.wordLogId == this.wordLogId);
}

class CoachNoteWordLogsCompanion extends UpdateCompanion<CoachNoteWordLog> {
  final Value<int> noteId;
  final Value<int> wordLogId;
  final Value<int> rowid;
  const CoachNoteWordLogsCompanion({
    this.noteId = const Value.absent(),
    this.wordLogId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CoachNoteWordLogsCompanion.insert({
    required int noteId,
    required int wordLogId,
    this.rowid = const Value.absent(),
  }) : noteId = Value(noteId),
       wordLogId = Value(wordLogId);
  static Insertable<CoachNoteWordLog> custom({
    Expression<int>? noteId,
    Expression<int>? wordLogId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (noteId != null) 'note_id': noteId,
      if (wordLogId != null) 'word_log_id': wordLogId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CoachNoteWordLogsCompanion copyWith({
    Value<int>? noteId,
    Value<int>? wordLogId,
    Value<int>? rowid,
  }) {
    return CoachNoteWordLogsCompanion(
      noteId: noteId ?? this.noteId,
      wordLogId: wordLogId ?? this.wordLogId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (noteId.present) {
      map['note_id'] = Variable<int>(noteId.value);
    }
    if (wordLogId.present) {
      map['word_log_id'] = Variable<int>(wordLogId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CoachNoteWordLogsCompanion(')
          ..write('noteId: $noteId, ')
          ..write('wordLogId: $wordLogId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MetricsEventsTable extends MetricsEvents
    with TableInfo<$MetricsEventsTable, MetricsEvent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MetricsEventsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<int> value = GeneratedColumn<int>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recordedAtMeta = const VerificationMeta(
    'recordedAt',
  );
  @override
  late final GeneratedColumn<DateTime> recordedAt = GeneratedColumn<DateTime>(
    'recorded_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [id, kind, value, recordedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'metrics_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<MetricsEvent> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('recorded_at')) {
      context.handle(
        _recordedAtMeta,
        recordedAt.isAcceptableOrUnknown(data['recorded_at']!, _recordedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MetricsEvent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MetricsEvent(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}value'],
      )!,
      recordedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}recorded_at'],
      )!,
    );
  }

  @override
  $MetricsEventsTable createAlias(String alias) {
    return $MetricsEventsTable(attachedDatabase, alias);
  }
}

class MetricsEvent extends DataClass implements Insertable<MetricsEvent> {
  final int id;

  /// Which metric this increment belongs to (a metric_kind.dart name).
  final String kind;

  /// The delta recorded by this event (ms for lesson duration, count
  /// otherwise). Always non-negative; the recorder sums across a window.
  final int value;

  /// When the increment happened. Drives the daily/weekly/monthly buckets.
  final DateTime recordedAt;
  const MetricsEvent({
    required this.id,
    required this.kind,
    required this.value,
    required this.recordedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['kind'] = Variable<String>(kind);
    map['value'] = Variable<int>(value);
    map['recorded_at'] = Variable<DateTime>(recordedAt);
    return map;
  }

  MetricsEventsCompanion toCompanion(bool nullToAbsent) {
    return MetricsEventsCompanion(
      id: Value(id),
      kind: Value(kind),
      value: Value(value),
      recordedAt: Value(recordedAt),
    );
  }

  factory MetricsEvent.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MetricsEvent(
      id: serializer.fromJson<int>(json['id']),
      kind: serializer.fromJson<String>(json['kind']),
      value: serializer.fromJson<int>(json['value']),
      recordedAt: serializer.fromJson<DateTime>(json['recordedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'kind': serializer.toJson<String>(kind),
      'value': serializer.toJson<int>(value),
      'recordedAt': serializer.toJson<DateTime>(recordedAt),
    };
  }

  MetricsEvent copyWith({
    int? id,
    String? kind,
    int? value,
    DateTime? recordedAt,
  }) => MetricsEvent(
    id: id ?? this.id,
    kind: kind ?? this.kind,
    value: value ?? this.value,
    recordedAt: recordedAt ?? this.recordedAt,
  );
  MetricsEvent copyWithCompanion(MetricsEventsCompanion data) {
    return MetricsEvent(
      id: data.id.present ? data.id.value : this.id,
      kind: data.kind.present ? data.kind.value : this.kind,
      value: data.value.present ? data.value.value : this.value,
      recordedAt: data.recordedAt.present
          ? data.recordedAt.value
          : this.recordedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MetricsEvent(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('value: $value, ')
          ..write('recordedAt: $recordedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, kind, value, recordedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MetricsEvent &&
          other.id == this.id &&
          other.kind == this.kind &&
          other.value == this.value &&
          other.recordedAt == this.recordedAt);
}

class MetricsEventsCompanion extends UpdateCompanion<MetricsEvent> {
  final Value<int> id;
  final Value<String> kind;
  final Value<int> value;
  final Value<DateTime> recordedAt;
  const MetricsEventsCompanion({
    this.id = const Value.absent(),
    this.kind = const Value.absent(),
    this.value = const Value.absent(),
    this.recordedAt = const Value.absent(),
  });
  MetricsEventsCompanion.insert({
    this.id = const Value.absent(),
    required String kind,
    required int value,
    this.recordedAt = const Value.absent(),
  }) : kind = Value(kind),
       value = Value(value);
  static Insertable<MetricsEvent> custom({
    Expression<int>? id,
    Expression<String>? kind,
    Expression<int>? value,
    Expression<DateTime>? recordedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (kind != null) 'kind': kind,
      if (value != null) 'value': value,
      if (recordedAt != null) 'recorded_at': recordedAt,
    });
  }

  MetricsEventsCompanion copyWith({
    Value<int>? id,
    Value<String>? kind,
    Value<int>? value,
    Value<DateTime>? recordedAt,
  }) {
    return MetricsEventsCompanion(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      value: value ?? this.value,
      recordedAt: recordedAt ?? this.recordedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (value.present) {
      map['value'] = Variable<int>(value.value);
    }
    if (recordedAt.present) {
      map['recorded_at'] = Variable<DateTime>(recordedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MetricsEventsCompanion(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('value: $value, ')
          ..write('recordedAt: $recordedAt')
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
  late final $AiImageCacheItemsTable aiImageCacheItems =
      $AiImageCacheItemsTable(this);
  late final $TasksTable tasks = $TasksTable(this);
  late final $CoachNotesTable coachNotes = $CoachNotesTable(this);
  late final $CoachNoteRecordingsTable coachNoteRecordings =
      $CoachNoteRecordingsTable(this);
  late final $CoachNoteWordLogsTable coachNoteWordLogs =
      $CoachNoteWordLogsTable(this);
  late final $MetricsEventsTable metricsEvents = $MetricsEventsTable(this);
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
    aiImageCacheItems,
    tasks,
    coachNotes,
    coachNoteRecordings,
    coachNoteWordLogs,
    metricsEvents,
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
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'coach_notes',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('coach_note_recordings', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'recordings',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('coach_note_recordings', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'coach_notes',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('coach_note_word_logs', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'word_logs',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('coach_note_word_logs', kind: UpdateKind.delete)],
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

  static MultiTypedResultKey<
    $CoachNoteRecordingsTable,
    List<CoachNoteRecording>
  >
  _coachNoteRecordingsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.coachNoteRecordings,
        aliasName: 'recordings__id__coach_note_recordings__recording_id',
      );

  $$CoachNoteRecordingsTableProcessedTableManager get coachNoteRecordingsRefs {
    final manager = $$CoachNoteRecordingsTableTableManager(
      $_db,
      $_db.coachNoteRecordings,
    ).filter((f) => f.recordingId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _coachNoteRecordingsRefsTable($_db),
    );
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

  Expression<bool> coachNoteRecordingsRefs(
    Expression<bool> Function($$CoachNoteRecordingsTableFilterComposer f) f,
  ) {
    final $$CoachNoteRecordingsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.coachNoteRecordings,
      getReferencedColumn: (t) => t.recordingId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CoachNoteRecordingsTableFilterComposer(
            $db: $db,
            $table: $db.coachNoteRecordings,
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

  Expression<T> coachNoteRecordingsRefs<T extends Object>(
    Expression<T> Function($$CoachNoteRecordingsTableAnnotationComposer a) f,
  ) {
    final $$CoachNoteRecordingsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.coachNoteRecordings,
          getReferencedColumn: (t) => t.recordingId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$CoachNoteRecordingsTableAnnotationComposer(
                $db: $db,
                $table: $db.coachNoteRecordings,
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
          PrefetchHooks Function({
            bool reviewEventsRefs,
            bool wordLogsRefs,
            bool coachNoteRecordingsRefs,
          })
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
              ({
                reviewEventsRefs = false,
                wordLogsRefs = false,
                coachNoteRecordingsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (reviewEventsRefs) db.reviewEvents,
                    if (wordLogsRefs) db.wordLogs,
                    if (coachNoteRecordingsRefs) db.coachNoteRecordings,
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
                      if (coachNoteRecordingsRefs)
                        await $_getPrefetchedData<
                          Recording,
                          $RecordingsTable,
                          CoachNoteRecording
                        >(
                          currentTable: table,
                          referencedTable: $$RecordingsTableReferences
                              ._coachNoteRecordingsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$RecordingsTableReferences(
                                db,
                                table,
                                p0,
                              ).coachNoteRecordingsRefs,
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
      PrefetchHooks Function({
        bool reviewEventsRefs,
        bool wordLogsRefs,
        bool coachNoteRecordingsRefs,
      })
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

  static MultiTypedResultKey<$CoachNoteWordLogsTable, List<CoachNoteWordLog>>
  _coachNoteWordLogsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.coachNoteWordLogs,
        aliasName: 'word_logs__id__coach_note_word_logs__word_log_id',
      );

  $$CoachNoteWordLogsTableProcessedTableManager get coachNoteWordLogsRefs {
    final manager = $$CoachNoteWordLogsTableTableManager(
      $_db,
      $_db.coachNoteWordLogs,
    ).filter((f) => f.wordLogId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _coachNoteWordLogsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
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

  Expression<bool> coachNoteWordLogsRefs(
    Expression<bool> Function($$CoachNoteWordLogsTableFilterComposer f) f,
  ) {
    final $$CoachNoteWordLogsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.coachNoteWordLogs,
      getReferencedColumn: (t) => t.wordLogId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CoachNoteWordLogsTableFilterComposer(
            $db: $db,
            $table: $db.coachNoteWordLogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
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

  Expression<T> coachNoteWordLogsRefs<T extends Object>(
    Expression<T> Function($$CoachNoteWordLogsTableAnnotationComposer a) f,
  ) {
    final $$CoachNoteWordLogsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.coachNoteWordLogs,
          getReferencedColumn: (t) => t.wordLogId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$CoachNoteWordLogsTableAnnotationComposer(
                $db: $db,
                $table: $db.coachNoteWordLogs,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
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
          PrefetchHooks Function({bool recordingId, bool coachNoteWordLogsRefs})
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
          prefetchHooksCallback:
              ({recordingId = false, coachNoteWordLogsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (coachNoteWordLogsRefs) db.coachNoteWordLogs,
                  ],
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
                    return [
                      if (coachNoteWordLogsRefs)
                        await $_getPrefetchedData<
                          WordLog,
                          $WordLogsTable,
                          CoachNoteWordLog
                        >(
                          currentTable: table,
                          referencedTable: $$WordLogsTableReferences
                              ._coachNoteWordLogsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$WordLogsTableReferences(
                                db,
                                table,
                                p0,
                              ).coachNoteWordLogsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.wordLogId == item.id,
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
      PrefetchHooks Function({bool recordingId, bool coachNoteWordLogsRefs})
    >;
typedef $$AiImageCacheItemsTableCreateCompanionBuilder =
    AiImageCacheItemsCompanion Function({
      required String uzbekWord,
      required String relativePath,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });
typedef $$AiImageCacheItemsTableUpdateCompanionBuilder =
    AiImageCacheItemsCompanion Function({
      Value<String> uzbekWord,
      Value<String> relativePath,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$AiImageCacheItemsTableFilterComposer
    extends Composer<_$AppDatabase, $AiImageCacheItemsTable> {
  $$AiImageCacheItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get uzbekWord => $composableBuilder(
    column: $table.uzbekWord,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get relativePath => $composableBuilder(
    column: $table.relativePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AiImageCacheItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $AiImageCacheItemsTable> {
  $$AiImageCacheItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get uzbekWord => $composableBuilder(
    column: $table.uzbekWord,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get relativePath => $composableBuilder(
    column: $table.relativePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AiImageCacheItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AiImageCacheItemsTable> {
  $$AiImageCacheItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get uzbekWord =>
      $composableBuilder(column: $table.uzbekWord, builder: (column) => column);

  GeneratedColumn<String> get relativePath => $composableBuilder(
    column: $table.relativePath,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$AiImageCacheItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AiImageCacheItemsTable,
          AiImageCacheItem,
          $$AiImageCacheItemsTableFilterComposer,
          $$AiImageCacheItemsTableOrderingComposer,
          $$AiImageCacheItemsTableAnnotationComposer,
          $$AiImageCacheItemsTableCreateCompanionBuilder,
          $$AiImageCacheItemsTableUpdateCompanionBuilder,
          (
            AiImageCacheItem,
            BaseReferences<
              _$AppDatabase,
              $AiImageCacheItemsTable,
              AiImageCacheItem
            >,
          ),
          AiImageCacheItem,
          PrefetchHooks Function()
        > {
  $$AiImageCacheItemsTableTableManager(
    _$AppDatabase db,
    $AiImageCacheItemsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AiImageCacheItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AiImageCacheItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AiImageCacheItemsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> uzbekWord = const Value.absent(),
                Value<String> relativePath = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AiImageCacheItemsCompanion(
                uzbekWord: uzbekWord,
                relativePath: relativePath,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String uzbekWord,
                required String relativePath,
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AiImageCacheItemsCompanion.insert(
                uzbekWord: uzbekWord,
                relativePath: relativePath,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AiImageCacheItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AiImageCacheItemsTable,
      AiImageCacheItem,
      $$AiImageCacheItemsTableFilterComposer,
      $$AiImageCacheItemsTableOrderingComposer,
      $$AiImageCacheItemsTableAnnotationComposer,
      $$AiImageCacheItemsTableCreateCompanionBuilder,
      $$AiImageCacheItemsTableUpdateCompanionBuilder,
      (
        AiImageCacheItem,
        BaseReferences<
          _$AppDatabase,
          $AiImageCacheItemsTable,
          AiImageCacheItem
        >,
      ),
      AiImageCacheItem,
      PrefetchHooks Function()
    >;
typedef $$TasksTableCreateCompanionBuilder =
    TasksCompanion Function({
      Value<int> id,
      required String title,
      Value<String?> description,
      Value<DateTime?> dueDate,
      Value<bool> completed,
      Value<DateTime?> completedAt,
      Value<DateTime> createdAt,
    });
typedef $$TasksTableUpdateCompanionBuilder =
    TasksCompanion Function({
      Value<int> id,
      Value<String> title,
      Value<String?> description,
      Value<DateTime?> dueDate,
      Value<bool> completed,
      Value<DateTime?> completedAt,
      Value<DateTime> createdAt,
    });

class $$TasksTableFilterComposer extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableFilterComposer({
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

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get completed => $composableBuilder(
    column: $table.completed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TasksTableOrderingComposer
    extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableOrderingComposer({
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

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get completed => $composableBuilder(
    column: $table.completed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TasksTableAnnotationComposer
    extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get dueDate =>
      $composableBuilder(column: $table.dueDate, builder: (column) => column);

  GeneratedColumn<bool> get completed =>
      $composableBuilder(column: $table.completed, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$TasksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TasksTable,
          Task,
          $$TasksTableFilterComposer,
          $$TasksTableOrderingComposer,
          $$TasksTableAnnotationComposer,
          $$TasksTableCreateCompanionBuilder,
          $$TasksTableUpdateCompanionBuilder,
          (Task, BaseReferences<_$AppDatabase, $TasksTable, Task>),
          Task,
          PrefetchHooks Function()
        > {
  $$TasksTableTableManager(_$AppDatabase db, $TasksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TasksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TasksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TasksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<DateTime?> dueDate = const Value.absent(),
                Value<bool> completed = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => TasksCompanion(
                id: id,
                title: title,
                description: description,
                dueDate: dueDate,
                completed: completed,
                completedAt: completedAt,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String title,
                Value<String?> description = const Value.absent(),
                Value<DateTime?> dueDate = const Value.absent(),
                Value<bool> completed = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => TasksCompanion.insert(
                id: id,
                title: title,
                description: description,
                dueDate: dueDate,
                completed: completed,
                completedAt: completedAt,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TasksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TasksTable,
      Task,
      $$TasksTableFilterComposer,
      $$TasksTableOrderingComposer,
      $$TasksTableAnnotationComposer,
      $$TasksTableCreateCompanionBuilder,
      $$TasksTableUpdateCompanionBuilder,
      (Task, BaseReferences<_$AppDatabase, $TasksTable, Task>),
      Task,
      PrefetchHooks Function()
    >;
typedef $$CoachNotesTableCreateCompanionBuilder =
    CoachNotesCompanion Function({
      Value<int> id,
      required String title,
      Value<String?> body,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$CoachNotesTableUpdateCompanionBuilder =
    CoachNotesCompanion Function({
      Value<int> id,
      Value<String> title,
      Value<String?> body,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

final class $$CoachNotesTableReferences
    extends BaseReferences<_$AppDatabase, $CoachNotesTable, CoachNote> {
  $$CoachNotesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<
    $CoachNoteRecordingsTable,
    List<CoachNoteRecording>
  >
  _coachNoteRecordingsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.coachNoteRecordings,
        aliasName: 'coach_notes__id__coach_note_recordings__note_id',
      );

  $$CoachNoteRecordingsTableProcessedTableManager get coachNoteRecordingsRefs {
    final manager = $$CoachNoteRecordingsTableTableManager(
      $_db,
      $_db.coachNoteRecordings,
    ).filter((f) => f.noteId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _coachNoteRecordingsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$CoachNoteWordLogsTable, List<CoachNoteWordLog>>
  _coachNoteWordLogsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.coachNoteWordLogs,
        aliasName: 'coach_notes__id__coach_note_word_logs__note_id',
      );

  $$CoachNoteWordLogsTableProcessedTableManager get coachNoteWordLogsRefs {
    final manager = $$CoachNoteWordLogsTableTableManager(
      $_db,
      $_db.coachNoteWordLogs,
    ).filter((f) => f.noteId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _coachNoteWordLogsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CoachNotesTableFilterComposer
    extends Composer<_$AppDatabase, $CoachNotesTable> {
  $$CoachNotesTableFilterComposer({
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

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
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

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> coachNoteRecordingsRefs(
    Expression<bool> Function($$CoachNoteRecordingsTableFilterComposer f) f,
  ) {
    final $$CoachNoteRecordingsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.coachNoteRecordings,
      getReferencedColumn: (t) => t.noteId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CoachNoteRecordingsTableFilterComposer(
            $db: $db,
            $table: $db.coachNoteRecordings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> coachNoteWordLogsRefs(
    Expression<bool> Function($$CoachNoteWordLogsTableFilterComposer f) f,
  ) {
    final $$CoachNoteWordLogsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.coachNoteWordLogs,
      getReferencedColumn: (t) => t.noteId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CoachNoteWordLogsTableFilterComposer(
            $db: $db,
            $table: $db.coachNoteWordLogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CoachNotesTableOrderingComposer
    extends Composer<_$AppDatabase, $CoachNotesTable> {
  $$CoachNotesTableOrderingComposer({
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

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
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

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CoachNotesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CoachNotesTable> {
  $$CoachNotesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> coachNoteRecordingsRefs<T extends Object>(
    Expression<T> Function($$CoachNoteRecordingsTableAnnotationComposer a) f,
  ) {
    final $$CoachNoteRecordingsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.coachNoteRecordings,
          getReferencedColumn: (t) => t.noteId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$CoachNoteRecordingsTableAnnotationComposer(
                $db: $db,
                $table: $db.coachNoteRecordings,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> coachNoteWordLogsRefs<T extends Object>(
    Expression<T> Function($$CoachNoteWordLogsTableAnnotationComposer a) f,
  ) {
    final $$CoachNoteWordLogsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.coachNoteWordLogs,
          getReferencedColumn: (t) => t.noteId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$CoachNoteWordLogsTableAnnotationComposer(
                $db: $db,
                $table: $db.coachNoteWordLogs,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$CoachNotesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CoachNotesTable,
          CoachNote,
          $$CoachNotesTableFilterComposer,
          $$CoachNotesTableOrderingComposer,
          $$CoachNotesTableAnnotationComposer,
          $$CoachNotesTableCreateCompanionBuilder,
          $$CoachNotesTableUpdateCompanionBuilder,
          (CoachNote, $$CoachNotesTableReferences),
          CoachNote,
          PrefetchHooks Function({
            bool coachNoteRecordingsRefs,
            bool coachNoteWordLogsRefs,
          })
        > {
  $$CoachNotesTableTableManager(_$AppDatabase db, $CoachNotesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CoachNotesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CoachNotesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CoachNotesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> body = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => CoachNotesCompanion(
                id: id,
                title: title,
                body: body,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String title,
                Value<String?> body = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => CoachNotesCompanion.insert(
                id: id,
                title: title,
                body: body,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CoachNotesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                coachNoteRecordingsRefs = false,
                coachNoteWordLogsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (coachNoteRecordingsRefs) db.coachNoteRecordings,
                    if (coachNoteWordLogsRefs) db.coachNoteWordLogs,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (coachNoteRecordingsRefs)
                        await $_getPrefetchedData<
                          CoachNote,
                          $CoachNotesTable,
                          CoachNoteRecording
                        >(
                          currentTable: table,
                          referencedTable: $$CoachNotesTableReferences
                              ._coachNoteRecordingsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CoachNotesTableReferences(
                                db,
                                table,
                                p0,
                              ).coachNoteRecordingsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.noteId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (coachNoteWordLogsRefs)
                        await $_getPrefetchedData<
                          CoachNote,
                          $CoachNotesTable,
                          CoachNoteWordLog
                        >(
                          currentTable: table,
                          referencedTable: $$CoachNotesTableReferences
                              ._coachNoteWordLogsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CoachNotesTableReferences(
                                db,
                                table,
                                p0,
                              ).coachNoteWordLogsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.noteId == item.id,
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

typedef $$CoachNotesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CoachNotesTable,
      CoachNote,
      $$CoachNotesTableFilterComposer,
      $$CoachNotesTableOrderingComposer,
      $$CoachNotesTableAnnotationComposer,
      $$CoachNotesTableCreateCompanionBuilder,
      $$CoachNotesTableUpdateCompanionBuilder,
      (CoachNote, $$CoachNotesTableReferences),
      CoachNote,
      PrefetchHooks Function({
        bool coachNoteRecordingsRefs,
        bool coachNoteWordLogsRefs,
      })
    >;
typedef $$CoachNoteRecordingsTableCreateCompanionBuilder =
    CoachNoteRecordingsCompanion Function({
      required int noteId,
      required int recordingId,
      Value<int> rowid,
    });
typedef $$CoachNoteRecordingsTableUpdateCompanionBuilder =
    CoachNoteRecordingsCompanion Function({
      Value<int> noteId,
      Value<int> recordingId,
      Value<int> rowid,
    });

final class $$CoachNoteRecordingsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $CoachNoteRecordingsTable,
          CoachNoteRecording
        > {
  $$CoachNoteRecordingsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $CoachNotesTable _noteIdTable(_$AppDatabase db) => db.coachNotes
      .createAlias('coach_note_recordings__note_id__coach_notes__id');

  $$CoachNotesTableProcessedTableManager get noteId {
    final $_column = $_itemColumn<int>('note_id')!;

    final manager = $$CoachNotesTableTableManager(
      $_db,
      $_db.coachNotes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_noteIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $RecordingsTable _recordingIdTable(_$AppDatabase db) => db.recordings
      .createAlias('coach_note_recordings__recording_id__recordings__id');

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

class $$CoachNoteRecordingsTableFilterComposer
    extends Composer<_$AppDatabase, $CoachNoteRecordingsTable> {
  $$CoachNoteRecordingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$CoachNotesTableFilterComposer get noteId {
    final $$CoachNotesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.noteId,
      referencedTable: $db.coachNotes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CoachNotesTableFilterComposer(
            $db: $db,
            $table: $db.coachNotes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

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

class $$CoachNoteRecordingsTableOrderingComposer
    extends Composer<_$AppDatabase, $CoachNoteRecordingsTable> {
  $$CoachNoteRecordingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$CoachNotesTableOrderingComposer get noteId {
    final $$CoachNotesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.noteId,
      referencedTable: $db.coachNotes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CoachNotesTableOrderingComposer(
            $db: $db,
            $table: $db.coachNotes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

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

class $$CoachNoteRecordingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CoachNoteRecordingsTable> {
  $$CoachNoteRecordingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$CoachNotesTableAnnotationComposer get noteId {
    final $$CoachNotesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.noteId,
      referencedTable: $db.coachNotes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CoachNotesTableAnnotationComposer(
            $db: $db,
            $table: $db.coachNotes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

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

class $$CoachNoteRecordingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CoachNoteRecordingsTable,
          CoachNoteRecording,
          $$CoachNoteRecordingsTableFilterComposer,
          $$CoachNoteRecordingsTableOrderingComposer,
          $$CoachNoteRecordingsTableAnnotationComposer,
          $$CoachNoteRecordingsTableCreateCompanionBuilder,
          $$CoachNoteRecordingsTableUpdateCompanionBuilder,
          (CoachNoteRecording, $$CoachNoteRecordingsTableReferences),
          CoachNoteRecording,
          PrefetchHooks Function({bool noteId, bool recordingId})
        > {
  $$CoachNoteRecordingsTableTableManager(
    _$AppDatabase db,
    $CoachNoteRecordingsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CoachNoteRecordingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CoachNoteRecordingsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$CoachNoteRecordingsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> noteId = const Value.absent(),
                Value<int> recordingId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CoachNoteRecordingsCompanion(
                noteId: noteId,
                recordingId: recordingId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int noteId,
                required int recordingId,
                Value<int> rowid = const Value.absent(),
              }) => CoachNoteRecordingsCompanion.insert(
                noteId: noteId,
                recordingId: recordingId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CoachNoteRecordingsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({noteId = false, recordingId = false}) {
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
                    if (noteId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.noteId,
                                referencedTable:
                                    $$CoachNoteRecordingsTableReferences
                                        ._noteIdTable(db),
                                referencedColumn:
                                    $$CoachNoteRecordingsTableReferences
                                        ._noteIdTable(db)
                                        .id,
                              )
                              as T;
                    }
                    if (recordingId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.recordingId,
                                referencedTable:
                                    $$CoachNoteRecordingsTableReferences
                                        ._recordingIdTable(db),
                                referencedColumn:
                                    $$CoachNoteRecordingsTableReferences
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

typedef $$CoachNoteRecordingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CoachNoteRecordingsTable,
      CoachNoteRecording,
      $$CoachNoteRecordingsTableFilterComposer,
      $$CoachNoteRecordingsTableOrderingComposer,
      $$CoachNoteRecordingsTableAnnotationComposer,
      $$CoachNoteRecordingsTableCreateCompanionBuilder,
      $$CoachNoteRecordingsTableUpdateCompanionBuilder,
      (CoachNoteRecording, $$CoachNoteRecordingsTableReferences),
      CoachNoteRecording,
      PrefetchHooks Function({bool noteId, bool recordingId})
    >;
typedef $$CoachNoteWordLogsTableCreateCompanionBuilder =
    CoachNoteWordLogsCompanion Function({
      required int noteId,
      required int wordLogId,
      Value<int> rowid,
    });
typedef $$CoachNoteWordLogsTableUpdateCompanionBuilder =
    CoachNoteWordLogsCompanion Function({
      Value<int> noteId,
      Value<int> wordLogId,
      Value<int> rowid,
    });

final class $$CoachNoteWordLogsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $CoachNoteWordLogsTable,
          CoachNoteWordLog
        > {
  $$CoachNoteWordLogsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $CoachNotesTable _noteIdTable(_$AppDatabase db) => db.coachNotes
      .createAlias('coach_note_word_logs__note_id__coach_notes__id');

  $$CoachNotesTableProcessedTableManager get noteId {
    final $_column = $_itemColumn<int>('note_id')!;

    final manager = $$CoachNotesTableTableManager(
      $_db,
      $_db.coachNotes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_noteIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $WordLogsTable _wordLogIdTable(_$AppDatabase db) => db.wordLogs
      .createAlias('coach_note_word_logs__word_log_id__word_logs__id');

  $$WordLogsTableProcessedTableManager get wordLogId {
    final $_column = $_itemColumn<int>('word_log_id')!;

    final manager = $$WordLogsTableTableManager(
      $_db,
      $_db.wordLogs,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_wordLogIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CoachNoteWordLogsTableFilterComposer
    extends Composer<_$AppDatabase, $CoachNoteWordLogsTable> {
  $$CoachNoteWordLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$CoachNotesTableFilterComposer get noteId {
    final $$CoachNotesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.noteId,
      referencedTable: $db.coachNotes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CoachNotesTableFilterComposer(
            $db: $db,
            $table: $db.coachNotes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$WordLogsTableFilterComposer get wordLogId {
    final $$WordLogsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.wordLogId,
      referencedTable: $db.wordLogs,
      getReferencedColumn: (t) => t.id,
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
    return composer;
  }
}

class $$CoachNoteWordLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $CoachNoteWordLogsTable> {
  $$CoachNoteWordLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$CoachNotesTableOrderingComposer get noteId {
    final $$CoachNotesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.noteId,
      referencedTable: $db.coachNotes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CoachNotesTableOrderingComposer(
            $db: $db,
            $table: $db.coachNotes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$WordLogsTableOrderingComposer get wordLogId {
    final $$WordLogsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.wordLogId,
      referencedTable: $db.wordLogs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WordLogsTableOrderingComposer(
            $db: $db,
            $table: $db.wordLogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CoachNoteWordLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CoachNoteWordLogsTable> {
  $$CoachNoteWordLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$CoachNotesTableAnnotationComposer get noteId {
    final $$CoachNotesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.noteId,
      referencedTable: $db.coachNotes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CoachNotesTableAnnotationComposer(
            $db: $db,
            $table: $db.coachNotes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$WordLogsTableAnnotationComposer get wordLogId {
    final $$WordLogsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.wordLogId,
      referencedTable: $db.wordLogs,
      getReferencedColumn: (t) => t.id,
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
    return composer;
  }
}

class $$CoachNoteWordLogsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CoachNoteWordLogsTable,
          CoachNoteWordLog,
          $$CoachNoteWordLogsTableFilterComposer,
          $$CoachNoteWordLogsTableOrderingComposer,
          $$CoachNoteWordLogsTableAnnotationComposer,
          $$CoachNoteWordLogsTableCreateCompanionBuilder,
          $$CoachNoteWordLogsTableUpdateCompanionBuilder,
          (CoachNoteWordLog, $$CoachNoteWordLogsTableReferences),
          CoachNoteWordLog,
          PrefetchHooks Function({bool noteId, bool wordLogId})
        > {
  $$CoachNoteWordLogsTableTableManager(
    _$AppDatabase db,
    $CoachNoteWordLogsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CoachNoteWordLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CoachNoteWordLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CoachNoteWordLogsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> noteId = const Value.absent(),
                Value<int> wordLogId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CoachNoteWordLogsCompanion(
                noteId: noteId,
                wordLogId: wordLogId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int noteId,
                required int wordLogId,
                Value<int> rowid = const Value.absent(),
              }) => CoachNoteWordLogsCompanion.insert(
                noteId: noteId,
                wordLogId: wordLogId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CoachNoteWordLogsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({noteId = false, wordLogId = false}) {
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
                    if (noteId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.noteId,
                                referencedTable:
                                    $$CoachNoteWordLogsTableReferences
                                        ._noteIdTable(db),
                                referencedColumn:
                                    $$CoachNoteWordLogsTableReferences
                                        ._noteIdTable(db)
                                        .id,
                              )
                              as T;
                    }
                    if (wordLogId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.wordLogId,
                                referencedTable:
                                    $$CoachNoteWordLogsTableReferences
                                        ._wordLogIdTable(db),
                                referencedColumn:
                                    $$CoachNoteWordLogsTableReferences
                                        ._wordLogIdTable(db)
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

typedef $$CoachNoteWordLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CoachNoteWordLogsTable,
      CoachNoteWordLog,
      $$CoachNoteWordLogsTableFilterComposer,
      $$CoachNoteWordLogsTableOrderingComposer,
      $$CoachNoteWordLogsTableAnnotationComposer,
      $$CoachNoteWordLogsTableCreateCompanionBuilder,
      $$CoachNoteWordLogsTableUpdateCompanionBuilder,
      (CoachNoteWordLog, $$CoachNoteWordLogsTableReferences),
      CoachNoteWordLog,
      PrefetchHooks Function({bool noteId, bool wordLogId})
    >;
typedef $$MetricsEventsTableCreateCompanionBuilder =
    MetricsEventsCompanion Function({
      Value<int> id,
      required String kind,
      required int value,
      Value<DateTime> recordedAt,
    });
typedef $$MetricsEventsTableUpdateCompanionBuilder =
    MetricsEventsCompanion Function({
      Value<int> id,
      Value<String> kind,
      Value<int> value,
      Value<DateTime> recordedAt,
    });

class $$MetricsEventsTableFilterComposer
    extends Composer<_$AppDatabase, $MetricsEventsTable> {
  $$MetricsEventsTableFilterComposer({
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

  ColumnFilters<int> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MetricsEventsTableOrderingComposer
    extends Composer<_$AppDatabase, $MetricsEventsTable> {
  $$MetricsEventsTableOrderingComposer({
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

  ColumnOrderings<int> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MetricsEventsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MetricsEventsTable> {
  $$MetricsEventsTableAnnotationComposer({
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

  GeneratedColumn<int> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => column,
  );
}

class $$MetricsEventsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MetricsEventsTable,
          MetricsEvent,
          $$MetricsEventsTableFilterComposer,
          $$MetricsEventsTableOrderingComposer,
          $$MetricsEventsTableAnnotationComposer,
          $$MetricsEventsTableCreateCompanionBuilder,
          $$MetricsEventsTableUpdateCompanionBuilder,
          (
            MetricsEvent,
            BaseReferences<_$AppDatabase, $MetricsEventsTable, MetricsEvent>,
          ),
          MetricsEvent,
          PrefetchHooks Function()
        > {
  $$MetricsEventsTableTableManager(_$AppDatabase db, $MetricsEventsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MetricsEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MetricsEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MetricsEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<int> value = const Value.absent(),
                Value<DateTime> recordedAt = const Value.absent(),
              }) => MetricsEventsCompanion(
                id: id,
                kind: kind,
                value: value,
                recordedAt: recordedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String kind,
                required int value,
                Value<DateTime> recordedAt = const Value.absent(),
              }) => MetricsEventsCompanion.insert(
                id: id,
                kind: kind,
                value: value,
                recordedAt: recordedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MetricsEventsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MetricsEventsTable,
      MetricsEvent,
      $$MetricsEventsTableFilterComposer,
      $$MetricsEventsTableOrderingComposer,
      $$MetricsEventsTableAnnotationComposer,
      $$MetricsEventsTableCreateCompanionBuilder,
      $$MetricsEventsTableUpdateCompanionBuilder,
      (
        MetricsEvent,
        BaseReferences<_$AppDatabase, $MetricsEventsTable, MetricsEvent>,
      ),
      MetricsEvent,
      PrefetchHooks Function()
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
  $$AiImageCacheItemsTableTableManager get aiImageCacheItems =>
      $$AiImageCacheItemsTableTableManager(_db, _db.aiImageCacheItems);
  $$TasksTableTableManager get tasks =>
      $$TasksTableTableManager(_db, _db.tasks);
  $$CoachNotesTableTableManager get coachNotes =>
      $$CoachNotesTableTableManager(_db, _db.coachNotes);
  $$CoachNoteRecordingsTableTableManager get coachNoteRecordings =>
      $$CoachNoteRecordingsTableTableManager(_db, _db.coachNoteRecordings);
  $$CoachNoteWordLogsTableTableManager get coachNoteWordLogs =>
      $$CoachNoteWordLogsTableTableManager(_db, _db.coachNoteWordLogs);
  $$MetricsEventsTableTableManager get metricsEvents =>
      $$MetricsEventsTableTableManager(_db, _db.metricsEvents);
}
