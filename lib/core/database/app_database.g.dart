// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $HabitsTable extends Habits with TableInfo<$HabitsTable, Habit> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HabitsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 200,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('general'),
  );
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
    'icon',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('check'),
  );
  static const VerificationMeta _frequencyTypeMeta = const VerificationMeta(
    'frequencyType',
  );
  @override
  late final GeneratedColumn<String> frequencyType = GeneratedColumn<String>(
    'frequency_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('daily'),
  );
  static const VerificationMeta _frequencyValueMeta = const VerificationMeta(
    'frequencyValue',
  );
  @override
  late final GeneratedColumn<String> frequencyValue = GeneratedColumn<String>(
    'frequency_value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  static const VerificationMeta _timeOfDayMeta = const VerificationMeta(
    'timeOfDay',
  );
  @override
  late final GeneratedColumn<String> timeOfDay = GeneratedColumn<String>(
    'time_of_day',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('anytime'),
  );
  static const VerificationMeta _isFocusMeta = const VerificationMeta(
    'isFocus',
  );
  @override
  late final GeneratedColumn<bool> isFocus = GeneratedColumn<bool>(
    'is_focus',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_focus" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isArchivedMeta = const VerificationMeta(
    'isArchived',
  );
  @override
  late final GeneratedColumn<bool> isArchived = GeneratedColumn<bool>(
    'is_archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_archived" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    category,
    icon,
    frequencyType,
    frequencyValue,
    timeOfDay,
    isFocus,
    isArchived,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'habits';
  @override
  VerificationContext validateIntegrity(
    Insertable<Habit> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    }
    if (data.containsKey('icon')) {
      context.handle(
        _iconMeta,
        icon.isAcceptableOrUnknown(data['icon']!, _iconMeta),
      );
    }
    if (data.containsKey('frequency_type')) {
      context.handle(
        _frequencyTypeMeta,
        frequencyType.isAcceptableOrUnknown(
          data['frequency_type']!,
          _frequencyTypeMeta,
        ),
      );
    }
    if (data.containsKey('frequency_value')) {
      context.handle(
        _frequencyValueMeta,
        frequencyValue.isAcceptableOrUnknown(
          data['frequency_value']!,
          _frequencyValueMeta,
        ),
      );
    }
    if (data.containsKey('time_of_day')) {
      context.handle(
        _timeOfDayMeta,
        timeOfDay.isAcceptableOrUnknown(data['time_of_day']!, _timeOfDayMeta),
      );
    }
    if (data.containsKey('is_focus')) {
      context.handle(
        _isFocusMeta,
        isFocus.isAcceptableOrUnknown(data['is_focus']!, _isFocusMeta),
      );
    }
    if (data.containsKey('is_archived')) {
      context.handle(
        _isArchivedMeta,
        isArchived.isAcceptableOrUnknown(data['is_archived']!, _isArchivedMeta),
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Habit map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Habit(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      icon: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon'],
      )!,
      frequencyType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}frequency_type'],
      )!,
      frequencyValue: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}frequency_value'],
      )!,
      timeOfDay: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}time_of_day'],
      )!,
      isFocus: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_focus'],
      )!,
      isArchived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_archived'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $HabitsTable createAlias(String alias) {
    return $HabitsTable(attachedDatabase, alias);
  }
}

