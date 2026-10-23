// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $TasksTable extends Tasks with TableInfo<$TasksTable, TaskRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TasksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<int> color = GeneratedColumn<int>(
    'color',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tagMeta = const VerificationMeta('tag');
  @override
  late final GeneratedColumn<String> tag = GeneratedColumn<String>(
    'tag',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _priorityMeta = const VerificationMeta(
    'priority',
  );
  @override
  late final GeneratedColumn<int> priority = GeneratedColumn<int>(
    'priority',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _allDayMeta = const VerificationMeta('allDay');
  @override
  late final GeneratedColumn<bool> allDay = GeneratedColumn<bool>(
    'all_day',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("all_day" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _startDateMeta = const VerificationMeta(
    'startDate',
  );
  @override
  late final GeneratedColumn<String> startDate = GeneratedColumn<String>(
    'start_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startMinuteMeta = const VerificationMeta(
    'startMinute',
  );
  @override
  late final GeneratedColumn<int> startMinute = GeneratedColumn<int>(
    'start_minute',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _durationMinMeta = const VerificationMeta(
    'durationMin',
  );
  @override
  late final GeneratedColumn<int> durationMin = GeneratedColumn<int>(
    'duration_min',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _repeatKindMeta = const VerificationMeta(
    'repeatKind',
  );
  @override
  late final GeneratedColumn<String> repeatKind = GeneratedColumn<String>(
    'repeat_kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('none'),
  );
  static const VerificationMeta _rruleMeta = const VerificationMeta('rrule');
  @override
  late final GeneratedColumn<String> rrule = GeneratedColumn<String>(
    'rrule',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _quotaPerWeekMeta = const VerificationMeta(
    'quotaPerWeek',
  );
  @override
  late final GeneratedColumn<int> quotaPerWeek = GeneratedColumn<int>(
    'quota_per_week',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _quotaPreferredDaysMeta =
      const VerificationMeta('quotaPreferredDays');
  @override
  late final GeneratedColumn<String> quotaPreferredDays =
      GeneratedColumn<String>(
        'quota_preferred_days',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _endsOnMeta = const VerificationMeta('endsOn');
  @override
  late final GeneratedColumn<String> endsOn = GeneratedColumn<String>(
    'ends_on',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _endsAfterCountMeta = const VerificationMeta(
    'endsAfterCount',
  );
  @override
  late final GeneratedColumn<int> endsAfterCount = GeneratedColumn<int>(
    'ends_after_count',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _seriesIdMeta = const VerificationMeta(
    'seriesId',
  );
  @override
  late final GeneratedColumn<String> seriesId = GeneratedColumn<String>(
    'series_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timeZoneMeta = const VerificationMeta(
    'timeZone',
  );
  @override
  late final GeneratedColumn<String> timeZone = GeneratedColumn<String>(
    'time_zone',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    notes,
    color,
    tag,
    priority,
    allDay,
    startDate,
    startMinute,
    durationMin,
    repeatKind,
    rrule,
    quotaPerWeek,
    quotaPreferredDays,
    endsOn,
    endsAfterCount,
    seriesId,
    timeZone,
    createdAt,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tasks';
  @override
  VerificationContext validateIntegrity(
    Insertable<TaskRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    } else if (isInserting) {
      context.missing(_colorMeta);
    }
    if (data.containsKey('tag')) {
      context.handle(
        _tagMeta,
        tag.isAcceptableOrUnknown(data['tag']!, _tagMeta),
      );
    }
    if (data.containsKey('priority')) {
      context.handle(
        _priorityMeta,
        priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta),
      );
    }
    if (data.containsKey('all_day')) {
      context.handle(
        _allDayMeta,
        allDay.isAcceptableOrUnknown(data['all_day']!, _allDayMeta),
      );
    }
    if (data.containsKey('start_date')) {
      context.handle(
        _startDateMeta,
        startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta),
      );
    } else if (isInserting) {
      context.missing(_startDateMeta);
    }
    if (data.containsKey('start_minute')) {
      context.handle(
        _startMinuteMeta,
        startMinute.isAcceptableOrUnknown(
          data['start_minute']!,
          _startMinuteMeta,
        ),
      );
    }
    if (data.containsKey('duration_min')) {
      context.handle(
        _durationMinMeta,
        durationMin.isAcceptableOrUnknown(
          data['duration_min']!,
          _durationMinMeta,
        ),
      );
    }
    if (data.containsKey('repeat_kind')) {
      context.handle(
        _repeatKindMeta,
        repeatKind.isAcceptableOrUnknown(data['repeat_kind']!, _repeatKindMeta),
      );
    }
    if (data.containsKey('rrule')) {
      context.handle(
        _rruleMeta,
        rrule.isAcceptableOrUnknown(data['rrule']!, _rruleMeta),
      );
    }
    if (data.containsKey('quota_per_week')) {
      context.handle(
        _quotaPerWeekMeta,
        quotaPerWeek.isAcceptableOrUnknown(
          data['quota_per_week']!,
          _quotaPerWeekMeta,
        ),
      );
    }
    if (data.containsKey('quota_preferred_days')) {
      context.handle(
        _quotaPreferredDaysMeta,
        quotaPreferredDays.isAcceptableOrUnknown(
          data['quota_preferred_days']!,
          _quotaPreferredDaysMeta,
        ),
      );
    }
    if (data.containsKey('ends_on')) {
      context.handle(
        _endsOnMeta,
        endsOn.isAcceptableOrUnknown(data['ends_on']!, _endsOnMeta),
      );
    }
    if (data.containsKey('ends_after_count')) {
      context.handle(
        _endsAfterCountMeta,
        endsAfterCount.isAcceptableOrUnknown(
          data['ends_after_count']!,
          _endsAfterCountMeta,
        ),
      );
    }
    if (data.containsKey('series_id')) {
      context.handle(
        _seriesIdMeta,
        seriesId.isAcceptableOrUnknown(data['series_id']!, _seriesIdMeta),
      );
    } else if (isInserting) {
      context.missing(_seriesIdMeta);
    }
    if (data.containsKey('time_zone')) {
      context.handle(
        _timeZoneMeta,
        timeZone.isAcceptableOrUnknown(data['time_zone']!, _timeZoneMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TaskRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TaskRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color'],
      )!,
      tag: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tag'],
      ),
      priority: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}priority'],
      )!,
      allDay: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}all_day'],
      )!,
      startDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}start_date'],
      )!,
      startMinute: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_minute'],
      ),
      durationMin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_min'],
      ),
      repeatKind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}repeat_kind'],
      )!,
      rrule: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rrule'],
      ),
      quotaPerWeek: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quota_per_week'],
      ),
      quotaPreferredDays: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}quota_preferred_days'],
      ),
      endsOn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ends_on'],
      ),
      endsAfterCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ends_after_count'],
      ),
      seriesId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}series_id'],
      )!,
      timeZone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}time_zone'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $TasksTable createAlias(String alias) {
    return $TasksTable(attachedDatabase, alias);
  }
}

