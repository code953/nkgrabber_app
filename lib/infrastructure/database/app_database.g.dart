// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $AccountsTable extends Accounts
    with TableInfo<$AccountsTable, AccountEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AccountsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _studentNoMeta = const VerificationMeta(
    'studentNo',
  );
  @override
  late final GeneratedColumn<String> studentNo = GeneratedColumn<String>(
    'student_no',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<LoginType, String> loginType =
      GeneratedColumn<String>(
        'login_type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<LoginType>($AccountsTable.$converterloginType);
  static const VerificationMeta _credentialRefMeta = const VerificationMeta(
    'credentialRef',
  );
  @override
  late final GeneratedColumn<String> credentialRef = GeneratedColumn<String>(
    'credential_ref',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cookieJarRefMeta = const VerificationMeta(
    'cookieJarRef',
  );
  @override
  late final GeneratedColumn<String> cookieJarRef = GeneratedColumn<String>(
    'cookie_jar_ref',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<AccountStatus, String> status =
      GeneratedColumn<String>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<AccountStatus>($AccountsTable.$converterstatus);
  static const VerificationMeta _lastValidatedAtMeta = const VerificationMeta(
    'lastValidatedAt',
  );
  @override
  late final GeneratedColumn<String> lastValidatedAt = GeneratedColumn<String>(
    'last_validated_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ephemeralMeta = const VerificationMeta(
    'ephemeral',
  );
  @override
  late final GeneratedColumn<bool> ephemeral = GeneratedColumn<bool>(
    'ephemeral',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("ephemeral" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _enabledMeta = const VerificationMeta(
    'enabled',
  );
  @override
  late final GeneratedColumn<bool> enabled = GeneratedColumn<bool>(
    'enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _disabledReasonMeta = const VerificationMeta(
    'disabledReason',
  );
  @override
  late final GeneratedColumn<String> disabledReason = GeneratedColumn<String>(
    'disabled_reason',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    displayName,
    studentNo,
    loginType,
    credentialRef,
    cookieJarRef,
    status,
    lastValidatedAt,
    ephemeral,
    enabled,
    disabledReason,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'accounts';
  @override
  VerificationContext validateIntegrity(
    Insertable<AccountEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('student_no')) {
      context.handle(
        _studentNoMeta,
        studentNo.isAcceptableOrUnknown(data['student_no']!, _studentNoMeta),
      );
    } else if (isInserting) {
      context.missing(_studentNoMeta);
    }
    if (data.containsKey('credential_ref')) {
      context.handle(
        _credentialRefMeta,
        credentialRef.isAcceptableOrUnknown(
          data['credential_ref']!,
          _credentialRefMeta,
        ),
      );
    }
    if (data.containsKey('cookie_jar_ref')) {
      context.handle(
        _cookieJarRefMeta,
        cookieJarRef.isAcceptableOrUnknown(
          data['cookie_jar_ref']!,
          _cookieJarRefMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_cookieJarRefMeta);
    }
    if (data.containsKey('last_validated_at')) {
      context.handle(
        _lastValidatedAtMeta,
        lastValidatedAt.isAcceptableOrUnknown(
          data['last_validated_at']!,
          _lastValidatedAtMeta,
        ),
      );
    }
    if (data.containsKey('ephemeral')) {
      context.handle(
        _ephemeralMeta,
        ephemeral.isAcceptableOrUnknown(data['ephemeral']!, _ephemeralMeta),
      );
    }
    if (data.containsKey('enabled')) {
      context.handle(
        _enabledMeta,
        enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta),
      );
    }
    if (data.containsKey('disabled_reason')) {
      context.handle(
        _disabledReasonMeta,
        disabledReason.isAcceptableOrUnknown(
          data['disabled_reason']!,
          _disabledReasonMeta,
        ),
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AccountEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AccountEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
      studentNo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}student_no'],
      )!,
      loginType: $AccountsTable.$converterloginType.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}login_type'],
        )!,
      ),
      credentialRef: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}credential_ref'],
      ),
      cookieJarRef: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cookie_jar_ref'],
      )!,
      status: $AccountsTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
      lastValidatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_validated_at'],
      ),
      ephemeral: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}ephemeral'],
      )!,
      enabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}enabled'],
      )!,
      disabledReason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}disabled_reason'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $AccountsTable createAlias(String alias) {
    return $AccountsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<LoginType, String, String> $converterloginType =
      const EnumNameConverter<LoginType>(LoginType.values);
  static JsonTypeConverter2<AccountStatus, String, String> $converterstatus =
      const EnumNameConverter<AccountStatus>(AccountStatus.values);
}

class AccountEntry extends DataClass implements Insertable<AccountEntry> {
  /// UUID v4 primary key.
  final String id;

  /// Display name format: "姓名（学号后四位）".
  final String displayName;

  /// Student number.
  final String studentNo;

  /// Login method: 'password' or 'cookie'.
  final LoginType loginType;

  /// Reference to secure storage entry for credentials.
  final String? credentialRef;

  /// Reference to the isolated Cookie Jar for this account.
  final String cookieJarRef;

  /// Current account status.
  final AccountStatus status;

  /// Last time the session was validated against campus.
  final String? lastValidatedAt;

  /// Whether this is a temporary (cookie-mode) account.
  final bool ephemeral;

  /// Whether this account is enabled for grabbing.
  final bool enabled;

  /// Reason for being disabled (e.g., plan limit exceeded).
  final String? disabledReason;

  /// When this account was created.
  final String createdAt;