class Habit extends DataClass implements Insertable<Habit> {
  final int id;
  final String name;
  final String category;
  final String icon;
  final String frequencyType;
  final String frequencyValue;
  final String timeOfDay;
  final bool isFocus;
  final bool isArchived;
  final int createdAt;
  const Habit({
    required this.id,
    required this.name,
    required this.category,
    required this.icon,
    required this.frequencyType,
    required this.frequencyValue,
    required this.timeOfDay,
    required this.isFocus,
    required this.isArchived,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['category'] = Variable<String>(category);
    map['icon'] = Variable<String>(icon);
    map['frequency_type'] = Variable<String>(frequencyType);
    map['frequency_value'] = Variable<String>(frequencyValue);
    map['time_of_day'] = Variable<String>(timeOfDay);
    map['is_focus'] = Variable<bool>(isFocus);
    map['is_archived'] = Variable<bool>(isArchived);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  HabitsCompanion toCompanion(bool nullToAbsent) {
    return HabitsCompanion(
      id: Value(id),
      name: Value(name),
      category: Value(category),
      icon: Value(icon),
      frequencyType: Value(frequencyType),
      frequencyValue: Value(frequencyValue),
      timeOfDay: Value(timeOfDay),
      isFocus: Value(isFocus),
      isArchived: Value(isArchived),
      createdAt: Value(createdAt),
    );
  }

  factory Habit.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Habit(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      category: serializer.fromJson<String>(json['category']),
      icon: serializer.fromJson<String>(json['icon']),
      frequencyType: serializer.fromJson<String>(json['frequencyType']),
      frequencyValue: serializer.fromJson<String>(json['frequencyValue']),
      timeOfDay: serializer.fromJson<String>(json['timeOfDay']),
      isFocus: serializer.fromJson<bool>(json['isFocus']),
      isArchived: serializer.fromJson<bool>(json['isArchived']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'category': serializer.toJson<String>(category),
      'icon': serializer.toJson<String>(icon),
      'frequencyType': serializer.toJson<String>(frequencyType),
      'frequencyValue': serializer.toJson<String>(frequencyValue),
      'timeOfDay': serializer.toJson<String>(timeOfDay),
      'isFocus': serializer.toJson<bool>(isFocus),
      'isArchived': serializer.toJson<bool>(isArchived),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  Habit copyWith({
    int? id,
    String? name,
    String? category,
    String? icon,
    String? frequencyType,
    String? frequencyValue,
    String? timeOfDay,
    bool? isFocus,
    bool? isArchived,
    int? createdAt,
  }) => Habit(
    id: id ?? this.id,
    name: name ?? this.name,
    category: category ?? this.category,
    icon: icon ?? this.icon,
    frequencyType: frequencyType ?? this.frequencyType,
    frequencyValue: frequencyValue ?? this.frequencyValue,
    timeOfDay: timeOfDay ?? this.timeOfDay,
    isFocus: isFocus ?? this.isFocus,
    isArchived: isArchived ?? this.isArchived,
    createdAt: createdAt ?? this.createdAt,
  );
  Habit copyWithCompanion(HabitsCompanion data) {
    return Habit(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      category: data.category.present ? data.category.value : this.category,
      icon: data.icon.present ? data.icon.value : this.icon,
      frequencyType: data.frequencyType.present
          ? data.frequencyType.value
          : this.frequencyType,
      frequencyValue: data.frequencyValue.present
          ? data.frequencyValue.value
          : this.frequencyValue,
      timeOfDay: data.timeOfDay.present ? data.timeOfDay.value : this.timeOfDay,
      isFocus: data.isFocus.present ? data.isFocus.value : this.isFocus,
      isArchived: data.isArchived.present
          ? data.isArchived.value
          : this.isArchived,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Habit(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('category: $category, ')
          ..write('icon: $icon, ')
          ..write('frequencyType: $frequencyType, ')
          ..write('frequencyValue: $frequencyValue, ')
          ..write('timeOfDay: $timeOfDay, ')
          ..write('isFocus: $isFocus, ')
          ..write('isArchived: $isArchived, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    category,
    icon,
    frequencyType,
    frequencyValue,
    timeOfDay,
    isFocus,
    isArchived,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Habit &&
          other.id == this.id &&
          other.name == this.name &&
          other.category == this.category &&
          other.icon == this.icon &&
          other.frequencyType == this.frequencyType &&
          other.frequencyValue == this.frequencyValue &&
          other.timeOfDay == this.timeOfDay &&
          other.isFocus == this.isFocus &&
          other.isArchived == this.isArchived &&
          other.createdAt == this.createdAt);
}

class HabitsCompanion extends UpdateCompanion<Habit> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> category;
  final Value<String> icon;
  final Value<String> frequencyType;
  final Value<String> frequencyValue;
  final Value<String> timeOfDay;
  final Value<bool> isFocus;
  final Value<bool> isArchived;
  final Value<int> createdAt;
  const HabitsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.category = const Value.absent(),
    this.icon = const Value.absent(),
    this.frequencyType = const Value.absent(),
    this.frequencyValue = const Value.absent(),
    this.timeOfDay = const Value.absent(),
    this.isFocus = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  HabitsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.category = const Value.absent(),
    this.icon = const Value.absent(),
    this.frequencyType = const Value.absent(),
    this.frequencyValue = const Value.absent(),
    this.timeOfDay = const Value.absent(),
    this.isFocus = const Value.absent(),
    this.isArchived = const Value.absent(),
    required int createdAt,
  }) : name = Value(name),
       createdAt = Value(createdAt);
  static Insertable<Habit> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? category,
    Expression<String>? icon,
    Expression<String>? frequencyType,
    Expression<String>? frequencyValue,
    Expression<String>? timeOfDay,
    Expression<bool>? isFocus,
    Expression<bool>? isArchived,
    Expression<int>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (category != null) 'category': category,
      if (icon != null) 'icon': icon,
      if (frequencyType != null) 'frequency_type': frequencyType,
      if (frequencyValue != null) 'frequency_value': frequencyValue,
      if (timeOfDay != null) 'time_of_day': timeOfDay,
      if (isFocus != null) 'is_focus': isFocus,
      if (isArchived != null) 'is_archived': isArchived,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  HabitsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? category,
    Value<String>? icon,
    Value<String>? frequencyType,
    Value<String>? frequencyValue,
    Value<String>? timeOfDay,
    Value<bool>? isFocus,
    Value<bool>? isArchived,
    Value<int>? createdAt,
  }) {
    return HabitsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      icon: icon ?? this.icon,
      frequencyType: frequencyType ?? this.frequencyType,
      frequencyValue: frequencyValue ?? this.frequencyValue,
      timeOfDay: timeOfDay ?? this.timeOfDay,
      isFocus: isFocus ?? this.isFocus,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    if (frequencyType.present) {
      map['frequency_type'] = Variable<String>(frequencyType.value);
    }
    if (frequencyValue.present) {
      map['frequency_value'] = Variable<String>(frequencyValue.value);
    }
    if (timeOfDay.present) {
      map['time_of_day'] = Variable<String>(timeOfDay.value);
    }
    if (isFocus.present) {
      map['is_focus'] = Variable<bool>(isFocus.value);
    }
    if (isArchived.present) {
      map['is_archived'] = Variable<bool>(isArchived.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HabitsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('category: $category, ')
          ..write('icon: $icon, ')
          ..write('frequencyType: $frequencyType, ')
          ..write('frequencyValue: $frequencyValue, ')
          ..write('timeOfDay: $timeOfDay, ')
          ..write('isFocus: $isFocus, ')
          ..write('isArchived: $isArchived, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $HabitLogsTable extends HabitLogs
    with TableInfo<$HabitLogsTable, HabitLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HabitLogsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _habitIdMeta = const VerificationMeta(
    'habitId',
  );
  @override
  late final GeneratedColumn<int> habitId = GeneratedColumn<int>(
    'habit_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'REFERENCES habits (id) ON DELETE CASCADE',
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<int> date = GeneratedColumn<int>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<LogStatus, String> status =
      GeneratedColumn<String>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('pending'),
      ).withConverter<LogStatus>($HabitLogsTable.$converterstatus);
  static const VerificationMeta _loggedHourMeta = const VerificationMeta(
    'loggedHour',
  );
  @override
  late final GeneratedColumn<int> loggedHour = GeneratedColumn<int>(
    'logged_hour',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, habitId, date, status, loggedHour];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'habit_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<HabitLog> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('habit_id')) {
      context.handle(
        _habitIdMeta,
        habitId.isAcceptableOrUnknown(data['habit_id']!, _habitIdMeta),
      );
    } else if (isInserting) {
      context.missing(_habitIdMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('logged_hour')) {
      context.handle(
        _loggedHourMeta,
        loggedHour.isAcceptableOrUnknown(data['logged_hour']!, _loggedHourMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  HabitLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HabitLog(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      habitId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}habit_id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}date'],
      )!,
      status: $HabitLogsTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
      loggedHour: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}logged_hour'],
      ),
    );
  }

  @override
  $HabitLogsTable createAlias(String alias) {
    return $HabitLogsTable(attachedDatabase, alias);
  }

  static TypeConverter<LogStatus, String> $converterstatus =
      const LogStatusConverter();
}

class HabitLog extends DataClass implements Insertable<HabitLog> {
  final int id;
  final int habitId;
  final int date;
  final LogStatus status;
  final int? loggedHour;
  const HabitLog({
    required this.id,
    required this.habitId,
    required this.date,
    required this.status,
    this.loggedHour,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['habit_id'] = Variable<int>(habitId);
    map['date'] = Variable<int>(date);
    {
      map['status'] = Variable<String>(
        $HabitLogsTable.$converterstatus.toSql(status),
      );
    }
    if (!nullToAbsent || loggedHour != null) {
      map['logged_hour'] = Variable<int>(loggedHour);
    }
    return map;
  }

  HabitLogsCompanion toCompanion(bool nullToAbsent) {
    return HabitLogsCompanion(
      id: Value(id),
      habitId: Value(habitId),
      date: Value(date),
      status: Value(status),
      loggedHour: loggedHour == null && nullToAbsent
          ? const Value.absent()
          : Value(loggedHour),
    );
  }

  factory HabitLog.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HabitLog(
      id: serializer.fromJson<int>(json['id']),
      habitId: serializer.fromJson<int>(json['habitId']),
      date: serializer.fromJson<int>(json['date']),
      status: serializer.fromJson<LogStatus>(json['status']),
      loggedHour: serializer.fromJson<int?>(json['loggedHour']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'habitId': serializer.toJson<int>(habitId),
      'date': serializer.toJson<int>(date),
      'status': serializer.toJson<LogStatus>(status),
      'loggedHour': serializer.toJson<int?>(loggedHour),
    };
  }

  HabitLog copyWith({
    int? id,
    int? habitId,
    int? date,
    LogStatus? status,
    Value<int?> loggedHour = const Value.absent(),
  }) => HabitLog(
    id: id ?? this.id,
    habitId: habitId ?? this.habitId,
    date: date ?? this.date,
    status: status ?? this.status,
    loggedHour: loggedHour.present ? loggedHour.value : this.loggedHour,
  );
  HabitLog copyWithCompanion(HabitLogsCompanion data) {
    return HabitLog(
      id: data.id.present ? data.id.value : this.id,
      habitId: data.habitId.present ? data.habitId.value : this.habitId,
      date: data.date.present ? data.date.value : this.date,
      status: data.status.present ? data.status.value : this.status,
      loggedHour: data.loggedHour.present
          ? data.loggedHour.value
          : this.loggedHour,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HabitLog(')
          ..write('id: $id, ')
          ..write('habitId: $habitId, ')
          ..write('date: $date, ')
          ..write('status: $status, ')
          ..write('loggedHour: $loggedHour')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, habitId, date, status, loggedHour);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HabitLog &&
          other.id == this.id &&
          other.habitId == this.habitId &&
          other.date == this.date &&
          other.status == this.status &&
          other.loggedHour == this.loggedHour);
}

class HabitLogsCompanion extends UpdateCompanion<HabitLog> {
  final Value<int> id;
  final Value<int> habitId;
  final Value<int> date;
  final Value<LogStatus> status;
  final Value<int?> loggedHour;
  const HabitLogsCompanion({
    this.id = const Value.absent(),
    this.habitId = const Value.absent(),
    this.date = const Value.absent(),
    this.status = const Value.absent(),
    this.loggedHour = const Value.absent(),
  });
  HabitLogsCompanion.insert({
    this.id = const Value.absent(),
    required int habitId,
    required int date,
    this.status = const Value.absent(),
    this.loggedHour = const Value.absent(),
  }) : habitId = Value(habitId),
       date = Value(date);
  static Insertable<HabitLog> custom({
    Expression<int>? id,
    Expression<int>? habitId,
    Expression<int>? date,
    Expression<String>? status,
    Expression<int>? loggedHour,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (habitId != null) 'habit_id': habitId,
      if (date != null) 'date': date,
      if (status != null) 'status': status,
      if (loggedHour != null) 'logged_hour': loggedHour,
    });
  }

  HabitLogsCompanion copyWith({
    Value<int>? id,
    Value<int>? habitId,
    Value<int>? date,
    Value<LogStatus>? status,
    Value<int?>? loggedHour,
  }) {
    return HabitLogsCompanion(
      id: id ?? this.id,
      habitId: habitId ?? this.habitId,
      date: date ?? this.date,
      status: status ?? this.status,
      loggedHour: loggedHour ?? this.loggedHour,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (habitId.present) {
      map['habit_id'] = Variable<int>(habitId.value);
    }
    if (date.present) {
      map['date'] = Variable<int>(date.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $HabitLogsTable.$converterstatus.toSql(status.value),
      );
    }
    if (loggedHour.present) {
      map['logged_hour'] = Variable<int>(loggedHour.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HabitLogsCompanion(')
          ..write('id: $id, ')
          ..write('habitId: $habitId, ')
          ..write('date: $date, ')
          ..write('status: $status, ')
          ..write('loggedHour: $loggedHour')
          ..write(')'))
        .toString();
  }
}

class $DayNotesTable extends DayNotes with TableInfo<$DayNotesTable, DayNote> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DayNotesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<int> date = GeneratedColumn<int>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _momentMeta = const VerificationMeta('moment');
  @override
  late final GeneratedColumn<String> moment = GeneratedColumn<String>(
    'moment',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DayMood?, String> mood =
      GeneratedColumn<String>(
        'mood',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<DayMood?>($DayNotesTable.$convertermoodn);
  static const VerificationMeta _timeQualityMeta = const VerificationMeta(
    'timeQuality',
  );
  @override
  late final GeneratedColumn<int> timeQuality = GeneratedColumn<int>(
    'time_quality',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, date, moment, mood, timeQuality];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'day_notes';
  @override
  VerificationContext validateIntegrity(
    Insertable<DayNote> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('moment')) {
      context.handle(
        _momentMeta,
        moment.isAcceptableOrUnknown(data['moment']!, _momentMeta),
      );
    }
    if (data.containsKey('time_quality')) {
      context.handle(
        _timeQualityMeta,
        timeQuality.isAcceptableOrUnknown(
          data['time_quality']!,
          _timeQualityMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DayNote map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DayNote(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}date'],
      )!,
      moment: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}moment'],
      ),
      mood: $DayNotesTable.$convertermoodn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}mood'],
        ),
      ),
      timeQuality: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}time_quality'],
      ),
    );
  }

  @override
  $DayNotesTable createAlias(String alias) {
    return $DayNotesTable(attachedDatabase, alias);
  }

  static TypeConverter<DayMood, String> $convertermood =
      const DayMoodConverter();
  static TypeConverter<DayMood?, String?> $convertermoodn =
      NullAwareTypeConverter.wrap($convertermood);
}

class DayNote extends DataClass implements Insertable<DayNote> {
  final int id;
  final int date;
  final String? moment;
  final DayMood? mood;
  final int? timeQuality;
  const DayNote({
    required this.id,
    required this.date,
    this.moment,
    this.mood,
    this.timeQuality,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['date'] = Variable<int>(date);
    if (!nullToAbsent || moment != null) {
      map['moment'] = Variable<String>(moment);
    }
    if (!nullToAbsent || mood != null) {
      map['mood'] = Variable<String>(
        $DayNotesTable.$convertermoodn.toSql(mood),
      );
    }
    if (!nullToAbsent || timeQuality != null) {
      map['time_quality'] = Variable<int>(timeQuality);
    }
    return map;
  }

  DayNotesCompanion toCompanion(bool nullToAbsent) {
    return DayNotesCompanion(
      id: Value(id),
      date: Value(date),
      moment: moment == null && nullToAbsent
          ? const Value.absent()
          : Value(moment),
      mood: mood == null && nullToAbsent ? const Value.absent() : Value(mood),
      timeQuality: timeQuality == null && nullToAbsent
          ? const Value.absent()
          : Value(timeQuality),
    );
  }

  factory DayNote.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DayNote(
      id: serializer.fromJson<int>(json['id']),
      date: serializer.fromJson<int>(json['date']),
      moment: serializer.fromJson<String?>(json['moment']),
      mood: serializer.fromJson<DayMood?>(json['mood']),
      timeQuality: serializer.fromJson<int?>(json['timeQuality']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'date': serializer.toJson<int>(date),
      'moment': serializer.toJson<String?>(moment),
      'mood': serializer.toJson<DayMood?>(mood),
      'timeQuality': serializer.toJson<int?>(timeQuality),
    };
  }

  DayNote copyWith({
    int? id,
    int? date,
    Value<String?> moment = const Value.absent(),
    Value<DayMood?> mood = const Value.absent(),
    Value<int?> timeQuality = const Value.absent(),
  }) => DayNote(
    id: id ?? this.id,
    date: date ?? this.date,
    moment: moment.present ? moment.value : this.moment,
    mood: mood.present ? mood.value : this.mood,
    timeQuality: timeQuality.present ? timeQuality.value : this.timeQuality,
  );
  DayNote copyWithCompanion(DayNotesCompanion data) {
    return DayNote(
      id: data.id.present ? data.id.value : this.id,
      date: data.date.present ? data.date.value : this.date,
      moment: data.moment.present ? data.moment.value : this.moment,
      mood: data.mood.present ? data.mood.value : this.mood,
      timeQuality: data.timeQuality.present
          ? data.timeQuality.value
          : this.timeQuality,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DayNote(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('moment: $moment, ')
          ..write('mood: $mood, ')
          ..write('timeQuality: $timeQuality')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, date, moment, mood, timeQuality);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DayNote &&
          other.id == this.id &&
          other.date == this.date &&
          other.moment == this.moment &&
          other.mood == this.mood &&
          other.timeQuality == this.timeQuality);
}

class DayNotesCompanion extends UpdateCompanion<DayNote> {
  final Value<int> id;
  final Value<int> date;
  final Value<String?> moment;
  final Value<DayMood?> mood;
  final Value<int?> timeQuality;
  const DayNotesCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
    this.moment = const Value.absent(),
    this.mood = const Value.absent(),
    this.timeQuality = const Value.absent(),
  });
  DayNotesCompanion.insert({
    this.id = const Value.absent(),
    required int date,
    this.moment = const Value.absent(),
    this.mood = const Value.absent(),
    this.timeQuality = const Value.absent(),
  }) : date = Value(date);
  static Insertable<DayNote> custom({
    Expression<int>? id,
    Expression<int>? date,
    Expression<String>? moment,
    Expression<String>? mood,
    Expression<int>? timeQuality,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (moment != null) 'moment': moment,
      if (mood != null) 'mood': mood,
      if (timeQuality != null) 'time_quality': timeQuality,
    });
  }