class TaskRow extends DataClass implements Insertable<TaskRow> {
  final String id;
  final String title;
  final String? notes;
  final int color;
  final String? tag;
  final int priority;
  final bool allDay;
  final String startDate;
  final int? startMinute;
  final int? durationMin;
  final String repeatKind;
  final String? rrule;
  final int? quotaPerWeek;
  final String? quotaPreferredDays;
  final String? endsOn;
  final int? endsAfterCount;
  final String seriesId;
  final String? timeZone;
  final int createdAt;
  final int updatedAt;
  final int? deletedAt;
  const TaskRow({
    required this.id,
    required this.title,
    this.notes,
    required this.color,
    this.tag,
    required this.priority,
    required this.allDay,
    required this.startDate,
    this.startMinute,
    this.durationMin,
    required this.repeatKind,
    this.rrule,
    this.quotaPerWeek,
    this.quotaPreferredDays,
    this.endsOn,
    this.endsAfterCount,
    required this.seriesId,
    this.timeZone,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['color'] = Variable<int>(color);
    if (!nullToAbsent || tag != null) {
      map['tag'] = Variable<String>(tag);
    }
    map['priority'] = Variable<int>(priority);
    map['all_day'] = Variable<bool>(allDay);
    map['start_date'] = Variable<String>(startDate);
    if (!nullToAbsent || startMinute != null) {
      map['start_minute'] = Variable<int>(startMinute);
    }
    if (!nullToAbsent || durationMin != null) {
      map['duration_min'] = Variable<int>(durationMin);
    }
    map['repeat_kind'] = Variable<String>(repeatKind);
    if (!nullToAbsent || rrule != null) {
      map['rrule'] = Variable<String>(rrule);
    }
    if (!nullToAbsent || quotaPerWeek != null) {
      map['quota_per_week'] = Variable<int>(quotaPerWeek);
    }
    if (!nullToAbsent || quotaPreferredDays != null) {
      map['quota_preferred_days'] = Variable<String>(quotaPreferredDays);
    }
    if (!nullToAbsent || endsOn != null) {
      map['ends_on'] = Variable<String>(endsOn);
    }
    if (!nullToAbsent || endsAfterCount != null) {
      map['ends_after_count'] = Variable<int>(endsAfterCount);
    }
    map['series_id'] = Variable<String>(seriesId);
    if (!nullToAbsent || timeZone != null) {
      map['time_zone'] = Variable<String>(timeZone);
    }
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    return map;
  }

  TasksCompanion toCompanion(bool nullToAbsent) {
    return TasksCompanion(
      id: Value(id),
      title: Value(title),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      color: Value(color),
      tag: tag == null && nullToAbsent ? const Value.absent() : Value(tag),
      priority: Value(priority),
      allDay: Value(allDay),
      startDate: Value(startDate),
      startMinute: startMinute == null && nullToAbsent
          ? const Value.absent()
          : Value(startMinute),
      durationMin: durationMin == null && nullToAbsent
          ? const Value.absent()
          : Value(durationMin),
      repeatKind: Value(repeatKind),
      rrule: rrule == null && nullToAbsent
          ? const Value.absent()
          : Value(rrule),
      quotaPerWeek: quotaPerWeek == null && nullToAbsent
          ? const Value.absent()
          : Value(quotaPerWeek),
      quotaPreferredDays: quotaPreferredDays == null && nullToAbsent
          ? const Value.absent()
          : Value(quotaPreferredDays),
      endsOn: endsOn == null && nullToAbsent
          ? const Value.absent()
          : Value(endsOn),
      endsAfterCount: endsAfterCount == null && nullToAbsent
          ? const Value.absent()
          : Value(endsAfterCount),
      seriesId: Value(seriesId),
      timeZone: timeZone == null && nullToAbsent
          ? const Value.absent()
          : Value(timeZone),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory TaskRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TaskRow(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      notes: serializer.fromJson<String?>(json['notes']),
      color: serializer.fromJson<int>(json['color']),
      tag: serializer.fromJson<String?>(json['tag']),
      priority: serializer.fromJson<int>(json['priority']),
      allDay: serializer.fromJson<bool>(json['allDay']),
      startDate: serializer.fromJson<String>(json['startDate']),
      startMinute: serializer.fromJson<int?>(json['startMinute']),
      durationMin: serializer.fromJson<int?>(json['durationMin']),
      repeatKind: serializer.fromJson<String>(json['repeatKind']),
      rrule: serializer.fromJson<String?>(json['rrule']),
      quotaPerWeek: serializer.fromJson<int?>(json['quotaPerWeek']),
      quotaPreferredDays: serializer.fromJson<String?>(
        json['quotaPreferredDays'],
      ),
      endsOn: serializer.fromJson<String?>(json['endsOn']),
      endsAfterCount: serializer.fromJson<int?>(json['endsAfterCount']),
      seriesId: serializer.fromJson<String>(json['seriesId']),
      timeZone: serializer.fromJson<String?>(json['timeZone']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'notes': serializer.toJson<String?>(notes),
      'color': serializer.toJson<int>(color),
      'tag': serializer.toJson<String?>(tag),
      'priority': serializer.toJson<int>(priority),
      'allDay': serializer.toJson<bool>(allDay),
      'startDate': serializer.toJson<String>(startDate),
      'startMinute': serializer.toJson<int?>(startMinute),
      'durationMin': serializer.toJson<int?>(durationMin),
      'repeatKind': serializer.toJson<String>(repeatKind),
      'rrule': serializer.toJson<String?>(rrule),
      'quotaPerWeek': serializer.toJson<int?>(quotaPerWeek),
      'quotaPreferredDays': serializer.toJson<String?>(quotaPreferredDays),
      'endsOn': serializer.toJson<String?>(endsOn),
      'endsAfterCount': serializer.toJson<int?>(endsAfterCount),
      'seriesId': serializer.toJson<String>(seriesId),
      'timeZone': serializer.toJson<String?>(timeZone),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
    };
  }

  TaskRow copyWith({
    String? id,
    String? title,
    Value<String?> notes = const Value.absent(),
    int? color,
    Value<String?> tag = const Value.absent(),
    int? priority,
    bool? allDay,
    String? startDate,
    Value<int?> startMinute = const Value.absent(),
    Value<int?> durationMin = const Value.absent(),
    String? repeatKind,
    Value<String?> rrule = const Value.absent(),
    Value<int?> quotaPerWeek = const Value.absent(),
    Value<String?> quotaPreferredDays = const Value.absent(),
    Value<String?> endsOn = const Value.absent(),
    Value<int?> endsAfterCount = const Value.absent(),
    String? seriesId,
    Value<String?> timeZone = const Value.absent(),
    int? createdAt,
    int? updatedAt,
    Value<int?> deletedAt = const Value.absent(),
  }) => TaskRow(
    id: id ?? this.id,
    title: title ?? this.title,
    notes: notes.present ? notes.value : this.notes,
    color: color ?? this.color,
    tag: tag.present ? tag.value : this.tag,
    priority: priority ?? this.priority,
    allDay: allDay ?? this.allDay,
    startDate: startDate ?? this.startDate,
    startMinute: startMinute.present ? startMinute.value : this.startMinute,
    durationMin: durationMin.present ? durationMin.value : this.durationMin,
    repeatKind: repeatKind ?? this.repeatKind,
    rrule: rrule.present ? rrule.value : this.rrule,
    quotaPerWeek: quotaPerWeek.present ? quotaPerWeek.value : this.quotaPerWeek,
    quotaPreferredDays: quotaPreferredDays.present
        ? quotaPreferredDays.value
        : this.quotaPreferredDays,
    endsOn: endsOn.present ? endsOn.value : this.endsOn,
    endsAfterCount: endsAfterCount.present
        ? endsAfterCount.value
        : this.endsAfterCount,
    seriesId: seriesId ?? this.seriesId,
    timeZone: timeZone.present ? timeZone.value : this.timeZone,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  TaskRow copyWithCompanion(TasksCompanion data) {
    return TaskRow(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      notes: data.notes.present ? data.notes.value : this.notes,
      color: data.color.present ? data.color.value : this.color,
      tag: data.tag.present ? data.tag.value : this.tag,
      priority: data.priority.present ? data.priority.value : this.priority,
      allDay: data.allDay.present ? data.allDay.value : this.allDay,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      startMinute: data.startMinute.present
          ? data.startMinute.value
          : this.startMinute,
      durationMin: data.durationMin.present
          ? data.durationMin.value
          : this.durationMin,
      repeatKind: data.repeatKind.present
          ? data.repeatKind.value
          : this.repeatKind,
      rrule: data.rrule.present ? data.rrule.value : this.rrule,
      quotaPerWeek: data.quotaPerWeek.present
          ? data.quotaPerWeek.value
          : this.quotaPerWeek,
      quotaPreferredDays: data.quotaPreferredDays.present
          ? data.quotaPreferredDays.value
          : this.quotaPreferredDays,
      endsOn: data.endsOn.present ? data.endsOn.value : this.endsOn,
      endsAfterCount: data.endsAfterCount.present
          ? data.endsAfterCount.value
          : this.endsAfterCount,
      seriesId: data.seriesId.present ? data.seriesId.value : this.seriesId,
      timeZone: data.timeZone.present ? data.timeZone.value : this.timeZone,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TaskRow(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('notes: $notes, ')
          ..write('color: $color, ')
          ..write('tag: $tag, ')
          ..write('priority: $priority, ')
          ..write('allDay: $allDay, ')
          ..write('startDate: $startDate, ')
          ..write('startMinute: $startMinute, ')
          ..write('durationMin: $durationMin, ')
          ..write('repeatKind: $repeatKind, ')
          ..write('rrule: $rrule, ')
          ..write('quotaPerWeek: $quotaPerWeek, ')
          ..write('quotaPreferredDays: $quotaPreferredDays, ')
          ..write('endsOn: $endsOn, ')
          ..write('endsAfterCount: $endsAfterCount, ')
          ..write('seriesId: $seriesId, ')
          ..write('timeZone: $timeZone, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    title,
    notes,
    color,
    tag,
    priority,
    allDay,
    startDate,
    startMinute,
    durationMin,
    repeatKind,
    rrule,
    quotaPerWeek,
    quotaPreferredDays,
    endsOn,
    endsAfterCount,
    seriesId,
    timeZone,
    createdAt,
    updatedAt,
    deletedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TaskRow &&
          other.id == this.id &&
          other.title == this.title &&
          other.notes == this.notes &&
          other.color == this.color &&
          other.tag == this.tag &&
          other.priority == this.priority &&
          other.allDay == this.allDay &&
          other.startDate == this.startDate &&
          other.startMinute == this.startMinute &&
          other.durationMin == this.durationMin &&
          other.repeatKind == this.repeatKind &&
          other.rrule == this.rrule &&
          other.quotaPerWeek == this.quotaPerWeek &&
          other.quotaPreferredDays == this.quotaPreferredDays &&
          other.endsOn == this.endsOn &&
          other.endsAfterCount == this.endsAfterCount &&
          other.seriesId == this.seriesId &&
          other.timeZone == this.timeZone &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class TasksCompanion extends UpdateCompanion<TaskRow> {
  final Value<String> id;
  final Value<String> title;
  final Value<String?> notes;
  final Value<int> color;
  final Value<String?> tag;
  final Value<int> priority;
  final Value<bool> allDay;
  final Value<String> startDate;
  final Value<int?> startMinute;
  final Value<int?> durationMin;
  final Value<String> repeatKind;
  final Value<String?> rrule;
  final Value<int?> quotaPerWeek;
  final Value<String?> quotaPreferredDays;
  final Value<String?> endsOn;
  final Value<int?> endsAfterCount;
  final Value<String> seriesId;
  final Value<String?> timeZone;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int?> deletedAt;
  final Value<int> rowid;
  const TasksCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.notes = const Value.absent(),
    this.color = const Value.absent(),
    this.tag = const Value.absent(),
    this.priority = const Value.absent(),
    this.allDay = const Value.absent(),
    this.startDate = const Value.absent(),
    this.startMinute = const Value.absent(),
    this.durationMin = const Value.absent(),
    this.repeatKind = const Value.absent(),
    this.rrule = const Value.absent(),
    this.quotaPerWeek = const Value.absent(),
    this.quotaPreferredDays = const Value.absent(),
    this.endsOn = const Value.absent(),
    this.endsAfterCount = const Value.absent(),
    this.seriesId = const Value.absent(),
    this.timeZone = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TasksCompanion.insert({
    required String id,
    required String title,
    this.notes = const Value.absent(),
    required int color,
    this.tag = const Value.absent(),
    this.priority = const Value.absent(),
    this.allDay = const Value.absent(),
    required String startDate,
    this.startMinute = const Value.absent(),
    this.durationMin = const Value.absent(),
    this.repeatKind = const Value.absent(),
    this.rrule = const Value.absent(),
    this.quotaPerWeek = const Value.absent(),
    this.quotaPreferredDays = const Value.absent(),
    this.endsOn = const Value.absent(),
    this.endsAfterCount = const Value.absent(),
    required String seriesId,
    this.timeZone = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       color = Value(color),
       startDate = Value(startDate),
       seriesId = Value(seriesId),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<TaskRow> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? notes,
    Expression<int>? color,
    Expression<String>? tag,
    Expression<int>? priority,
    Expression<bool>? allDay,
    Expression<String>? startDate,
    Expression<int>? startMinute,
    Expression<int>? durationMin,
    Expression<String>? repeatKind,
    Expression<String>? rrule,
    Expression<int>? quotaPerWeek,
    Expression<String>? quotaPreferredDays,
    Expression<String>? endsOn,
    Expression<int>? endsAfterCount,
    Expression<String>? seriesId,
    Expression<String>? timeZone,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (notes != null) 'notes': notes,
      if (color != null) 'color': color,
      if (tag != null) 'tag': tag,
      if (priority != null) 'priority': priority,
      if (allDay != null) 'all_day': allDay,
      if (startDate != null) 'start_date': startDate,
      if (startMinute != null) 'start_minute': startMinute,
      if (durationMin != null) 'duration_min': durationMin,
      if (repeatKind != null) 'repeat_kind': repeatKind,
      if (rrule != null) 'rrule': rrule,
      if (quotaPerWeek != null) 'quota_per_week': quotaPerWeek,
      if (quotaPreferredDays != null)
        'quota_preferred_days': quotaPreferredDays,
      if (endsOn != null) 'ends_on': endsOn,
      if (endsAfterCount != null) 'ends_after_count': endsAfterCount,
      if (seriesId != null) 'series_id': seriesId,
      if (timeZone != null) 'time_zone': timeZone,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TasksCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<String?>? notes,
    Value<int>? color,
    Value<String?>? tag,
    Value<int>? priority,
    Value<bool>? allDay,
    Value<String>? startDate,
    Value<int?>? startMinute,
    Value<int?>? durationMin,
    Value<String>? repeatKind,
    Value<String?>? rrule,
    Value<int?>? quotaPerWeek,
    Value<String?>? quotaPreferredDays,
    Value<String?>? endsOn,
    Value<int?>? endsAfterCount,
    Value<String>? seriesId,
    Value<String?>? timeZone,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int?>? deletedAt,
    Value<int>? rowid,
  }) {
    return TasksCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      color: color ?? this.color,
      tag: tag ?? this.tag,
      priority: priority ?? this.priority,
      allDay: allDay ?? this.allDay,
      startDate: startDate ?? this.startDate,
      startMinute: startMinute ?? this.startMinute,
      durationMin: durationMin ?? this.durationMin,
      repeatKind: repeatKind ?? this.repeatKind,
      rrule: rrule ?? this.rrule,
      quotaPerWeek: quotaPerWeek ?? this.quotaPerWeek,
      quotaPreferredDays: quotaPreferredDays ?? this.quotaPreferredDays,
      endsOn: endsOn ?? this.endsOn,
      endsAfterCount: endsAfterCount ?? this.endsAfterCount,
      seriesId: seriesId ?? this.seriesId,
      timeZone: timeZone ?? this.timeZone,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (color.present) {
      map['color'] = Variable<int>(color.value);
    }
    if (tag.present) {
      map['tag'] = Variable<String>(tag.value);
    }
    if (priority.present) {
      map['priority'] = Variable<int>(priority.value);
    }
    if (allDay.present) {
      map['all_day'] = Variable<bool>(allDay.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<String>(startDate.value);
    }
    if (startMinute.present) {
      map['start_minute'] = Variable<int>(startMinute.value);
    }
    if (durationMin.present) {
      map['duration_min'] = Variable<int>(durationMin.value);
    }
    if (repeatKind.present) {
      map['repeat_kind'] = Variable<String>(repeatKind.value);
    }
    if (rrule.present) {
      map['rrule'] = Variable<String>(rrule.value);
    }
    if (quotaPerWeek.present) {
      map['quota_per_week'] = Variable<int>(quotaPerWeek.value);
    }
    if (quotaPreferredDays.present) {
      map['quota_preferred_days'] = Variable<String>(quotaPreferredDays.value);
    }
    if (endsOn.present) {
      map['ends_on'] = Variable<String>(endsOn.value);
    }
    if (endsAfterCount.present) {
      map['ends_after_count'] = Variable<int>(endsAfterCount.value);
    }
    if (seriesId.present) {
      map['series_id'] = Variable<String>(seriesId.value);
    }
    if (timeZone.present) {
      map['time_zone'] = Variable<String>(timeZone.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TasksCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('notes: $notes, ')
          ..write('color: $color, ')
          ..write('tag: $tag, ')
          ..write('priority: $priority, ')
          ..write('allDay: $allDay, ')
          ..write('startDate: $startDate, ')
          ..write('startMinute: $startMinute, ')
          ..write('durationMin: $durationMin, ')
          ..write('repeatKind: $repeatKind, ')
          ..write('rrule: $rrule, ')
          ..write('quotaPerWeek: $quotaPerWeek, ')
          ..write('quotaPreferredDays: $quotaPreferredDays, ')
          ..write('endsOn: $endsOn, ')
          ..write('endsAfterCount: $endsAfterCount, ')
          ..write('seriesId: $seriesId, ')
          ..write('timeZone: $timeZone, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TaskRemindersTable extends TaskReminders
    with TableInfo<$TaskRemindersTable, TaskReminderRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TaskRemindersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _taskIdMeta = const VerificationMeta('taskId');
  @override
  late final GeneratedColumn<String> taskId = GeneratedColumn<String>(
    'task_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES tasks (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _offsetMinMeta = const VerificationMeta(
    'offsetMin',
  );
  @override
  late final GeneratedColumn<int> offsetMin = GeneratedColumn<int>(
    'offset_min',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _atMinuteMeta = const VerificationMeta(
    'atMinute',
  );
  @override
  late final GeneratedColumn<int> atMinute = GeneratedColumn<int>(
    'at_minute',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, taskId, offsetMin, atMinute];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'task_reminders';
  @override
  VerificationContext validateIntegrity(
    Insertable<TaskReminderRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('task_id')) {
      context.handle(
        _taskIdMeta,
        taskId.isAcceptableOrUnknown(data['task_id']!, _taskIdMeta),
      );
    } else if (isInserting) {
      context.missing(_taskIdMeta);
    }
    if (data.containsKey('offset_min')) {
      context.handle(
        _offsetMinMeta,
        offsetMin.isAcceptableOrUnknown(data['offset_min']!, _offsetMinMeta),
      );
    } else if (isInserting) {
      context.missing(_offsetMinMeta);
    }
    if (data.containsKey('at_minute')) {
      context.handle(
        _atMinuteMeta,
        atMinute.isAcceptableOrUnknown(data['at_minute']!, _atMinuteMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TaskReminderRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TaskReminderRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      taskId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}task_id'],
      )!,
      offsetMin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}offset_min'],
      )!,
      atMinute: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}at_minute'],
      ),
    );
  }

  @override
  $TaskRemindersTable createAlias(String alias) {
    return $TaskRemindersTable(attachedDatabase, alias);
  }
}

class TaskReminderRow extends DataClass implements Insertable<TaskReminderRow> {
  final String id;
  final String taskId;
  final int offsetMin;
  final int? atMinute;
  const TaskReminderRow({
    required this.id,
    required this.taskId,
    required this.offsetMin,
    this.atMinute,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['task_id'] = Variable<String>(taskId);
    map['offset_min'] = Variable<int>(offsetMin);
    if (!nullToAbsent || atMinute != null) {
      map['at_minute'] = Variable<int>(atMinute);
    }
    return map;
  }

  TaskRemindersCompanion toCompanion(bool nullToAbsent) {
    return TaskRemindersCompanion(
      id: Value(id),
      taskId: Value(taskId),
      offsetMin: Value(offsetMin),
      atMinute: atMinute == null && nullToAbsent
          ? const Value.absent()
          : Value(atMinute),
    );
  }

  factory TaskReminderRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TaskReminderRow(
      id: serializer.fromJson<String>(json['id']),
      taskId: serializer.fromJson<String>(json['taskId']),
      offsetMin: serializer.fromJson<int>(json['offsetMin']),
      atMinute: serializer.fromJson<int?>(json['atMinute']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'taskId': serializer.toJson<String>(taskId),
      'offsetMin': serializer.toJson<int>(offsetMin),
      'atMinute': serializer.toJson<int?>(atMinute),
    };
  }

  TaskReminderRow copyWith({
    String? id,
    String? taskId,
    int? offsetMin,
    Value<int?> atMinute = const Value.absent(),
  }) => TaskReminderRow(
    id: id ?? this.id,
    taskId: taskId ?? this.taskId,
    offsetMin: offsetMin ?? this.offsetMin,
    atMinute: atMinute.present ? atMinute.value : this.atMinute,
  );
  TaskReminderRow copyWithCompanion(TaskRemindersCompanion data) {
    return TaskReminderRow(
      id: data.id.present ? data.id.value : this.id,
      taskId: data.taskId.present ? data.taskId.value : this.taskId,
      offsetMin: data.offsetMin.present ? data.offsetMin.value : this.offsetMin,
      atMinute: data.atMinute.present ? data.atMinute.value : this.atMinute,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TaskReminderRow(')
          ..write('id: $id, ')
          ..write('taskId: $taskId, ')
          ..write('offsetMin: $offsetMin, ')
          ..write('atMinute: $atMinute')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, taskId, offsetMin, atMinute);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TaskReminderRow &&
          other.id == this.id &&
          other.taskId == this.taskId &&
          other.offsetMin == this.offsetMin &&
          other.atMinute == this.atMinute);
}

class TaskRemindersCompanion extends UpdateCompanion<TaskReminderRow> {
  final Value<String> id;
  final Value<String> taskId;
  final Value<int> offsetMin;
  final Value<int?> atMinute;
  final Value<int> rowid;
  const TaskRemindersCompanion({
    this.id = const Value.absent(),
    this.taskId = const Value.absent(),
    this.offsetMin = const Value.absent(),
    this.atMinute = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TaskRemindersCompanion.insert({
    required String id,
    required String taskId,
    required int offsetMin,
    this.atMinute = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       taskId = Value(taskId),
       offsetMin = Value(offsetMin);
  static Insertable<TaskReminderRow> custom({
    Expression<String>? id,
    Expression<String>? taskId,
    Expression<int>? offsetMin,
    Expression<int>? atMinute,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (taskId != null) 'task_id': taskId,
      if (offsetMin != null) 'offset_min': offsetMin,
      if (atMinute != null) 'at_minute': atMinute,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TaskRemindersCompanion copyWith({
    Value<String>? id,
    Value<String>? taskId,
    Value<int>? offsetMin,
    Value<int?>? atMinute,
    Value<int>? rowid,
  }) {
    return TaskRemindersCompanion(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      offsetMin: offsetMin ?? this.offsetMin,
      atMinute: atMinute ?? this.atMinute,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (taskId.present) {
      map['task_id'] = Variable<String>(taskId.value);
    }
    if (offsetMin.present) {
      map['offset_min'] = Variable<int>(offsetMin.value);
    }
    if (atMinute.present) {
      map['at_minute'] = Variable<int>(atMinute.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TaskRemindersCompanion(')
          ..write('id: $id, ')
          ..write('taskId: $taskId, ')
          ..write('offsetMin: $offsetMin, ')
          ..write('atMinute: $atMinute, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OccurrenceRecordsTable extends OccurrenceRecords
    with TableInfo<$OccurrenceRecordsTable, OccurrenceRecordRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OccurrenceRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _taskIdMeta = const VerificationMeta('taskId');
  @override
  late final GeneratedColumn<String> taskId = GeneratedColumn<String>(
    'task_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES tasks (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _occurrenceDateMeta = const VerificationMeta(
    'occurrenceDate',
  );
  @override
  late final GeneratedColumn<String> occurrenceDate = GeneratedColumn<String>(
    'occurrence_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('none'),
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<int> completedAt = GeneratedColumn<int>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _overrideDateMeta = const VerificationMeta(
    'overrideDate',
  );
  @override
  late final GeneratedColumn<String> overrideDate = GeneratedColumn<String>(
    'override_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _overrideStartMinuteMeta =
      const VerificationMeta('overrideStartMinute');
  @override
  late final GeneratedColumn<int> overrideStartMinute = GeneratedColumn<int>(
    'override_start_minute',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _overrideTitleMeta = const VerificationMeta(
    'overrideTitle',
  );
  @override
  late final GeneratedColumn<String> overrideTitle = GeneratedColumn<String>(
    'override_title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lateMeta = const VerificationMeta('late');
  @override
  late final GeneratedColumn<bool> late = GeneratedColumn<bool>(
    'late',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("late" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    taskId,
    occurrenceDate,
    status,
    completedAt,
    overrideDate,
    overrideStartMinute,
    overrideTitle,
    late,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'occurrence_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<OccurrenceRecordRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('task_id')) {
      context.handle(
        _taskIdMeta,
        taskId.isAcceptableOrUnknown(data['task_id']!, _taskIdMeta),
      );
    } else if (isInserting) {
      context.missing(_taskIdMeta);
    }
    if (data.containsKey('occurrence_date')) {
      context.handle(
        _occurrenceDateMeta,
        occurrenceDate.isAcceptableOrUnknown(
          data['occurrence_date']!,
          _occurrenceDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_occurrenceDateMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
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
    if (data.containsKey('override_date')) {
      context.handle(
        _overrideDateMeta,
        overrideDate.isAcceptableOrUnknown(
          data['override_date']!,
          _overrideDateMeta,
        ),
      );
    }
    if (data.containsKey('override_start_minute')) {
      context.handle(
        _overrideStartMinuteMeta,
        overrideStartMinute.isAcceptableOrUnknown(
          data['override_start_minute']!,
          _overrideStartMinuteMeta,
        ),
      );
    }
    if (data.containsKey('override_title')) {
      context.handle(
        _overrideTitleMeta,
        overrideTitle.isAcceptableOrUnknown(
          data['override_title']!,
          _overrideTitleMeta,
        ),
      );
    }
    if (data.containsKey('late')) {
      context.handle(
        _lateMeta,
        late.isAcceptableOrUnknown(data['late']!, _lateMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {taskId, occurrenceDate},
  ];
  @override
  OccurrenceRecordRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OccurrenceRecordRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      taskId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}task_id'],
      )!,
      occurrenceDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}occurrence_date'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}completed_at'],
      ),
      overrideDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}override_date'],
      ),
      overrideStartMinute: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}override_start_minute'],
      ),
      overrideTitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}override_title'],
      ),
      late: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}late'],
      )!,
    );
  }

  @override
  $OccurrenceRecordsTable createAlias(String alias) {
    return $OccurrenceRecordsTable(attachedDatabase, alias);
  }
}

class OccurrenceRecordRow extends DataClass
    implements Insertable<OccurrenceRecordRow> {
  final String id;
  final String taskId;
  final String occurrenceDate;

  /// none | done | skipped | deleted. "missed" is derived, never stored.
  final String status;
  final int? completedAt;
  final String? overrideDate;
  final int? overrideStartMinute;
  final String? overrideTitle;

  /// Back-filled completion (§4.11 day sheet) — keeps on-time stats honest.
  final bool late;
  const OccurrenceRecordRow({
    required this.id,
    required this.taskId,
    required this.occurrenceDate,
    required this.status,
    this.completedAt,
    this.overrideDate,
    this.overrideStartMinute,
    this.overrideTitle,
    required this.late,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['task_id'] = Variable<String>(taskId);
    map['occurrence_date'] = Variable<String>(occurrenceDate);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<int>(completedAt);
    }
    if (!nullToAbsent || overrideDate != null) {
      map['override_date'] = Variable<String>(overrideDate);
    }
    if (!nullToAbsent || overrideStartMinute != null) {
      map['override_start_minute'] = Variable<int>(overrideStartMinute);
    }
    if (!nullToAbsent || overrideTitle != null) {
      map['override_title'] = Variable<String>(overrideTitle);
    }
    map['late'] = Variable<bool>(late);
    return map;
  }

  OccurrenceRecordsCompanion toCompanion(bool nullToAbsent) {
    return OccurrenceRecordsCompanion(
      id: Value(id),
      taskId: Value(taskId),
      occurrenceDate: Value(occurrenceDate),
      status: Value(status),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      overrideDate: overrideDate == null && nullToAbsent
          ? const Value.absent()
          : Value(overrideDate),
      overrideStartMinute: overrideStartMinute == null && nullToAbsent
          ? const Value.absent()
          : Value(overrideStartMinute),
      overrideTitle: overrideTitle == null && nullToAbsent
          ? const Value.absent()
          : Value(overrideTitle),
      late: Value(late),
    );
  }

  factory OccurrenceRecordRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OccurrenceRecordRow(
      id: serializer.fromJson<String>(json['id']),
      taskId: serializer.fromJson<String>(json['taskId']),
      occurrenceDate: serializer.fromJson<String>(json['occurrenceDate']),
      status: serializer.fromJson<String>(json['status']),
      completedAt: serializer.fromJson<int?>(json['completedAt']),
      overrideDate: serializer.fromJson<String?>(json['overrideDate']),
      overrideStartMinute: serializer.fromJson<int?>(
        json['overrideStartMinute'],
      ),
      overrideTitle: serializer.fromJson<String?>(json['overrideTitle']),
      late: serializer.fromJson<bool>(json['late']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'taskId': serializer.toJson<String>(taskId),
      'occurrenceDate': serializer.toJson<String>(occurrenceDate),
      'status': serializer.toJson<String>(status),
      'completedAt': serializer.toJson<int?>(completedAt),
      'overrideDate': serializer.toJson<String?>(overrideDate),
      'overrideStartMinute': serializer.toJson<int?>(overrideStartMinute),
      'overrideTitle': serializer.toJson<String?>(overrideTitle),
      'late': serializer.toJson<bool>(late),
    };
  }

  OccurrenceRecordRow copyWith({
    String? id,
    String? taskId,
    String? occurrenceDate,
    String? status,
    Value<int?> completedAt = const Value.absent(),
    Value<String?> overrideDate = const Value.absent(),
    Value<int?> overrideStartMinute = const Value.absent(),
    Value<String?> overrideTitle = const Value.absent(),
    bool? late,
  }) => OccurrenceRecordRow(
    id: id ?? this.id,
    taskId: taskId ?? this.taskId,
    occurrenceDate: occurrenceDate ?? this.occurrenceDate,
    status: status ?? this.status,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
    overrideDate: overrideDate.present ? overrideDate.value : this.overrideDate,
    overrideStartMinute: overrideStartMinute.present
        ? overrideStartMinute.value
        : this.overrideStartMinute,
    overrideTitle: overrideTitle.present
        ? overrideTitle.value
        : this.overrideTitle,
    late: late ?? this.late,
  );
  OccurrenceRecordRow copyWithCompanion(OccurrenceRecordsCompanion data) {
    return OccurrenceRecordRow(
      id: data.id.present ? data.id.value : this.id,
      taskId: data.taskId.present ? data.taskId.value : this.taskId,
      occurrenceDate: data.occurrenceDate.present
          ? data.occurrenceDate.value
          : this.occurrenceDate,
      status: data.status.present ? data.status.value : this.status,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      overrideDate: data.overrideDate.present
          ? data.overrideDate.value
          : this.overrideDate,
      overrideStartMinute: data.overrideStartMinute.present
          ? data.overrideStartMinute.value
          : this.overrideStartMinute,
      overrideTitle: data.overrideTitle.present
          ? data.overrideTitle.value
          : this.overrideTitle,
      late: data.late.present ? data.late.value : this.late,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OccurrenceRecordRow(')
          ..write('id: $id, ')
          ..write('taskId: $taskId, ')
          ..write('occurrenceDate: $occurrenceDate, ')
          ..write('status: $status, ')
          ..write('completedAt: $completedAt, ')
          ..write('overrideDate: $overrideDate, ')
          ..write('overrideStartMinute: $overrideStartMinute, ')
          ..write('overrideTitle: $overrideTitle, ')
          ..write('late: $late')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    taskId,
    occurrenceDate,
    status,
    completedAt,
    overrideDate,
    overrideStartMinute,
    overrideTitle,
    late,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OccurrenceRecordRow &&
          other.id == this.id &&
          other.taskId == this.taskId &&
          other.occurrenceDate == this.occurrenceDate &&
          other.status == this.status &&
          other.completedAt == this.completedAt &&
          other.overrideDate == this.overrideDate &&
          other.overrideStartMinute == this.overrideStartMinute &&
          other.overrideTitle == this.overrideTitle &&
          other.late == this.late);
}

class OccurrenceRecordsCompanion extends UpdateCompanion<OccurrenceRecordRow> {
  final Value<String> id;
  final Value<String> taskId;
  final Value<String> occurrenceDate;
  final Value<String> status;
  final Value<int?> completedAt;
  final Value<String?> overrideDate;
  final Value<int?> overrideStartMinute;
  final Value<String?> overrideTitle;
  final Value<bool> late;
  final Value<int> rowid;
  const OccurrenceRecordsCompanion({
    this.id = const Value.absent(),
    this.taskId = const Value.absent(),
    this.occurrenceDate = const Value.absent(),
    this.status = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.overrideDate = const Value.absent(),
    this.overrideStartMinute = const Value.absent(),
    this.overrideTitle = const Value.absent(),
    this.late = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OccurrenceRecordsCompanion.insert({
    required String id,
    required String taskId,
    required String occurrenceDate,
    this.status = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.overrideDate = const Value.absent(),
    this.overrideStartMinute = const Value.absent(),
    this.overrideTitle = const Value.absent(),
    this.late = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       taskId = Value(taskId),
       occurrenceDate = Value(occurrenceDate);
  static Insertable<OccurrenceRecordRow> custom({
    Expression<String>? id,
    Expression<String>? taskId,
    Expression<String>? occurrenceDate,
    Expression<String>? status,
    Expression<int>? completedAt,
    Expression<String>? overrideDate,
    Expression<int>? overrideStartMinute,
    Expression<String>? overrideTitle,
    Expression<bool>? late,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (taskId != null) 'task_id': taskId,
      if (occurrenceDate != null) 'occurrence_date': occurrenceDate,
      if (status != null) 'status': status,
      if (completedAt != null) 'completed_at': completedAt,
      if (overrideDate != null) 'override_date': overrideDate,
      if (overrideStartMinute != null)
        'override_start_minute': overrideStartMinute,
      if (overrideTitle != null) 'override_title': overrideTitle,
      if (late != null) 'late': late,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OccurrenceRecordsCompanion copyWith({
    Value<String>? id,
    Value<String>? taskId,
    Value<String>? occurrenceDate,
    Value<String>? status,
    Value<int?>? completedAt,
    Value<String?>? overrideDate,
    Value<int?>? overrideStartMinute,
    Value<String?>? overrideTitle,
    Value<bool>? late,
    Value<int>? rowid,
  }) {
    return OccurrenceRecordsCompanion(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      occurrenceDate: occurrenceDate ?? this.occurrenceDate,
      status: status ?? this.status,
      completedAt: completedAt ?? this.completedAt,
      overrideDate: overrideDate ?? this.overrideDate,
      overrideStartMinute: overrideStartMinute ?? this.overrideStartMinute,
      overrideTitle: overrideTitle ?? this.overrideTitle,
      late: late ?? this.late,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (taskId.present) {
      map['task_id'] = Variable<String>(taskId.value);
    }
    if (occurrenceDate.present) {
      map['occurrence_date'] = Variable<String>(occurrenceDate.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<int>(completedAt.value);
    }
    if (overrideDate.present) {
      map['override_date'] = Variable<String>(overrideDate.value);
    }
    if (overrideStartMinute.present) {
      map['override_start_minute'] = Variable<int>(overrideStartMinute.value);
    }
    if (overrideTitle.present) {
      map['override_title'] = Variable<String>(overrideTitle.value);
    }
    if (late.present) {
      map['late'] = Variable<bool>(late.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OccurrenceRecordsCompanion(')
          ..write('id: $id, ')
          ..write('taskId: $taskId, ')
          ..write('occurrenceDate: $occurrenceDate, ')
          ..write('status: $status, ')
          ..write('completedAt: $completedAt, ')
          ..write('overrideDate: $overrideDate, ')
          ..write('overrideStartMinute: $overrideStartMinute, ')
          ..write('overrideTitle: $overrideTitle, ')
          ..write('late: $late, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FocusSessionsTable extends FocusSessions
    with TableInfo<$FocusSessionsTable, FocusSessionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FocusSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<int> startedAt = GeneratedColumn<int>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endedAtMeta = const VerificationMeta(
    'endedAt',
  );
  @override
  late final GeneratedColumn<int> endedAt = GeneratedColumn<int>(
    'ended_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _plannedFocusMinMeta = const VerificationMeta(
    'plannedFocusMin',
  );
  @override
  late final GeneratedColumn<int> plannedFocusMin = GeneratedColumn<int>(
    'planned_focus_min',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _shortBreakMinMeta = const VerificationMeta(
    'shortBreakMin',
  );
  @override
  late final GeneratedColumn<int> shortBreakMin = GeneratedColumn<int>(
    'short_break_min',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _longBreakMinMeta = const VerificationMeta(
    'longBreakMin',
  );
  @override
  late final GeneratedColumn<int> longBreakMin = GeneratedColumn<int>(
    'long_break_min',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _longEveryMeta = const VerificationMeta(
    'longEvery',
  );
  @override
  late final GeneratedColumn<int> longEvery = GeneratedColumn<int>(
    'long_every',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _focusMsCompletedMeta = const VerificationMeta(
    'focusMsCompleted',
  );
  @override
  late final GeneratedColumn<int> focusMsCompleted = GeneratedColumn<int>(
    'focus_ms_completed',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _phasesCompletedMeta = const VerificationMeta(
    'phasesCompleted',
  );
  @override
  late final GeneratedColumn<int> phasesCompleted = GeneratedColumn<int>(
    'phases_completed',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _endedEarlyMeta = const VerificationMeta(
    'endedEarly',
  );
  @override
  late final GeneratedColumn<bool> endedEarly = GeneratedColumn<bool>(
    'ended_early',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("ended_early" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _linkedTaskIdMeta = const VerificationMeta(
    'linkedTaskId',
  );
  @override
  late final GeneratedColumn<String> linkedTaskId = GeneratedColumn<String>(
    'linked_task_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _linkedOccurrenceDateMeta =
      const VerificationMeta('linkedOccurrenceDate');
  @override
  late final GeneratedColumn<String> linkedOccurrenceDate =
      GeneratedColumn<String>(
        'linked_occurrence_date',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _pausedMsMeta = const VerificationMeta(
    'pausedMs',
  );
  @override
  late final GeneratedColumn<int> pausedMs = GeneratedColumn<int>(
    'paused_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _awayMsMeta = const VerificationMeta('awayMs');
  @override
  late final GeneratedColumn<int> awayMs = GeneratedColumn<int>(
    'away_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _interruptionsMeta = const VerificationMeta(
    'interruptions',
  );
  @override
  late final GeneratedColumn<int> interruptions = GeneratedColumn<int>(
    'interruptions',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _distractionsMeta = const VerificationMeta(
    'distractions',
  );
  @override
  late final GeneratedColumn<String> distractions = GeneratedColumn<String>(
    'distractions',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    startedAt,
    endedAt,
    plannedFocusMin,
    shortBreakMin,
    longBreakMin,
    longEvery,
    focusMsCompleted,
    phasesCompleted,
    endedEarly,
    linkedTaskId,
    linkedOccurrenceDate,
    pausedMs,
    awayMs,
    interruptions,
    distractions,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'focus_sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<FocusSessionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('ended_at')) {
      context.handle(
        _endedAtMeta,
        endedAt.isAcceptableOrUnknown(data['ended_at']!, _endedAtMeta),
      );
    }
    if (data.containsKey('planned_focus_min')) {
      context.handle(
        _plannedFocusMinMeta,
        plannedFocusMin.isAcceptableOrUnknown(
          data['planned_focus_min']!,
          _plannedFocusMinMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_plannedFocusMinMeta);
    }
    if (data.containsKey('short_break_min')) {
      context.handle(
        _shortBreakMinMeta,
        shortBreakMin.isAcceptableOrUnknown(
          data['short_break_min']!,
          _shortBreakMinMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_shortBreakMinMeta);
    }
    if (data.containsKey('long_break_min')) {
      context.handle(
        _longBreakMinMeta,
        longBreakMin.isAcceptableOrUnknown(
          data['long_break_min']!,
          _longBreakMinMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_longBreakMinMeta);
    }
    if (data.containsKey('long_every')) {
      context.handle(
        _longEveryMeta,
        longEvery.isAcceptableOrUnknown(data['long_every']!, _longEveryMeta),
      );
    } else if (isInserting) {
      context.missing(_longEveryMeta);
    }
    if (data.containsKey('focus_ms_completed')) {
      context.handle(
        _focusMsCompletedMeta,
        focusMsCompleted.isAcceptableOrUnknown(
          data['focus_ms_completed']!,
          _focusMsCompletedMeta,
        ),
      );
    }
    if (data.containsKey('phases_completed')) {
      context.handle(
        _phasesCompletedMeta,
        phasesCompleted.isAcceptableOrUnknown(
          data['phases_completed']!,
          _phasesCompletedMeta,
        ),
      );
    }
    if (data.containsKey('ended_early')) {
      context.handle(
        _endedEarlyMeta,
        endedEarly.isAcceptableOrUnknown(data['ended_early']!, _endedEarlyMeta),
      );
    }
    if (data.containsKey('linked_task_id')) {
      context.handle(
        _linkedTaskIdMeta,
        linkedTaskId.isAcceptableOrUnknown(
          data['linked_task_id']!,
          _linkedTaskIdMeta,
        ),
      );
    }
    if (data.containsKey('linked_occurrence_date')) {
      context.handle(
        _linkedOccurrenceDateMeta,
        linkedOccurrenceDate.isAcceptableOrUnknown(
          data['linked_occurrence_date']!,
          _linkedOccurrenceDateMeta,
        ),
      );
    }
    if (data.containsKey('paused_ms')) {
      context.handle(
        _pausedMsMeta,
        pausedMs.isAcceptableOrUnknown(data['paused_ms']!, _pausedMsMeta),
      );
    }
    if (data.containsKey('away_ms')) {
      context.handle(
        _awayMsMeta,
        awayMs.isAcceptableOrUnknown(data['away_ms']!, _awayMsMeta),
      );
    }
    if (data.containsKey('interruptions')) {
      context.handle(
        _interruptionsMeta,
        interruptions.isAcceptableOrUnknown(
          data['interruptions']!,
          _interruptionsMeta,
        ),
      );
    }
    if (data.containsKey('distractions')) {
      context.handle(
        _distractionsMeta,
        distractions.isAcceptableOrUnknown(
          data['distractions']!,
          _distractionsMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FocusSessionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FocusSessionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}started_at'],
      )!,
      endedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ended_at'],
      ),
      plannedFocusMin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}planned_focus_min'],
      )!,
      shortBreakMin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}short_break_min'],
      )!,
      longBreakMin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}long_break_min'],
      )!,
      longEvery: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}long_every'],
      )!,
      focusMsCompleted: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}focus_ms_completed'],
      )!,
      phasesCompleted: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}phases_completed'],
      )!,
      endedEarly: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}ended_early'],
      )!,
      linkedTaskId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}linked_task_id'],
      ),
      linkedOccurrenceDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}linked_occurrence_date'],
      ),
      pausedMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}paused_ms'],
      )!,
      awayMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}away_ms'],
      )!,
      interruptions: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}interruptions'],
      )!,
      distractions: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}distractions'],
      ),
    );
  }

  @override
  $FocusSessionsTable createAlias(String alias) {
    return $FocusSessionsTable(attachedDatabase, alias);
  }
}

class FocusSessionRow extends DataClass implements Insertable<FocusSessionRow> {
  final String id;
  final int startedAt;
  final int? endedAt;
  final int plannedFocusMin;
  final int shortBreakMin;
  final int longBreakMin;
  final int longEvery;
  final int focusMsCompleted;
  final int phasesCompleted;
  final bool endedEarly;
  final String? linkedTaskId;
  final String? linkedOccurrenceDate;
  final int pausedMs;
  final int awayMs;
  final int interruptions;

  /// JSON object: Android package name → ms in that app during the session.
  final String? distractions;
  const FocusSessionRow({
    required this.id,
    required this.startedAt,
    this.endedAt,
    required this.plannedFocusMin,
    required this.shortBreakMin,
    required this.longBreakMin,
    required this.longEvery,
    required this.focusMsCompleted,
    required this.phasesCompleted,
    required this.endedEarly,
    this.linkedTaskId,
    this.linkedOccurrenceDate,
    required this.pausedMs,
    required this.awayMs,
    required this.interruptions,
    this.distractions,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['started_at'] = Variable<int>(startedAt);
    if (!nullToAbsent || endedAt != null) {
      map['ended_at'] = Variable<int>(endedAt);
    }
    map['planned_focus_min'] = Variable<int>(plannedFocusMin);
    map['short_break_min'] = Variable<int>(shortBreakMin);
    map['long_break_min'] = Variable<int>(longBreakMin);
    map['long_every'] = Variable<int>(longEvery);
    map['focus_ms_completed'] = Variable<int>(focusMsCompleted);
    map['phases_completed'] = Variable<int>(phasesCompleted);
    map['ended_early'] = Variable<bool>(endedEarly);
    if (!nullToAbsent || linkedTaskId != null) {
      map['linked_task_id'] = Variable<String>(linkedTaskId);
    }
    if (!nullToAbsent || linkedOccurrenceDate != null) {
      map['linked_occurrence_date'] = Variable<String>(linkedOccurrenceDate);
    }
    map['paused_ms'] = Variable<int>(pausedMs);
    map['away_ms'] = Variable<int>(awayMs);
    map['interruptions'] = Variable<int>(interruptions);
    if (!nullToAbsent || distractions != null) {
      map['distractions'] = Variable<String>(distractions);
    }
    return map;
  }

  FocusSessionsCompanion toCompanion(bool nullToAbsent) {
    return FocusSessionsCompanion(
      id: Value(id),
      startedAt: Value(startedAt),
      endedAt: endedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(endedAt),
      plannedFocusMin: Value(plannedFocusMin),
      shortBreakMin: Value(shortBreakMin),
      longBreakMin: Value(longBreakMin),
      longEvery: Value(longEvery),
      focusMsCompleted: Value(focusMsCompleted),
      phasesCompleted: Value(phasesCompleted),
      endedEarly: Value(endedEarly),
      linkedTaskId: linkedTaskId == null && nullToAbsent
          ? const Value.absent()
          : Value(linkedTaskId),
      linkedOccurrenceDate: linkedOccurrenceDate == null && nullToAbsent
          ? const Value.absent()
          : Value(linkedOccurrenceDate),
      pausedMs: Value(pausedMs),
      awayMs: Value(awayMs),
      interruptions: Value(interruptions),
      distractions: distractions == null && nullToAbsent
          ? const Value.absent()
          : Value(distractions),
    );
  }

  factory FocusSessionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FocusSessionRow(
      id: serializer.fromJson<String>(json['id']),
      startedAt: serializer.fromJson<int>(json['startedAt']),
      endedAt: serializer.fromJson<int?>(json['endedAt']),
      plannedFocusMin: serializer.fromJson<int>(json['plannedFocusMin']),
      shortBreakMin: serializer.fromJson<int>(json['shortBreakMin']),
      longBreakMin: serializer.fromJson<int>(json['longBreakMin']),
      longEvery: serializer.fromJson<int>(json['longEvery']),
      focusMsCompleted: serializer.fromJson<int>(json['focusMsCompleted']),
      phasesCompleted: serializer.fromJson<int>(json['phasesCompleted']),
      endedEarly: serializer.fromJson<bool>(json['endedEarly']),
      linkedTaskId: serializer.fromJson<String?>(json['linkedTaskId']),
      linkedOccurrenceDate: serializer.fromJson<String?>(
        json['linkedOccurrenceDate'],
      ),
      pausedMs: serializer.fromJson<int>(json['pausedMs']),
      awayMs: serializer.fromJson<int>(json['awayMs']),
      interruptions: serializer.fromJson<int>(json['interruptions']),
      distractions: serializer.fromJson<String?>(json['distractions']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'startedAt': serializer.toJson<int>(startedAt),
      'endedAt': serializer.toJson<int?>(endedAt),
      'plannedFocusMin': serializer.toJson<int>(plannedFocusMin),
      'shortBreakMin': serializer.toJson<int>(shortBreakMin),
      'longBreakMin': serializer.toJson<int>(longBreakMin),
      'longEvery': serializer.toJson<int>(longEvery),
      'focusMsCompleted': serializer.toJson<int>(focusMsCompleted),
      'phasesCompleted': serializer.toJson<int>(phasesCompleted),
      'endedEarly': serializer.toJson<bool>(endedEarly),
      'linkedTaskId': serializer.toJson<String?>(linkedTaskId),
      'linkedOccurrenceDate': serializer.toJson<String?>(linkedOccurrenceDate),
      'pausedMs': serializer.toJson<int>(pausedMs),
      'awayMs': serializer.toJson<int>(awayMs),
      'interruptions': serializer.toJson<int>(interruptions),
      'distractions': serializer.toJson<String?>(distractions),
    };
  }

  FocusSessionRow copyWith({
    String? id,
    int? startedAt,
    Value<int?> endedAt = const Value.absent(),
    int? plannedFocusMin,
    int? shortBreakMin,
    int? longBreakMin,
    int? longEvery,
    int? focusMsCompleted,
    int? phasesCompleted,
    bool? endedEarly,
    Value<String?> linkedTaskId = const Value.absent(),
    Value<String?> linkedOccurrenceDate = const Value.absent(),
    int? pausedMs,
    int? awayMs,
    int? interruptions,
    Value<String?> distractions = const Value.absent(),
  }) => FocusSessionRow(
    id: id ?? this.id,
    startedAt: startedAt ?? this.startedAt,
    endedAt: endedAt.present ? endedAt.value : this.endedAt,
    plannedFocusMin: plannedFocusMin ?? this.plannedFocusMin,
    shortBreakMin: shortBreakMin ?? this.shortBreakMin,
    longBreakMin: longBreakMin ?? this.longBreakMin,
    longEvery: longEvery ?? this.longEvery,
    focusMsCompleted: focusMsCompleted ?? this.focusMsCompleted,
    phasesCompleted: phasesCompleted ?? this.phasesCompleted,
    endedEarly: endedEarly ?? this.endedEarly,
    linkedTaskId: linkedTaskId.present ? linkedTaskId.value : this.linkedTaskId,
    linkedOccurrenceDate: linkedOccurrenceDate.present
        ? linkedOccurrenceDate.value
        : this.linkedOccurrenceDate,
    pausedMs: pausedMs ?? this.pausedMs,
    awayMs: awayMs ?? this.awayMs,
    interruptions: interruptions ?? this.interruptions,
    distractions: distractions.present ? distractions.value : this.distractions,
  );
  FocusSessionRow copyWithCompanion(FocusSessionsCompanion data) {
    return FocusSessionRow(
      id: data.id.present ? data.id.value : this.id,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
      plannedFocusMin: data.plannedFocusMin.present
          ? data.plannedFocusMin.value
          : this.plannedFocusMin,
      shortBreakMin: data.shortBreakMin.present
          ? data.shortBreakMin.value
          : this.shortBreakMin,
      longBreakMin: data.longBreakMin.present
          ? data.longBreakMin.value
          : this.longBreakMin,
      longEvery: data.longEvery.present ? data.longEvery.value : this.longEvery,
      focusMsCompleted: data.focusMsCompleted.present
          ? data.focusMsCompleted.value
          : this.focusMsCompleted,
      phasesCompleted: data.phasesCompleted.present
          ? data.phasesCompleted.value
          : this.phasesCompleted,
      endedEarly: data.endedEarly.present
          ? data.endedEarly.value
          : this.endedEarly,
      linkedTaskId: data.linkedTaskId.present
          ? data.linkedTaskId.value
          : this.linkedTaskId,
      linkedOccurrenceDate: data.linkedOccurrenceDate.present
          ? data.linkedOccurrenceDate.value
          : this.linkedOccurrenceDate,
      pausedMs: data.pausedMs.present ? data.pausedMs.value : this.pausedMs,
      awayMs: data.awayMs.present ? data.awayMs.value : this.awayMs,
      interruptions: data.interruptions.present
          ? data.interruptions.value
          : this.interruptions,
      distractions: data.distractions.present
          ? data.distractions.value
          : this.distractions,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FocusSessionRow(')
          ..write('id: $id, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('plannedFocusMin: $plannedFocusMin, ')
          ..write('shortBreakMin: $shortBreakMin, ')
          ..write('longBreakMin: $longBreakMin, ')
          ..write('longEvery: $longEvery, ')
          ..write('focusMsCompleted: $focusMsCompleted, ')
          ..write('phasesCompleted: $phasesCompleted, ')
          ..write('endedEarly: $endedEarly, ')
          ..write('linkedTaskId: $linkedTaskId, ')
          ..write('linkedOccurrenceDate: $linkedOccurrenceDate, ')
          ..write('pausedMs: $pausedMs, ')
          ..write('awayMs: $awayMs, ')
          ..write('interruptions: $interruptions, ')
          ..write('distractions: $distractions')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    startedAt,
    endedAt,
    plannedFocusMin,
    shortBreakMin,
    longBreakMin,
    longEvery,
    focusMsCompleted,
    phasesCompleted,
    endedEarly,
    linkedTaskId,
    linkedOccurrenceDate,
    pausedMs,
    awayMs,
    interruptions,
    distractions,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FocusSessionRow &&
          other.id == this.id &&
          other.startedAt == this.startedAt &&
          other.endedAt == this.endedAt &&
          other.plannedFocusMin == this.plannedFocusMin &&
          other.shortBreakMin == this.shortBreakMin &&
          other.longBreakMin == this.longBreakMin &&
          other.longEvery == this.longEvery &&
          other.focusMsCompleted == this.focusMsCompleted &&
          other.phasesCompleted == this.phasesCompleted &&
          other.endedEarly == this.endedEarly &&
          other.linkedTaskId == this.linkedTaskId &&
          other.linkedOccurrenceDate == this.linkedOccurrenceDate &&
          other.pausedMs == this.pausedMs &&
          other.awayMs == this.awayMs &&
          other.interruptions == this.interruptions &&
          other.distractions == this.distractions);
}

class FocusSessionsCompanion extends UpdateCompanion<FocusSessionRow> {
  final Value<String> id;
  final Value<int> startedAt;
  final Value<int?> endedAt;
  final Value<int> plannedFocusMin;
  final Value<int> shortBreakMin;
  final Value<int> longBreakMin;
  final Value<int> longEvery;
  final Value<int> focusMsCompleted;
  final Value<int> phasesCompleted;
  final Value<bool> endedEarly;
  final Value<String?> linkedTaskId;
  final Value<String?> linkedOccurrenceDate;
  final Value<int> pausedMs;
  final Value<int> awayMs;
  final Value<int> interruptions;
  final Value<String?> distractions;
  final Value<int> rowid;
  const FocusSessionsCompanion({
    this.id = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.plannedFocusMin = const Value.absent(),
    this.shortBreakMin = const Value.absent(),
    this.longBreakMin = const Value.absent(),
    this.longEvery = const Value.absent(),
    this.focusMsCompleted = const Value.absent(),
    this.phasesCompleted = const Value.absent(),
    this.endedEarly = const Value.absent(),
    this.linkedTaskId = const Value.absent(),
    this.linkedOccurrenceDate = const Value.absent(),
    this.pausedMs = const Value.absent(),
    this.awayMs = const Value.absent(),
    this.interruptions = const Value.absent(),
    this.distractions = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FocusSessionsCompanion.insert({
    required String id,
    required int startedAt,
    this.endedAt = const Value.absent(),
    required int plannedFocusMin,
    required int shortBreakMin,
    required int longBreakMin,
    required int longEvery,
    this.focusMsCompleted = const Value.absent(),
    this.phasesCompleted = const Value.absent(),
    this.endedEarly = const Value.absent(),
    this.linkedTaskId = const Value.absent(),
    this.linkedOccurrenceDate = const Value.absent(),
    this.pausedMs = const Value.absent(),
    this.awayMs = const Value.absent(),
    this.interruptions = const Value.absent(),
    this.distractions = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       startedAt = Value(startedAt),
       plannedFocusMin = Value(plannedFocusMin),
       shortBreakMin = Value(shortBreakMin),
       longBreakMin = Value(longBreakMin),
       longEvery = Value(longEvery);
  static Insertable<FocusSessionRow> custom({
    Expression<String>? id,
    Expression<int>? startedAt,
    Expression<int>? endedAt,
    Expression<int>? plannedFocusMin,
    Expression<int>? shortBreakMin,
    Expression<int>? longBreakMin,
    Expression<int>? longEvery,
    Expression<int>? focusMsCompleted,
    Expression<int>? phasesCompleted,
    Expression<bool>? endedEarly,
    Expression<String>? linkedTaskId,
    Expression<String>? linkedOccurrenceDate,
    Expression<int>? pausedMs,
    Expression<int>? awayMs,
    Expression<int>? interruptions,
    Expression<String>? distractions,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (startedAt != null) 'started_at': startedAt,
      if (endedAt != null) 'ended_at': endedAt,
      if (plannedFocusMin != null) 'planned_focus_min': plannedFocusMin,
      if (shortBreakMin != null) 'short_break_min': shortBreakMin,
      if (longBreakMin != null) 'long_break_min': longBreakMin,
      if (longEvery != null) 'long_every': longEvery,
      if (focusMsCompleted != null) 'focus_ms_completed': focusMsCompleted,
      if (phasesCompleted != null) 'phases_completed': phasesCompleted,
      if (endedEarly != null) 'ended_early': endedEarly,
      if (linkedTaskId != null) 'linked_task_id': linkedTaskId,
      if (linkedOccurrenceDate != null)
        'linked_occurrence_date': linkedOccurrenceDate,
      if (pausedMs != null) 'paused_ms': pausedMs,
      if (awayMs != null) 'away_ms': awayMs,
      if (interruptions != null) 'interruptions': interruptions,
      if (distractions != null) 'distractions': distractions,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FocusSessionsCompanion copyWith({
    Value<String>? id,
    Value<int>? startedAt,
    Value<int?>? endedAt,
    Value<int>? plannedFocusMin,
    Value<int>? shortBreakMin,
    Value<int>? longBreakMin,
    Value<int>? longEvery,
    Value<int>? focusMsCompleted,
    Value<int>? phasesCompleted,
    Value<bool>? endedEarly,
    Value<String?>? linkedTaskId,
    Value<String?>? linkedOccurrenceDate,
    Value<int>? pausedMs,
    Value<int>? awayMs,
    Value<int>? interruptions,
    Value<String?>? distractions,
    Value<int>? rowid,
  }) {
    return FocusSessionsCompanion(
      id: id ?? this.id,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      plannedFocusMin: plannedFocusMin ?? this.plannedFocusMin,
      shortBreakMin: shortBreakMin ?? this.shortBreakMin,
      longBreakMin: longBreakMin ?? this.longBreakMin,
      longEvery: longEvery ?? this.longEvery,
      focusMsCompleted: focusMsCompleted ?? this.focusMsCompleted,
      phasesCompleted: phasesCompleted ?? this.phasesCompleted,
      endedEarly: endedEarly ?? this.endedEarly,
      linkedTaskId: linkedTaskId ?? this.linkedTaskId,
      linkedOccurrenceDate: linkedOccurrenceDate ?? this.linkedOccurrenceDate,
      pausedMs: pausedMs ?? this.pausedMs,
      awayMs: awayMs ?? this.awayMs,
      interruptions: interruptions ?? this.interruptions,
      distractions: distractions ?? this.distractions,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<int>(startedAt.value);
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<int>(endedAt.value);
    }
    if (plannedFocusMin.present) {
      map['planned_focus_min'] = Variable<int>(plannedFocusMin.value);
    }
    if (shortBreakMin.present) {
      map['short_break_min'] = Variable<int>(shortBreakMin.value);
    }
    if (longBreakMin.present) {
      map['long_break_min'] = Variable<int>(longBreakMin.value);
    }
    if (longEvery.present) {
      map['long_every'] = Variable<int>(longEvery.value);
    }
    if (focusMsCompleted.present) {
      map['focus_ms_completed'] = Variable<int>(focusMsCompleted.value);
    }
    if (phasesCompleted.present) {
      map['phases_completed'] = Variable<int>(phasesCompleted.value);
    }
    if (endedEarly.present) {
      map['ended_early'] = Variable<bool>(endedEarly.value);
    }
    if (linkedTaskId.present) {
      map['linked_task_id'] = Variable<String>(linkedTaskId.value);
    }
    if (linkedOccurrenceDate.present) {
      map['linked_occurrence_date'] = Variable<String>(
        linkedOccurrenceDate.value,
      );
    }
    if (pausedMs.present) {
      map['paused_ms'] = Variable<int>(pausedMs.value);
    }
    if (awayMs.present) {
      map['away_ms'] = Variable<int>(awayMs.value);
    }
    if (interruptions.present) {
      map['interruptions'] = Variable<int>(interruptions.value);
    }
    if (distractions.present) {
      map['distractions'] = Variable<String>(distractions.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FocusSessionsCompanion(')
          ..write('id: $id, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('plannedFocusMin: $plannedFocusMin, ')
          ..write('shortBreakMin: $shortBreakMin, ')
          ..write('longBreakMin: $longBreakMin, ')
          ..write('longEvery: $longEvery, ')
          ..write('focusMsCompleted: $focusMsCompleted, ')
          ..write('phasesCompleted: $phasesCompleted, ')
          ..write('endedEarly: $endedEarly, ')
          ..write('linkedTaskId: $linkedTaskId, ')
          ..write('linkedOccurrenceDate: $linkedOccurrenceDate, ')
          ..write('pausedMs: $pausedMs, ')
          ..write('awayMs: $awayMs, ')
          ..write('interruptions: $interruptions, ')
          ..write('distractions: $distractions, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FocusStatesTable extends FocusStates
    with TableInfo<$FocusStatesTable, FocusStateRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FocusStatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _phaseMeta = const VerificationMeta('phase');
  @override
  late final GeneratedColumn<String> phase = GeneratedColumn<String>(
    'phase',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _focusIndexMeta = const VerificationMeta(
    'focusIndex',
  );
  @override
  late final GeneratedColumn<int> focusIndex = GeneratedColumn<int>(
    'focus_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _phaseStartedAtMeta = const VerificationMeta(
    'phaseStartedAt',
  );
  @override
  late final GeneratedColumn<int> phaseStartedAt = GeneratedColumn<int>(
    'phase_started_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _phaseDurationMsMeta = const VerificationMeta(
    'phaseDurationMs',
  );
  @override
  late final GeneratedColumn<int> phaseDurationMs = GeneratedColumn<int>(
    'phase_duration_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pausedAtMeta = const VerificationMeta(
    'pausedAt',
  );
  @override
  late final GeneratedColumn<int> pausedAt = GeneratedColumn<int>(
    'paused_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pausedAccumMsMeta = const VerificationMeta(
    'pausedAccumMs',
  );
  @override
  late final GeneratedColumn<int> pausedAccumMs = GeneratedColumn<int>(
    'paused_accum_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _focusMsCompletedMeta = const VerificationMeta(
    'focusMsCompleted',
  );
  @override
  late final GeneratedColumn<int> focusMsCompleted = GeneratedColumn<int>(
    'focus_ms_completed',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _phasesCompletedMeta = const VerificationMeta(
    'phasesCompleted',
  );
  @override
  late final GeneratedColumn<int> phasesCompleted = GeneratedColumn<int>(
    'phases_completed',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _pausedTotalMsMeta = const VerificationMeta(
    'pausedTotalMs',
  );
  @override
  late final GeneratedColumn<int> pausedTotalMs = GeneratedColumn<int>(
    'paused_total_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _interruptionsMeta = const VerificationMeta(
    'interruptions',
  );
  @override
  late final GeneratedColumn<int> interruptions = GeneratedColumn<int>(
    'interruptions',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _awayMsMeta = const VerificationMeta('awayMs');
  @override
  late final GeneratedColumn<int> awayMs = GeneratedColumn<int>(
    'away_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _awayStartedAtMeta = const VerificationMeta(
    'awayStartedAt',
  );
  @override
  late final GeneratedColumn<int> awayStartedAt = GeneratedColumn<int>(
    'away_started_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _awayCapAtMeta = const VerificationMeta(
    'awayCapAt',
  );
  @override
  late final GeneratedColumn<int> awayCapAt = GeneratedColumn<int>(
    'away_cap_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastSeenAtMeta = const VerificationMeta(
    'lastSeenAt',
  );
  @override
  late final GeneratedColumn<int> lastSeenAt = GeneratedColumn<int>(
    'last_seen_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _strictMeta = const VerificationMeta('strict');
  @override
  late final GeneratedColumn<bool> strict = GeneratedColumn<bool>(
    'strict',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("strict" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sessionId,
    phase,
    focusIndex,
    phaseStartedAt,
    phaseDurationMs,
    pausedAt,
    pausedAccumMs,
    focusMsCompleted,
    phasesCompleted,
    pausedTotalMs,
    interruptions,
    awayMs,
    awayStartedAt,
    awayCapAt,
    lastSeenAt,
    strict,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'focus_state';
  @override
  VerificationContext validateIntegrity(
    Insertable<FocusStateRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('phase')) {
      context.handle(
        _phaseMeta,
        phase.isAcceptableOrUnknown(data['phase']!, _phaseMeta),
      );
    } else if (isInserting) {
      context.missing(_phaseMeta);
    }
    if (data.containsKey('focus_index')) {
      context.handle(
        _focusIndexMeta,
        focusIndex.isAcceptableOrUnknown(data['focus_index']!, _focusIndexMeta),
      );
    } else if (isInserting) {
      context.missing(_focusIndexMeta);
    }
    if (data.containsKey('phase_started_at')) {
      context.handle(
        _phaseStartedAtMeta,
        phaseStartedAt.isAcceptableOrUnknown(
          data['phase_started_at']!,
          _phaseStartedAtMeta,
        ),
      );
    }
    if (data.containsKey('phase_duration_ms')) {
      context.handle(
        _phaseDurationMsMeta,
        phaseDurationMs.isAcceptableOrUnknown(
          data['phase_duration_ms']!,
          _phaseDurationMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_phaseDurationMsMeta);
    }
    if (data.containsKey('paused_at')) {
      context.handle(
        _pausedAtMeta,
        pausedAt.isAcceptableOrUnknown(data['paused_at']!, _pausedAtMeta),
      );
    }
    if (data.containsKey('paused_accum_ms')) {
      context.handle(
        _pausedAccumMsMeta,
        pausedAccumMs.isAcceptableOrUnknown(
          data['paused_accum_ms']!,
          _pausedAccumMsMeta,
        ),
      );
    }
    if (data.containsKey('focus_ms_completed')) {
      context.handle(
        _focusMsCompletedMeta,
        focusMsCompleted.isAcceptableOrUnknown(
          data['focus_ms_completed']!,
          _focusMsCompletedMeta,
        ),
      );
    }
    if (data.containsKey('phases_completed')) {
      context.handle(
        _phasesCompletedMeta,
        phasesCompleted.isAcceptableOrUnknown(
          data['phases_completed']!,
          _phasesCompletedMeta,
        ),
      );
    }
    if (data.containsKey('paused_total_ms')) {
      context.handle(
        _pausedTotalMsMeta,
        pausedTotalMs.isAcceptableOrUnknown(
          data['paused_total_ms']!,
          _pausedTotalMsMeta,
        ),
      );
    }
    if (data.containsKey('interruptions')) {
      context.handle(
        _interruptionsMeta,
        interruptions.isAcceptableOrUnknown(
          data['interruptions']!,
          _interruptionsMeta,
        ),
      );
    }
    if (data.containsKey('away_ms')) {
      context.handle(
        _awayMsMeta,
        awayMs.isAcceptableOrUnknown(data['away_ms']!, _awayMsMeta),
      );
    }
    if (data.containsKey('away_started_at')) {
      context.handle(
        _awayStartedAtMeta,
        awayStartedAt.isAcceptableOrUnknown(
          data['away_started_at']!,
          _awayStartedAtMeta,
        ),
      );
    }
    if (data.containsKey('away_cap_at')) {
      context.handle(
        _awayCapAtMeta,
        awayCapAt.isAcceptableOrUnknown(data['away_cap_at']!, _awayCapAtMeta),
      );
    }
    if (data.containsKey('last_seen_at')) {
      context.handle(
        _lastSeenAtMeta,
        lastSeenAt.isAcceptableOrUnknown(
          data['last_seen_at']!,
          _lastSeenAtMeta,
        ),
      );
    }
    if (data.containsKey('strict')) {
      context.handle(
        _strictMeta,
        strict.isAcceptableOrUnknown(data['strict']!, _strictMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FocusStateRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FocusStateRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      )!,
      phase: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phase'],
      )!,
      focusIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}focus_index'],
      )!,
      phaseStartedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}phase_started_at'],
      ),
      phaseDurationMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}phase_duration_ms'],
      )!,
      pausedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}paused_at'],
      ),
      pausedAccumMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}paused_accum_ms'],
      )!,
      focusMsCompleted: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}focus_ms_completed'],
      )!,
      phasesCompleted: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}phases_completed'],
      )!,
      pausedTotalMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}paused_total_ms'],
      )!,
      interruptions: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}interruptions'],
      )!,
      awayMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}away_ms'],
      )!,
      awayStartedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}away_started_at'],
      ),
      awayCapAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}away_cap_at'],
      ),
      lastSeenAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_seen_at'],
      ),
      strict: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}strict'],
      )!,
    );
  }

  @override
  $FocusStatesTable createAlias(String alias) {
    return $FocusStatesTable(attachedDatabase, alias);
  }
}

class FocusStateRow extends DataClass implements Insertable<FocusStateRow> {
  final int id;
  final String sessionId;
  final String phase;
  final int focusIndex;
  final int? phaseStartedAt;
  final int phaseDurationMs;
  final int? pausedAt;
  final int pausedAccumMs;
  final int focusMsCompleted;
  final int phasesCompleted;
  final int pausedTotalMs;
  final int interruptions;
  final int awayMs;
  final int? awayStartedAt;
  final int? awayCapAt;
  final int? lastSeenAt;
  final bool strict;
  const FocusStateRow({
    required this.id,
    required this.sessionId,
    required this.phase,
    required this.focusIndex,
    this.phaseStartedAt,
    required this.phaseDurationMs,
    this.pausedAt,
    required this.pausedAccumMs,
    required this.focusMsCompleted,
    required this.phasesCompleted,
    required this.pausedTotalMs,
    required this.interruptions,
    required this.awayMs,
    this.awayStartedAt,
    this.awayCapAt,
    this.lastSeenAt,
    required this.strict,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['session_id'] = Variable<String>(sessionId);
    map['phase'] = Variable<String>(phase);
    map['focus_index'] = Variable<int>(focusIndex);
    if (!nullToAbsent || phaseStartedAt != null) {
      map['phase_started_at'] = Variable<int>(phaseStartedAt);
    }
    map['phase_duration_ms'] = Variable<int>(phaseDurationMs);
    if (!nullToAbsent || pausedAt != null) {
      map['paused_at'] = Variable<int>(pausedAt);
    }
    map['paused_accum_ms'] = Variable<int>(pausedAccumMs);
    map['focus_ms_completed'] = Variable<int>(focusMsCompleted);
    map['phases_completed'] = Variable<int>(phasesCompleted);
    map['paused_total_ms'] = Variable<int>(pausedTotalMs);
    map['interruptions'] = Variable<int>(interruptions);
    map['away_ms'] = Variable<int>(awayMs);
    if (!nullToAbsent || awayStartedAt != null) {
      map['away_started_at'] = Variable<int>(awayStartedAt);
    }
    if (!nullToAbsent || awayCapAt != null) {
      map['away_cap_at'] = Variable<int>(awayCapAt);
    }
    if (!nullToAbsent || lastSeenAt != null) {
      map['last_seen_at'] = Variable<int>(lastSeenAt);
    }
    map['strict'] = Variable<bool>(strict);
    return map;
  }

  FocusStatesCompanion toCompanion(bool nullToAbsent) {
    return FocusStatesCompanion(
      id: Value(id),
      sessionId: Value(sessionId),
      phase: Value(phase),
      focusIndex: Value(focusIndex),
      phaseStartedAt: phaseStartedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(phaseStartedAt),
      phaseDurationMs: Value(phaseDurationMs),
      pausedAt: pausedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(pausedAt),
      pausedAccumMs: Value(pausedAccumMs),
      focusMsCompleted: Value(focusMsCompleted),
      phasesCompleted: Value(phasesCompleted),
      pausedTotalMs: Value(pausedTotalMs),
      interruptions: Value(interruptions),
      awayMs: Value(awayMs),
      awayStartedAt: awayStartedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(awayStartedAt),
      awayCapAt: awayCapAt == null && nullToAbsent
          ? const Value.absent()
          : Value(awayCapAt),
      lastSeenAt: lastSeenAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSeenAt),
      strict: Value(strict),
    );
  }

  factory FocusStateRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FocusStateRow(
      id: serializer.fromJson<int>(json['id']),
      sessionId: serializer.fromJson<String>(json['sessionId']),
      phase: serializer.fromJson<String>(json['phase']),
      focusIndex: serializer.fromJson<int>(json['focusIndex']),
      phaseStartedAt: serializer.fromJson<int?>(json['phaseStartedAt']),
      phaseDurationMs: serializer.fromJson<int>(json['phaseDurationMs']),
      pausedAt: serializer.fromJson<int?>(json['pausedAt']),
      pausedAccumMs: serializer.fromJson<int>(json['pausedAccumMs']),
      focusMsCompleted: serializer.fromJson<int>(json['focusMsCompleted']),
      phasesCompleted: serializer.fromJson<int>(json['phasesCompleted']),
      pausedTotalMs: serializer.fromJson<int>(json['pausedTotalMs']),
      interruptions: serializer.fromJson<int>(json['interruptions']),
      awayMs: serializer.fromJson<int>(json['awayMs']),
      awayStartedAt: serializer.fromJson<int?>(json['awayStartedAt']),
      awayCapAt: serializer.fromJson<int?>(json['awayCapAt']),
      lastSeenAt: serializer.fromJson<int?>(json['lastSeenAt']),
      strict: serializer.fromJson<bool>(json['strict']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'sessionId': serializer.toJson<String>(sessionId),
      'phase': serializer.toJson<String>(phase),
      'focusIndex': serializer.toJson<int>(focusIndex),
      'phaseStartedAt': serializer.toJson<int?>(phaseStartedAt),
      'phaseDurationMs': serializer.toJson<int>(phaseDurationMs),
      'pausedAt': serializer.toJson<int?>(pausedAt),
      'pausedAccumMs': serializer.toJson<int>(pausedAccumMs),
      'focusMsCompleted': serializer.toJson<int>(focusMsCompleted),
      'phasesCompleted': serializer.toJson<int>(phasesCompleted),
      'pausedTotalMs': serializer.toJson<int>(pausedTotalMs),
      'interruptions': serializer.toJson<int>(interruptions),
      'awayMs': serializer.toJson<int>(awayMs),
      'awayStartedAt': serializer.toJson<int?>(awayStartedAt),
      'awayCapAt': serializer.toJson<int?>(awayCapAt),
      'lastSeenAt': serializer.toJson<int?>(lastSeenAt),
      'strict': serializer.toJson<bool>(strict),
    };
  }

  FocusStateRow copyWith({
    int? id,
    String? sessionId,
    String? phase,
    int? focusIndex,
    Value<int?> phaseStartedAt = const Value.absent(),
    int? phaseDurationMs,
    Value<int?> pausedAt = const Value.absent(),
    int? pausedAccumMs,
    int? focusMsCompleted,
    int? phasesCompleted,
    int? pausedTotalMs,
    int? interruptions,
    int? awayMs,
    Value<int?> awayStartedAt = const Value.absent(),
    Value<int?> awayCapAt = const Value.absent(),
    Value<int?> lastSeenAt = const Value.absent(),
    bool? strict,
  }) => FocusStateRow(
    id: id ?? this.id,
    sessionId: sessionId ?? this.sessionId,
    phase: phase ?? this.phase,
    focusIndex: focusIndex ?? this.focusIndex,
    phaseStartedAt: phaseStartedAt.present
        ? phaseStartedAt.value
        : this.phaseStartedAt,
    phaseDurationMs: phaseDurationMs ?? this.phaseDurationMs,
    pausedAt: pausedAt.present ? pausedAt.value : this.pausedAt,
    pausedAccumMs: pausedAccumMs ?? this.pausedAccumMs,
    focusMsCompleted: focusMsCompleted ?? this.focusMsCompleted,
    phasesCompleted: phasesCompleted ?? this.phasesCompleted,
    pausedTotalMs: pausedTotalMs ?? this.pausedTotalMs,
    interruptions: interruptions ?? this.interruptions,
    awayMs: awayMs ?? this.awayMs,
    awayStartedAt: awayStartedAt.present
        ? awayStartedAt.value
        : this.awayStartedAt,
    awayCapAt: awayCapAt.present ? awayCapAt.value : this.awayCapAt,
    lastSeenAt: lastSeenAt.present ? lastSeenAt.value : this.lastSeenAt,
    strict: strict ?? this.strict,
  );
  FocusStateRow copyWithCompanion(FocusStatesCompanion data) {
    return FocusStateRow(
      id: data.id.present ? data.id.value : this.id,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      phase: data.phase.present ? data.phase.value : this.phase,
      focusIndex: data.focusIndex.present
          ? data.focusIndex.value
          : this.focusIndex,
      phaseStartedAt: data.phaseStartedAt.present
          ? data.phaseStartedAt.value
          : this.phaseStartedAt,
      phaseDurationMs: data.phaseDurationMs.present
          ? data.phaseDurationMs.value
          : this.phaseDurationMs,
      pausedAt: data.pausedAt.present ? data.pausedAt.value : this.pausedAt,
      pausedAccumMs: data.pausedAccumMs.present
          ? data.pausedAccumMs.value
          : this.pausedAccumMs,
      focusMsCompleted: data.focusMsCompleted.present
          ? data.focusMsCompleted.value
          : this.focusMsCompleted,
      phasesCompleted: data.phasesCompleted.present
          ? data.phasesCompleted.value
          : this.phasesCompleted,
      pausedTotalMs: data.pausedTotalMs.present
          ? data.pausedTotalMs.value
          : this.pausedTotalMs,
      interruptions: data.interruptions.present
          ? data.interruptions.value
          : this.interruptions,
      awayMs: data.awayMs.present ? data.awayMs.value : this.awayMs,
      awayStartedAt: data.awayStartedAt.present
          ? data.awayStartedAt.value
          : this.awayStartedAt,
      awayCapAt: data.awayCapAt.present ? data.awayCapAt.value : this.awayCapAt,
      lastSeenAt: data.lastSeenAt.present
          ? data.lastSeenAt.value
          : this.lastSeenAt,
      strict: data.strict.present ? data.strict.value : this.strict,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FocusStateRow(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('phase: $phase, ')
          ..write('focusIndex: $focusIndex, ')
          ..write('phaseStartedAt: $phaseStartedAt, ')
          ..write('phaseDurationMs: $phaseDurationMs, ')
          ..write('pausedAt: $pausedAt, ')
          ..write('pausedAccumMs: $pausedAccumMs, ')
          ..write('focusMsCompleted: $focusMsCompleted, ')
          ..write('phasesCompleted: $phasesCompleted, ')
          ..write('pausedTotalMs: $pausedTotalMs, ')
          ..write('interruptions: $interruptions, ')
          ..write('awayMs: $awayMs, ')
          ..write('awayStartedAt: $awayStartedAt, ')
          ..write('awayCapAt: $awayCapAt, ')
          ..write('lastSeenAt: $lastSeenAt, ')
          ..write('strict: $strict')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sessionId,
    phase,
    focusIndex,
    phaseStartedAt,
    phaseDurationMs,
    pausedAt,
    pausedAccumMs,
    focusMsCompleted,
    phasesCompleted,
    pausedTotalMs,
    interruptions,
    awayMs,
    awayStartedAt,
    awayCapAt,
    lastSeenAt,
    strict,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FocusStateRow &&
          other.id == this.id &&
          other.sessionId == this.sessionId &&
          other.phase == this.phase &&
          other.focusIndex == this.focusIndex &&
          other.phaseStartedAt == this.phaseStartedAt &&
          other.phaseDurationMs == this.phaseDurationMs &&
          other.pausedAt == this.pausedAt &&
          other.pausedAccumMs == this.pausedAccumMs &&
          other.focusMsCompleted == this.focusMsCompleted &&
          other.phasesCompleted == this.phasesCompleted &&
          other.pausedTotalMs == this.pausedTotalMs &&
          other.interruptions == this.interruptions &&
          other.awayMs == this.awayMs &&
          other.awayStartedAt == this.awayStartedAt &&
          other.awayCapAt == this.awayCapAt &&
          other.lastSeenAt == this.lastSeenAt &&
          other.strict == this.strict);
}

class FocusStatesCompanion extends UpdateCompanion<FocusStateRow> {
  final Value<int> id;
  final Value<String> sessionId;
  final Value<String> phase;
  final Value<int> focusIndex;
  final Value<int?> phaseStartedAt;
  final Value<int> phaseDurationMs;
  final Value<int?> pausedAt;
  final Value<int> pausedAccumMs;
  final Value<int> focusMsCompleted;
  final Value<int> phasesCompleted;
  final Value<int> pausedTotalMs;
  final Value<int> interruptions;
  final Value<int> awayMs;
  final Value<int?> awayStartedAt;
  final Value<int?> awayCapAt;
  final Value<int?> lastSeenAt;
  final Value<bool> strict;
  const FocusStatesCompanion({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.phase = const Value.absent(),
    this.focusIndex = const Value.absent(),
    this.phaseStartedAt = const Value.absent(),
    this.phaseDurationMs = const Value.absent(),
    this.pausedAt = const Value.absent(),
    this.pausedAccumMs = const Value.absent(),
    this.focusMsCompleted = const Value.absent(),
    this.phasesCompleted = const Value.absent(),
    this.pausedTotalMs = const Value.absent(),
    this.interruptions = const Value.absent(),
    this.awayMs = const Value.absent(),
    this.awayStartedAt = const Value.absent(),
    this.awayCapAt = const Value.absent(),
    this.lastSeenAt = const Value.absent(),
    this.strict = const Value.absent(),
  });
  FocusStatesCompanion.insert({
    this.id = const Value.absent(),
    required String sessionId,
    required String phase,
    required int focusIndex,
    this.phaseStartedAt = const Value.absent(),
    required int phaseDurationMs,
    this.pausedAt = const Value.absent(),
    this.pausedAccumMs = const Value.absent(),
    this.focusMsCompleted = const Value.absent(),
    this.phasesCompleted = const Value.absent(),
    this.pausedTotalMs = const Value.absent(),
    this.interruptions = const Value.absent(),
    this.awayMs = const Value.absent(),
    this.awayStartedAt = const Value.absent(),
    this.awayCapAt = const Value.absent(),
    this.lastSeenAt = const Value.absent(),
    this.strict = const Value.absent(),
  }) : sessionId = Value(sessionId),
       phase = Value(phase),
       focusIndex = Value(focusIndex),
       phaseDurationMs = Value(phaseDurationMs);
  static Insertable<FocusStateRow> custom({
    Expression<int>? id,
    Expression<String>? sessionId,
    Expression<String>? phase,
    Expression<int>? focusIndex,
    Expression<int>? phaseStartedAt,
    Expression<int>? phaseDurationMs,
    Expression<int>? pausedAt,
    Expression<int>? pausedAccumMs,
    Expression<int>? focusMsCompleted,
    Expression<int>? phasesCompleted,
    Expression<int>? pausedTotalMs,
    Expression<int>? interruptions,
    Expression<int>? awayMs,
    Expression<int>? awayStartedAt,
    Expression<int>? awayCapAt,
    Expression<int>? lastSeenAt,
    Expression<bool>? strict,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionId != null) 'session_id': sessionId,
      if (phase != null) 'phase': phase,
      if (focusIndex != null) 'focus_index': focusIndex,
      if (phaseStartedAt != null) 'phase_started_at': phaseStartedAt,
      if (phaseDurationMs != null) 'phase_duration_ms': phaseDurationMs,
      if (pausedAt != null) 'paused_at': pausedAt,
      if (pausedAccumMs != null) 'paused_accum_ms': pausedAccumMs,
      if (focusMsCompleted != null) 'focus_ms_completed': focusMsCompleted,
      if (phasesCompleted != null) 'phases_completed': phasesCompleted,
      if (pausedTotalMs != null) 'paused_total_ms': pausedTotalMs,
      if (interruptions != null) 'interruptions': interruptions,
      if (awayMs != null) 'away_ms': awayMs,
      if (awayStartedAt != null) 'away_started_at': awayStartedAt,
      if (awayCapAt != null) 'away_cap_at': awayCapAt,
      if (lastSeenAt != null) 'last_seen_at': lastSeenAt,
      if (strict != null) 'strict': strict,
    });
  }

  FocusStatesCompanion copyWith({
    Value<int>? id,
    Value<String>? sessionId,
    Value<String>? phase,
    Value<int>? focusIndex,
    Value<int?>? phaseStartedAt,
    Value<int>? phaseDurationMs,
    Value<int?>? pausedAt,
    Value<int>? pausedAccumMs,
    Value<int>? focusMsCompleted,
    Value<int>? phasesCompleted,
    Value<int>? pausedTotalMs,
    Value<int>? interruptions,
    Value<int>? awayMs,
    Value<int?>? awayStartedAt,
    Value<int?>? awayCapAt,
    Value<int?>? lastSeenAt,
    Value<bool>? strict,
  }) {
    return FocusStatesCompanion(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      phase: phase ?? this.phase,
      focusIndex: focusIndex ?? this.focusIndex,
      phaseStartedAt: phaseStartedAt ?? this.phaseStartedAt,
      phaseDurationMs: phaseDurationMs ?? this.phaseDurationMs,
      pausedAt: pausedAt ?? this.pausedAt,
      pausedAccumMs: pausedAccumMs ?? this.pausedAccumMs,
      focusMsCompleted: focusMsCompleted ?? this.focusMsCompleted,
      phasesCompleted: phasesCompleted ?? this.phasesCompleted,
      pausedTotalMs: pausedTotalMs ?? this.pausedTotalMs,
      interruptions: interruptions ?? this.interruptions,
      awayMs: awayMs ?? this.awayMs,
      awayStartedAt: awayStartedAt ?? this.awayStartedAt,
      awayCapAt: awayCapAt ?? this.awayCapAt,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      strict: strict ?? this.strict,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (phase.present) {
      map['phase'] = Variable<String>(phase.value);
    }
    if (focusIndex.present) {
      map['focus_index'] = Variable<int>(focusIndex.value);
    }
    if (phaseStartedAt.present) {
      map['phase_started_at'] = Variable<int>(phaseStartedAt.value);
    }
    if (phaseDurationMs.present) {
      map['phase_duration_ms'] = Variable<int>(phaseDurationMs.value);
    }
    if (pausedAt.present) {
      map['paused_at'] = Variable<int>(pausedAt.value);
    }
    if (pausedAccumMs.present) {
      map['paused_accum_ms'] = Variable<int>(pausedAccumMs.value);
    }
    if (focusMsCompleted.present) {
      map['focus_ms_completed'] = Variable<int>(focusMsCompleted.value);
    }
    if (phasesCompleted.present) {
      map['phases_completed'] = Variable<int>(phasesCompleted.value);
    }
    if (pausedTotalMs.present) {
      map['paused_total_ms'] = Variable<int>(pausedTotalMs.value);
    }
    if (interruptions.present) {
      map['interruptions'] = Variable<int>(interruptions.value);
    }
    if (awayMs.present) {
      map['away_ms'] = Variable<int>(awayMs.value);
    }
    if (awayStartedAt.present) {
      map['away_started_at'] = Variable<int>(awayStartedAt.value);
    }
    if (awayCapAt.present) {
      map['away_cap_at'] = Variable<int>(awayCapAt.value);
    }
    if (lastSeenAt.present) {
      map['last_seen_at'] = Variable<int>(lastSeenAt.value);
    }
    if (strict.present) {
      map['strict'] = Variable<bool>(strict.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FocusStatesCompanion(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('phase: $phase, ')
          ..write('focusIndex: $focusIndex, ')
          ..write('phaseStartedAt: $phaseStartedAt, ')
          ..write('phaseDurationMs: $phaseDurationMs, ')
          ..write('pausedAt: $pausedAt, ')
          ..write('pausedAccumMs: $pausedAccumMs, ')
          ..write('focusMsCompleted: $focusMsCompleted, ')
          ..write('phasesCompleted: $phasesCompleted, ')
          ..write('pausedTotalMs: $pausedTotalMs, ')
          ..write('interruptions: $interruptions, ')
          ..write('awayMs: $awayMs, ')
          ..write('awayStartedAt: $awayStartedAt, ')
          ..write('awayCapAt: $awayCapAt, ')
          ..write('lastSeenAt: $lastSeenAt, ')
          ..write('strict: $strict')
          ..write(')'))
        .toString();
  }
}

class $PresetsTable extends Presets with TableInfo<$PresetsTable, PresetRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PresetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
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
  static const VerificationMeta _focusMinMeta = const VerificationMeta(
    'focusMin',
  );
  @override
  late final GeneratedColumn<int> focusMin = GeneratedColumn<int>(
    'focus_min',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _shortMinMeta = const VerificationMeta(
    'shortMin',
  );
  @override
  late final GeneratedColumn<int> shortMin = GeneratedColumn<int>(
    'short_min',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _longMinMeta = const VerificationMeta(
    'longMin',
  );
  @override
  late final GeneratedColumn<int> longMin = GeneratedColumn<int>(
    'long_min',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _longEveryMeta = const VerificationMeta(
    'longEvery',
  );
  @override
  late final GeneratedColumn<int> longEvery = GeneratedColumn<int>(
    'long_every',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortMeta = const VerificationMeta('sort');
  @override
  late final GeneratedColumn<int> sort = GeneratedColumn<int>(
    'sort',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    focusMin,
    shortMin,
    longMin,
    longEvery,
    sort,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'presets';
  @override
  VerificationContext validateIntegrity(
    Insertable<PresetRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('focus_min')) {
      context.handle(
        _focusMinMeta,
        focusMin.isAcceptableOrUnknown(data['focus_min']!, _focusMinMeta),
      );
    } else if (isInserting) {
      context.missing(_focusMinMeta);
    }
    if (data.containsKey('short_min')) {
      context.handle(
        _shortMinMeta,
        shortMin.isAcceptableOrUnknown(data['short_min']!, _shortMinMeta),
      );
    } else if (isInserting) {
      context.missing(_shortMinMeta);
    }
    if (data.containsKey('long_min')) {
      context.handle(
        _longMinMeta,
        longMin.isAcceptableOrUnknown(data['long_min']!, _longMinMeta),
      );
    } else if (isInserting) {
      context.missing(_longMinMeta);
    }
    if (data.containsKey('long_every')) {
      context.handle(
        _longEveryMeta,
        longEvery.isAcceptableOrUnknown(data['long_every']!, _longEveryMeta),
      );
    } else if (isInserting) {
      context.missing(_longEveryMeta);
    }
    if (data.containsKey('sort')) {
      context.handle(
        _sortMeta,
        sort.isAcceptableOrUnknown(data['sort']!, _sortMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PresetRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PresetRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      focusMin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}focus_min'],
      )!,
      shortMin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}short_min'],
      )!,
      longMin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}long_min'],
      )!,
      longEvery: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}long_every'],
      )!,
      sort: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort'],
      )!,
    );
  }

  @override
  $PresetsTable createAlias(String alias) {
    return $PresetsTable(attachedDatabase, alias);
  }
}

class PresetRow extends DataClass implements Insertable<PresetRow> {
  final String id;
  final String name;
  final int focusMin;
  final int shortMin;
  final int longMin;
  final int longEvery;
  final int sort;
  const PresetRow({
    required this.id,
    required this.name,
    required this.focusMin,
    required this.shortMin,
    required this.longMin,
    required this.longEvery,
    required this.sort,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['focus_min'] = Variable<int>(focusMin);
    map['short_min'] = Variable<int>(shortMin);
    map['long_min'] = Variable<int>(longMin);
    map['long_every'] = Variable<int>(longEvery);
    map['sort'] = Variable<int>(sort);
    return map;
  }

  PresetsCompanion toCompanion(bool nullToAbsent) {
    return PresetsCompanion(
      id: Value(id),
      name: Value(name),
      focusMin: Value(focusMin),
      shortMin: Value(shortMin),
      longMin: Value(longMin),
      longEvery: Value(longEvery),
      sort: Value(sort),
    );
  }

  factory PresetRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PresetRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      focusMin: serializer.fromJson<int>(json['focusMin']),
      shortMin: serializer.fromJson<int>(json['shortMin']),
      longMin: serializer.fromJson<int>(json['longMin']),
      longEvery: serializer.fromJson<int>(json['longEvery']),
      sort: serializer.fromJson<int>(json['sort']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'focusMin': serializer.toJson<int>(focusMin),
      'shortMin': serializer.toJson<int>(shortMin),
      'longMin': serializer.toJson<int>(longMin),
      'longEvery': serializer.toJson<int>(longEvery),
      'sort': serializer.toJson<int>(sort),
    };
  }

  PresetRow copyWith({
    String? id,
    String? name,
    int? focusMin,
    int? shortMin,
    int? longMin,
    int? longEvery,
    int? sort,
  }) => PresetRow(
    id: id ?? this.id,
    name: name ?? this.name,
    focusMin: focusMin ?? this.focusMin,
    shortMin: shortMin ?? this.shortMin,
    longMin: longMin ?? this.longMin,
    longEvery: longEvery ?? this.longEvery,
    sort: sort ?? this.sort,
  );
  PresetRow copyWithCompanion(PresetsCompanion data) {
    return PresetRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      focusMin: data.focusMin.present ? data.focusMin.value : this.focusMin,
      shortMin: data.shortMin.present ? data.shortMin.value : this.shortMin,
      longMin: data.longMin.present ? data.longMin.value : this.longMin,
      longEvery: data.longEvery.present ? data.longEvery.value : this.longEvery,
      sort: data.sort.present ? data.sort.value : this.sort,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PresetRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('focusMin: $focusMin, ')
          ..write('shortMin: $shortMin, ')
          ..write('longMin: $longMin, ')
          ..write('longEvery: $longEvery, ')
          ..write('sort: $sort')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, focusMin, shortMin, longMin, longEvery, sort);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PresetRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.focusMin == this.focusMin &&
          other.shortMin == this.shortMin &&
          other.longMin == this.longMin &&
          other.longEvery == this.longEvery &&
          other.sort == this.sort);
}

class PresetsCompanion extends UpdateCompanion<PresetRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<int> focusMin;
  final Value<int> shortMin;
  final Value<int> longMin;
  final Value<int> longEvery;
  final Value<int> sort;
  final Value<int> rowid;
  const PresetsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.focusMin = const Value.absent(),
    this.shortMin = const Value.absent(),
    this.longMin = const Value.absent(),
    this.longEvery = const Value.absent(),
    this.sort = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PresetsCompanion.insert({
    required String id,
    required String name,
    required int focusMin,
    required int shortMin,
    required int longMin,
    required int longEvery,
    this.sort = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       focusMin = Value(focusMin),
       shortMin = Value(shortMin),
       longMin = Value(longMin),
       longEvery = Value(longEvery);
  static Insertable<PresetRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<int>? focusMin,
    Expression<int>? shortMin,
    Expression<int>? longMin,
    Expression<int>? longEvery,
    Expression<int>? sort,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (focusMin != null) 'focus_min': focusMin,
      if (shortMin != null) 'short_min': shortMin,
      if (longMin != null) 'long_min': longMin,
      if (longEvery != null) 'long_every': longEvery,
      if (sort != null) 'sort': sort,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PresetsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<int>? focusMin,
    Value<int>? shortMin,
    Value<int>? longMin,
    Value<int>? longEvery,
    Value<int>? sort,
    Value<int>? rowid,
  }) {
    return PresetsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      focusMin: focusMin ?? this.focusMin,
      shortMin: shortMin ?? this.shortMin,
      longMin: longMin ?? this.longMin,
      longEvery: longEvery ?? this.longEvery,
      sort: sort ?? this.sort,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (focusMin.present) {
      map['focus_min'] = Variable<int>(focusMin.value);
    }
    if (shortMin.present) {
      map['short_min'] = Variable<int>(shortMin.value);
    }
    if (longMin.present) {
      map['long_min'] = Variable<int>(longMin.value);
    }
    if (longEvery.present) {
      map['long_every'] = Variable<int>(longEvery.value);
    }
    if (sort.present) {
      map['sort'] = Variable<int>(sort.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PresetsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('focusMin: $focusMin, ')
          ..write('shortMin: $shortMin, ')
          ..write('longMin: $longMin, ')
          ..write('longEvery: $longEvery, ')
          ..write('sort: $sort, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $HeldRemindersTable extends HeldReminders
    with TableInfo<$HeldRemindersTable, HeldReminderRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HeldRemindersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _notificationIdMeta = const VerificationMeta(
    'notificationId',
  );
  @override
  late final GeneratedColumn<int> notificationId = GeneratedColumn<int>(
    'notification_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _taskIdMeta = const VerificationMeta('taskId');
  @override
  late final GeneratedColumn<String> taskId = GeneratedColumn<String>(
    'task_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _occurrenceDateMeta = const VerificationMeta(
    'occurrenceDate',
  );
  @override
  late final GeneratedColumn<String> occurrenceDate = GeneratedColumn<String>(
    'occurrence_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _originalFireAtMeta = const VerificationMeta(
    'originalFireAt',
  );
  @override
  late final GeneratedColumn<int> originalFireAt = GeneratedColumn<int>(
    'original_fire_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  List<GeneratedColumn> get $columns => [
    notificationId,
    taskId,
    occurrenceDate,
    originalFireAt,
    title,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'held_reminders';
  @override
  VerificationContext validateIntegrity(
    Insertable<HeldReminderRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('notification_id')) {
      context.handle(
        _notificationIdMeta,
        notificationId.isAcceptableOrUnknown(
          data['notification_id']!,
          _notificationIdMeta,
        ),
      );
    }
    if (data.containsKey('task_id')) {
      context.handle(
        _taskIdMeta,
        taskId.isAcceptableOrUnknown(data['task_id']!, _taskIdMeta),
      );
    } else if (isInserting) {
      context.missing(_taskIdMeta);
    }
    if (data.containsKey('occurrence_date')) {
      context.handle(
        _occurrenceDateMeta,
        occurrenceDate.isAcceptableOrUnknown(
          data['occurrence_date']!,
          _occurrenceDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_occurrenceDateMeta);
    }
    if (data.containsKey('original_fire_at')) {
      context.handle(
        _originalFireAtMeta,
        originalFireAt.isAcceptableOrUnknown(
          data['original_fire_at']!,
          _originalFireAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_originalFireAtMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {notificationId};
  @override
  HeldReminderRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HeldReminderRow(
      notificationId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}notification_id'],
      )!,
      taskId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}task_id'],
      )!,
      occurrenceDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}occurrence_date'],
      )!,
      originalFireAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}original_fire_at'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
    );
  }

  @override
  $HeldRemindersTable createAlias(String alias) {
    return $HeldRemindersTable(attachedDatabase, alias);
  }
}

class HeldReminderRow extends DataClass implements Insertable<HeldReminderRow> {
  final int notificationId;
  final String taskId;
  final String occurrenceDate;
  final int originalFireAt;
  final String title;
  const HeldReminderRow({
    required this.notificationId,
    required this.taskId,
    required this.occurrenceDate,
    required this.originalFireAt,
    required this.title,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['notification_id'] = Variable<int>(notificationId);
    map['task_id'] = Variable<String>(taskId);
    map['occurrence_date'] = Variable<String>(occurrenceDate);
    map['original_fire_at'] = Variable<int>(originalFireAt);
    map['title'] = Variable<String>(title);
    return map;
  }

  HeldRemindersCompanion toCompanion(bool nullToAbsent) {
    return HeldRemindersCompanion(
      notificationId: Value(notificationId),
      taskId: Value(taskId),
      occurrenceDate: Value(occurrenceDate),
      originalFireAt: Value(originalFireAt),
      title: Value(title),
    );
  }

  factory HeldReminderRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HeldReminderRow(
      notificationId: serializer.fromJson<int>(json['notificationId']),
      taskId: serializer.fromJson<String>(json['taskId']),
      occurrenceDate: serializer.fromJson<String>(json['occurrenceDate']),
      originalFireAt: serializer.fromJson<int>(json['originalFireAt']),
      title: serializer.fromJson<String>(json['title']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'notificationId': serializer.toJson<int>(notificationId),
      'taskId': serializer.toJson<String>(taskId),
      'occurrenceDate': serializer.toJson<String>(occurrenceDate),
      'originalFireAt': serializer.toJson<int>(originalFireAt),
      'title': serializer.toJson<String>(title),
    };
  }

  HeldReminderRow copyWith({
    int? notificationId,
    String? taskId,
    String? occurrenceDate,
    int? originalFireAt,
    String? title,
  }) => HeldReminderRow(
    notificationId: notificationId ?? this.notificationId,
    taskId: taskId ?? this.taskId,
    occurrenceDate: occurrenceDate ?? this.occurrenceDate,
    originalFireAt: originalFireAt ?? this.originalFireAt,
    title: title ?? this.title,
  );
  HeldReminderRow copyWithCompanion(HeldRemindersCompanion data) {
    return HeldReminderRow(
      notificationId: data.notificationId.present
          ? data.notificationId.value
          : this.notificationId,
      taskId: data.taskId.present ? data.taskId.value : this.taskId,
      occurrenceDate: data.occurrenceDate.present
          ? data.occurrenceDate.value
          : this.occurrenceDate,
      originalFireAt: data.originalFireAt.present
          ? data.originalFireAt.value
          : this.originalFireAt,
      title: data.title.present ? data.title.value : this.title,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HeldReminderRow(')
          ..write('notificationId: $notificationId, ')
          ..write('taskId: $taskId, ')
          ..write('occurrenceDate: $occurrenceDate, ')
          ..write('originalFireAt: $originalFireAt, ')
          ..write('title: $title')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    notificationId,
    taskId,
    occurrenceDate,
    originalFireAt,
    title,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HeldReminderRow &&
          other.notificationId == this.notificationId &&
          other.taskId == this.taskId &&
          other.occurrenceDate == this.occurrenceDate &&
          other.originalFireAt == this.originalFireAt &&
          other.title == this.title);
}

class HeldRemindersCompanion extends UpdateCompanion<HeldReminderRow> {
  final Value<int> notificationId;
  final Value<String> taskId;
  final Value<String> occurrenceDate;
  final Value<int> originalFireAt;
  final Value<String> title;
  const HeldRemindersCompanion({
    this.notificationId = const Value.absent(),
    this.taskId = const Value.absent(),
    this.occurrenceDate = const Value.absent(),
    this.originalFireAt = const Value.absent(),
    this.title = const Value.absent(),
  });
  HeldRemindersCompanion.insert({
    this.notificationId = const Value.absent(),
    required String taskId,
    required String occurrenceDate,
    required int originalFireAt,
    this.title = const Value.absent(),
  }) : taskId = Value(taskId),
       occurrenceDate = Value(occurrenceDate),
       originalFireAt = Value(originalFireAt);
  static Insertable<HeldReminderRow> custom({
    Expression<int>? notificationId,
    Expression<String>? taskId,
    Expression<String>? occurrenceDate,
    Expression<int>? originalFireAt,
    Expression<String>? title,
  }) {
    return RawValuesInsertable({
      if (notificationId != null) 'notification_id': notificationId,
      if (taskId != null) 'task_id': taskId,
      if (occurrenceDate != null) 'occurrence_date': occurrenceDate,
      if (originalFireAt != null) 'original_fire_at': originalFireAt,
      if (title != null) 'title': title,
    });
  }

  HeldRemindersCompanion copyWith({
    Value<int>? notificationId,
    Value<String>? taskId,
    Value<String>? occurrenceDate,
    Value<int>? originalFireAt,
    Value<String>? title,
  }) {
    return HeldRemindersCompanion(
      notificationId: notificationId ?? this.notificationId,
      taskId: taskId ?? this.taskId,
      occurrenceDate: occurrenceDate ?? this.occurrenceDate,
      originalFireAt: originalFireAt ?? this.originalFireAt,
      title: title ?? this.title,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (notificationId.present) {
      map['notification_id'] = Variable<int>(notificationId.value);
    }
    if (taskId.present) {
      map['task_id'] = Variable<String>(taskId.value);
    }
    if (occurrenceDate.present) {
      map['occurrence_date'] = Variable<String>(occurrenceDate.value);
    }
    if (originalFireAt.present) {
      map['original_fire_at'] = Variable<int>(originalFireAt.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HeldRemindersCompanion(')
          ..write('notificationId: $notificationId, ')
          ..write('taskId: $taskId, ')
          ..write('occurrenceDate: $occurrenceDate, ')
          ..write('originalFireAt: $originalFireAt, ')
          ..write('title: $title')
          ..write(')'))
        .toString();
  }
}

class $SettingsTable extends Settings
    with TableInfo<$SettingsTable, SettingRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTable(this.attachedDatabase, [this._alias]);
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
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<SettingRow> instance, {
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
  SettingRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SettingRow(
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
  $SettingsTable createAlias(String alias) {
    return $SettingsTable(attachedDatabase, alias);
  }
}

class SettingRow extends DataClass implements Insertable<SettingRow> {
  final String key;
  final String value;
  const SettingRow({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  SettingsCompanion toCompanion(bool nullToAbsent) {
    return SettingsCompanion(key: Value(key), value: Value(value));
  }

  factory SettingRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SettingRow(
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

  SettingRow copyWith({String? key, String? value}) =>
      SettingRow(key: key ?? this.key, value: value ?? this.value);
  SettingRow copyWithCompanion(SettingsCompanion data) {
    return SettingRow(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SettingRow(')
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
      (other is SettingRow &&
          other.key == this.key &&
          other.value == this.value);
}

class SettingsCompanion extends UpdateCompanion<SettingRow> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const SettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<SettingRow> custom({
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

  SettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return SettingsCompanion(
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
    return (StringBuffer('SettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $TasksTable tasks = $TasksTable(this);
  late final $TaskRemindersTable taskReminders = $TaskRemindersTable(this);
  late final $OccurrenceRecordsTable occurrenceRecords =
      $OccurrenceRecordsTable(this);
  late final $FocusSessionsTable focusSessions = $FocusSessionsTable(this);
  late final $FocusStatesTable focusStates = $FocusStatesTable(this);
  late final $PresetsTable presets = $PresetsTable(this);
  late final $HeldRemindersTable heldReminders = $HeldRemindersTable(this);
  late final $SettingsTable settings = $SettingsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    tasks,
    taskReminders,
    occurrenceRecords,
    focusSessions,
    focusStates,
    presets,
    heldReminders,
    settings,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'tasks',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('task_reminders', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'tasks',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('occurrence_records', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$TasksTableCreateCompanionBuilder = TasksCompanion Function({
  required String id,
  required String title,
  Value<String?> notes,
  required int color,
  Value<String?> tag,
  Value<int> priority,
  Value<bool> allDay,
  required String startDate,
  Value<int?> startMinute,
  Value<int?> durationMin,
  Value<String> repeatKind,
  Value<String?> rrule,
  Value<int?> quotaPerWeek,
  Value<String?> quotaPreferredDays,
  Value<String?> endsOn,
  Value<int?> endsAfterCount,
  required String seriesId,
  Value<String?> timeZone,
  required int createdAt,
  required int updatedAt,
  Value<int?> deletedAt,
  Value<int> rowid,
});
typedef $$TasksTableUpdateCompanionBuilder = TasksCompanion Function({
  Value<String> id,
  Value<String> title,
  Value<String?> notes,
  Value<int> color,
  Value<String?> tag,
  Value<int> priority,
  Value<bool> allDay,
  Value<String> startDate,
  Value<int?> startMinute,
  Value<int?> durationMin,
  Value<String> repeatKind,
  Value<String?> rrule,
  Value<int?> quotaPerWeek,
  Value<String?> quotaPreferredDays,
  Value<String?> endsOn,
  Value<int?> endsAfterCount,
  Value<String> seriesId,
  Value<String?> timeZone,
  Value<int> createdAt,
  Value<int> updatedAt,
  Value<int?> deletedAt,
  Value<int> rowid,
});

final class $$TasksTableReferences
    extends BaseReferences<_$AppDatabase, $TasksTable, TaskRow> {
  $$TasksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$TaskRemindersTable, List<TaskReminderRow>>
  _taskRemindersRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.taskReminders,
    aliasName: 'tasks__id__task_reminders__task_id',
  );

  $$TaskRemindersTableProcessedTableManager get taskRemindersRefs {
    final manager = $$TaskRemindersTableTableManager(
      $_db,
      $_db.taskReminders,
    ).filter((f) => f.taskId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_taskRemindersRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$OccurrenceRecordsTable, List<OccurrenceRecordRow>>
  _occurrenceRecordsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.occurrenceRecords,
        aliasName: 'tasks__id__occurrence_records__task_id',
      );

  $$OccurrenceRecordsTableProcessedTableManager get occurrenceRecordsRefs {
    final manager = $$OccurrenceRecordsTableTableManager(
      $_db,
      $_db.occurrenceRecords,
    ).filter((f) => f.taskId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _occurrenceRecordsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$TasksTableFilterComposer extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tag => $composableBuilder(
    column: $table.tag,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get allDay => $composableBuilder(
    column: $table.allDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startMinute => $composableBuilder(
    column: $table.startMinute,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMin => $composableBuilder(
    column: $table.durationMin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get repeatKind => $composableBuilder(
    column: $table.repeatKind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rrule => $composableBuilder(
    column: $table.rrule,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get quotaPerWeek => $composableBuilder(
    column: $table.quotaPerWeek,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get quotaPreferredDays => $composableBuilder(
    column: $table.quotaPreferredDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get endsOn => $composableBuilder(
    column: $table.endsOn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endsAfterCount => $composableBuilder(
    column: $table.endsAfterCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get seriesId => $composableBuilder(
    column: $table.seriesId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get timeZone => $composableBuilder(
    column: $table.timeZone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> taskRemindersRefs(
    Expression<bool> Function($$TaskRemindersTableFilterComposer f) f,
  ) {
    final $$TaskRemindersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.taskReminders,
      getReferencedColumn: (t) => t.taskId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TaskRemindersTableFilterComposer(
            $db: $db,
            $table: $db.taskReminders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> occurrenceRecordsRefs(
    Expression<bool> Function($$OccurrenceRecordsTableFilterComposer f) f,
  ) {
    final $$OccurrenceRecordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.occurrenceRecords,
      getReferencedColumn: (t) => t.taskId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OccurrenceRecordsTableFilterComposer(
            $db: $db,
            $table: $db.occurrenceRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
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
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tag => $composableBuilder(
    column: $table.tag,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get allDay => $composableBuilder(
    column: $table.allDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startMinute => $composableBuilder(
    column: $table.startMinute,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMin => $composableBuilder(
    column: $table.durationMin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get repeatKind => $composableBuilder(
    column: $table.repeatKind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rrule => $composableBuilder(
    column: $table.rrule,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get quotaPerWeek => $composableBuilder(
    column: $table.quotaPerWeek,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get quotaPreferredDays => $composableBuilder(
    column: $table.quotaPreferredDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get endsOn => $composableBuilder(
    column: $table.endsOn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endsAfterCount => $composableBuilder(
    column: $table.endsAfterCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get seriesId => $composableBuilder(
    column: $table.seriesId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get timeZone => $composableBuilder(
    column: $table.timeZone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
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
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<int> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<String> get tag =>
      $composableBuilder(column: $table.tag, builder: (column) => column);

  GeneratedColumn<int> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<bool> get allDay =>
      $composableBuilder(column: $table.allDay, builder: (column) => column);

  GeneratedColumn<String> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<int> get startMinute => $composableBuilder(
    column: $table.startMinute,
    builder: (column) => column,
  );

  GeneratedColumn<int> get durationMin => $composableBuilder(
    column: $table.durationMin,
    builder: (column) => column,
  );

  GeneratedColumn<String> get repeatKind => $composableBuilder(
    column: $table.repeatKind,
    builder: (column) => column,
  );

  GeneratedColumn<String> get rrule =>
      $composableBuilder(column: $table.rrule, builder: (column) => column);

  GeneratedColumn<int> get quotaPerWeek => $composableBuilder(
    column: $table.quotaPerWeek,
    builder: (column) => column,
  );

  GeneratedColumn<String> get quotaPreferredDays => $composableBuilder(
    column: $table.quotaPreferredDays,
    builder: (column) => column,
  );

  GeneratedColumn<String> get endsOn =>
      $composableBuilder(column: $table.endsOn, builder: (column) => column);

  GeneratedColumn<int> get endsAfterCount => $composableBuilder(
    column: $table.endsAfterCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get seriesId =>
      $composableBuilder(column: $table.seriesId, builder: (column) => column);

  GeneratedColumn<String> get timeZone =>
      $composableBuilder(column: $table.timeZone, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  Expression<T> taskRemindersRefs<T extends Object>(
    Expression<T> Function($$TaskRemindersTableAnnotationComposer a) f,
  ) {
    final $$TaskRemindersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.taskReminders,
      getReferencedColumn: (t) => t.taskId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TaskRemindersTableAnnotationComposer(
            $db: $db,
            $table: $db.taskReminders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> occurrenceRecordsRefs<T extends Object>(
    Expression<T> Function($$OccurrenceRecordsTableAnnotationComposer a) f,
  ) {
    final $$OccurrenceRecordsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.occurrenceRecords,
          getReferencedColumn: (t) => t.taskId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$OccurrenceRecordsTableAnnotationComposer(
                $db: $db,
                $table: $db.occurrenceRecords,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$TasksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TasksTable,
          TaskRow,
          $$TasksTableFilterComposer,
          $$TasksTableOrderingComposer,
          $$TasksTableAnnotationComposer,
          $$TasksTableCreateCompanionBuilder,
          $$TasksTableUpdateCompanionBuilder,
          (TaskRow, $$TasksTableReferences),
          TaskRow,
          PrefetchHooks Function({
            bool taskRemindersRefs,
            bool occurrenceRecordsRefs,
          })
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
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int> color = const Value.absent(),
                Value<String?> tag = const Value.absent(),
                Value<int> priority = const Value.absent(),
                Value<bool> allDay = const Value.absent(),
                Value<String> startDate = const Value.absent(),
                Value<int?> startMinute = const Value.absent(),
                Value<int?> durationMin = const Value.absent(),
                Value<String> repeatKind = const Value.absent(),
                Value<String?> rrule = const Value.absent(),
                Value<int?> quotaPerWeek = const Value.absent(),
                Value<String?> quotaPreferredDays = const Value.absent(),
                Value<String?> endsOn = const Value.absent(),
                Value<int?> endsAfterCount = const Value.absent(),
                Value<String> seriesId = const Value.absent(),
                Value<String?> timeZone = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TasksCompanion(
                id: id,
                title: title,
                notes: notes,
                color: color,
                tag: tag,
                priority: priority,
                allDay: allDay,
                startDate: startDate,
                startMinute: startMinute,
                durationMin: durationMin,
                repeatKind: repeatKind,
                rrule: rrule,
                quotaPerWeek: quotaPerWeek,
                quotaPreferredDays: quotaPreferredDays,
                endsOn: endsOn,
                endsAfterCount: endsAfterCount,
                seriesId: seriesId,
                timeZone: timeZone,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                Value<String?> notes = const Value.absent(),
                required int color,
                Value<String?> tag = const Value.absent(),
                Value<int> priority = const Value.absent(),
                Value<bool> allDay = const Value.absent(),
                required String startDate,
                Value<int?> startMinute = const Value.absent(),
                Value<int?> durationMin = const Value.absent(),
                Value<String> repeatKind = const Value.absent(),
                Value<String?> rrule = const Value.absent(),
                Value<int?> quotaPerWeek = const Value.absent(),
                Value<String?> quotaPreferredDays = const Value.absent(),
                Value<String?> endsOn = const Value.absent(),
                Value<int?> endsAfterCount = const Value.absent(),
                required String seriesId,
                Value<String?> timeZone = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<int?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TasksCompanion.insert(
                id: id,
                title: title,
                notes: notes,
                color: color,
                tag: tag,
                priority: priority,
                allDay: allDay,
                startDate: startDate,
                startMinute: startMinute,
                durationMin: durationMin,
                repeatKind: repeatKind,
                rrule: rrule,
                quotaPerWeek: quotaPerWeek,
                quotaPreferredDays: quotaPreferredDays,
                endsOn: endsOn,
                endsAfterCount: endsAfterCount,
                seriesId: seriesId,
                timeZone: timeZone,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TasksTable, TaskRow>(table),
                  $$TasksTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({taskRemindersRefs = false, occurrenceRecordsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (taskRemindersRefs) db.taskReminders,
                    if (occurrenceRecordsRefs) db.occurrenceRecords,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (taskRemindersRefs)
                        await $_getPrefetchedData<
                          TaskRow,
                          $TasksTable,
                          TaskReminderRow
                        >(
                          currentTable: table,
                          referencedTable: $$TasksTableReferences
                              ._taskRemindersRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TasksTableReferences(
                                db,
                                table,
                                p0,
                              ).taskRemindersRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.taskId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (occurrenceRecordsRefs)
                        await $_getPrefetchedData<
                          TaskRow,
                          $TasksTable,
                          OccurrenceRecordRow
                        >(
                          currentTable: table,
                          referencedTable: $$TasksTableReferences
                              ._occurrenceRecordsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TasksTableReferences(
                                db,
                                table,
                                p0,
                              ).occurrenceRecordsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.taskId == item.id,
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

typedef $$TasksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TasksTable,
      TaskRow,
      $$TasksTableFilterComposer,
      $$TasksTableOrderingComposer,
      $$TasksTableAnnotationComposer,
      $$TasksTableCreateCompanionBuilder,
      $$TasksTableUpdateCompanionBuilder,
      (TaskRow, $$TasksTableReferences),
      TaskRow,
      PrefetchHooks Function({
        bool taskRemindersRefs,
        bool occurrenceRecordsRefs,
      })
    >;
typedef $$TaskRemindersTableCreateCompanionBuilder =
    TaskRemindersCompanion Function({
      required String id,
      required String taskId,
      required int offsetMin,
      Value<int?> atMinute,
      Value<int> rowid,
    });
typedef $$TaskRemindersTableUpdateCompanionBuilder =
    TaskRemindersCompanion Function({
      Value<String> id,
      Value<String> taskId,
      Value<int> offsetMin,
      Value<int?> atMinute,
      Value<int> rowid,
    });

final class $$TaskRemindersTableReferences
    extends
        BaseReferences<_$AppDatabase, $TaskRemindersTable, TaskReminderRow> {
  $$TaskRemindersTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $TasksTable _taskIdTable(_$AppDatabase db) =>
      db.tasks.createAlias('task_reminders__task_id__tasks__id');

  $$TasksTableProcessedTableManager get taskId {
    final $_column = $_itemColumn<String>('task_id')!;

    final manager = $$TasksTableTableManager(
      $_db,
      $_db.tasks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_taskIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TaskRemindersTableFilterComposer
    extends Composer<_$AppDatabase, $TaskRemindersTable> {
  $$TaskRemindersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get offsetMin => $composableBuilder(
    column: $table.offsetMin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get atMinute => $composableBuilder(
    column: $table.atMinute,
    builder: (column) => ColumnFilters(column),
  );

  $$TasksTableFilterComposer get taskId {
    final $$TasksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableFilterComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TaskRemindersTableOrderingComposer
    extends Composer<_$AppDatabase, $TaskRemindersTable> {
  $$TaskRemindersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get offsetMin => $composableBuilder(
    column: $table.offsetMin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get atMinute => $composableBuilder(
    column: $table.atMinute,
    builder: (column) => ColumnOrderings(column),
  );

  $$TasksTableOrderingComposer get taskId {
    final $$TasksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableOrderingComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TaskRemindersTableAnnotationComposer
    extends Composer<_$AppDatabase, $TaskRemindersTable> {
  $$TaskRemindersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get offsetMin =>
      $composableBuilder(column: $table.offsetMin, builder: (column) => column);

  GeneratedColumn<int> get atMinute =>
      $composableBuilder(column: $table.atMinute, builder: (column) => column);

  $$TasksTableAnnotationComposer get taskId {
    final $$TasksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableAnnotationComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TaskRemindersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TaskRemindersTable,
          TaskReminderRow,
          $$TaskRemindersTableFilterComposer,
          $$TaskRemindersTableOrderingComposer,
          $$TaskRemindersTableAnnotationComposer,
          $$TaskRemindersTableCreateCompanionBuilder,
          $$TaskRemindersTableUpdateCompanionBuilder,
          (TaskReminderRow, $$TaskRemindersTableReferences),
          TaskReminderRow,
          PrefetchHooks Function({bool taskId})
        > {
  $$TaskRemindersTableTableManager(_$AppDatabase db, $TaskRemindersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TaskRemindersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TaskRemindersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TaskRemindersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> taskId = const Value.absent(),
                Value<int> offsetMin = const Value.absent(),
                Value<int?> atMinute = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TaskRemindersCompanion(
                id: id,
                taskId: taskId,
                offsetMin: offsetMin,
                atMinute: atMinute,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String taskId,
                required int offsetMin,
                Value<int?> atMinute = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TaskRemindersCompanion.insert(
                id: id,
                taskId: taskId,
                offsetMin: offsetMin,
                atMinute: atMinute,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TaskRemindersTable, TaskReminderRow>(table),
                  $$TaskRemindersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({taskId = false}) {
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
                    if (taskId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.taskId,
                        referencedTable: $$TaskRemindersTableReferences
                            ._taskIdTable(db),
                        referencedColumn: $$TaskRemindersTableReferences
                            ._taskIdTable(db)
                            .id,
                      ) as T;
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

typedef $$TaskRemindersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TaskRemindersTable,
      TaskReminderRow,
      $$TaskRemindersTableFilterComposer,
      $$TaskRemindersTableOrderingComposer,
      $$TaskRemindersTableAnnotationComposer,
      $$TaskRemindersTableCreateCompanionBuilder,
      $$TaskRemindersTableUpdateCompanionBuilder,
      (TaskReminderRow, $$TaskRemindersTableReferences),
      TaskReminderRow,
      PrefetchHooks Function({bool taskId})
    >;
typedef $$OccurrenceRecordsTableCreateCompanionBuilder =
    OccurrenceRecordsCompanion Function({
      required String id,
      required String taskId,
      required String occurrenceDate,
      Value<String> status,
      Value<int?> completedAt,
      Value<String?> overrideDate,
      Value<int?> overrideStartMinute,
      Value<String?> overrideTitle,
      Value<bool> late,
      Value<int> rowid,
    });
typedef $$OccurrenceRecordsTableUpdateCompanionBuilder =
    OccurrenceRecordsCompanion Function({
      Value<String> id,
      Value<String> taskId,
      Value<String> occurrenceDate,
      Value<String> status,
      Value<int?> completedAt,
      Value<String?> overrideDate,
      Value<int?> overrideStartMinute,
      Value<String?> overrideTitle,
      Value<bool> late,
      Value<int> rowid,
    });

final class $$OccurrenceRecordsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $OccurrenceRecordsTable,
          OccurrenceRecordRow
        > {
  $$OccurrenceRecordsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $TasksTable _taskIdTable(_$AppDatabase db) =>
      db.tasks.createAlias('occurrence_records__task_id__tasks__id');

  $$TasksTableProcessedTableManager get taskId {
    final $_column = $_itemColumn<String>('task_id')!;

    final manager = $$TasksTableTableManager(
      $_db,
      $_db.tasks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_taskIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$OccurrenceRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $OccurrenceRecordsTable> {
  $$OccurrenceRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get occurrenceDate => $composableBuilder(
    column: $table.occurrenceDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get overrideDate => $composableBuilder(
    column: $table.overrideDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get overrideStartMinute => $composableBuilder(
    column: $table.overrideStartMinute,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get overrideTitle => $composableBuilder(
    column: $table.overrideTitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get late => $composableBuilder(
    column: $table.late,
    builder: (column) => ColumnFilters(column),
  );

  $$TasksTableFilterComposer get taskId {
    final $$TasksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableFilterComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$OccurrenceRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $OccurrenceRecordsTable> {
  $$OccurrenceRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get occurrenceDate => $composableBuilder(
    column: $table.occurrenceDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get overrideDate => $composableBuilder(
    column: $table.overrideDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get overrideStartMinute => $composableBuilder(
    column: $table.overrideStartMinute,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get overrideTitle => $composableBuilder(
    column: $table.overrideTitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get late => $composableBuilder(
    column: $table.late,
    builder: (column) => ColumnOrderings(column),
  );

  $$TasksTableOrderingComposer get taskId {
    final $$TasksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableOrderingComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$OccurrenceRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $OccurrenceRecordsTable> {
  $$OccurrenceRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get occurrenceDate => $composableBuilder(
    column: $table.occurrenceDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get overrideDate => $composableBuilder(
    column: $table.overrideDate,
    builder: (column) => column,
  );

  GeneratedColumn<int> get overrideStartMinute => $composableBuilder(
    column: $table.overrideStartMinute,
    builder: (column) => column,
  );

  GeneratedColumn<String> get overrideTitle => $composableBuilder(
    column: $table.overrideTitle,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get late =>
      $composableBuilder(column: $table.late, builder: (column) => column);

  $$TasksTableAnnotationComposer get taskId {
    final $$TasksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableAnnotationComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$OccurrenceRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OccurrenceRecordsTable,
          OccurrenceRecordRow,
          $$OccurrenceRecordsTableFilterComposer,
          $$OccurrenceRecordsTableOrderingComposer,
          $$OccurrenceRecordsTableAnnotationComposer,
          $$OccurrenceRecordsTableCreateCompanionBuilder,
          $$OccurrenceRecordsTableUpdateCompanionBuilder,
          (OccurrenceRecordRow, $$OccurrenceRecordsTableReferences),
          OccurrenceRecordRow,
          PrefetchHooks Function({bool taskId})
        > {
  $$OccurrenceRecordsTableTableManager(
    _$AppDatabase db,
    $OccurrenceRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OccurrenceRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OccurrenceRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OccurrenceRecordsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> taskId = const Value.absent(),
                Value<String> occurrenceDate = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int?> completedAt = const Value.absent(),
                Value<String?> overrideDate = const Value.absent(),
                Value<int?> overrideStartMinute = const Value.absent(),
                Value<String?> overrideTitle = const Value.absent(),
                Value<bool> late = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OccurrenceRecordsCompanion(
                id: id,
                taskId: taskId,
                occurrenceDate: occurrenceDate,
                status: status,
                completedAt: completedAt,
                overrideDate: overrideDate,
                overrideStartMinute: overrideStartMinute,
                overrideTitle: overrideTitle,
                late: late,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String taskId,
                required String occurrenceDate,
                Value<String> status = const Value.absent(),
                Value<int?> completedAt = const Value.absent(),
                Value<String?> overrideDate = const Value.absent(),
                Value<int?> overrideStartMinute = const Value.absent(),
                Value<String?> overrideTitle = const Value.absent(),
                Value<bool> late = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OccurrenceRecordsCompanion.insert(
                id: id,
                taskId: taskId,
                occurrenceDate: occurrenceDate,
                status: status,
                completedAt: completedAt,
                overrideDate: overrideDate,
                overrideStartMinute: overrideStartMinute,
                overrideTitle: overrideTitle,
                late: late,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$OccurrenceRecordsTable, OccurrenceRecordRow>(
                    table,
                  ),
                  $$OccurrenceRecordsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({taskId = false}) {
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
                    if (taskId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.taskId,
                        referencedTable: $$OccurrenceRecordsTableReferences
                            ._taskIdTable(db),
                        referencedColumn: $$OccurrenceRecordsTableReferences
                            ._taskIdTable(db)
                            .id,
                      ) as T;
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

typedef $$OccurrenceRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OccurrenceRecordsTable,
      OccurrenceRecordRow,
      $$OccurrenceRecordsTableFilterComposer,
      $$OccurrenceRecordsTableOrderingComposer,
      $$OccurrenceRecordsTableAnnotationComposer,
      $$OccurrenceRecordsTableCreateCompanionBuilder,
      $$OccurrenceRecordsTableUpdateCompanionBuilder,
      (OccurrenceRecordRow, $$OccurrenceRecordsTableReferences),
      OccurrenceRecordRow,
      PrefetchHooks Function({bool taskId})
    >;
typedef $$FocusSessionsTableCreateCompanionBuilder =
    FocusSessionsCompanion Function({
      required String id,
      required int startedAt,
      Value<int?> endedAt,
      required int plannedFocusMin,
      required int shortBreakMin,
      required int longBreakMin,
      required int longEvery,
      Value<int> focusMsCompleted,
      Value<int> phasesCompleted,
      Value<bool> endedEarly,
      Value<String?> linkedTaskId,
      Value<String?> linkedOccurrenceDate,
      Value<int> pausedMs,
      Value<int> awayMs,
      Value<int> interruptions,
      Value<String?> distractions,
      Value<int> rowid,
    });
typedef $$FocusSessionsTableUpdateCompanionBuilder =
    FocusSessionsCompanion Function({
      Value<String> id,
      Value<int> startedAt,
      Value<int?> endedAt,
      Value<int> plannedFocusMin,
      Value<int> shortBreakMin,
      Value<int> longBreakMin,
      Value<int> longEvery,
      Value<int> focusMsCompleted,
      Value<int> phasesCompleted,
      Value<bool> endedEarly,
      Value<String?> linkedTaskId,
      Value<String?> linkedOccurrenceDate,
      Value<int> pausedMs,
      Value<int> awayMs,
      Value<int> interruptions,
      Value<String?> distractions,
      Value<int> rowid,
    });

class $$FocusSessionsTableFilterComposer
    extends Composer<_$AppDatabase, $FocusSessionsTable> {
  $$FocusSessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get plannedFocusMin => $composableBuilder(
    column: $table.plannedFocusMin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get shortBreakMin => $composableBuilder(
    column: $table.shortBreakMin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get longBreakMin => $composableBuilder(
    column: $table.longBreakMin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get longEvery => $composableBuilder(
    column: $table.longEvery,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get focusMsCompleted => $composableBuilder(
    column: $table.focusMsCompleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get phasesCompleted => $composableBuilder(
    column: $table.phasesCompleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get endedEarly => $composableBuilder(
    column: $table.endedEarly,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get linkedTaskId => $composableBuilder(
    column: $table.linkedTaskId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get linkedOccurrenceDate => $composableBuilder(
    column: $table.linkedOccurrenceDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pausedMs => $composableBuilder(
    column: $table.pausedMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get awayMs => $composableBuilder(
    column: $table.awayMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get interruptions => $composableBuilder(
    column: $table.interruptions,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get distractions => $composableBuilder(
    column: $table.distractions,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FocusSessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $FocusSessionsTable> {
  $$FocusSessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get plannedFocusMin => $composableBuilder(
    column: $table.plannedFocusMin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get shortBreakMin => $composableBuilder(
    column: $table.shortBreakMin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get longBreakMin => $composableBuilder(
    column: $table.longBreakMin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get longEvery => $composableBuilder(
    column: $table.longEvery,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get focusMsCompleted => $composableBuilder(
    column: $table.focusMsCompleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get phasesCompleted => $composableBuilder(
    column: $table.phasesCompleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get endedEarly => $composableBuilder(
    column: $table.endedEarly,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get linkedTaskId => $composableBuilder(
    column: $table.linkedTaskId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get linkedOccurrenceDate => $composableBuilder(
    column: $table.linkedOccurrenceDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pausedMs => $composableBuilder(
    column: $table.pausedMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get awayMs => $composableBuilder(
    column: $table.awayMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get interruptions => $composableBuilder(
    column: $table.interruptions,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get distractions => $composableBuilder(
    column: $table.distractions,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FocusSessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FocusSessionsTable> {
  $$FocusSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<int> get endedAt =>
      $composableBuilder(column: $table.endedAt, builder: (column) => column);

  GeneratedColumn<int> get plannedFocusMin => $composableBuilder(
    column: $table.plannedFocusMin,
    builder: (column) => column,
  );

  GeneratedColumn<int> get shortBreakMin => $composableBuilder(
    column: $table.shortBreakMin,
    builder: (column) => column,
  );

  GeneratedColumn<int> get longBreakMin => $composableBuilder(
    column: $table.longBreakMin,
    builder: (column) => column,
  );

  GeneratedColumn<int> get longEvery =>
      $composableBuilder(column: $table.longEvery, builder: (column) => column);

  GeneratedColumn<int> get focusMsCompleted => $composableBuilder(
    column: $table.focusMsCompleted,
    builder: (column) => column,
  );

  GeneratedColumn<int> get phasesCompleted => $composableBuilder(
    column: $table.phasesCompleted,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get endedEarly => $composableBuilder(
    column: $table.endedEarly,
    builder: (column) => column,
  );

  GeneratedColumn<String> get linkedTaskId => $composableBuilder(
    column: $table.linkedTaskId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get linkedOccurrenceDate => $composableBuilder(
    column: $table.linkedOccurrenceDate,
    builder: (column) => column,
  );

  GeneratedColumn<int> get pausedMs =>
      $composableBuilder(column: $table.pausedMs, builder: (column) => column);

  GeneratedColumn<int> get awayMs =>
      $composableBuilder(column: $table.awayMs, builder: (column) => column);

  GeneratedColumn<int> get interruptions => $composableBuilder(
    column: $table.interruptions,
    builder: (column) => column,
  );

  GeneratedColumn<String> get distractions => $composableBuilder(
    column: $table.distractions,
    builder: (column) => column,
  );
}

class $$FocusSessionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FocusSessionsTable,
          FocusSessionRow,
          $$FocusSessionsTableFilterComposer,
          $$FocusSessionsTableOrderingComposer,
          $$FocusSessionsTableAnnotationComposer,
          $$FocusSessionsTableCreateCompanionBuilder,
          $$FocusSessionsTableUpdateCompanionBuilder,
          (
            FocusSessionRow,
            BaseReferences<_$AppDatabase, $FocusSessionsTable, FocusSessionRow>,
          ),
          FocusSessionRow,
          PrefetchHooks Function()
        > {
  $$FocusSessionsTableTableManager(_$AppDatabase db, $FocusSessionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FocusSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FocusSessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FocusSessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> startedAt = const Value.absent(),
                Value<int?> endedAt = const Value.absent(),
                Value<int> plannedFocusMin = const Value.absent(),
                Value<int> shortBreakMin = const Value.absent(),
                Value<int> longBreakMin = const Value.absent(),
                Value<int> longEvery = const Value.absent(),
                Value<int> focusMsCompleted = const Value.absent(),
                Value<int> phasesCompleted = const Value.absent(),
                Value<bool> endedEarly = const Value.absent(),
                Value<String?> linkedTaskId = const Value.absent(),
                Value<String?> linkedOccurrenceDate = const Value.absent(),
                Value<int> pausedMs = const Value.absent(),
                Value<int> awayMs = const Value.absent(),
                Value<int> interruptions = const Value.absent(),
                Value<String?> distractions = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FocusSessionsCompanion(
                id: id,
                startedAt: startedAt,
                endedAt: endedAt,
                plannedFocusMin: plannedFocusMin,
                shortBreakMin: shortBreakMin,
                longBreakMin: longBreakMin,
                longEvery: longEvery,
                focusMsCompleted: focusMsCompleted,
                phasesCompleted: phasesCompleted,
                endedEarly: endedEarly,
                linkedTaskId: linkedTaskId,
                linkedOccurrenceDate: linkedOccurrenceDate,
                pausedMs: pausedMs,
                awayMs: awayMs,
                interruptions: interruptions,
                distractions: distractions,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int startedAt,
                Value<int?> endedAt = const Value.absent(),
                required int plannedFocusMin,
                required int shortBreakMin,
                required int longBreakMin,
                required int longEvery,
                Value<int> focusMsCompleted = const Value.absent(),
                Value<int> phasesCompleted = const Value.absent(),
                Value<bool> endedEarly = const Value.absent(),
                Value<String?> linkedTaskId = const Value.absent(),
                Value<String?> linkedOccurrenceDate = const Value.absent(),
                Value<int> pausedMs = const Value.absent(),
                Value<int> awayMs = const Value.absent(),
                Value<int> interruptions = const Value.absent(),
                Value<String?> distractions = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FocusSessionsCompanion.insert(
                id: id,
                startedAt: startedAt,
                endedAt: endedAt,
                plannedFocusMin: plannedFocusMin,
                shortBreakMin: shortBreakMin,
                longBreakMin: longBreakMin,
                longEvery: longEvery,
                focusMsCompleted: focusMsCompleted,
                phasesCompleted: phasesCompleted,
                endedEarly: endedEarly,
                linkedTaskId: linkedTaskId,
                linkedOccurrenceDate: linkedOccurrenceDate,
                pausedMs: pausedMs,
                awayMs: awayMs,
                interruptions: interruptions,
                distractions: distractions,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$FocusSessionsTable, FocusSessionRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $FocusSessionsTable,
                    FocusSessionRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FocusSessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FocusSessionsTable,
      FocusSessionRow,
      $$FocusSessionsTableFilterComposer,
      $$FocusSessionsTableOrderingComposer,
      $$FocusSessionsTableAnnotationComposer,
      $$FocusSessionsTableCreateCompanionBuilder,
      $$FocusSessionsTableUpdateCompanionBuilder,
      (
        FocusSessionRow,
        BaseReferences<_$AppDatabase, $FocusSessionsTable, FocusSessionRow>,
      ),
      FocusSessionRow,
      PrefetchHooks Function()
    >;
typedef $$FocusStatesTableCreateCompanionBuilder =
    FocusStatesCompanion Function({
      Value<int> id,
      required String sessionId,
      required String phase,
      required int focusIndex,
      Value<int?> phaseStartedAt,
      required int phaseDurationMs,
      Value<int?> pausedAt,
      Value<int> pausedAccumMs,
      Value<int> focusMsCompleted,
      Value<int> phasesCompleted,
      Value<int> pausedTotalMs,
      Value<int> interruptions,
      Value<int> awayMs,
      Value<int?> awayStartedAt,
      Value<int?> awayCapAt,
      Value<int?> lastSeenAt,
      Value<bool> strict,
    });
typedef $$FocusStatesTableUpdateCompanionBuilder =
    FocusStatesCompanion Function({
      Value<int> id,
      Value<String> sessionId,
      Value<String> phase,
      Value<int> focusIndex,
      Value<int?> phaseStartedAt,
      Value<int> phaseDurationMs,
      Value<int?> pausedAt,
      Value<int> pausedAccumMs,
      Value<int> focusMsCompleted,
      Value<int> phasesCompleted,
      Value<int> pausedTotalMs,
      Value<int> interruptions,
      Value<int> awayMs,
      Value<int?> awayStartedAt,
      Value<int?> awayCapAt,
      Value<int?> lastSeenAt,
      Value<bool> strict,
    });

class $$FocusStatesTableFilterComposer
    extends Composer<_$AppDatabase, $FocusStatesTable> {
  $$FocusStatesTableFilterComposer({
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

  ColumnFilters<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phase => $composableBuilder(
    column: $table.phase,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get focusIndex => $composableBuilder(
    column: $table.focusIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get phaseStartedAt => $composableBuilder(
    column: $table.phaseStartedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get phaseDurationMs => $composableBuilder(
    column: $table.phaseDurationMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pausedAt => $composableBuilder(
    column: $table.pausedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pausedAccumMs => $composableBuilder(
    column: $table.pausedAccumMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get focusMsCompleted => $composableBuilder(
    column: $table.focusMsCompleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get phasesCompleted => $composableBuilder(
    column: $table.phasesCompleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pausedTotalMs => $composableBuilder(
    column: $table.pausedTotalMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get interruptions => $composableBuilder(
    column: $table.interruptions,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get awayMs => $composableBuilder(
    column: $table.awayMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get awayStartedAt => $composableBuilder(
    column: $table.awayStartedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get awayCapAt => $composableBuilder(
    column: $table.awayCapAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastSeenAt => $composableBuilder(
    column: $table.lastSeenAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get strict => $composableBuilder(
    column: $table.strict,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FocusStatesTableOrderingComposer
    extends Composer<_$AppDatabase, $FocusStatesTable> {
  $$FocusStatesTableOrderingComposer({
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

  ColumnOrderings<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phase => $composableBuilder(
    column: $table.phase,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get focusIndex => $composableBuilder(
    column: $table.focusIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get phaseStartedAt => $composableBuilder(
    column: $table.phaseStartedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get phaseDurationMs => $composableBuilder(
    column: $table.phaseDurationMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pausedAt => $composableBuilder(
    column: $table.pausedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pausedAccumMs => $composableBuilder(
    column: $table.pausedAccumMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get focusMsCompleted => $composableBuilder(
    column: $table.focusMsCompleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get phasesCompleted => $composableBuilder(
    column: $table.phasesCompleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pausedTotalMs => $composableBuilder(
    column: $table.pausedTotalMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get interruptions => $composableBuilder(
    column: $table.interruptions,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get awayMs => $composableBuilder(
    column: $table.awayMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get awayStartedAt => $composableBuilder(
    column: $table.awayStartedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get awayCapAt => $composableBuilder(
    column: $table.awayCapAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastSeenAt => $composableBuilder(
    column: $table.lastSeenAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get strict => $composableBuilder(
    column: $table.strict,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FocusStatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $FocusStatesTable> {
  $$FocusStatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => column);

  GeneratedColumn<String> get phase =>
      $composableBuilder(column: $table.phase, builder: (column) => column);

  GeneratedColumn<int> get focusIndex => $composableBuilder(
    column: $table.focusIndex,
    builder: (column) => column,
  );

  GeneratedColumn<int> get phaseStartedAt => $composableBuilder(
    column: $table.phaseStartedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get phaseDurationMs => $composableBuilder(
    column: $table.phaseDurationMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get pausedAt =>
      $composableBuilder(column: $table.pausedAt, builder: (column) => column);

  GeneratedColumn<int> get pausedAccumMs => $composableBuilder(
    column: $table.pausedAccumMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get focusMsCompleted => $composableBuilder(
    column: $table.focusMsCompleted,
    builder: (column) => column,
  );

  GeneratedColumn<int> get phasesCompleted => $composableBuilder(
    column: $table.phasesCompleted,
    builder: (column) => column,
  );

  GeneratedColumn<int> get pausedTotalMs => $composableBuilder(
    column: $table.pausedTotalMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get interruptions => $composableBuilder(
    column: $table.interruptions,
    builder: (column) => column,
  );

  GeneratedColumn<int> get awayMs =>
      $composableBuilder(column: $table.awayMs, builder: (column) => column);

  GeneratedColumn<int> get awayStartedAt => $composableBuilder(
    column: $table.awayStartedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get awayCapAt =>
      $composableBuilder(column: $table.awayCapAt, builder: (column) => column);

  GeneratedColumn<int> get lastSeenAt => $composableBuilder(
    column: $table.lastSeenAt,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get strict =>
      $composableBuilder(column: $table.strict, builder: (column) => column);
}

class $$FocusStatesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FocusStatesTable,
          FocusStateRow,
          $$FocusStatesTableFilterComposer,
          $$FocusStatesTableOrderingComposer,
          $$FocusStatesTableAnnotationComposer,
          $$FocusStatesTableCreateCompanionBuilder,
          $$FocusStatesTableUpdateCompanionBuilder,
          (
            FocusStateRow,
            BaseReferences<_$AppDatabase, $FocusStatesTable, FocusStateRow>,
          ),
          FocusStateRow,
          PrefetchHooks Function()
        > {
  $$FocusStatesTableTableManager(_$AppDatabase db, $FocusStatesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FocusStatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FocusStatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FocusStatesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> sessionId = const Value.absent(),
                Value<String> phase = const Value.absent(),
                Value<int> focusIndex = const Value.absent(),
                Value<int?> phaseStartedAt = const Value.absent(),
                Value<int> phaseDurationMs = const Value.absent(),
                Value<int?> pausedAt = const Value.absent(),
                Value<int> pausedAccumMs = const Value.absent(),
                Value<int> focusMsCompleted = const Value.absent(),
                Value<int> phasesCompleted = const Value.absent(),
                Value<int> pausedTotalMs = const Value.absent(),
                Value<int> interruptions = const Value.absent(),
                Value<int> awayMs = const Value.absent(),
                Value<int?> awayStartedAt = const Value.absent(),
                Value<int?> awayCapAt = const Value.absent(),
                Value<int?> lastSeenAt = const Value.absent(),
                Value<bool> strict = const Value.absent(),
              }) => FocusStatesCompanion(
                id: id,
                sessionId: sessionId,
                phase: phase,
                focusIndex: focusIndex,
                phaseStartedAt: phaseStartedAt,
                phaseDurationMs: phaseDurationMs,
                pausedAt: pausedAt,
                pausedAccumMs: pausedAccumMs,
                focusMsCompleted: focusMsCompleted,
                phasesCompleted: phasesCompleted,
                pausedTotalMs: pausedTotalMs,
                interruptions: interruptions,
                awayMs: awayMs,
                awayStartedAt: awayStartedAt,
                awayCapAt: awayCapAt,
                lastSeenAt: lastSeenAt,
                strict: strict,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String sessionId,
                required String phase,
                required int focusIndex,
                Value<int?> phaseStartedAt = const Value.absent(),
                required int phaseDurationMs,
                Value<int?> pausedAt = const Value.absent(),
                Value<int> pausedAccumMs = const Value.absent(),
                Value<int> focusMsCompleted = const Value.absent(),
                Value<int> phasesCompleted = const Value.absent(),
                Value<int> pausedTotalMs = const Value.absent(),
                Value<int> interruptions = const Value.absent(),
                Value<int> awayMs = const Value.absent(),
                Value<int?> awayStartedAt = const Value.absent(),
                Value<int?> awayCapAt = const Value.absent(),
                Value<int?> lastSeenAt = const Value.absent(),
                Value<bool> strict = const Value.absent(),
              }) => FocusStatesCompanion.insert(
                id: id,
                sessionId: sessionId,
                phase: phase,
                focusIndex: focusIndex,
                phaseStartedAt: phaseStartedAt,
                phaseDurationMs: phaseDurationMs,
                pausedAt: pausedAt,
                pausedAccumMs: pausedAccumMs,
                focusMsCompleted: focusMsCompleted,
                phasesCompleted: phasesCompleted,
                pausedTotalMs: pausedTotalMs,
                interruptions: interruptions,
                awayMs: awayMs,
                awayStartedAt: awayStartedAt,
                awayCapAt: awayCapAt,
                lastSeenAt: lastSeenAt,
                strict: strict,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$FocusStatesTable, FocusStateRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $FocusStatesTable,
                    FocusStateRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FocusStatesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FocusStatesTable,
      FocusStateRow,
      $$FocusStatesTableFilterComposer,
      $$FocusStatesTableOrderingComposer,
      $$FocusStatesTableAnnotationComposer,
      $$FocusStatesTableCreateCompanionBuilder,
      $$FocusStatesTableUpdateCompanionBuilder,
      (
        FocusStateRow,
        BaseReferences<_$AppDatabase, $FocusStatesTable, FocusStateRow>,
      ),
      FocusStateRow,
      PrefetchHooks Function()
    >;
typedef $$PresetsTableCreateCompanionBuilder = PresetsCompanion Function({
  required String id,
  required String name,
  required int focusMin,
  required int shortMin,
  required int longMin,
  required int longEvery,
  Value<int> sort,
  Value<int> rowid,
});
typedef $$PresetsTableUpdateCompanionBuilder = PresetsCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<int> focusMin,
  Value<int> shortMin,
  Value<int> longMin,
  Value<int> longEvery,
  Value<int> sort,
  Value<int> rowid,
});

class $$PresetsTableFilterComposer
    extends Composer<_$AppDatabase, $PresetsTable> {
  $$PresetsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get focusMin => $composableBuilder(
    column: $table.focusMin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get shortMin => $composableBuilder(
    column: $table.shortMin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get longMin => $composableBuilder(
    column: $table.longMin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get longEvery => $composableBuilder(
    column: $table.longEvery,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sort => $composableBuilder(
    column: $table.sort,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PresetsTableOrderingComposer
    extends Composer<_$AppDatabase, $PresetsTable> {
  $$PresetsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get focusMin => $composableBuilder(
    column: $table.focusMin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get shortMin => $composableBuilder(
    column: $table.shortMin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get longMin => $composableBuilder(
    column: $table.longMin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get longEvery => $composableBuilder(
    column: $table.longEvery,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sort => $composableBuilder(
    column: $table.sort,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PresetsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PresetsTable> {
  $$PresetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get focusMin =>
      $composableBuilder(column: $table.focusMin, builder: (column) => column);

  GeneratedColumn<int> get shortMin =>
      $composableBuilder(column: $table.shortMin, builder: (column) => column);

  GeneratedColumn<int> get longMin =>
      $composableBuilder(column: $table.longMin, builder: (column) => column);

  GeneratedColumn<int> get longEvery =>
      $composableBuilder(column: $table.longEvery, builder: (column) => column);

  GeneratedColumn<int> get sort =>
      $composableBuilder(column: $table.sort, builder: (column) => column);
}

class $$PresetsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PresetsTable,
          PresetRow,
          $$PresetsTableFilterComposer,
          $$PresetsTableOrderingComposer,
          $$PresetsTableAnnotationComposer,
          $$PresetsTableCreateCompanionBuilder,
          $$PresetsTableUpdateCompanionBuilder,
          (PresetRow, BaseReferences<_$AppDatabase, $PresetsTable, PresetRow>),
          PresetRow,
          PrefetchHooks Function()
        > {
  $$PresetsTableTableManager(_$AppDatabase db, $PresetsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PresetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PresetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PresetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> focusMin = const Value.absent(),
                Value<int> shortMin = const Value.absent(),
                Value<int> longMin = const Value.absent(),
                Value<int> longEvery = const Value.absent(),
                Value<int> sort = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PresetsCompanion(
                id: id,
                name: name,
                focusMin: focusMin,
                shortMin: shortMin,
                longMin: longMin,
                longEvery: longEvery,
                sort: sort,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required int focusMin,
                required int shortMin,
                required int longMin,
                required int longEvery,
                Value<int> sort = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PresetsCompanion.insert(
                id: id,
                name: name,
                focusMin: focusMin,
                shortMin: shortMin,
                longMin: longMin,
                longEvery: longEvery,
                sort: sort,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PresetsTable, PresetRow>(table),
                  BaseReferences<_$AppDatabase, $PresetsTable, PresetRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PresetsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PresetsTable,
      PresetRow,
      $$PresetsTableFilterComposer,
      $$PresetsTableOrderingComposer,
      $$PresetsTableAnnotationComposer,
      $$PresetsTableCreateCompanionBuilder,
      $$PresetsTableUpdateCompanionBuilder,
      (PresetRow, BaseReferences<_$AppDatabase, $PresetsTable, PresetRow>),
      PresetRow,
      PrefetchHooks Function()
    >;
typedef $$HeldRemindersTableCreateCompanionBuilder =
    HeldRemindersCompanion Function({
      Value<int> notificationId,
      required String taskId,
      required String occurrenceDate,
      required int originalFireAt,
      Value<String> title,
    });
typedef $$HeldRemindersTableUpdateCompanionBuilder =
    HeldRemindersCompanion Function({
      Value<int> notificationId,
      Value<String> taskId,
      Value<String> occurrenceDate,
      Value<int> originalFireAt,
      Value<String> title,
    });

class $$HeldRemindersTableFilterComposer
    extends Composer<_$AppDatabase, $HeldRemindersTable> {
  $$HeldRemindersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get notificationId => $composableBuilder(
    column: $table.notificationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get taskId => $composableBuilder(
    column: $table.taskId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get occurrenceDate => $composableBuilder(
    column: $table.occurrenceDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get originalFireAt => $composableBuilder(
    column: $table.originalFireAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );
}

class $$HeldRemindersTableOrderingComposer
    extends Composer<_$AppDatabase, $HeldRemindersTable> {
  $$HeldRemindersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get notificationId => $composableBuilder(
    column: $table.notificationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get taskId => $composableBuilder(
    column: $table.taskId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get occurrenceDate => $composableBuilder(
    column: $table.occurrenceDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get originalFireAt => $composableBuilder(
    column: $table.originalFireAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$HeldRemindersTableAnnotationComposer
    extends Composer<_$AppDatabase, $HeldRemindersTable> {
  $$HeldRemindersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get notificationId => $composableBuilder(
    column: $table.notificationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get taskId =>
      $composableBuilder(column: $table.taskId, builder: (column) => column);

  GeneratedColumn<String> get occurrenceDate => $composableBuilder(
    column: $table.occurrenceDate,
    builder: (column) => column,
  );

  GeneratedColumn<int> get originalFireAt => $composableBuilder(
    column: $table.originalFireAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);
}

class $$HeldRemindersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $HeldRemindersTable,
          HeldReminderRow,
          $$HeldRemindersTableFilterComposer,
          $$HeldRemindersTableOrderingComposer,
          $$HeldRemindersTableAnnotationComposer,
          $$HeldRemindersTableCreateCompanionBuilder,
          $$HeldRemindersTableUpdateCompanionBuilder,
          (
            HeldReminderRow,
            BaseReferences<_$AppDatabase, $HeldRemindersTable, HeldReminderRow>,
          ),
          HeldReminderRow,
          PrefetchHooks Function()
        > {
  $$HeldRemindersTableTableManager(_$AppDatabase db, $HeldRemindersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HeldRemindersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HeldRemindersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HeldRemindersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> notificationId = const Value.absent(),
                Value<String> taskId = const Value.absent(),
                Value<String> occurrenceDate = const Value.absent(),
                Value<int> originalFireAt = const Value.absent(),
                Value<String> title = const Value.absent(),
              }) => HeldRemindersCompanion(
                notificationId: notificationId,
                taskId: taskId,
                occurrenceDate: occurrenceDate,
                originalFireAt: originalFireAt,
                title: title,
              ),
          createCompanionCallback:
              ({
                Value<int> notificationId = const Value.absent(),
                required String taskId,
                required String occurrenceDate,
                required int originalFireAt,
                Value<String> title = const Value.absent(),
              }) => HeldRemindersCompanion.insert(
                notificationId: notificationId,
                taskId: taskId,
                occurrenceDate: occurrenceDate,
                originalFireAt: originalFireAt,
                title: title,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$HeldRemindersTable, HeldReminderRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $HeldRemindersTable,
                    HeldReminderRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$HeldRemindersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $HeldRemindersTable,
      HeldReminderRow,
      $$HeldRemindersTableFilterComposer,
      $$HeldRemindersTableOrderingComposer,
      $$HeldRemindersTableAnnotationComposer,
      $$HeldRemindersTableCreateCompanionBuilder,
      $$HeldRemindersTableUpdateCompanionBuilder,
      (
        HeldReminderRow,
        BaseReferences<_$AppDatabase, $HeldRemindersTable, HeldReminderRow>,
      ),
      HeldReminderRow,
      PrefetchHooks Function()
    >;
typedef $$SettingsTableCreateCompanionBuilder = SettingsCompanion Function({
  required String key,
  required String value,
  Value<int> rowid,
});
typedef $$SettingsTableUpdateCompanionBuilder = SettingsCompanion Function({
  Value<String> key,
  Value<String> value,
  Value<int> rowid,
});

class $$SettingsTableFilterComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableFilterComposer({
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

class $$SettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableOrderingComposer({
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

class $$SettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableAnnotationComposer({
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

class $$SettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SettingsTable,
          SettingRow,
          $$SettingsTableFilterComposer,
          $$SettingsTableOrderingComposer,
          $$SettingsTableAnnotationComposer,
          $$SettingsTableCreateCompanionBuilder,
          $$SettingsTableUpdateCompanionBuilder,
          (
            SettingRow,
            BaseReferences<_$AppDatabase, $SettingsTable, SettingRow>,
          ),
          SettingRow,
          PrefetchHooks Function()
        > {
  $$SettingsTableTableManager(_$AppDatabase db, $SettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => SettingsCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback: ({
            required String key,
            required String value,
            Value<int> rowid = const Value.absent(),
          }) => SettingsCompanion.insert(key: key, value: value, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SettingsTable, SettingRow>(table),
                  BaseReferences<_$AppDatabase, $SettingsTable, SettingRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SettingsTable,
      SettingRow,
      $$SettingsTableFilterComposer,
      $$SettingsTableOrderingComposer,
      $$SettingsTableAnnotationComposer,
      $$SettingsTableCreateCompanionBuilder,
      $$SettingsTableUpdateCompanionBuilder,
      (SettingRow, BaseReferences<_$AppDatabase, $SettingsTable, SettingRow>),
      SettingRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$TasksTableTableManager get tasks =>
      $$TasksTableTableManager(_db, _db.tasks);
  $$TaskRemindersTableTableManager get taskReminders =>
      $$TaskRemindersTableTableManager(_db, _db.taskReminders);
  $$OccurrenceRecordsTableTableManager get occurrenceRecords =>
      $$OccurrenceRecordsTableTableManager(_db, _db.occurrenceRecords);
  $$FocusSessionsTableTableManager get focusSessions =>
      $$FocusSessionsTableTableManager(_db, _db.focusSessions);
  $$FocusStatesTableTableManager get focusStates =>
      $$FocusStatesTableTableManager(_db, _db.focusStates);
  $$PresetsTableTableManager get presets =>
      $$PresetsTableTableManager(_db, _db.presets);
  $$HeldRemindersTableTableManager get heldReminders =>
      $$HeldRemindersTableTableManager(_db, _db.heldReminders);
  $$SettingsTableTableManager get settings =>
      $$SettingsTableTableManager(_db, _db.settings);
}