  /// Last modification timestamp.
  final String updatedAt;
  const AccountEntry({
    required this.id,
    required this.displayName,
    required this.studentNo,
    required this.loginType,
    this.credentialRef,
    required this.cookieJarRef,
    required this.status,
    this.lastValidatedAt,
    required this.ephemeral,
    required this.enabled,
    this.disabledReason,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['display_name'] = Variable<String>(displayName);
    map['student_no'] = Variable<String>(studentNo);
    {
      map['login_type'] = Variable<String>(
        $AccountsTable.$converterloginType.toSql(loginType),
      );
    }
    if (!nullToAbsent || credentialRef != null) {
      map['credential_ref'] = Variable<String>(credentialRef);
    }
    map['cookie_jar_ref'] = Variable<String>(cookieJarRef);
    {
      map['status'] = Variable<String>(
        $AccountsTable.$converterstatus.toSql(status),
      );
    }
    if (!nullToAbsent || lastValidatedAt != null) {
      map['last_validated_at'] = Variable<String>(lastValidatedAt);
    }
    map['ephemeral'] = Variable<bool>(ephemeral);
    map['enabled'] = Variable<bool>(enabled);
    if (!nullToAbsent || disabledReason != null) {
      map['disabled_reason'] = Variable<String>(disabledReason);
    }
    map['created_at'] = Variable<String>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    return map;
  }

  AccountsCompanion toCompanion(bool nullToAbsent) {
    return AccountsCompanion(
      id: Value(id),
      displayName: Value(displayName),
      studentNo: Value(studentNo),
      loginType: Value(loginType),
      credentialRef: credentialRef == null && nullToAbsent
          ? const Value.absent()
          : Value(credentialRef),
      cookieJarRef: Value(cookieJarRef),
      status: Value(status),
      lastValidatedAt: lastValidatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastValidatedAt),
      ephemeral: Value(ephemeral),
      enabled: Value(enabled),
      disabledReason: disabledReason == null && nullToAbsent
          ? const Value.absent()
          : Value(disabledReason),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory AccountEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AccountEntry(
      id: serializer.fromJson<String>(json['id']),
      displayName: serializer.fromJson<String>(json['displayName']),
      studentNo: serializer.fromJson<String>(json['studentNo']),
      loginType: $AccountsTable.$converterloginType.fromJson(
        serializer.fromJson<String>(json['loginType']),
      ),
      credentialRef: serializer.fromJson<String?>(json['credentialRef']),
      cookieJarRef: serializer.fromJson<String>(json['cookieJarRef']),
      status: $AccountsTable.$converterstatus.fromJson(
        serializer.fromJson<String>(json['status']),
      ),
      lastValidatedAt: serializer.fromJson<String?>(json['lastValidatedAt']),
      ephemeral: serializer.fromJson<bool>(json['ephemeral']),
      enabled: serializer.fromJson<bool>(json['enabled']),
      disabledReason: serializer.fromJson<String?>(json['disabledReason']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'displayName': serializer.toJson<String>(displayName),
      'studentNo': serializer.toJson<String>(studentNo),
      'loginType': serializer.toJson<String>(
        $AccountsTable.$converterloginType.toJson(loginType),
      ),
      'credentialRef': serializer.toJson<String?>(credentialRef),
      'cookieJarRef': serializer.toJson<String>(cookieJarRef),
      'status': serializer.toJson<String>(
        $AccountsTable.$converterstatus.toJson(status),
      ),
      'lastValidatedAt': serializer.toJson<String?>(lastValidatedAt),
      'ephemeral': serializer.toJson<bool>(ephemeral),
      'enabled': serializer.toJson<bool>(enabled),
      'disabledReason': serializer.toJson<String?>(disabledReason),
      'createdAt': serializer.toJson<String>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
    };
  }

  AccountEntry copyWith({
    String? id,
    String? displayName,
    String? studentNo,
    LoginType? loginType,
    Value<String?> credentialRef = const Value.absent(),
    String? cookieJarRef,
    AccountStatus? status,
    Value<String?> lastValidatedAt = const Value.absent(),
    bool? ephemeral,
    bool? enabled,
    Value<String?> disabledReason = const Value.absent(),
    String? createdAt,
    String? updatedAt,
  }) => AccountEntry(
    id: id ?? this.id,
    displayName: displayName ?? this.displayName,
    studentNo: studentNo ?? this.studentNo,
    loginType: loginType ?? this.loginType,
    credentialRef: credentialRef.present
        ? credentialRef.value
        : this.credentialRef,
    cookieJarRef: cookieJarRef ?? this.cookieJarRef,
    status: status ?? this.status,
    lastValidatedAt: lastValidatedAt.present
        ? lastValidatedAt.value
        : this.lastValidatedAt,
    ephemeral: ephemeral ?? this.ephemeral,
    enabled: enabled ?? this.enabled,
    disabledReason: disabledReason.present
        ? disabledReason.value
        : this.disabledReason,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  AccountEntry copyWithCompanion(AccountsCompanion data) {
    return AccountEntry(
      id: data.id.present ? data.id.value : this.id,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      studentNo: data.studentNo.present ? data.studentNo.value : this.studentNo,
      loginType: data.loginType.present ? data.loginType.value : this.loginType,
      credentialRef: data.credentialRef.present
          ? data.credentialRef.value
          : this.credentialRef,
      cookieJarRef: data.cookieJarRef.present
          ? data.cookieJarRef.value
          : this.cookieJarRef,
      status: data.status.present ? data.status.value : this.status,
      lastValidatedAt: data.lastValidatedAt.present
          ? data.lastValidatedAt.value
          : this.lastValidatedAt,
      ephemeral: data.ephemeral.present ? data.ephemeral.value : this.ephemeral,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
      disabledReason: data.disabledReason.present
          ? data.disabledReason.value
          : this.disabledReason,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AccountEntry(')
          ..write('id: $id, ')
          ..write('displayName: $displayName, ')
          ..write('studentNo: $studentNo, ')
          ..write('loginType: $loginType, ')
          ..write('credentialRef: $credentialRef, ')
          ..write('cookieJarRef: $cookieJarRef, ')
          ..write('status: $status, ')
          ..write('lastValidatedAt: $lastValidatedAt, ')
          ..write('ephemeral: $ephemeral, ')
          ..write('enabled: $enabled, ')
          ..write('disabledReason: $disabledReason, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    displayName,
    studentNo,
    loginType,
    credentialRef,
    cookieJarRef,
    status,
    lastValidatedAt,
    ephemeral,
    enabled,
    disabledReason,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AccountEntry &&
          other.id == this.id &&
          other.displayName == this.displayName &&
          other.studentNo == this.studentNo &&
          other.loginType == this.loginType &&
          other.credentialRef == this.credentialRef &&
          other.cookieJarRef == this.cookieJarRef &&
          other.status == this.status &&
          other.lastValidatedAt == this.lastValidatedAt &&
          other.ephemeral == this.ephemeral &&
          other.enabled == this.enabled &&
          other.disabledReason == this.disabledReason &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class AccountsCompanion extends UpdateCompanion<AccountEntry> {
  final Value<String> id;
  final Value<String> displayName;
  final Value<String> studentNo;
  final Value<LoginType> loginType;
  final Value<String?> credentialRef;
  final Value<String> cookieJarRef;
  final Value<AccountStatus> status;
  final Value<String?> lastValidatedAt;
  final Value<bool> ephemeral;
  final Value<bool> enabled;
  final Value<String?> disabledReason;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  final Value<int> rowid;
  const AccountsCompanion({
    this.id = const Value.absent(),
    this.displayName = const Value.absent(),
    this.studentNo = const Value.absent(),
    this.loginType = const Value.absent(),
    this.credentialRef = const Value.absent(),
    this.cookieJarRef = const Value.absent(),
    this.status = const Value.absent(),
    this.lastValidatedAt = const Value.absent(),
    this.ephemeral = const Value.absent(),
    this.enabled = const Value.absent(),
    this.disabledReason = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AccountsCompanion.insert({
    required String id,
    required String displayName,
    required String studentNo,
    required LoginType loginType,
    this.credentialRef = const Value.absent(),
    required String cookieJarRef,
    required AccountStatus status,
    this.lastValidatedAt = const Value.absent(),
    this.ephemeral = const Value.absent(),
    this.enabled = const Value.absent(),
    this.disabledReason = const Value.absent(),
    required String createdAt,
    required String updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       displayName = Value(displayName),
       studentNo = Value(studentNo),
       loginType = Value(loginType),
       cookieJarRef = Value(cookieJarRef),
       status = Value(status),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<AccountEntry> custom({
    Expression<String>? id,
    Expression<String>? displayName,
    Expression<String>? studentNo,
    Expression<String>? loginType,
    Expression<String>? credentialRef,
    Expression<String>? cookieJarRef,
    Expression<String>? status,
    Expression<String>? lastValidatedAt,
    Expression<bool>? ephemeral,
    Expression<bool>? enabled,
    Expression<String>? disabledReason,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (displayName != null) 'display_name': displayName,
      if (studentNo != null) 'student_no': studentNo,
      if (loginType != null) 'login_type': loginType,
      if (credentialRef != null) 'credential_ref': credentialRef,
      if (cookieJarRef != null) 'cookie_jar_ref': cookieJarRef,
      if (status != null) 'status': status,
      if (lastValidatedAt != null) 'last_validated_at': lastValidatedAt,
      if (ephemeral != null) 'ephemeral': ephemeral,
      if (enabled != null) 'enabled': enabled,
      if (disabledReason != null) 'disabled_reason': disabledReason,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AccountsCompanion copyWith({
    Value<String>? id,
    Value<String>? displayName,
    Value<String>? studentNo,
    Value<LoginType>? loginType,
    Value<String?>? credentialRef,
    Value<String>? cookieJarRef,
    Value<AccountStatus>? status,
    Value<String?>? lastValidatedAt,
    Value<bool>? ephemeral,
    Value<bool>? enabled,
    Value<String?>? disabledReason,
    Value<String>? createdAt,
    Value<String>? updatedAt,
    Value<int>? rowid,
  }) {
    return AccountsCompanion(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      studentNo: studentNo ?? this.studentNo,
      loginType: loginType ?? this.loginType,
      credentialRef: credentialRef ?? this.credentialRef,
      cookieJarRef: cookieJarRef ?? this.cookieJarRef,
      status: status ?? this.status,
      lastValidatedAt: lastValidatedAt ?? this.lastValidatedAt,
      ephemeral: ephemeral ?? this.ephemeral,
      enabled: enabled ?? this.enabled,
      disabledReason: disabledReason ?? this.disabledReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (studentNo.present) {
      map['student_no'] = Variable<String>(studentNo.value);
    }
    if (loginType.present) {
      map['login_type'] = Variable<String>(
        $AccountsTable.$converterloginType.toSql(loginType.value),
      );
    }
    if (credentialRef.present) {
      map['credential_ref'] = Variable<String>(credentialRef.value);
    }
    if (cookieJarRef.present) {
      map['cookie_jar_ref'] = Variable<String>(cookieJarRef.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $AccountsTable.$converterstatus.toSql(status.value),
      );
    }
    if (lastValidatedAt.present) {
      map['last_validated_at'] = Variable<String>(lastValidatedAt.value);
    }
    if (ephemeral.present) {
      map['ephemeral'] = Variable<bool>(ephemeral.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<bool>(enabled.value);
    }
    if (disabledReason.present) {
      map['disabled_reason'] = Variable<String>(disabledReason.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AccountsCompanion(')
          ..write('id: $id, ')
          ..write('displayName: $displayName, ')
          ..write('studentNo: $studentNo, ')
          ..write('loginType: $loginType, ')
          ..write('credentialRef: $credentialRef, ')
          ..write('cookieJarRef: $cookieJarRef, ')
          ..write('status: $status, ')
          ..write('lastValidatedAt: $lastValidatedAt, ')
          ..write('ephemeral: $ephemeral, ')
          ..write('enabled: $enabled, ')
          ..write('disabledReason: $disabledReason, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CourseTargetsTable extends CourseTargets
    with TableInfo<$CourseTargetsTable, CourseTargetEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CourseTargetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES accounts (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _xkidMeta = const VerificationMeta('xkid');
  @override
  late final GeneratedColumn<String> xkid = GeneratedColumn<String>(
    'xkid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _xkmsMeta = const VerificationMeta('xkms');
  @override
  late final GeneratedColumn<String> xkms = GeneratedColumn<String>(
    'xkms',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kmhMeta = const VerificationMeta('kmh');
  @override
  late final GeneratedColumn<String> kmh = GeneratedColumn<String>(
    'kmh',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _xbkidMeta = const VerificationMeta('xbkid');
  @override
  late final GeneratedColumn<String> xbkid = GeneratedColumn<String>(
    'xbkid',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _batchNameMeta = const VerificationMeta(
    'batchName',
  );
  @override
  late final GeneratedColumn<String> batchName = GeneratedColumn<String>(
    'batch_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _courseNameMeta = const VerificationMeta(
    'courseName',
  );
  @override
  late final GeneratedColumn<String> courseName = GeneratedColumn<String>(
    'course_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _enabledMeta = const VerificationMeta(
    'enabled',
  );
  @override
  late final GeneratedColumn<bool> enabled = GeneratedColumn<bool>(
    'enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _snapshotAtMeta = const VerificationMeta(
    'snapshotAt',
  );
  @override
  late final GeneratedColumn<String> snapshotAt = GeneratedColumn<String>(
    'snapshot_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    accountId,
    xkid,
    xkms,
    kmh,
    xbkid,
    batchName,
    courseName,
    priority,
    enabled,
    snapshotAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'course_targets';
  @override
  VerificationContext validateIntegrity(
    Insertable<CourseTargetEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('xkid')) {
      context.handle(
        _xkidMeta,
        xkid.isAcceptableOrUnknown(data['xkid']!, _xkidMeta),
      );
    } else if (isInserting) {
      context.missing(_xkidMeta);
    }
    if (data.containsKey('xkms')) {
      context.handle(
        _xkmsMeta,
        xkms.isAcceptableOrUnknown(data['xkms']!, _xkmsMeta),
      );
    } else if (isInserting) {
      context.missing(_xkmsMeta);
    }
    if (data.containsKey('kmh')) {
      context.handle(
        _kmhMeta,
        kmh.isAcceptableOrUnknown(data['kmh']!, _kmhMeta),
      );
    } else if (isInserting) {
      context.missing(_kmhMeta);
    }
    if (data.containsKey('xbkid')) {
      context.handle(
        _xbkidMeta,
        xbkid.isAcceptableOrUnknown(data['xbkid']!, _xbkidMeta),
      );
    }
    if (data.containsKey('batch_name')) {
      context.handle(
        _batchNameMeta,
        batchName.isAcceptableOrUnknown(data['batch_name']!, _batchNameMeta),
      );
    } else if (isInserting) {
      context.missing(_batchNameMeta);
    }
    if (data.containsKey('course_name')) {
      context.handle(
        _courseNameMeta,
        courseName.isAcceptableOrUnknown(data['course_name']!, _courseNameMeta),
      );
    } else if (isInserting) {
      context.missing(_courseNameMeta);
    }
    if (data.containsKey('priority')) {
      context.handle(
        _priorityMeta,
        priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta),
      );
    }
    if (data.containsKey('enabled')) {
      context.handle(
        _enabledMeta,
        enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta),
      );
    }
    if (data.containsKey('snapshot_at')) {
      context.handle(
        _snapshotAtMeta,
        snapshotAt.isAcceptableOrUnknown(data['snapshot_at']!, _snapshotAtMeta),
      );
    } else if (isInserting) {
      context.missing(_snapshotAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CourseTargetEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CourseTargetEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      )!,
      xkid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}xkid'],
      )!,
      xkms: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}xkms'],
      )!,
      kmh: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kmh'],
      )!,
      xbkid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}xbkid'],
      ),
      batchName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}batch_name'],
      )!,
      courseName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}course_name'],
      )!,
      priority: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}priority'],
      )!,
      enabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}enabled'],
      )!,
      snapshotAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}snapshot_at'],
      )!,
    );
  }

  @override
  $CourseTargetsTable createAlias(String alias) {
    return $CourseTargetsTable(attachedDatabase, alias);
  }
}

class CourseTargetEntry extends DataClass
    implements Insertable<CourseTargetEntry> {
  /// UUID v4 primary key.
  final String id;

  /// FK to Account.id — cascading delete.
  final String accountId;

  /// 选课批次 ID from campus system.
  final String xkid;

  /// 选课模式: "1"=抢选, "2"=正选, "3"=补退选.
  final String xkms;

  /// 课目号 — the real course number used for submission.
  final String kmh;

  /// 选报课 ID — display group, may differ from kmh.
  final String? xbkid;

  /// Snapshot of batch name at configuration time.
  final String batchName;

  /// Snapshot of course name at configuration time.
  final String courseName;

  /// Priority ordering (lower = higher priority).
  final int priority;

  /// Whether this target is active.
  final bool enabled;

  /// When the course info was captured.
  final String snapshotAt;
  const CourseTargetEntry({
    required this.id,
    required this.accountId,
    required this.xkid,
    required this.xkms,
    required this.kmh,
    this.xbkid,
    required this.batchName,
    required this.courseName,
    required this.priority,
    required this.enabled,
    required this.snapshotAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['account_id'] = Variable<String>(accountId);
    map['xkid'] = Variable<String>(xkid);
    map['xkms'] = Variable<String>(xkms);
    map['kmh'] = Variable<String>(kmh);
    if (!nullToAbsent || xbkid != null) {
      map['xbkid'] = Variable<String>(xbkid);
    }
    map['batch_name'] = Variable<String>(batchName);
    map['course_name'] = Variable<String>(courseName);
    map['priority'] = Variable<int>(priority);
    map['enabled'] = Variable<bool>(enabled);
    map['snapshot_at'] = Variable<String>(snapshotAt);
    return map;
  }

  CourseTargetsCompanion toCompanion(bool nullToAbsent) {
    return CourseTargetsCompanion(
      id: Value(id),
      accountId: Value(accountId),
      xkid: Value(xkid),
      xkms: Value(xkms),
      kmh: Value(kmh),
      xbkid: xbkid == null && nullToAbsent
          ? const Value.absent()
          : Value(xbkid),
      batchName: Value(batchName),
      courseName: Value(courseName),
      priority: Value(priority),
      enabled: Value(enabled),
      snapshotAt: Value(snapshotAt),
    );
  }

  factory CourseTargetEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CourseTargetEntry(
      id: serializer.fromJson<String>(json['id']),
      accountId: serializer.fromJson<String>(json['accountId']),
      xkid: serializer.fromJson<String>(json['xkid']),
      xkms: serializer.fromJson<String>(json['xkms']),
      kmh: serializer.fromJson<String>(json['kmh']),
      xbkid: serializer.fromJson<String?>(json['xbkid']),
      batchName: serializer.fromJson<String>(json['batchName']),
      courseName: serializer.fromJson<String>(json['courseName']),
      priority: serializer.fromJson<int>(json['priority']),
      enabled: serializer.fromJson<bool>(json['enabled']),
      snapshotAt: serializer.fromJson<String>(json['snapshotAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'accountId': serializer.toJson<String>(accountId),
      'xkid': serializer.toJson<String>(xkid),
      'xkms': serializer.toJson<String>(xkms),
      'kmh': serializer.toJson<String>(kmh),
      'xbkid': serializer.toJson<String?>(xbkid),
      'batchName': serializer.toJson<String>(batchName),
      'courseName': serializer.toJson<String>(courseName),
      'priority': serializer.toJson<int>(priority),
      'enabled': serializer.toJson<bool>(enabled),
      'snapshotAt': serializer.toJson<String>(snapshotAt),
    };
  }

  CourseTargetEntry copyWith({
    String? id,
    String? accountId,
    String? xkid,
    String? xkms,
    String? kmh,
    Value<String?> xbkid = const Value.absent(),
    String? batchName,
    String? courseName,
    int? priority,
    bool? enabled,
    String? snapshotAt,
  }) => CourseTargetEntry(
    id: id ?? this.id,
    accountId: accountId ?? this.accountId,
    xkid: xkid ?? this.xkid,
    xkms: xkms ?? this.xkms,
    kmh: kmh ?? this.kmh,
    xbkid: xbkid.present ? xbkid.value : this.xbkid,
    batchName: batchName ?? this.batchName,
    courseName: courseName ?? this.courseName,
    priority: priority ?? this.priority,
    enabled: enabled ?? this.enabled,
    snapshotAt: snapshotAt ?? this.snapshotAt,
  );
  CourseTargetEntry copyWithCompanion(CourseTargetsCompanion data) {
    return CourseTargetEntry(
      id: data.id.present ? data.id.value : this.id,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      xkid: data.xkid.present ? data.xkid.value : this.xkid,
      xkms: data.xkms.present ? data.xkms.value : this.xkms,
      kmh: data.kmh.present ? data.kmh.value : this.kmh,
      xbkid: data.xbkid.present ? data.xbkid.value : this.xbkid,
      batchName: data.batchName.present ? data.batchName.value : this.batchName,
      courseName: data.courseName.present
          ? data.courseName.value
          : this.courseName,
      priority: data.priority.present ? data.priority.value : this.priority,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
      snapshotAt: data.snapshotAt.present
          ? data.snapshotAt.value
          : this.snapshotAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CourseTargetEntry(')
          ..write('id: $id, ')
          ..write('accountId: $accountId, ')
          ..write('xkid: $xkid, ')
          ..write('xkms: $xkms, ')
          ..write('kmh: $kmh, ')
          ..write('xbkid: $xbkid, ')
          ..write('batchName: $batchName, ')
          ..write('courseName: $courseName, ')
          ..write('priority: $priority, ')
          ..write('enabled: $enabled, ')
          ..write('snapshotAt: $snapshotAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    accountId,
    xkid,
    xkms,
    kmh,
    xbkid,
    batchName,
    courseName,
    priority,
    enabled,
    snapshotAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CourseTargetEntry &&
          other.id == this.id &&
          other.accountId == this.accountId &&
          other.xkid == this.xkid &&
          other.xkms == this.xkms &&
          other.kmh == this.kmh &&
          other.xbkid == this.xbkid &&
          other.batchName == this.batchName &&
          other.courseName == this.courseName &&
          other.priority == this.priority &&
          other.enabled == this.enabled &&
          other.snapshotAt == this.snapshotAt);
}

class CourseTargetsCompanion extends UpdateCompanion<CourseTargetEntry> {
  final Value<String> id;
  final Value<String> accountId;
  final Value<String> xkid;
  final Value<String> xkms;
  final Value<String> kmh;
  final Value<String?> xbkid;
  final Value<String> batchName;
  final Value<String> courseName;
  final Value<int> priority;
  final Value<bool> enabled;
  final Value<String> snapshotAt;
  final Value<int> rowid;
  const CourseTargetsCompanion({
    this.id = const Value.absent(),
    this.accountId = const Value.absent(),
    this.xkid = const Value.absent(),
    this.xkms = const Value.absent(),
    this.kmh = const Value.absent(),
    this.xbkid = const Value.absent(),
    this.batchName = const Value.absent(),
    this.courseName = const Value.absent(),
    this.priority = const Value.absent(),
    this.enabled = const Value.absent(),
    this.snapshotAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CourseTargetsCompanion.insert({
    required String id,
    required String accountId,
    required String xkid,
    required String xkms,
    required String kmh,
    this.xbkid = const Value.absent(),
    required String batchName,
    required String courseName,
    this.priority = const Value.absent(),
    this.enabled = const Value.absent(),
    required String snapshotAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       accountId = Value(accountId),
       xkid = Value(xkid),
       xkms = Value(xkms),
       kmh = Value(kmh),
       batchName = Value(batchName),
       courseName = Value(courseName),
       snapshotAt = Value(snapshotAt);
  static Insertable<CourseTargetEntry> custom({
    Expression<String>? id,
    Expression<String>? accountId,
    Expression<String>? xkid,
    Expression<String>? xkms,
    Expression<String>? kmh,
    Expression<String>? xbkid,
    Expression<String>? batchName,
    Expression<String>? courseName,
    Expression<int>? priority,
    Expression<bool>? enabled,
    Expression<String>? snapshotAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (accountId != null) 'account_id': accountId,
      if (xkid != null) 'xkid': xkid,
      if (xkms != null) 'xkms': xkms,
      if (kmh != null) 'kmh': kmh,
      if (xbkid != null) 'xbkid': xbkid,
      if (batchName != null) 'batch_name': batchName,
      if (courseName != null) 'course_name': courseName,
      if (priority != null) 'priority': priority,
      if (enabled != null) 'enabled': enabled,
      if (snapshotAt != null) 'snapshot_at': snapshotAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CourseTargetsCompanion copyWith({
    Value<String>? id,
    Value<String>? accountId,
    Value<String>? xkid,
    Value<String>? xkms,
    Value<String>? kmh,
    Value<String?>? xbkid,
    Value<String>? batchName,
    Value<String>? courseName,
    Value<int>? priority,
    Value<bool>? enabled,
    Value<String>? snapshotAt,
    Value<int>? rowid,
  }) {
    return CourseTargetsCompanion(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      xkid: xkid ?? this.xkid,
      xkms: xkms ?? this.xkms,
      kmh: kmh ?? this.kmh,
      xbkid: xbkid ?? this.xbkid,
      batchName: batchName ?? this.batchName,
      courseName: courseName ?? this.courseName,
      priority: priority ?? this.priority,
      enabled: enabled ?? this.enabled,
      snapshotAt: snapshotAt ?? this.snapshotAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (xkid.present) {
      map['xkid'] = Variable<String>(xkid.value);
    }
    if (xkms.present) {
      map['xkms'] = Variable<String>(xkms.value);
    }
    if (kmh.present) {
      map['kmh'] = Variable<String>(kmh.value);
    }
    if (xbkid.present) {
      map['xbkid'] = Variable<String>(xbkid.value);
    }
    if (batchName.present) {
      map['batch_name'] = Variable<String>(batchName.value);
    }
    if (courseName.present) {
      map['course_name'] = Variable<String>(courseName.value);
    }
    if (priority.present) {
      map['priority'] = Variable<int>(priority.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<bool>(enabled.value);
    }
    if (snapshotAt.present) {
      map['snapshot_at'] = Variable<String>(snapshotAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CourseTargetsCompanion(')
          ..write('id: $id, ')
          ..write('accountId: $accountId, ')
          ..write('xkid: $xkid, ')
          ..write('xkms: $xkms, ')
          ..write('kmh: $kmh, ')
          ..write('xbkid: $xbkid, ')
          ..write('batchName: $batchName, ')
          ..write('courseName: $courseName, ')
          ..write('priority: $priority, ')
          ..write('enabled: $enabled, ')
          ..write('snapshotAt: $snapshotAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GrabTasksTable extends GrabTasks
    with TableInfo<$GrabTasksTable, GrabTaskEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GrabTasksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES accounts (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _targetIdsJsonMeta = const VerificationMeta(
    'targetIdsJson',
  );
  @override
  late final GeneratedColumn<String> targetIdsJson = GeneratedColumn<String>(
    'target_ids_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<GrabTaskStatus, String> status =
      GeneratedColumn<String>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<GrabTaskStatus>($GrabTasksTable.$converterstatus);
  static const VerificationMeta _effectiveIntervalMsMeta =
      const VerificationMeta('effectiveIntervalMs');
  @override
  late final GeneratedColumn<int> effectiveIntervalMs = GeneratedColumn<int>(
    'effective_interval_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<String> startedAt = GeneratedColumn<String>(
    'started_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _stoppedAtMeta = const VerificationMeta(
    'stoppedAt',
  );
  @override
  late final GeneratedColumn<String> stoppedAt = GeneratedColumn<String>(
    'stopped_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastResultJsonMeta = const VerificationMeta(
    'lastResultJson',
  );
  @override
  late final GeneratedColumn<String> lastResultJson = GeneratedColumn<String>(
    'last_result_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    accountId,
    targetIdsJson,
    status,
    effectiveIntervalMs,
    startedAt,
    stoppedAt,
    lastResultJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'grab_tasks';
  @override
  VerificationContext validateIntegrity(
    Insertable<GrabTaskEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('target_ids_json')) {
      context.handle(
        _targetIdsJsonMeta,
        targetIdsJson.isAcceptableOrUnknown(
          data['target_ids_json']!,
          _targetIdsJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_targetIdsJsonMeta);
    }
    if (data.containsKey('effective_interval_ms')) {
      context.handle(
        _effectiveIntervalMsMeta,
        effectiveIntervalMs.isAcceptableOrUnknown(
          data['effective_interval_ms']!,
          _effectiveIntervalMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_effectiveIntervalMsMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    }
    if (data.containsKey('stopped_at')) {
      context.handle(
        _stoppedAtMeta,
        stoppedAt.isAcceptableOrUnknown(data['stopped_at']!, _stoppedAtMeta),
      );
    }
    if (data.containsKey('last_result_json')) {
      context.handle(
        _lastResultJsonMeta,
        lastResultJson.isAcceptableOrUnknown(
          data['last_result_json']!,
          _lastResultJsonMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GrabTaskEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GrabTaskEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      )!,
      targetIdsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_ids_json'],
      )!,
      status: $GrabTasksTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
      effectiveIntervalMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}effective_interval_ms'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}started_at'],
      ),
      stoppedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}stopped_at'],
      ),
      lastResultJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_result_json'],
      ),
    );
  }

  @override
  $GrabTasksTable createAlias(String alias) {
    return $GrabTasksTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<GrabTaskStatus, String, String> $converterstatus =
      const EnumNameConverter<GrabTaskStatus>(GrabTaskStatus.values);
}

class GrabTaskEntry extends DataClass implements Insertable<GrabTaskEntry> {
  /// UUID v4 primary key.
  final String id;

  /// FK to Account.id — cascading delete.
  final String accountId;

  /// JSON array of CourseTarget.id values assigned to this task.
  final String targetIdsJson;

  /// Current task state in the state machine.
  final GrabTaskStatus status;

  /// Effective request interval in milliseconds (max of user setting and plan minimum).
  final int effectiveIntervalMs;

  /// When the task started running.
  final String? startedAt;

  /// When the task was stopped/completed.
  final String? stoppedAt;

  /// Sanitized snapshot of the last submit result (JSON).
  final String? lastResultJson;
  const GrabTaskEntry({
    required this.id,
    required this.accountId,
    required this.targetIdsJson,
    required this.status,
    required this.effectiveIntervalMs,
    this.startedAt,
    this.stoppedAt,
    this.lastResultJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['account_id'] = Variable<String>(accountId);
    map['target_ids_json'] = Variable<String>(targetIdsJson);
    {
      map['status'] = Variable<String>(
        $GrabTasksTable.$converterstatus.toSql(status),
      );
    }
    map['effective_interval_ms'] = Variable<int>(effectiveIntervalMs);
    if (!nullToAbsent || startedAt != null) {
      map['started_at'] = Variable<String>(startedAt);
    }
    if (!nullToAbsent || stoppedAt != null) {
      map['stopped_at'] = Variable<String>(stoppedAt);
    }
    if (!nullToAbsent || lastResultJson != null) {
      map['last_result_json'] = Variable<String>(lastResultJson);
    }
    return map;
  }

  GrabTasksCompanion toCompanion(bool nullToAbsent) {
    return GrabTasksCompanion(
      id: Value(id),
      accountId: Value(accountId),
      targetIdsJson: Value(targetIdsJson),
      status: Value(status),
      effectiveIntervalMs: Value(effectiveIntervalMs),
      startedAt: startedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(startedAt),
      stoppedAt: stoppedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(stoppedAt),
      lastResultJson: lastResultJson == null && nullToAbsent
          ? const Value.absent()
          : Value(lastResultJson),
    );
  }

  factory GrabTaskEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GrabTaskEntry(
      id: serializer.fromJson<String>(json['id']),
      accountId: serializer.fromJson<String>(json['accountId']),
      targetIdsJson: serializer.fromJson<String>(json['targetIdsJson']),
      status: $GrabTasksTable.$converterstatus.fromJson(
        serializer.fromJson<String>(json['status']),
      ),
      effectiveIntervalMs: serializer.fromJson<int>(
        json['effectiveIntervalMs'],
      ),
      startedAt: serializer.fromJson<String?>(json['startedAt']),
      stoppedAt: serializer.fromJson<String?>(json['stoppedAt']),
      lastResultJson: serializer.fromJson<String?>(json['lastResultJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'accountId': serializer.toJson<String>(accountId),
      'targetIdsJson': serializer.toJson<String>(targetIdsJson),
      'status': serializer.toJson<String>(
        $GrabTasksTable.$converterstatus.toJson(status),
      ),
      'effectiveIntervalMs': serializer.toJson<int>(effectiveIntervalMs),
      'startedAt': serializer.toJson<String?>(startedAt),
      'stoppedAt': serializer.toJson<String?>(stoppedAt),
      'lastResultJson': serializer.toJson<String?>(lastResultJson),
    };
  }

  GrabTaskEntry copyWith({
    String? id,
    String? accountId,
    String? targetIdsJson,
    GrabTaskStatus? status,
    int? effectiveIntervalMs,
    Value<String?> startedAt = const Value.absent(),
    Value<String?> stoppedAt = const Value.absent(),
    Value<String?> lastResultJson = const Value.absent(),
  }) => GrabTaskEntry(
    id: id ?? this.id,
    accountId: accountId ?? this.accountId,
    targetIdsJson: targetIdsJson ?? this.targetIdsJson,
    status: status ?? this.status,
    effectiveIntervalMs: effectiveIntervalMs ?? this.effectiveIntervalMs,
    startedAt: startedAt.present ? startedAt.value : this.startedAt,
    stoppedAt: stoppedAt.present ? stoppedAt.value : this.stoppedAt,
    lastResultJson: lastResultJson.present
        ? lastResultJson.value
        : this.lastResultJson,
  );
  GrabTaskEntry copyWithCompanion(GrabTasksCompanion data) {
    return GrabTaskEntry(
      id: data.id.present ? data.id.value : this.id,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      targetIdsJson: data.targetIdsJson.present
          ? data.targetIdsJson.value
          : this.targetIdsJson,
      status: data.status.present ? data.status.value : this.status,
      effectiveIntervalMs: data.effectiveIntervalMs.present
          ? data.effectiveIntervalMs.value
          : this.effectiveIntervalMs,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      stoppedAt: data.stoppedAt.present ? data.stoppedAt.value : this.stoppedAt,
      lastResultJson: data.lastResultJson.present
          ? data.lastResultJson.value
          : this.lastResultJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GrabTaskEntry(')
          ..write('id: $id, ')
          ..write('accountId: $accountId, ')
          ..write('targetIdsJson: $targetIdsJson, ')
          ..write('status: $status, ')
          ..write('effectiveIntervalMs: $effectiveIntervalMs, ')
          ..write('startedAt: $startedAt, ')
          ..write('stoppedAt: $stoppedAt, ')
          ..write('lastResultJson: $lastResultJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    accountId,
    targetIdsJson,
    status,
    effectiveIntervalMs,
    startedAt,
    stoppedAt,
    lastResultJson,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GrabTaskEntry &&
          other.id == this.id &&
          other.accountId == this.accountId &&
          other.targetIdsJson == this.targetIdsJson &&
          other.status == this.status &&
          other.effectiveIntervalMs == this.effectiveIntervalMs &&
          other.startedAt == this.startedAt &&
          other.stoppedAt == this.stoppedAt &&
          other.lastResultJson == this.lastResultJson);
}

class GrabTasksCompanion extends UpdateCompanion<GrabTaskEntry> {
  final Value<String> id;
  final Value<String> accountId;
  final Value<String> targetIdsJson;
  final Value<GrabTaskStatus> status;
  final Value<int> effectiveIntervalMs;
  final Value<String?> startedAt;
  final Value<String?> stoppedAt;
  final Value<String?> lastResultJson;
  final Value<int> rowid;
  const GrabTasksCompanion({
    this.id = const Value.absent(),
    this.accountId = const Value.absent(),
    this.targetIdsJson = const Value.absent(),
    this.status = const Value.absent(),
    this.effectiveIntervalMs = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.stoppedAt = const Value.absent(),
    this.lastResultJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GrabTasksCompanion.insert({
    required String id,
    required String accountId,
    required String targetIdsJson,
    required GrabTaskStatus status,
    required int effectiveIntervalMs,
    this.startedAt = const Value.absent(),
    this.stoppedAt = const Value.absent(),
    this.lastResultJson = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       accountId = Value(accountId),
       targetIdsJson = Value(targetIdsJson),
       status = Value(status),
       effectiveIntervalMs = Value(effectiveIntervalMs);
  static Insertable<GrabTaskEntry> custom({
    Expression<String>? id,
    Expression<String>? accountId,
    Expression<String>? targetIdsJson,
    Expression<String>? status,
    Expression<int>? effectiveIntervalMs,
    Expression<String>? startedAt,
    Expression<String>? stoppedAt,
    Expression<String>? lastResultJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (accountId != null) 'account_id': accountId,
      if (targetIdsJson != null) 'target_ids_json': targetIdsJson,
      if (status != null) 'status': status,
      if (effectiveIntervalMs != null)
        'effective_interval_ms': effectiveIntervalMs,
      if (startedAt != null) 'started_at': startedAt,
      if (stoppedAt != null) 'stopped_at': stoppedAt,
      if (lastResultJson != null) 'last_result_json': lastResultJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GrabTasksCompanion copyWith({
    Value<String>? id,
    Value<String>? accountId,
    Value<String>? targetIdsJson,
    Value<GrabTaskStatus>? status,
    Value<int>? effectiveIntervalMs,
    Value<String?>? startedAt,
    Value<String?>? stoppedAt,
    Value<String?>? lastResultJson,
    Value<int>? rowid,
  }) {
    return GrabTasksCompanion(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      targetIdsJson: targetIdsJson ?? this.targetIdsJson,
      status: status ?? this.status,
      effectiveIntervalMs: effectiveIntervalMs ?? this.effectiveIntervalMs,
      startedAt: startedAt ?? this.startedAt,
      stoppedAt: stoppedAt ?? this.stoppedAt,
      lastResultJson: lastResultJson ?? this.lastResultJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (targetIdsJson.present) {
      map['target_ids_json'] = Variable<String>(targetIdsJson.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $GrabTasksTable.$converterstatus.toSql(status.value),
      );
    }
    if (effectiveIntervalMs.present) {
      map['effective_interval_ms'] = Variable<int>(effectiveIntervalMs.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<String>(startedAt.value);
    }
    if (stoppedAt.present) {
      map['stopped_at'] = Variable<String>(stoppedAt.value);
    }
    if (lastResultJson.present) {
      map['last_result_json'] = Variable<String>(lastResultJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GrabTasksCompanion(')
          ..write('id: $id, ')
          ..write('accountId: $accountId, ')
          ..write('targetIdsJson: $targetIdsJson, ')
          ..write('status: $status, ')
          ..write('effectiveIntervalMs: $effectiveIntervalMs, ')
          ..write('startedAt: $startedAt, ')
          ..write('stoppedAt: $stoppedAt, ')
          ..write('lastResultJson: $lastResultJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AppSettingsTable extends AppSettings
    with TableInfo<$AppSettingsTable, AppSettingsEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _themeMeta = const VerificationMeta('theme');
  @override
  late final GeneratedColumn<String> theme = GeneratedColumn<String>(
    'theme',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('system'),
  );
  static const VerificationMeta _userIntervalMsMeta = const VerificationMeta(
    'userIntervalMs',
  );
  @override
  late final GeneratedColumn<int> userIntervalMs = GeneratedColumn<int>(
    'user_interval_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1000),
  );
  static const VerificationMeta _updateChannelMeta = const VerificationMeta(
    'updateChannel',
  );
  @override
  late final GeneratedColumn<String> updateChannel = GeneratedColumn<String>(
    'update_channel',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('stable'),
  );
  static const VerificationMeta _logLevelMeta = const VerificationMeta(
    'logLevel',
  );
  @override
  late final GeneratedColumn<String> logLevel = GeneratedColumn<String>(
    'log_level',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('info'),
  );
  static const VerificationMeta _localeMeta = const VerificationMeta('locale');
  @override
  late final GeneratedColumn<String> locale = GeneratedColumn<String>(
    'locale',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('zh_CN'),
  );
  static const VerificationMeta _crashReportingEnabledMeta =
      const VerificationMeta('crashReportingEnabled');
  @override
  late final GeneratedColumn<bool> crashReportingEnabled =
      GeneratedColumn<bool>(
        'crash_reporting_enabled',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("crash_reporting_enabled" IN (0, 1))',
        ),
        defaultValue: const Constant(true),
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    theme,
    userIntervalMs,
    updateChannel,
    logLevel,
    locale,
    crashReportingEnabled,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppSettingsEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('theme')) {
      context.handle(
        _themeMeta,
        theme.isAcceptableOrUnknown(data['theme']!, _themeMeta),
      );
    }
    if (data.containsKey('user_interval_ms')) {
      context.handle(
        _userIntervalMsMeta,
        userIntervalMs.isAcceptableOrUnknown(
          data['user_interval_ms']!,
          _userIntervalMsMeta,
        ),
      );
    }
    if (data.containsKey('update_channel')) {
      context.handle(
        _updateChannelMeta,
        updateChannel.isAcceptableOrUnknown(
          data['update_channel']!,
          _updateChannelMeta,
        ),
      );
    }
    if (data.containsKey('log_level')) {
      context.handle(
        _logLevelMeta,
        logLevel.isAcceptableOrUnknown(data['log_level']!, _logLevelMeta),
      );
    }
    if (data.containsKey('locale')) {
      context.handle(
        _localeMeta,
        locale.isAcceptableOrUnknown(data['locale']!, _localeMeta),
      );
    }
    if (data.containsKey('crash_reporting_enabled')) {
      context.handle(
        _crashReportingEnabledMeta,
        crashReportingEnabled.isAcceptableOrUnknown(
          data['crash_reporting_enabled']!,
          _crashReportingEnabledMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AppSettingsEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSettingsEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      theme: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}theme'],
      )!,
      userIntervalMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}user_interval_ms'],
      )!,
      updateChannel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}update_channel'],
      )!,
      logLevel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}log_level'],
      )!,
      locale: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}locale'],
      )!,
      crashReportingEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}crash_reporting_enabled'],
      )!,
    );
  }

  @override
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }
}

class AppSettingsEntry extends DataClass
    implements Insertable<AppSettingsEntry> {
  /// Singleton row ID (always 1).
  final int id;

  /// UI theme: 'simple', 'anime', or 'system'.
  final String theme;

  /// User-configured request interval in milliseconds.
  final int userIntervalMs;

  /// Update channel preference.
  final String updateChannel;

  /// Minimum log level: 'debug', 'info', 'warn', 'error'.
  final String logLevel;

  /// UI locale code.
  final String locale;

  /// Whether crash reporting is enabled (opt-out).
  final bool crashReportingEnabled;
  const AppSettingsEntry({
    required this.id,
    required this.theme,
    required this.userIntervalMs,
    required this.updateChannel,
    required this.logLevel,
    required this.locale,
    required this.crashReportingEnabled,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['theme'] = Variable<String>(theme);
    map['user_interval_ms'] = Variable<int>(userIntervalMs);
    map['update_channel'] = Variable<String>(updateChannel);
    map['log_level'] = Variable<String>(logLevel);
    map['locale'] = Variable<String>(locale);
    map['crash_reporting_enabled'] = Variable<bool>(crashReportingEnabled);
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(
      id: Value(id),
      theme: Value(theme),
      userIntervalMs: Value(userIntervalMs),
      updateChannel: Value(updateChannel),
      logLevel: Value(logLevel),
      locale: Value(locale),
      crashReportingEnabled: Value(crashReportingEnabled),
    );
  }

  factory AppSettingsEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSettingsEntry(
      id: serializer.fromJson<int>(json['id']),
      theme: serializer.fromJson<String>(json['theme']),
      userIntervalMs: serializer.fromJson<int>(json['userIntervalMs']),
      updateChannel: serializer.fromJson<String>(json['updateChannel']),
      logLevel: serializer.fromJson<String>(json['logLevel']),
      locale: serializer.fromJson<String>(json['locale']),
      crashReportingEnabled: serializer.fromJson<bool>(
        json['crashReportingEnabled'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'theme': serializer.toJson<String>(theme),
      'userIntervalMs': serializer.toJson<int>(userIntervalMs),
      'updateChannel': serializer.toJson<String>(updateChannel),
      'logLevel': serializer.toJson<String>(logLevel),
      'locale': serializer.toJson<String>(locale),
      'crashReportingEnabled': serializer.toJson<bool>(crashReportingEnabled),
    };
  }

  AppSettingsEntry copyWith({
    int? id,
    String? theme,
    int? userIntervalMs,
    String? updateChannel,
    String? logLevel,
    String? locale,
    bool? crashReportingEnabled,
  }) => AppSettingsEntry(
    id: id ?? this.id,
    theme: theme ?? this.theme,
    userIntervalMs: userIntervalMs ?? this.userIntervalMs,
    updateChannel: updateChannel ?? this.updateChannel,
    logLevel: logLevel ?? this.logLevel,
    locale: locale ?? this.locale,
    crashReportingEnabled: crashReportingEnabled ?? this.crashReportingEnabled,
  );
  AppSettingsEntry copyWithCompanion(AppSettingsCompanion data) {
    return AppSettingsEntry(
      id: data.id.present ? data.id.value : this.id,
      theme: data.theme.present ? data.theme.value : this.theme,
      userIntervalMs: data.userIntervalMs.present
          ? data.userIntervalMs.value
          : this.userIntervalMs,
      updateChannel: data.updateChannel.present
          ? data.updateChannel.value
          : this.updateChannel,
      logLevel: data.logLevel.present ? data.logLevel.value : this.logLevel,
      locale: data.locale.present ? data.locale.value : this.locale,
      crashReportingEnabled: data.crashReportingEnabled.present
          ? data.crashReportingEnabled.value
          : this.crashReportingEnabled,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsEntry(')
          ..write('id: $id, ')
          ..write('theme: $theme, ')
          ..write('userIntervalMs: $userIntervalMs, ')
          ..write('updateChannel: $updateChannel, ')
          ..write('logLevel: $logLevel, ')
          ..write('locale: $locale, ')
          ..write('crashReportingEnabled: $crashReportingEnabled')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    theme,
    userIntervalMs,
    updateChannel,
    logLevel,
    locale,
    crashReportingEnabled,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSettingsEntry &&
          other.id == this.id &&
          other.theme == this.theme &&
          other.userIntervalMs == this.userIntervalMs &&
          other.updateChannel == this.updateChannel &&
          other.logLevel == this.logLevel &&
          other.locale == this.locale &&
          other.crashReportingEnabled == this.crashReportingEnabled);
}

class AppSettingsCompanion extends UpdateCompanion<AppSettingsEntry> {
  final Value<int> id;
  final Value<String> theme;
  final Value<int> userIntervalMs;
  final Value<String> updateChannel;
  final Value<String> logLevel;
  final Value<String> locale;
  final Value<bool> crashReportingEnabled;
  const AppSettingsCompanion({
    this.id = const Value.absent(),
    this.theme = const Value.absent(),
    this.userIntervalMs = const Value.absent(),
    this.updateChannel = const Value.absent(),
    this.logLevel = const Value.absent(),
    this.locale = const Value.absent(),
    this.crashReportingEnabled = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    this.id = const Value.absent(),
    this.theme = const Value.absent(),
    this.userIntervalMs = const Value.absent(),
    this.updateChannel = const Value.absent(),
    this.logLevel = const Value.absent(),
    this.locale = const Value.absent(),
    this.crashReportingEnabled = const Value.absent(),
  });
  static Insertable<AppSettingsEntry> custom({
    Expression<int>? id,
    Expression<String>? theme,
    Expression<int>? userIntervalMs,
    Expression<String>? updateChannel,
    Expression<String>? logLevel,
    Expression<String>? locale,
    Expression<bool>? crashReportingEnabled,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (theme != null) 'theme': theme,
      if (userIntervalMs != null) 'user_interval_ms': userIntervalMs,
      if (updateChannel != null) 'update_channel': updateChannel,
      if (logLevel != null) 'log_level': logLevel,
      if (locale != null) 'locale': locale,
      if (crashReportingEnabled != null)
        'crash_reporting_enabled': crashReportingEnabled,
    });
  }

  AppSettingsCompanion copyWith({
    Value<int>? id,
    Value<String>? theme,
    Value<int>? userIntervalMs,
    Value<String>? updateChannel,
    Value<String>? logLevel,
    Value<String>? locale,
    Value<bool>? crashReportingEnabled,
  }) {
    return AppSettingsCompanion(
      id: id ?? this.id,
      theme: theme ?? this.theme,
      userIntervalMs: userIntervalMs ?? this.userIntervalMs,
      updateChannel: updateChannel ?? this.updateChannel,
      logLevel: logLevel ?? this.logLevel,
      locale: locale ?? this.locale,
      crashReportingEnabled:
          crashReportingEnabled ?? this.crashReportingEnabled,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (theme.present) {
      map['theme'] = Variable<String>(theme.value);
    }
    if (userIntervalMs.present) {
      map['user_interval_ms'] = Variable<int>(userIntervalMs.value);
    }
    if (updateChannel.present) {
      map['update_channel'] = Variable<String>(updateChannel.value);
    }
    if (logLevel.present) {
      map['log_level'] = Variable<String>(logLevel.value);
    }
    if (locale.present) {
      map['locale'] = Variable<String>(locale.value);
    }
    if (crashReportingEnabled.present) {
      map['crash_reporting_enabled'] = Variable<bool>(
        crashReportingEnabled.value,
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsCompanion(')
          ..write('id: $id, ')
          ..write('theme: $theme, ')
          ..write('userIntervalMs: $userIntervalMs, ')
          ..write('updateChannel: $updateChannel, ')
          ..write('logLevel: $logLevel, ')
          ..write('locale: $locale, ')
          ..write('crashReportingEnabled: $crashReportingEnabled')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $AccountsTable accounts = $AccountsTable(this);
  late final $CourseTargetsTable courseTargets = $CourseTargetsTable(this);
  late final $GrabTasksTable grabTasks = $GrabTasksTable(this);
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  late final AccountDao accountDao = AccountDao(this as AppDatabase);
  late final CourseTargetDao courseTargetDao = CourseTargetDao(
    this as AppDatabase,
  );
  late final GrabTaskDao grabTaskDao = GrabTaskDao(this as AppDatabase);
  late final SettingsDao settingsDao = SettingsDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    accounts,
    courseTargets,
    grabTasks,
    appSettings,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'accounts',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('course_targets', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'accounts',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('grab_tasks', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$AccountsTableCreateCompanionBuilder =
    AccountsCompanion Function({
      required String id,
      required String displayName,
      required String studentNo,
      required LoginType loginType,
      Value<String?> credentialRef,
      required String cookieJarRef,
      required AccountStatus status,
      Value<String?> lastValidatedAt,
      Value<bool> ephemeral,
      Value<bool> enabled,
      Value<String?> disabledReason,
      required String createdAt,
      required String updatedAt,
      Value<int> rowid,
    });
typedef $$AccountsTableUpdateCompanionBuilder =
    AccountsCompanion Function({
      Value<String> id,
      Value<String> displayName,
      Value<String> studentNo,
      Value<LoginType> loginType,
      Value<String?> credentialRef,
      Value<String> cookieJarRef,
      Value<AccountStatus> status,
      Value<String?> lastValidatedAt,
      Value<bool> ephemeral,
      Value<bool> enabled,
      Value<String?> disabledReason,
      Value<String> createdAt,
      Value<String> updatedAt,
      Value<int> rowid,
    });

final class $$AccountsTableReferences
    extends BaseReferences<_$AppDatabase, $AccountsTable, AccountEntry> {
  $$AccountsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$CourseTargetsTable, List<CourseTargetEntry>>
  _courseTargetsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.courseTargets,
    aliasName: $_aliasNameGenerator(db.accounts.id, db.courseTargets.accountId),
  );

  $$CourseTargetsTableProcessedTableManager get courseTargetsRefs {
    final manager = $$CourseTargetsTableTableManager(
      $_db,
      $_db.courseTargets,
    ).filter((f) => f.accountId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_courseTargetsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$GrabTasksTable, List<GrabTaskEntry>>
  _grabTasksRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.grabTasks,
    aliasName: $_aliasNameGenerator(db.accounts.id, db.grabTasks.accountId),
  );

  $$GrabTasksTableProcessedTableManager get grabTasksRefs {
    final manager = $$GrabTasksTableTableManager(
      $_db,
      $_db.grabTasks,
    ).filter((f) => f.accountId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_grabTasksRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$AccountsTableFilterComposer
    extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableFilterComposer({
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

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get studentNo => $composableBuilder(
    column: $table.studentNo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<LoginType, LoginType, String> get loginType =>
      $composableBuilder(
        column: $table.loginType,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get credentialRef => $composableBuilder(
    column: $table.credentialRef,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cookieJarRef => $composableBuilder(
    column: $table.cookieJarRef,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<AccountStatus, AccountStatus, String>
  get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get lastValidatedAt => $composableBuilder(
    column: $table.lastValidatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get ephemeral => $composableBuilder(
    column: $table.ephemeral,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get disabledReason => $composableBuilder(
    column: $table.disabledReason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> courseTargetsRefs(
    Expression<bool> Function($$CourseTargetsTableFilterComposer f) f,
  ) {
    final $$CourseTargetsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.courseTargets,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CourseTargetsTableFilterComposer(
            $db: $db,
            $table: $db.courseTargets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> grabTasksRefs(
    Expression<bool> Function($$GrabTasksTableFilterComposer f) f,
  ) {
    final $$GrabTasksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.grabTasks,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GrabTasksTableFilterComposer(
            $db: $db,
            $table: $db.grabTasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AccountsTableOrderingComposer
    extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableOrderingComposer({
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

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get studentNo => $composableBuilder(
    column: $table.studentNo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get loginType => $composableBuilder(
    column: $table.loginType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get credentialRef => $composableBuilder(
    column: $table.credentialRef,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cookieJarRef => $composableBuilder(
    column: $table.cookieJarRef,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastValidatedAt => $composableBuilder(
    column: $table.lastValidatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get ephemeral => $composableBuilder(
    column: $table.ephemeral,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get disabledReason => $composableBuilder(
    column: $table.disabledReason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AccountsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get studentNo =>
      $composableBuilder(column: $table.studentNo, builder: (column) => column);

  GeneratedColumnWithTypeConverter<LoginType, String> get loginType =>
      $composableBuilder(column: $table.loginType, builder: (column) => column);

  GeneratedColumn<String> get credentialRef => $composableBuilder(
    column: $table.credentialRef,
    builder: (column) => column,
  );

  GeneratedColumn<String> get cookieJarRef => $composableBuilder(
    column: $table.cookieJarRef,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<AccountStatus, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get lastValidatedAt => $composableBuilder(
    column: $table.lastValidatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get ephemeral =>
      $composableBuilder(column: $table.ephemeral, builder: (column) => column);

  GeneratedColumn<bool> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => column);

  GeneratedColumn<String> get disabledReason => $composableBuilder(
    column: $table.disabledReason,
    builder: (column) => column,
  );

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> courseTargetsRefs<T extends Object>(
    Expression<T> Function($$CourseTargetsTableAnnotationComposer a) f,
  ) {
    final $$CourseTargetsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.courseTargets,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CourseTargetsTableAnnotationComposer(
            $db: $db,
            $table: $db.courseTargets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> grabTasksRefs<T extends Object>(
    Expression<T> Function($$GrabTasksTableAnnotationComposer a) f,
  ) {
    final $$GrabTasksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.grabTasks,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GrabTasksTableAnnotationComposer(
            $db: $db,
            $table: $db.grabTasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AccountsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AccountsTable,
          AccountEntry,
          $$AccountsTableFilterComposer,
          $$AccountsTableOrderingComposer,
          $$AccountsTableAnnotationComposer,
          $$AccountsTableCreateCompanionBuilder,
          $$AccountsTableUpdateCompanionBuilder,
          (AccountEntry, $$AccountsTableReferences),
          AccountEntry,
          PrefetchHooks Function({bool courseTargetsRefs, bool grabTasksRefs})
        > {
  $$AccountsTableTableManager(_$AppDatabase db, $AccountsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AccountsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AccountsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AccountsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<String> studentNo = const Value.absent(),
                Value<LoginType> loginType = const Value.absent(),
                Value<String?> credentialRef = const Value.absent(),
                Value<String> cookieJarRef = const Value.absent(),
                Value<AccountStatus> status = const Value.absent(),
                Value<String?> lastValidatedAt = const Value.absent(),
                Value<bool> ephemeral = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<String?> disabledReason = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AccountsCompanion(
                id: id,
                displayName: displayName,
                studentNo: studentNo,
                loginType: loginType,
                credentialRef: credentialRef,
                cookieJarRef: cookieJarRef,
                status: status,
                lastValidatedAt: lastValidatedAt,
                ephemeral: ephemeral,
                enabled: enabled,
                disabledReason: disabledReason,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String displayName,
                required String studentNo,
                required LoginType loginType,
                Value<String?> credentialRef = const Value.absent(),
                required String cookieJarRef,
                required AccountStatus status,
                Value<String?> lastValidatedAt = const Value.absent(),
                Value<bool> ephemeral = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<String?> disabledReason = const Value.absent(),
                required String createdAt,
                required String updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => AccountsCompanion.insert(
                id: id,
                displayName: displayName,
                studentNo: studentNo,
                loginType: loginType,
                credentialRef: credentialRef,
                cookieJarRef: cookieJarRef,
                status: status,
                lastValidatedAt: lastValidatedAt,
                ephemeral: ephemeral,
                enabled: enabled,
                disabledReason: disabledReason,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$AccountsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({courseTargetsRefs = false, grabTasksRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (courseTargetsRefs) db.courseTargets,
                    if (grabTasksRefs) db.grabTasks,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (courseTargetsRefs)
                        await $_getPrefetchedData<
                          AccountEntry,
                          $AccountsTable,
                          CourseTargetEntry
                        >(
                          currentTable: table,
                          referencedTable: $$AccountsTableReferences
                              ._courseTargetsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AccountsTableReferences(
                                db,
                                table,
                                p0,
                              ).courseTargetsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.accountId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (grabTasksRefs)
                        await $_getPrefetchedData<
                          AccountEntry,
                          $AccountsTable,
                          GrabTaskEntry
                        >(
                          currentTable: table,
                          referencedTable: $$AccountsTableReferences
                              ._grabTasksRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AccountsTableReferences(
                                db,
                                table,
                                p0,
                              ).grabTasksRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.accountId == item.id,
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

typedef $$AccountsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AccountsTable,
      AccountEntry,
      $$AccountsTableFilterComposer,
      $$AccountsTableOrderingComposer,
      $$AccountsTableAnnotationComposer,
      $$AccountsTableCreateCompanionBuilder,
      $$AccountsTableUpdateCompanionBuilder,
      (AccountEntry, $$AccountsTableReferences),
      AccountEntry,
      PrefetchHooks Function({bool courseTargetsRefs, bool grabTasksRefs})
    >;
typedef $$CourseTargetsTableCreateCompanionBuilder =
    CourseTargetsCompanion Function({
      required String id,
      required String accountId,
      required String xkid,
      required String xkms,
      required String kmh,
      Value<String?> xbkid,
      required String batchName,
      required String courseName,
      Value<int> priority,
      Value<bool> enabled,
      required String snapshotAt,
      Value<int> rowid,
    });
typedef $$CourseTargetsTableUpdateCompanionBuilder =
    CourseTargetsCompanion Function({
      Value<String> id,
      Value<String> accountId,
      Value<String> xkid,
      Value<String> xkms,
      Value<String> kmh,
      Value<String?> xbkid,
      Value<String> batchName,
      Value<String> courseName,
      Value<int> priority,
      Value<bool> enabled,
      Value<String> snapshotAt,
      Value<int> rowid,
    });

final class $$CourseTargetsTableReferences
    extends
        BaseReferences<_$AppDatabase, $CourseTargetsTable, CourseTargetEntry> {
  $$CourseTargetsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $AccountsTable _accountIdTable(_$AppDatabase db) =>
      db.accounts.createAlias(
        $_aliasNameGenerator(db.courseTargets.accountId, db.accounts.id),
      );

  $$AccountsTableProcessedTableManager get accountId {
    final $_column = $_itemColumn<String>('account_id')!;

    final manager = $$AccountsTableTableManager(
      $_db,
      $_db.accounts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_accountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CourseTargetsTableFilterComposer
    extends Composer<_$AppDatabase, $CourseTargetsTable> {
  $$CourseTargetsTableFilterComposer({
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

  ColumnFilters<String> get xkid => $composableBuilder(
    column: $table.xkid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get xkms => $composableBuilder(
    column: $table.xkms,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kmh => $composableBuilder(
    column: $table.kmh,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get xbkid => $composableBuilder(
    column: $table.xbkid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get batchName => $composableBuilder(
    column: $table.batchName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get courseName => $composableBuilder(
    column: $table.courseName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get snapshotAt => $composableBuilder(
    column: $table.snapshotAt,
    builder: (column) => ColumnFilters(column),
  );

  $$AccountsTableFilterComposer get accountId {
    final $$AccountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableFilterComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CourseTargetsTableOrderingComposer
    extends Composer<_$AppDatabase, $CourseTargetsTable> {
  $$CourseTargetsTableOrderingComposer({
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

  ColumnOrderings<String> get xkid => $composableBuilder(
    column: $table.xkid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get xkms => $composableBuilder(
    column: $table.xkms,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kmh => $composableBuilder(
    column: $table.kmh,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get xbkid => $composableBuilder(
    column: $table.xbkid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get batchName => $composableBuilder(
    column: $table.batchName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get courseName => $composableBuilder(
    column: $table.courseName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get snapshotAt => $composableBuilder(
    column: $table.snapshotAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$AccountsTableOrderingComposer get accountId {
    final $$AccountsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableOrderingComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CourseTargetsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CourseTargetsTable> {
  $$CourseTargetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get xkid =>
      $composableBuilder(column: $table.xkid, builder: (column) => column);

  GeneratedColumn<String> get xkms =>
      $composableBuilder(column: $table.xkms, builder: (column) => column);

  GeneratedColumn<String> get kmh =>
      $composableBuilder(column: $table.kmh, builder: (column) => column);

  GeneratedColumn<String> get xbkid =>
      $composableBuilder(column: $table.xbkid, builder: (column) => column);

  GeneratedColumn<String> get batchName =>
      $composableBuilder(column: $table.batchName, builder: (column) => column);

  GeneratedColumn<String> get courseName => $composableBuilder(
    column: $table.courseName,
    builder: (column) => column,
  );

  GeneratedColumn<int> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<bool> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => column);

  GeneratedColumn<String> get snapshotAt => $composableBuilder(
    column: $table.snapshotAt,
    builder: (column) => column,
  );

  $$AccountsTableAnnotationComposer get accountId {
    final $$AccountsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableAnnotationComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CourseTargetsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CourseTargetsTable,
          CourseTargetEntry,
          $$CourseTargetsTableFilterComposer,
          $$CourseTargetsTableOrderingComposer,
          $$CourseTargetsTableAnnotationComposer,
          $$CourseTargetsTableCreateCompanionBuilder,
          $$CourseTargetsTableUpdateCompanionBuilder,
          (CourseTargetEntry, $$CourseTargetsTableReferences),
          CourseTargetEntry,
          PrefetchHooks Function({bool accountId})
        > {
  $$CourseTargetsTableTableManager(_$AppDatabase db, $CourseTargetsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CourseTargetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CourseTargetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CourseTargetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> accountId = const Value.absent(),
                Value<String> xkid = const Value.absent(),
                Value<String> xkms = const Value.absent(),
                Value<String> kmh = const Value.absent(),
                Value<String?> xbkid = const Value.absent(),
                Value<String> batchName = const Value.absent(),
                Value<String> courseName = const Value.absent(),
                Value<int> priority = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<String> snapshotAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CourseTargetsCompanion(
                id: id,
                accountId: accountId,
                xkid: xkid,
                xkms: xkms,
                kmh: kmh,
                xbkid: xbkid,
                batchName: batchName,
                courseName: courseName,
                priority: priority,
                enabled: enabled,
                snapshotAt: snapshotAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String accountId,
                required String xkid,
                required String xkms,
                required String kmh,
                Value<String?> xbkid = const Value.absent(),
                required String batchName,
                required String courseName,
                Value<int> priority = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                required String snapshotAt,
                Value<int> rowid = const Value.absent(),
              }) => CourseTargetsCompanion.insert(
                id: id,
                accountId: accountId,
                xkid: xkid,
                xkms: xkms,
                kmh: kmh,
                xbkid: xbkid,
                batchName: batchName,
                courseName: courseName,
                priority: priority,
                enabled: enabled,
                snapshotAt: snapshotAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CourseTargetsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({accountId = false}) {
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
                    if (accountId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.accountId,
                                referencedTable: $$CourseTargetsTableReferences
                                    ._accountIdTable(db),
                                referencedColumn: $$CourseTargetsTableReferences
                                    ._accountIdTable(db)
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

typedef $$CourseTargetsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CourseTargetsTable,
      CourseTargetEntry,
      $$CourseTargetsTableFilterComposer,
      $$CourseTargetsTableOrderingComposer,
      $$CourseTargetsTableAnnotationComposer,
      $$CourseTargetsTableCreateCompanionBuilder,
      $$CourseTargetsTableUpdateCompanionBuilder,
      (CourseTargetEntry, $$CourseTargetsTableReferences),
      CourseTargetEntry,
      PrefetchHooks Function({bool accountId})
    >;
typedef $$GrabTasksTableCreateCompanionBuilder =
    GrabTasksCompanion Function({
      required String id,
      required String accountId,
      required String targetIdsJson,
      required GrabTaskStatus status,
      required int effectiveIntervalMs,
      Value<String?> startedAt,
      Value<String?> stoppedAt,
      Value<String?> lastResultJson,
      Value<int> rowid,
    });
typedef $$GrabTasksTableUpdateCompanionBuilder =
    GrabTasksCompanion Function({
      Value<String> id,
      Value<String> accountId,
      Value<String> targetIdsJson,
      Value<GrabTaskStatus> status,
      Value<int> effectiveIntervalMs,
      Value<String?> startedAt,
      Value<String?> stoppedAt,
      Value<String?> lastResultJson,
      Value<int> rowid,
    });

final class $$GrabTasksTableReferences
    extends BaseReferences<_$AppDatabase, $GrabTasksTable, GrabTaskEntry> {
  $$GrabTasksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $AccountsTable _accountIdTable(_$AppDatabase db) =>
      db.accounts.createAlias(
        $_aliasNameGenerator(db.grabTasks.accountId, db.accounts.id),
      );

  $$AccountsTableProcessedTableManager get accountId {
    final $_column = $_itemColumn<String>('account_id')!;

    final manager = $$AccountsTableTableManager(
      $_db,
      $_db.accounts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_accountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$GrabTasksTableFilterComposer
    extends Composer<_$AppDatabase, $GrabTasksTable> {
  $$GrabTasksTableFilterComposer({
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

  ColumnFilters<String> get targetIdsJson => $composableBuilder(
    column: $table.targetIdsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<GrabTaskStatus, GrabTaskStatus, String>
  get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get effectiveIntervalMs => $composableBuilder(
    column: $table.effectiveIntervalMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get stoppedAt => $composableBuilder(
    column: $table.stoppedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastResultJson => $composableBuilder(
    column: $table.lastResultJson,
    builder: (column) => ColumnFilters(column),
  );

  $$AccountsTableFilterComposer get accountId {
    final $$AccountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableFilterComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$GrabTasksTableOrderingComposer
    extends Composer<_$AppDatabase, $GrabTasksTable> {
  $$GrabTasksTableOrderingComposer({
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

  ColumnOrderings<String> get targetIdsJson => $composableBuilder(
    column: $table.targetIdsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get effectiveIntervalMs => $composableBuilder(
    column: $table.effectiveIntervalMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get stoppedAt => $composableBuilder(
    column: $table.stoppedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastResultJson => $composableBuilder(
    column: $table.lastResultJson,
    builder: (column) => ColumnOrderings(column),
  );

  $$AccountsTableOrderingComposer get accountId {
    final $$AccountsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableOrderingComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$GrabTasksTableAnnotationComposer
    extends Composer<_$AppDatabase, $GrabTasksTable> {
  $$GrabTasksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get targetIdsJson => $composableBuilder(
    column: $table.targetIdsJson,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<GrabTaskStatus, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get effectiveIntervalMs => $composableBuilder(
    column: $table.effectiveIntervalMs,
    builder: (column) => column,
  );

  GeneratedColumn<String> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<String> get stoppedAt =>
      $composableBuilder(column: $table.stoppedAt, builder: (column) => column);

  GeneratedColumn<String> get lastResultJson => $composableBuilder(
    column: $table.lastResultJson,
    builder: (column) => column,
  );

  $$AccountsTableAnnotationComposer get accountId {
    final $$AccountsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableAnnotationComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$GrabTasksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GrabTasksTable,
          GrabTaskEntry,
          $$GrabTasksTableFilterComposer,
          $$GrabTasksTableOrderingComposer,
          $$GrabTasksTableAnnotationComposer,
          $$GrabTasksTableCreateCompanionBuilder,
          $$GrabTasksTableUpdateCompanionBuilder,
          (GrabTaskEntry, $$GrabTasksTableReferences),
          GrabTaskEntry,
          PrefetchHooks Function({bool accountId})
        > {
  $$GrabTasksTableTableManager(_$AppDatabase db, $GrabTasksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GrabTasksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GrabTasksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GrabTasksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> accountId = const Value.absent(),
                Value<String> targetIdsJson = const Value.absent(),
                Value<GrabTaskStatus> status = const Value.absent(),
                Value<int> effectiveIntervalMs = const Value.absent(),
                Value<String?> startedAt = const Value.absent(),
                Value<String?> stoppedAt = const Value.absent(),
                Value<String?> lastResultJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GrabTasksCompanion(
                id: id,
                accountId: accountId,
                targetIdsJson: targetIdsJson,
                status: status,
                effectiveIntervalMs: effectiveIntervalMs,
                startedAt: startedAt,
                stoppedAt: stoppedAt,
                lastResultJson: lastResultJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String accountId,
                required String targetIdsJson,
                required GrabTaskStatus status,
                required int effectiveIntervalMs,
                Value<String?> startedAt = const Value.absent(),
                Value<String?> stoppedAt = const Value.absent(),
                Value<String?> lastResultJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GrabTasksCompanion.insert(
                id: id,
                accountId: accountId,
                targetIdsJson: targetIdsJson,
                status: status,
                effectiveIntervalMs: effectiveIntervalMs,
                startedAt: startedAt,
                stoppedAt: stoppedAt,
                lastResultJson: lastResultJson,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$GrabTasksTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({accountId = false}) {
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
                    if (accountId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.accountId,
                                referencedTable: $$GrabTasksTableReferences
                                    ._accountIdTable(db),
                                referencedColumn: $$GrabTasksTableReferences
                                    ._accountIdTable(db)
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

typedef $$GrabTasksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GrabTasksTable,
      GrabTaskEntry,
      $$GrabTasksTableFilterComposer,
      $$GrabTasksTableOrderingComposer,
      $$GrabTasksTableAnnotationComposer,
      $$GrabTasksTableCreateCompanionBuilder,
      $$GrabTasksTableUpdateCompanionBuilder,
      (GrabTaskEntry, $$GrabTasksTableReferences),
      GrabTaskEntry,
      PrefetchHooks Function({bool accountId})
    >;
typedef $$AppSettingsTableCreateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<int> id,
      Value<String> theme,
      Value<int> userIntervalMs,
      Value<String> updateChannel,
      Value<String> logLevel,
      Value<String> locale,
      Value<bool> crashReportingEnabled,
    });
typedef $$AppSettingsTableUpdateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<int> id,
      Value<String> theme,
      Value<int> userIntervalMs,
      Value<String> updateChannel,
      Value<String> logLevel,
      Value<String> locale,
      Value<bool> crashReportingEnabled,
    });

class $$AppSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableFilterComposer({
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

  ColumnFilters<String> get theme => $composableBuilder(
    column: $table.theme,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get userIntervalMs => $composableBuilder(
    column: $table.userIntervalMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updateChannel => $composableBuilder(
    column: $table.updateChannel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get logLevel => $composableBuilder(
    column: $table.logLevel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get locale => $composableBuilder(
    column: $table.locale,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get crashReportingEnabled => $composableBuilder(
    column: $table.crashReportingEnabled,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableOrderingComposer({
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

  ColumnOrderings<String> get theme => $composableBuilder(
    column: $table.theme,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get userIntervalMs => $composableBuilder(
    column: $table.userIntervalMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updateChannel => $composableBuilder(
    column: $table.updateChannel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get logLevel => $composableBuilder(
    column: $table.logLevel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get locale => $composableBuilder(
    column: $table.locale,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get crashReportingEnabled => $composableBuilder(
    column: $table.crashReportingEnabled,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get theme =>
      $composableBuilder(column: $table.theme, builder: (column) => column);

  GeneratedColumn<int> get userIntervalMs => $composableBuilder(
    column: $table.userIntervalMs,
    builder: (column) => column,
  );

  GeneratedColumn<String> get updateChannel => $composableBuilder(
    column: $table.updateChannel,
    builder: (column) => column,
  );

  GeneratedColumn<String> get logLevel =>
      $composableBuilder(column: $table.logLevel, builder: (column) => column);

  GeneratedColumn<String> get locale =>
      $composableBuilder(column: $table.locale, builder: (column) => column);

  GeneratedColumn<bool> get crashReportingEnabled => $composableBuilder(
    column: $table.crashReportingEnabled,
    builder: (column) => column,
  );
}

class $$AppSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppSettingsTable,
          AppSettingsEntry,
          $$AppSettingsTableFilterComposer,
          $$AppSettingsTableOrderingComposer,
          $$AppSettingsTableAnnotationComposer,
          $$AppSettingsTableCreateCompanionBuilder,
          $$AppSettingsTableUpdateCompanionBuilder,
          (
            AppSettingsEntry,
            BaseReferences<_$AppDatabase, $AppSettingsTable, AppSettingsEntry>,
          ),
          AppSettingsEntry,
          PrefetchHooks Function()
        > {
  $$AppSettingsTableTableManager(_$AppDatabase db, $AppSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> theme = const Value.absent(),
                Value<int> userIntervalMs = const Value.absent(),
                Value<String> updateChannel = const Value.absent(),
                Value<String> logLevel = const Value.absent(),
                Value<String> locale = const Value.absent(),
                Value<bool> crashReportingEnabled = const Value.absent(),
              }) => AppSettingsCompanion(
                id: id,
                theme: theme,
                userIntervalMs: userIntervalMs,
                updateChannel: updateChannel,
                logLevel: logLevel,
                locale: locale,
                crashReportingEnabled: crashReportingEnabled,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> theme = const Value.absent(),
                Value<int> userIntervalMs = const Value.absent(),
                Value<String> updateChannel = const Value.absent(),
                Value<String> logLevel = const Value.absent(),
                Value<String> locale = const Value.absent(),
                Value<bool> crashReportingEnabled = const Value.absent(),
              }) => AppSettingsCompanion.insert(
                id: id,
                theme: theme,
                userIntervalMs: userIntervalMs,
                updateChannel: updateChannel,
                logLevel: logLevel,
                locale: locale,
                crashReportingEnabled: crashReportingEnabled,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppSettingsTable,
      AppSettingsEntry,
      $$AppSettingsTableFilterComposer,
      $$AppSettingsTableOrderingComposer,
      $$AppSettingsTableAnnotationComposer,
      $$AppSettingsTableCreateCompanionBuilder,
      $$AppSettingsTableUpdateCompanionBuilder,
      (
        AppSettingsEntry,
        BaseReferences<_$AppDatabase, $AppSettingsTable, AppSettingsEntry>,
      ),
      AppSettingsEntry,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$AccountsTableTableManager get accounts =>
      $$AccountsTableTableManager(_db, _db.accounts);
  $$CourseTargetsTableTableManager get courseTargets =>
      $$CourseTargetsTableTableManager(_db, _db.courseTargets);
  $$GrabTasksTableTableManager get grabTasks =>
      $$GrabTasksTableTableManager(_db, _db.grabTasks);
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db, _db.appSettings);
}