  DayNotesCompanion copyWith({
    Value<int>? id,
    Value<int>? date,
    Value<String?>? moment,
    Value<DayMood?>? mood,
    Value<int?>? timeQuality,
  }) {
    return DayNotesCompanion(
      id: id ?? this.id,
      date: date ?? this.date,
      moment: moment ?? this.moment,
      mood: mood ?? this.mood,
      timeQuality: timeQuality ?? this.timeQuality,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (date.present) {
      map['date'] = Variable<int>(date.value);
    }
    if (moment.present) {
      map['moment'] = Variable<String>(moment.value);
    }
    if (mood.present) {
      map['mood'] = Variable<String>(
        $DayNotesTable.$convertermoodn.toSql(mood.value),
      );
    }
    if (timeQuality.present) {
      map['time_quality'] = Variable<int>(timeQuality.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DayNotesCompanion(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('moment: $moment, ')
          ..write('mood: $mood, ')
          ..write('timeQuality: $timeQuality')
          ..write(')'))
        .toString();
  }
}

class $MonthlyGoalsTable extends MonthlyGoals
    with TableInfo<$MonthlyGoalsTable, MonthlyGoal> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MonthlyGoalsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _monthMeta = const VerificationMeta('month');
  @override
  late final GeneratedColumn<int> month = GeneratedColumn<int>(
    'month',
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
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 200,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isDoneMeta = const VerificationMeta('isDone');
  @override
  late final GeneratedColumn<bool> isDone = GeneratedColumn<bool>(
    'is_done',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_done" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [id, month, title, isDone];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'monthly_goals';
  @override
  VerificationContext validateIntegrity(
    Insertable<MonthlyGoal> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('month')) {
      context.handle(
        _monthMeta,
        month.isAcceptableOrUnknown(data['month']!, _monthMeta),
      );
    } else if (isInserting) {
      context.missing(_monthMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('is_done')) {
      context.handle(
        _isDoneMeta,
        isDone.isAcceptableOrUnknown(data['is_done']!, _isDoneMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MonthlyGoal map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MonthlyGoal(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      month: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}month'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      isDone: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_done'],
      )!,
    );
  }

  @override
  $MonthlyGoalsTable createAlias(String alias) {
    return $MonthlyGoalsTable(attachedDatabase, alias);
  }
}

class MonthlyGoal extends DataClass implements Insertable<MonthlyGoal> {
  final int id;

  /// First-of-month unix timestamp.
  final int month;
  final String title;
  final bool isDone;
  const MonthlyGoal({
    required this.id,
    required this.month,
    required this.title,
    required this.isDone,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['month'] = Variable<int>(month);
    map['title'] = Variable<String>(title);
    map['is_done'] = Variable<bool>(isDone);
    return map;
  }

  MonthlyGoalsCompanion toCompanion(bool nullToAbsent) {
    return MonthlyGoalsCompanion(
      id: Value(id),
      month: Value(month),
      title: Value(title),
      isDone: Value(isDone),
    );
  }

  factory MonthlyGoal.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MonthlyGoal(
      id: serializer.fromJson<int>(json['id']),
      month: serializer.fromJson<int>(json['month']),
      title: serializer.fromJson<String>(json['title']),
      isDone: serializer.fromJson<bool>(json['isDone']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'month': serializer.toJson<int>(month),
      'title': serializer.toJson<String>(title),
      'isDone': serializer.toJson<bool>(isDone),
    };
  }

  MonthlyGoal copyWith({int? id, int? month, String? title, bool? isDone}) =>
      MonthlyGoal(
        id: id ?? this.id,
        month: month ?? this.month,
        title: title ?? this.title,
        isDone: isDone ?? this.isDone,
      );
  MonthlyGoal copyWithCompanion(MonthlyGoalsCompanion data) {
    return MonthlyGoal(
      id: data.id.present ? data.id.value : this.id,
      month: data.month.present ? data.month.value : this.month,
      title: data.title.present ? data.title.value : this.title,
      isDone: data.isDone.present ? data.isDone.value : this.isDone,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MonthlyGoal(')
          ..write('id: $id, ')
          ..write('month: $month, ')
          ..write('title: $title, ')
          ..write('isDone: $isDone')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, month, title, isDone);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MonthlyGoal &&
          other.id == this.id &&
          other.month == this.month &&
          other.title == this.title &&
          other.isDone == this.isDone);
}

class MonthlyGoalsCompanion extends UpdateCompanion<MonthlyGoal> {
  final Value<int> id;
  final Value<int> month;
  final Value<String> title;
  final Value<bool> isDone;
  const MonthlyGoalsCompanion({
    this.id = const Value.absent(),
    this.month = const Value.absent(),
    this.title = const Value.absent(),
    this.isDone = const Value.absent(),
  });
  MonthlyGoalsCompanion.insert({
    this.id = const Value.absent(),
    required int month,
    required String title,
    this.isDone = const Value.absent(),
  }) : month = Value(month),
       title = Value(title);
  static Insertable<MonthlyGoal> custom({
    Expression<int>? id,
    Expression<int>? month,
    Expression<String>? title,
    Expression<bool>? isDone,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (month != null) 'month': month,
      if (title != null) 'title': title,
      if (isDone != null) 'is_done': isDone,
    });
  }

  MonthlyGoalsCompanion copyWith({
    Value<int>? id,
    Value<int>? month,
    Value<String>? title,
    Value<bool>? isDone,
  }) {
    return MonthlyGoalsCompanion(
      id: id ?? this.id,
      month: month ?? this.month,
      title: title ?? this.title,
      isDone: isDone ?? this.isDone,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (month.present) {
      map['month'] = Variable<int>(month.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (isDone.present) {
      map['is_done'] = Variable<bool>(isDone.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MonthlyGoalsCompanion(')
          ..write('id: $id, ')
          ..write('month: $month, ')
          ..write('title: $title, ')
          ..write('isDone: $isDone')
          ..write(')'))
        .toString();
  }
}

class $LettersTable extends Letters with TableInfo<$LettersTable, Letter> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LettersTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _deliverAtMeta = const VerificationMeta(
    'deliverAt',
  );
  @override
  late final GeneratedColumn<int> deliverAt = GeneratedColumn<int>(
    'deliver_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
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
  static const VerificationMeta _isOpenedMeta = const VerificationMeta(
    'isOpened',
  );
  @override
  late final GeneratedColumn<bool> isOpened = GeneratedColumn<bool>(
    'is_opened',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_opened" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _openedAtMeta = const VerificationMeta(
    'openedAt',
  );
  @override
  late final GeneratedColumn<int> openedAt = GeneratedColumn<int>(
    'opened_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reactionMeta = const VerificationMeta(
    'reaction',
  );
  @override
  late final GeneratedColumn<String> reaction = GeneratedColumn<String>(
    'reaction',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _replyMeta = const VerificationMeta('reply');
  @override
  late final GeneratedColumn<String> reply = GeneratedColumn<String>(
    'reply',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    deliverAt,
    body,
    isOpened,
    openedAt,
    reaction,
    reply,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'letters';
  @override
  VerificationContext validateIntegrity(
    Insertable<Letter> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('deliver_at')) {
      context.handle(
        _deliverAtMeta,
        deliverAt.isAcceptableOrUnknown(data['deliver_at']!, _deliverAtMeta),
      );
    } else if (isInserting) {
      context.missing(_deliverAtMeta);
    }
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    if (data.containsKey('is_opened')) {
      context.handle(
        _isOpenedMeta,
        isOpened.isAcceptableOrUnknown(data['is_opened']!, _isOpenedMeta),
      );
    }
    if (data.containsKey('opened_at')) {
      context.handle(
        _openedAtMeta,
        openedAt.isAcceptableOrUnknown(data['opened_at']!, _openedAtMeta),
      );
    }
    if (data.containsKey('reaction')) {
      context.handle(
        _reactionMeta,
        reaction.isAcceptableOrUnknown(data['reaction']!, _reactionMeta),
      );
    }
    if (data.containsKey('reply')) {
      context.handle(
        _replyMeta,
        reply.isAcceptableOrUnknown(data['reply']!, _replyMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Letter map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Letter(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      deliverAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deliver_at'],
      )!,
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body'],
      )!,
      isOpened: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_opened'],
      )!,
      openedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}opened_at'],
      ),
      reaction: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reaction'],
      ),
      reply: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reply'],
      ),
    );
  }

  @override
  $LettersTable createAlias(String alias) {
    return $LettersTable(attachedDatabase, alias);
  }
}

class Letter extends DataClass implements Insertable<Letter> {
  final int id;
  final int createdAt;
  final int deliverAt;
  final String body;
  final bool isOpened;
  final int? openedAt;

  /// The reader's verdict on an opened capsule — written confirmation of what
  /// came of the message, not a streak or a score.
  final String? reaction;

  /// A free-form reply to the capsule, written after opening it.
  final String? reply;
  const Letter({
    required this.id,
    required this.createdAt,
    required this.deliverAt,
    required this.body,
    required this.isOpened,
    this.openedAt,
    this.reaction,
    this.reply,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['created_at'] = Variable<int>(createdAt);
    map['deliver_at'] = Variable<int>(deliverAt);
    map['body'] = Variable<String>(body);
    map['is_opened'] = Variable<bool>(isOpened);
    if (!nullToAbsent || openedAt != null) {
      map['opened_at'] = Variable<int>(openedAt);
    }
    if (!nullToAbsent || reaction != null) {
      map['reaction'] = Variable<String>(reaction);
    }
    if (!nullToAbsent || reply != null) {
      map['reply'] = Variable<String>(reply);
    }
    return map;
  }

  LettersCompanion toCompanion(bool nullToAbsent) {
    return LettersCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      deliverAt: Value(deliverAt),
      body: Value(body),
      isOpened: Value(isOpened),
      openedAt: openedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(openedAt),
      reaction: reaction == null && nullToAbsent
          ? const Value.absent()
          : Value(reaction),
      reply: reply == null && nullToAbsent
          ? const Value.absent()
          : Value(reply),
    );
  }

  factory Letter.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Letter(
      id: serializer.fromJson<int>(json['id']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      deliverAt: serializer.fromJson<int>(json['deliverAt']),
      body: serializer.fromJson<String>(json['body']),
      isOpened: serializer.fromJson<bool>(json['isOpened']),
      openedAt: serializer.fromJson<int?>(json['openedAt']),
      reaction: serializer.fromJson<String?>(json['reaction']),
      reply: serializer.fromJson<String?>(json['reply']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'createdAt': serializer.toJson<int>(createdAt),
      'deliverAt': serializer.toJson<int>(deliverAt),
      'body': serializer.toJson<String>(body),
      'isOpened': serializer.toJson<bool>(isOpened),
      'openedAt': serializer.toJson<int?>(openedAt),
      'reaction': serializer.toJson<String?>(reaction),
      'reply': serializer.toJson<String?>(reply),
    };
  }

  Letter copyWith({
    int? id,
    int? createdAt,
    int? deliverAt,
    String? body,
    bool? isOpened,
    Value<int?> openedAt = const Value.absent(),
    Value<String?> reaction = const Value.absent(),
    Value<String?> reply = const Value.absent(),
  }) => Letter(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    deliverAt: deliverAt ?? this.deliverAt,
    body: body ?? this.body,
    isOpened: isOpened ?? this.isOpened,
    openedAt: openedAt.present ? openedAt.value : this.openedAt,
    reaction: reaction.present ? reaction.value : this.reaction,
    reply: reply.present ? reply.value : this.reply,
  );
  Letter copyWithCompanion(LettersCompanion data) {
    return Letter(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      deliverAt: data.deliverAt.present ? data.deliverAt.value : this.deliverAt,
      body: data.body.present ? data.body.value : this.body,
      isOpened: data.isOpened.present ? data.isOpened.value : this.isOpened,
      openedAt: data.openedAt.present ? data.openedAt.value : this.openedAt,
      reaction: data.reaction.present ? data.reaction.value : this.reaction,
      reply: data.reply.present ? data.reply.value : this.reply,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Letter(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('deliverAt: $deliverAt, ')
          ..write('body: $body, ')
          ..write('isOpened: $isOpened, ')
          ..write('openedAt: $openedAt, ')
          ..write('reaction: $reaction, ')
          ..write('reply: $reply')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    deliverAt,
    body,
    isOpened,
    openedAt,
    reaction,
    reply,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Letter &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.deliverAt == this.deliverAt &&
          other.body == this.body &&
          other.isOpened == this.isOpened &&
          other.openedAt == this.openedAt &&
          other.reaction == this.reaction &&
          other.reply == this.reply);
}

class LettersCompanion extends UpdateCompanion<Letter> {
  final Value<int> id;
  final Value<int> createdAt;
  final Value<int> deliverAt;
  final Value<String> body;
  final Value<bool> isOpened;
  final Value<int?> openedAt;
  final Value<String?> reaction;
  final Value<String?> reply;
  const LettersCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.deliverAt = const Value.absent(),
    this.body = const Value.absent(),
    this.isOpened = const Value.absent(),
    this.openedAt = const Value.absent(),
    this.reaction = const Value.absent(),
    this.reply = const Value.absent(),
  });
  LettersCompanion.insert({
    this.id = const Value.absent(),
    required int createdAt,
    required int deliverAt,
    required String body,
    this.isOpened = const Value.absent(),
    this.openedAt = const Value.absent(),
    this.reaction = const Value.absent(),
    this.reply = const Value.absent(),
  }) : createdAt = Value(createdAt),
       deliverAt = Value(deliverAt),
       body = Value(body);
  static Insertable<Letter> custom({
    Expression<int>? id,
    Expression<int>? createdAt,
    Expression<int>? deliverAt,
    Expression<String>? body,
    Expression<bool>? isOpened,
    Expression<int>? openedAt,
    Expression<String>? reaction,
    Expression<String>? reply,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (deliverAt != null) 'deliver_at': deliverAt,
      if (body != null) 'body': body,
      if (isOpened != null) 'is_opened': isOpened,
      if (openedAt != null) 'opened_at': openedAt,
      if (reaction != null) 'reaction': reaction,
      if (reply != null) 'reply': reply,
    });
  }

  LettersCompanion copyWith({
    Value<int>? id,
    Value<int>? createdAt,
    Value<int>? deliverAt,
    Value<String>? body,
    Value<bool>? isOpened,
    Value<int?>? openedAt,
    Value<String?>? reaction,
    Value<String?>? reply,
  }) {
    return LettersCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      deliverAt: deliverAt ?? this.deliverAt,
      body: body ?? this.body,
      isOpened: isOpened ?? this.isOpened,
      openedAt: openedAt ?? this.openedAt,
      reaction: reaction ?? this.reaction,
      reply: reply ?? this.reply,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (deliverAt.present) {
      map['deliver_at'] = Variable<int>(deliverAt.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (isOpened.present) {
      map['is_opened'] = Variable<bool>(isOpened.value);
    }
    if (openedAt.present) {
      map['opened_at'] = Variable<int>(openedAt.value);
    }
    if (reaction.present) {
      map['reaction'] = Variable<String>(reaction.value);
    }
    if (reply.present) {
      map['reply'] = Variable<String>(reply.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LettersCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('deliverAt: $deliverAt, ')
          ..write('body: $body, ')
          ..write('isOpened: $isOpened, ')
          ..write('openedAt: $openedAt, ')
          ..write('reaction: $reaction, ')
          ..write('reply: $reply')
          ..write(')'))
        .toString();
  }
}

class $WeeklyIntentionsTable extends WeeklyIntentions
    with TableInfo<$WeeklyIntentionsTable, WeeklyIntention> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WeeklyIntentionsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _weekStartMeta = const VerificationMeta(
    'weekStart',
  );
  @override
  late final GeneratedColumn<int> weekStart = GeneratedColumn<int>(
    'week_start',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _intentionMeta = const VerificationMeta(
    'intention',
  );
  @override
  late final GeneratedColumn<String> intention = GeneratedColumn<String>(
    'intention',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, weekStart, intention];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'weekly_intentions';
  @override
  VerificationContext validateIntegrity(
    Insertable<WeeklyIntention> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('week_start')) {
      context.handle(
        _weekStartMeta,
        weekStart.isAcceptableOrUnknown(data['week_start']!, _weekStartMeta),
      );
    } else if (isInserting) {
      context.missing(_weekStartMeta);
    }
    if (data.containsKey('intention')) {
      context.handle(
        _intentionMeta,
        intention.isAcceptableOrUnknown(data['intention']!, _intentionMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WeeklyIntention map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WeeklyIntention(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      weekStart: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}week_start'],
      )!,
      intention: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}intention'],
      ),
    );
  }

  @override
  $WeeklyIntentionsTable createAlias(String alias) {
    return $WeeklyIntentionsTable(attachedDatabase, alias);
  }
}

class WeeklyIntention extends DataClass implements Insertable<WeeklyIntention> {
  final int id;
  final int weekStart;
  final String? intention;
  const WeeklyIntention({
    required this.id,
    required this.weekStart,
    this.intention,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['week_start'] = Variable<int>(weekStart);
    if (!nullToAbsent || intention != null) {
      map['intention'] = Variable<String>(intention);
    }
    return map;
  }

  WeeklyIntentionsCompanion toCompanion(bool nullToAbsent) {
    return WeeklyIntentionsCompanion(
      id: Value(id),
      weekStart: Value(weekStart),
      intention: intention == null && nullToAbsent
          ? const Value.absent()
          : Value(intention),
    );
  }

  factory WeeklyIntention.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WeeklyIntention(
      id: serializer.fromJson<int>(json['id']),
      weekStart: serializer.fromJson<int>(json['weekStart']),
      intention: serializer.fromJson<String?>(json['intention']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'weekStart': serializer.toJson<int>(weekStart),
      'intention': serializer.toJson<String?>(intention),
    };
  }

  WeeklyIntention copyWith({
    int? id,
    int? weekStart,
    Value<String?> intention = const Value.absent(),
  }) => WeeklyIntention(
    id: id ?? this.id,
    weekStart: weekStart ?? this.weekStart,
    intention: intention.present ? intention.value : this.intention,
  );
  WeeklyIntention copyWithCompanion(WeeklyIntentionsCompanion data) {
    return WeeklyIntention(
      id: data.id.present ? data.id.value : this.id,
      weekStart: data.weekStart.present ? data.weekStart.value : this.weekStart,
      intention: data.intention.present ? data.intention.value : this.intention,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WeeklyIntention(')
          ..write('id: $id, ')
          ..write('weekStart: $weekStart, ')
          ..write('intention: $intention')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, weekStart, intention);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WeeklyIntention &&
          other.id == this.id &&
          other.weekStart == this.weekStart &&
          other.intention == this.intention);
}

class WeeklyIntentionsCompanion extends UpdateCompanion<WeeklyIntention> {
  final Value<int> id;
  final Value<int> weekStart;
  final Value<String?> intention;
  const WeeklyIntentionsCompanion({
    this.id = const Value.absent(),
    this.weekStart = const Value.absent(),
    this.intention = const Value.absent(),
  });
  WeeklyIntentionsCompanion.insert({
    this.id = const Value.absent(),
    required int weekStart,
    this.intention = const Value.absent(),
  }) : weekStart = Value(weekStart);
  static Insertable<WeeklyIntention> custom({
    Expression<int>? id,
    Expression<int>? weekStart,
    Expression<String>? intention,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (weekStart != null) 'week_start': weekStart,
      if (intention != null) 'intention': intention,
    });
  }

  WeeklyIntentionsCompanion copyWith({
    Value<int>? id,
    Value<int>? weekStart,
    Value<String?>? intention,
  }) {
    return WeeklyIntentionsCompanion(
      id: id ?? this.id,
      weekStart: weekStart ?? this.weekStart,
      intention: intention ?? this.intention,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (weekStart.present) {
      map['week_start'] = Variable<int>(weekStart.value);
    }
    if (intention.present) {
      map['intention'] = Variable<String>(intention.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WeeklyIntentionsCompanion(')
          ..write('id: $id, ')
          ..write('weekStart: $weekStart, ')
          ..write('intention: $intention')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $HabitsTable habits = $HabitsTable(this);
  late final $HabitLogsTable habitLogs = $HabitLogsTable(this);
  late final $DayNotesTable dayNotes = $DayNotesTable(this);
  late final $MonthlyGoalsTable monthlyGoals = $MonthlyGoalsTable(this);
  late final $LettersTable letters = $LettersTable(this);
  late final $WeeklyIntentionsTable weeklyIntentions = $WeeklyIntentionsTable(
    this,
  );
  late final Index idxHabitLogsHabitDate = Index(
    'idx_habit_logs_habit_date',
    'CREATE UNIQUE INDEX idx_habit_logs_habit_date ON habit_logs (habit_id, date)',
  );
  late final HabitsDao habitsDao = HabitsDao(this as AppDatabase);
  late final HabitLogsDao habitLogsDao = HabitLogsDao(this as AppDatabase);
  late final DayNotesDao dayNotesDao = DayNotesDao(this as AppDatabase);
  late final MonthlyGoalsDao monthlyGoalsDao = MonthlyGoalsDao(
    this as AppDatabase,
  );
  late final LettersDao lettersDao = LettersDao(this as AppDatabase);
  late final WeeklyIntentionsDao weeklyIntentionsDao = WeeklyIntentionsDao(
    this as AppDatabase,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    habits,
    habitLogs,
    dayNotes,
    monthlyGoals,
    letters,
    weeklyIntentions,
    idxHabitLogsHabitDate,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'habits',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('habit_logs', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$HabitsTableCreateCompanionBuilder =
    HabitsCompanion Function({
      Value<int> id,
      required String name,
      Value<String> category,
      Value<String> icon,
      Value<String> frequencyType,
      Value<String> frequencyValue,
      Value<String> timeOfDay,
      Value<bool> isFocus,
      Value<bool> isArchived,
      required int createdAt,
    });
typedef $$HabitsTableUpdateCompanionBuilder =
    HabitsCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String> category,
      Value<String> icon,
      Value<String> frequencyType,
      Value<String> frequencyValue,
      Value<String> timeOfDay,
      Value<bool> isFocus,
      Value<bool> isArchived,
      Value<int> createdAt,
    });

final class $$HabitsTableReferences
    extends BaseReferences<_$AppDatabase, $HabitsTable, Habit> {
  $$HabitsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$HabitLogsTable, List<HabitLog>>
  _habitLogsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.habitLogs,
    aliasName: $_aliasNameGenerator(db.habits.id, db.habitLogs.habitId),
  );

  $$HabitLogsTableProcessedTableManager get habitLogsRefs {
    final manager = $$HabitLogsTableTableManager(
      $_db,
      $_db.habitLogs,
    ).filter((f) => f.habitId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_habitLogsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$HabitsTableFilterComposer
    extends Composer<_$AppDatabase, $HabitsTable> {
  $$HabitsTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get frequencyType => $composableBuilder(
    column: $table.frequencyType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get frequencyValue => $composableBuilder(
    column: $table.frequencyValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get timeOfDay => $composableBuilder(
    column: $table.timeOfDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isFocus => $composableBuilder(
    column: $table.isFocus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> habitLogsRefs(
    Expression<bool> Function($$HabitLogsTableFilterComposer f) f,
  ) {
    final $$HabitLogsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.habitLogs,
      getReferencedColumn: (t) => t.habitId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HabitLogsTableFilterComposer(
            $db: $db,
            $table: $db.habitLogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$HabitsTableOrderingComposer
    extends Composer<_$AppDatabase, $HabitsTable> {
  $$HabitsTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get frequencyType => $composableBuilder(
    column: $table.frequencyType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get frequencyValue => $composableBuilder(
    column: $table.frequencyValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get timeOfDay => $composableBuilder(
    column: $table.timeOfDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isFocus => $composableBuilder(
    column: $table.isFocus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$HabitsTableAnnotationComposer
    extends Composer<_$AppDatabase, $HabitsTable> {
  $$HabitsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get icon =>
      $composableBuilder(column: $table.icon, builder: (column) => column);

  GeneratedColumn<String> get frequencyType => $composableBuilder(
    column: $table.frequencyType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get frequencyValue => $composableBuilder(
    column: $table.frequencyValue,
    builder: (column) => column,
  );

  GeneratedColumn<String> get timeOfDay =>
      $composableBuilder(column: $table.timeOfDay, builder: (column) => column);

  GeneratedColumn<bool> get isFocus =>
      $composableBuilder(column: $table.isFocus, builder: (column) => column);

  GeneratedColumn<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> habitLogsRefs<T extends Object>(
    Expression<T> Function($$HabitLogsTableAnnotationComposer a) f,
  ) {
    final $$HabitLogsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.habitLogs,
      getReferencedColumn: (t) => t.habitId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HabitLogsTableAnnotationComposer(
            $db: $db,
            $table: $db.habitLogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$HabitsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $HabitsTable,
          Habit,
          $$HabitsTableFilterComposer,
          $$HabitsTableOrderingComposer,
          $$HabitsTableAnnotationComposer,
          $$HabitsTableCreateCompanionBuilder,
          $$HabitsTableUpdateCompanionBuilder,
          (Habit, $$HabitsTableReferences),
          Habit,
          PrefetchHooks Function({bool habitLogsRefs})
        > {
  $$HabitsTableTableManager(_$AppDatabase db, $HabitsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HabitsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HabitsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HabitsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String> icon = const Value.absent(),
                Value<String> frequencyType = const Value.absent(),
                Value<String> frequencyValue = const Value.absent(),
                Value<String> timeOfDay = const Value.absent(),
                Value<bool> isFocus = const Value.absent(),
                Value<bool> isArchived = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
              }) => HabitsCompanion(
                id: id,
                name: name,
                category: category,
                icon: icon,
                frequencyType: frequencyType,
                frequencyValue: frequencyValue,
                timeOfDay: timeOfDay,
                isFocus: isFocus,
                isArchived: isArchived,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<String> category = const Value.absent(),
                Value<String> icon = const Value.absent(),
                Value<String> frequencyType = const Value.absent(),
                Value<String> frequencyValue = const Value.absent(),
                Value<String> timeOfDay = const Value.absent(),
                Value<bool> isFocus = const Value.absent(),
                Value<bool> isArchived = const Value.absent(),
                required int createdAt,
              }) => HabitsCompanion.insert(
                id: id,
                name: name,
                category: category,
                icon: icon,
                frequencyType: frequencyType,
                frequencyValue: frequencyValue,
                timeOfDay: timeOfDay,
                isFocus: isFocus,
                isArchived: isArchived,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$HabitsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({habitLogsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (habitLogsRefs) db.habitLogs],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (habitLogsRefs)
                    await $_getPrefetchedData<Habit, $HabitsTable, HabitLog>(
                      currentTable: table,
                      referencedTable: $$HabitsTableReferences
                          ._habitLogsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$HabitsTableReferences(db, table, p0).habitLogsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.habitId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$HabitsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $HabitsTable,
      Habit,
      $$HabitsTableFilterComposer,
      $$HabitsTableOrderingComposer,
      $$HabitsTableAnnotationComposer,
      $$HabitsTableCreateCompanionBuilder,
      $$HabitsTableUpdateCompanionBuilder,
      (Habit, $$HabitsTableReferences),
      Habit,
      PrefetchHooks Function({bool habitLogsRefs})
    >;
typedef $$HabitLogsTableCreateCompanionBuilder =
    HabitLogsCompanion Function({
      Value<int> id,
      required int habitId,
      required int date,
      Value<LogStatus> status,
      Value<int?> loggedHour,
    });
typedef $$HabitLogsTableUpdateCompanionBuilder =
    HabitLogsCompanion Function({
      Value<int> id,
      Value<int> habitId,
      Value<int> date,
      Value<LogStatus> status,
      Value<int?> loggedHour,
    });

final class $$HabitLogsTableReferences
    extends BaseReferences<_$AppDatabase, $HabitLogsTable, HabitLog> {
  $$HabitLogsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $HabitsTable _habitIdTable(_$AppDatabase db) => db.habits.createAlias(
    $_aliasNameGenerator(db.habitLogs.habitId, db.habits.id),
  );

  $$HabitsTableProcessedTableManager get habitId {
    final $_column = $_itemColumn<int>('habit_id')!;

    final manager = $$HabitsTableTableManager(
      $_db,
      $_db.habits,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_habitIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$HabitLogsTableFilterComposer
    extends Composer<_$AppDatabase, $HabitLogsTable> {
  $$HabitLogsTableFilterComposer({
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

  ColumnFilters<int> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<LogStatus, LogStatus, String> get status =>
      $composableBuilder(
        column: $table.status,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get loggedHour => $composableBuilder(
    column: $table.loggedHour,
    builder: (column) => ColumnFilters(column),
  );

  $$HabitsTableFilterComposer get habitId {
    final $$HabitsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.habitId,
      referencedTable: $db.habits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HabitsTableFilterComposer(
            $db: $db,
            $table: $db.habits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$HabitLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $HabitLogsTable> {
  $$HabitLogsTableOrderingComposer({
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

  ColumnOrderings<int> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get loggedHour => $composableBuilder(
    column: $table.loggedHour,
    builder: (column) => ColumnOrderings(column),
  );

  $$HabitsTableOrderingComposer get habitId {
    final $$HabitsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.habitId,
      referencedTable: $db.habits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HabitsTableOrderingComposer(
            $db: $db,
            $table: $db.habits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$HabitLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $HabitLogsTable> {
  $$HabitLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumnWithTypeConverter<LogStatus, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get loggedHour => $composableBuilder(
    column: $table.loggedHour,
    builder: (column) => column,
  );

  $$HabitsTableAnnotationComposer get habitId {
    final $$HabitsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.habitId,
      referencedTable: $db.habits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HabitsTableAnnotationComposer(
            $db: $db,
            $table: $db.habits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$HabitLogsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $HabitLogsTable,
          HabitLog,
          $$HabitLogsTableFilterComposer,
          $$HabitLogsTableOrderingComposer,
          $$HabitLogsTableAnnotationComposer,
          $$HabitLogsTableCreateCompanionBuilder,
          $$HabitLogsTableUpdateCompanionBuilder,
          (HabitLog, $$HabitLogsTableReferences),
          HabitLog,
          PrefetchHooks Function({bool habitId})
        > {
  $$HabitLogsTableTableManager(_$AppDatabase db, $HabitLogsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HabitLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HabitLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HabitLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> habitId = const Value.absent(),
                Value<int> date = const Value.absent(),
                Value<LogStatus> status = const Value.absent(),
                Value<int?> loggedHour = const Value.absent(),
              }) => HabitLogsCompanion(
                id: id,
                habitId: habitId,
                date: date,
                status: status,
                loggedHour: loggedHour,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int habitId,
                required int date,
                Value<LogStatus> status = const Value.absent(),
                Value<int?> loggedHour = const Value.absent(),
              }) => HabitLogsCompanion.insert(
                id: id,
                habitId: habitId,
                date: date,
                status: status,
                loggedHour: loggedHour,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$HabitLogsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({habitId = false}) {
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
                    if (habitId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.habitId,
                                referencedTable: $$HabitLogsTableReferences
                                    ._habitIdTable(db),
                                referencedColumn: $$HabitLogsTableReferences
                                    ._habitIdTable(db)
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

typedef $$HabitLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $HabitLogsTable,
      HabitLog,
      $$HabitLogsTableFilterComposer,
      $$HabitLogsTableOrderingComposer,
      $$HabitLogsTableAnnotationComposer,
      $$HabitLogsTableCreateCompanionBuilder,
      $$HabitLogsTableUpdateCompanionBuilder,
      (HabitLog, $$HabitLogsTableReferences),
      HabitLog,
      PrefetchHooks Function({bool habitId})
    >;
typedef $$DayNotesTableCreateCompanionBuilder =
    DayNotesCompanion Function({
      Value<int> id,
      required int date,
      Value<String?> moment,
      Value<DayMood?> mood,
      Value<int?> timeQuality,
    });
typedef $$DayNotesTableUpdateCompanionBuilder =
    DayNotesCompanion Function({
      Value<int> id,
      Value<int> date,
      Value<String?> moment,
      Value<DayMood?> mood,
      Value<int?> timeQuality,
    });

class $$DayNotesTableFilterComposer
    extends Composer<_$AppDatabase, $DayNotesTable> {
  $$DayNotesTableFilterComposer({
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

  ColumnFilters<int> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get moment => $composableBuilder(
    column: $table.moment,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DayMood?, DayMood, String> get mood =>
      $composableBuilder(
        column: $table.mood,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get timeQuality => $composableBuilder(
    column: $table.timeQuality,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DayNotesTableOrderingComposer
    extends Composer<_$AppDatabase, $DayNotesTable> {
  $$DayNotesTableOrderingComposer({
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

  ColumnOrderings<int> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get moment => $composableBuilder(
    column: $table.moment,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mood => $composableBuilder(
    column: $table.mood,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get timeQuality => $composableBuilder(
    column: $table.timeQuality,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DayNotesTableAnnotationComposer
    extends Composer<_$AppDatabase, $DayNotesTable> {
  $$DayNotesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get moment =>
      $composableBuilder(column: $table.moment, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DayMood?, String> get mood =>
      $composableBuilder(column: $table.mood, builder: (column) => column);

  GeneratedColumn<int> get timeQuality => $composableBuilder(
    column: $table.timeQuality,
    builder: (column) => column,
  );
}

class $$DayNotesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DayNotesTable,
          DayNote,
          $$DayNotesTableFilterComposer,
          $$DayNotesTableOrderingComposer,
          $$DayNotesTableAnnotationComposer,
          $$DayNotesTableCreateCompanionBuilder,
          $$DayNotesTableUpdateCompanionBuilder,
          (DayNote, BaseReferences<_$AppDatabase, $DayNotesTable, DayNote>),
          DayNote,
          PrefetchHooks Function()
        > {
  $$DayNotesTableTableManager(_$AppDatabase db, $DayNotesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DayNotesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DayNotesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DayNotesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> date = const Value.absent(),
                Value<String?> moment = const Value.absent(),
                Value<DayMood?> mood = const Value.absent(),
                Value<int?> timeQuality = const Value.absent(),
              }) => DayNotesCompanion(
                id: id,
                date: date,
                moment: moment,
                mood: mood,
                timeQuality: timeQuality,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int date,
                Value<String?> moment = const Value.absent(),
                Value<DayMood?> mood = const Value.absent(),
                Value<int?> timeQuality = const Value.absent(),
              }) => DayNotesCompanion.insert(
                id: id,
                date: date,
                moment: moment,
                mood: mood,
                timeQuality: timeQuality,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DayNotesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DayNotesTable,
      DayNote,
      $$DayNotesTableFilterComposer,
      $$DayNotesTableOrderingComposer,
      $$DayNotesTableAnnotationComposer,
      $$DayNotesTableCreateCompanionBuilder,
      $$DayNotesTableUpdateCompanionBuilder,
      (DayNote, BaseReferences<_$AppDatabase, $DayNotesTable, DayNote>),
      DayNote,
      PrefetchHooks Function()
    >;
typedef $$MonthlyGoalsTableCreateCompanionBuilder =
    MonthlyGoalsCompanion Function({
      Value<int> id,
      required int month,
      required String title,
      Value<bool> isDone,
    });
typedef $$MonthlyGoalsTableUpdateCompanionBuilder =
    MonthlyGoalsCompanion Function({
      Value<int> id,
      Value<int> month,
      Value<String> title,
      Value<bool> isDone,
    });

class $$MonthlyGoalsTableFilterComposer
    extends Composer<_$AppDatabase, $MonthlyGoalsTable> {
  $$MonthlyGoalsTableFilterComposer({
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

  ColumnFilters<int> get month => $composableBuilder(
    column: $table.month,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDone => $composableBuilder(
    column: $table.isDone,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MonthlyGoalsTableOrderingComposer
    extends Composer<_$AppDatabase, $MonthlyGoalsTable> {
  $$MonthlyGoalsTableOrderingComposer({
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

  ColumnOrderings<int> get month => $composableBuilder(
    column: $table.month,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDone => $composableBuilder(
    column: $table.isDone,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MonthlyGoalsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MonthlyGoalsTable> {
  $$MonthlyGoalsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get month =>
      $composableBuilder(column: $table.month, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<bool> get isDone =>
      $composableBuilder(column: $table.isDone, builder: (column) => column);
}

class $$MonthlyGoalsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MonthlyGoalsTable,
          MonthlyGoal,
          $$MonthlyGoalsTableFilterComposer,
          $$MonthlyGoalsTableOrderingComposer,
          $$MonthlyGoalsTableAnnotationComposer,
          $$MonthlyGoalsTableCreateCompanionBuilder,
          $$MonthlyGoalsTableUpdateCompanionBuilder,
          (
            MonthlyGoal,
            BaseReferences<_$AppDatabase, $MonthlyGoalsTable, MonthlyGoal>,
          ),
          MonthlyGoal,
          PrefetchHooks Function()
        > {
  $$MonthlyGoalsTableTableManager(_$AppDatabase db, $MonthlyGoalsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MonthlyGoalsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MonthlyGoalsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MonthlyGoalsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> month = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<bool> isDone = const Value.absent(),
              }) => MonthlyGoalsCompanion(
                id: id,
                month: month,
                title: title,
                isDone: isDone,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int month,
                required String title,
                Value<bool> isDone = const Value.absent(),
              }) => MonthlyGoalsCompanion.insert(
                id: id,
                month: month,
                title: title,
                isDone: isDone,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MonthlyGoalsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MonthlyGoalsTable,
      MonthlyGoal,
      $$MonthlyGoalsTableFilterComposer,
      $$MonthlyGoalsTableOrderingComposer,
      $$MonthlyGoalsTableAnnotationComposer,
      $$MonthlyGoalsTableCreateCompanionBuilder,
      $$MonthlyGoalsTableUpdateCompanionBuilder,
      (
        MonthlyGoal,
        BaseReferences<_$AppDatabase, $MonthlyGoalsTable, MonthlyGoal>,
      ),
      MonthlyGoal,
      PrefetchHooks Function()
    >;
typedef $$LettersTableCreateCompanionBuilder =
    LettersCompanion Function({
      Value<int> id,
      required int createdAt,
      required int deliverAt,
      required String body,
      Value<bool> isOpened,
      Value<int?> openedAt,
      Value<String?> reaction,
      Value<String?> reply,
    });
typedef $$LettersTableUpdateCompanionBuilder =
    LettersCompanion Function({
      Value<int> id,
      Value<int> createdAt,
      Value<int> deliverAt,
      Value<String> body,
      Value<bool> isOpened,
      Value<int?> openedAt,
      Value<String?> reaction,
      Value<String?> reply,
    });

class $$LettersTableFilterComposer
    extends Composer<_$AppDatabase, $LettersTable> {
  $$LettersTableFilterComposer({
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

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deliverAt => $composableBuilder(
    column: $table.deliverAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isOpened => $composableBuilder(
    column: $table.isOpened,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get openedAt => $composableBuilder(
    column: $table.openedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reaction => $composableBuilder(
    column: $table.reaction,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reply => $composableBuilder(
    column: $table.reply,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LettersTableOrderingComposer
    extends Composer<_$AppDatabase, $LettersTable> {
  $$LettersTableOrderingComposer({
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

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deliverAt => $composableBuilder(
    column: $table.deliverAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isOpened => $composableBuilder(
    column: $table.isOpened,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get openedAt => $composableBuilder(
    column: $table.openedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reaction => $composableBuilder(
    column: $table.reaction,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reply => $composableBuilder(
    column: $table.reply,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LettersTableAnnotationComposer
    extends Composer<_$AppDatabase, $LettersTable> {
  $$LettersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get deliverAt =>
      $composableBuilder(column: $table.deliverAt, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<bool> get isOpened =>
      $composableBuilder(column: $table.isOpened, builder: (column) => column);

  GeneratedColumn<int> get openedAt =>
      $composableBuilder(column: $table.openedAt, builder: (column) => column);

  GeneratedColumn<String> get reaction =>
      $composableBuilder(column: $table.reaction, builder: (column) => column);

  GeneratedColumn<String> get reply =>
      $composableBuilder(column: $table.reply, builder: (column) => column);
}

class $$LettersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LettersTable,
          Letter,
          $$LettersTableFilterComposer,
          $$LettersTableOrderingComposer,
          $$LettersTableAnnotationComposer,
          $$LettersTableCreateCompanionBuilder,
          $$LettersTableUpdateCompanionBuilder,
          (Letter, BaseReferences<_$AppDatabase, $LettersTable, Letter>),
          Letter,
          PrefetchHooks Function()
        > {
  $$LettersTableTableManager(_$AppDatabase db, $LettersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LettersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LettersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LettersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> deliverAt = const Value.absent(),
                Value<String> body = const Value.absent(),
                Value<bool> isOpened = const Value.absent(),
                Value<int?> openedAt = const Value.absent(),
                Value<String?> reaction = const Value.absent(),
                Value<String?> reply = const Value.absent(),
              }) => LettersCompanion(
                id: id,
                createdAt: createdAt,
                deliverAt: deliverAt,
                body: body,
                isOpened: isOpened,
                openedAt: openedAt,
                reaction: reaction,
                reply: reply,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int createdAt,
                required int deliverAt,
                required String body,
                Value<bool> isOpened = const Value.absent(),
                Value<int?> openedAt = const Value.absent(),
                Value<String?> reaction = const Value.absent(),
                Value<String?> reply = const Value.absent(),
              }) => LettersCompanion.insert(
                id: id,
                createdAt: createdAt,
                deliverAt: deliverAt,
                body: body,
                isOpened: isOpened,
                openedAt: openedAt,
                reaction: reaction,
                reply: reply,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LettersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LettersTable,
      Letter,
      $$LettersTableFilterComposer,
      $$LettersTableOrderingComposer,
      $$LettersTableAnnotationComposer,
      $$LettersTableCreateCompanionBuilder,
      $$LettersTableUpdateCompanionBuilder,
      (Letter, BaseReferences<_$AppDatabase, $LettersTable, Letter>),
      Letter,
      PrefetchHooks Function()
    >;
typedef $$WeeklyIntentionsTableCreateCompanionBuilder =
    WeeklyIntentionsCompanion Function({
      Value<int> id,
      required int weekStart,
      Value<String?> intention,
    });
typedef $$WeeklyIntentionsTableUpdateCompanionBuilder =
    WeeklyIntentionsCompanion Function({
      Value<int> id,
      Value<int> weekStart,
      Value<String?> intention,
    });

class $$WeeklyIntentionsTableFilterComposer
    extends Composer<_$AppDatabase, $WeeklyIntentionsTable> {
  $$WeeklyIntentionsTableFilterComposer({
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

  ColumnFilters<int> get weekStart => $composableBuilder(
    column: $table.weekStart,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get intention => $composableBuilder(
    column: $table.intention,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WeeklyIntentionsTableOrderingComposer
    extends Composer<_$AppDatabase, $WeeklyIntentionsTable> {
  $$WeeklyIntentionsTableOrderingComposer({
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

  ColumnOrderings<int> get weekStart => $composableBuilder(
    column: $table.weekStart,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get intention => $composableBuilder(
    column: $table.intention,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WeeklyIntentionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WeeklyIntentionsTable> {
  $$WeeklyIntentionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get weekStart =>
      $composableBuilder(column: $table.weekStart, builder: (column) => column);

  GeneratedColumn<String> get intention =>
      $composableBuilder(column: $table.intention, builder: (column) => column);
}

class $$WeeklyIntentionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WeeklyIntentionsTable,
          WeeklyIntention,
          $$WeeklyIntentionsTableFilterComposer,
          $$WeeklyIntentionsTableOrderingComposer,
          $$WeeklyIntentionsTableAnnotationComposer,
          $$WeeklyIntentionsTableCreateCompanionBuilder,
          $$WeeklyIntentionsTableUpdateCompanionBuilder,
          (
            WeeklyIntention,
            BaseReferences<
              _$AppDatabase,
              $WeeklyIntentionsTable,
              WeeklyIntention
            >,
          ),
          WeeklyIntention,
          PrefetchHooks Function()
        > {
  $$WeeklyIntentionsTableTableManager(
    _$AppDatabase db,
    $WeeklyIntentionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WeeklyIntentionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WeeklyIntentionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WeeklyIntentionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> weekStart = const Value.absent(),
                Value<String?> intention = const Value.absent(),
              }) => WeeklyIntentionsCompanion(
                id: id,
                weekStart: weekStart,
                intention: intention,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int weekStart,
                Value<String?> intention = const Value.absent(),
              }) => WeeklyIntentionsCompanion.insert(
                id: id,
                weekStart: weekStart,
                intention: intention,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WeeklyIntentionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WeeklyIntentionsTable,
      WeeklyIntention,
      $$WeeklyIntentionsTableFilterComposer,
      $$WeeklyIntentionsTableOrderingComposer,
      $$WeeklyIntentionsTableAnnotationComposer,
      $$WeeklyIntentionsTableCreateCompanionBuilder,
      $$WeeklyIntentionsTableUpdateCompanionBuilder,
      (
        WeeklyIntention,
        BaseReferences<_$AppDatabase, $WeeklyIntentionsTable, WeeklyIntention>,
      ),
      WeeklyIntention,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$HabitsTableTableManager get habits =>
      $$HabitsTableTableManager(_db, _db.habits);
  $$HabitLogsTableTableManager get habitLogs =>
      $$HabitLogsTableTableManager(_db, _db.habitLogs);
  $$DayNotesTableTableManager get dayNotes =>
      $$DayNotesTableTableManager(_db, _db.dayNotes);
  $$MonthlyGoalsTableTableManager get monthlyGoals =>
      $$MonthlyGoalsTableTableManager(_db, _db.monthlyGoals);
  $$LettersTableTableManager get letters =>
      $$LettersTableTableManager(_db, _db.letters);
  $$WeeklyIntentionsTableTableManager get weeklyIntentions =>
      $$WeeklyIntentionsTableTableManager(_db, _db.weeklyIntentions);
}
