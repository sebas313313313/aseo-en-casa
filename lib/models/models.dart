import 'dart:ui' show Color;

import '../core/dates.dart';

enum UserRole { admin, tenant }

extension UserRoleX on UserRole {
  String get label => this == UserRole.admin ? 'Administrador' : 'Inquilino';
  String get shortLabel => this == UserRole.admin ? 'Admin' : 'Inquilino';
}

UserRole roleFromString(String? value) =>
    value == 'admin' ? UserRole.admin : UserRole.tenant;

Color colorFromHex(String hex) {
  final clean = hex.replaceAll('#', '').trim();
  final value = clean.length == 6 ? 'FF$clean' : clean;
  return Color(int.parse(value, radix: 16));
}

class HouseUser {
  HouseUser({
    required this.id,
    required this.name,
    required this.username,
    required this.password,
    required this.role,
    required this.colorHex,
    required this.joinedAt,
  });

  final String id;
  String name;
  final String username;
  String password;
  UserRole role;
  final String colorHex;
  final String joinedAt;

  bool get isAdmin => role == UserRole.admin;

  String get firstName => name.trim().split(RegExp(r'\s+')).first;

  String get initials {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      final first = parts.first;
      return (first.length >= 2 ? first.substring(0, 2) : first).toUpperCase();
    }
    return (parts.first.substring(0, 1) + parts.elementAt(1).substring(0, 1))
        .toUpperCase();
  }

  Color get color => colorFromHex(colorHex);

  DateTime get joinedDate => DateTime.tryParse(joinedAt) ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'username': username,
        'password': password,
        'role': role.name,
        'colorHex': colorHex,
        'joinedAt': joinedAt,
      };

  factory HouseUser.fromJson(Map<String, dynamic> json) => HouseUser(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? 'Sin nombre',
        username: json['username']?.toString() ?? '',
        password: json['password']?.toString() ?? '',
        role: roleFromString(json['role']?.toString()),
        colorHex: json['colorHex']?.toString() ?? '#4D96FF',
        joinedAt: json['joinedAt']?.toString() ?? DateTime.now().toIso8601String(),
      );
}

enum CleaningZone { bano, cocina, sala, piso }

extension CleaningZoneX on CleaningZone {
  String get label => switch (this) {
        CleaningZone.bano => 'Baño',
        CleaningZone.cocina => 'Cocina',
        CleaningZone.sala => 'Sala',
        CleaningZone.piso => 'Piso',
      };

  String get hint => switch (this) {
        CleaningZone.bano => 'Limpieza completa del baño',
        CleaningZone.cocina => 'Mesón, estufa y lavaplatos',
        CleaningZone.sala => 'Sofás, mesa y superficies',
        CleaningZone.piso => 'Barrer y trapear toda la casa',
      };
}

class WeekPlan {
  const WeekPlan({
    required this.weekStart,
    required this.index,
    required this.team,
    required this.zoneOwners,
    required this.bagBuyer,
    required this.isOverridden,
  });

  final DateTime weekStart;
  final int index;
  final List<String> team;
  final Map<CleaningZone, String> zoneOwners;
  final String bagBuyer;
  final bool isOverridden;
}

class WeekOverride {
  const WeekOverride({this.team, this.bagBuyer});

  final List<String>? team;
  final String? bagBuyer;

  Map<String, dynamic> toJson() => {
        if (team != null) 'team': team,
        if (bagBuyer != null) 'bagBuyer': bagBuyer,
      };

  factory WeekOverride.fromJson(Map<String, dynamic> json) => WeekOverride(
        team: (json['team'] as List?)?.map((e) => e.toString()).toList(),
        bagBuyer: json['bagBuyer']?.toString(),
      );
}

class TaskCompletion {
  const TaskCompletion({required this.at, required this.by});

  final DateTime at;
  final String by;

  Map<String, dynamic> toJson() => {
        'at': at.toIso8601String(),
        'by': by,
      };

  factory TaskCompletion.fromJson(Map<String, dynamic> json) => TaskCompletion(
        at: DateTime.tryParse(json['at']?.toString() ?? '') ?? DateTime.now(),
        by: json['by']?.toString() ?? '',
      );
}

class PaymentRecord {
  PaymentRecord({this.paid = false, this.paidAt, this.markedBy});

  bool paid;
  DateTime? paidAt;
  String? markedBy;

  Map<String, dynamic> toJson() => {
        'paid': paid,
        if (paidAt != null) 'paidAt': paidAt!.toIso8601String(),
        if (markedBy != null) 'markedBy': markedBy,
      };

  factory PaymentRecord.fromJson(Map<String, dynamic> json) => PaymentRecord(
        paid: json['paid'] == true,
        paidAt: DateTime.tryParse(json['paidAt']?.toString() ?? ''),
        markedBy: json['markedBy']?.toString(),
      );
}

class TrashLog {
  const TrashLog({required this.userId, required this.at});

  final String userId;
  final DateTime at;

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'at': at.toIso8601String(),
      };

  factory TrashLog.fromJson(Map<String, dynamic> json) => TrashLog(
        userId: json['userId']?.toString() ?? '',
        at: DateTime.tryParse(json['at']?.toString() ?? '') ?? DateTime.now(),
      );
}

class TrashState {
  TrashState({
    required this.order,
    this.currentIndex = 0,
    this.lastEmptiedAt,
    this.lastEmptiedBy,
    List<TrashLog>? history,
  }) : history = history ?? <TrashLog>[];

  List<String> order;
  int currentIndex;
  DateTime? lastEmptiedAt;
  String? lastEmptiedBy;
  List<TrashLog> history;

  String? get currentUserId =>
      order.isEmpty ? null : order[currentIndex % order.length];

  String? get nextUserId {
    if (order.isEmpty) return null;
    return order[(currentIndex + 1) % order.length];
  }

  void advance({required String by, required DateTime at}) {
    if (order.isEmpty) return;
    lastEmptiedAt = at;
    lastEmptiedBy = by;
    history.insert(0, TrashLog(userId: by, at: at));
    if (history.length > 30) history.removeRange(30, history.length);
    currentIndex = (currentIndex + 1) % order.length;
  }

  void skip() {
    if (order.isNotEmpty) currentIndex = (currentIndex + 1) % order.length;
  }

  Map<String, dynamic> toJson() => {
        'order': order,
        'currentIndex': currentIndex,
        if (lastEmptiedAt != null) 'lastEmptiedAt': lastEmptiedAt!.toIso8601String(),
        if (lastEmptiedBy != null) 'lastEmptiedBy': lastEmptiedBy,
        'history': history.map((e) => e.toJson()).toList(),
      };

  factory TrashState.fromJson(Map<String, dynamic>? json) {
    final data = json ?? const <String, dynamic>{};
    final order =
        (data['order'] as List?)?.map((e) => e.toString()).toList() ?? <String>[];
    var index = (data['currentIndex'] as num?)?.toInt() ?? 0;
    if (order.isNotEmpty) index = index % order.length;
    return TrashState(
      order: order,
      currentIndex: index,
      lastEmptiedAt: DateTime.tryParse(data['lastEmptiedAt']?.toString() ?? ''),
      lastEmptiedBy: data['lastEmptiedBy']?.toString(),
      history: (data['history'] as List?)
              ?.map((e) => TrashLog.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          <TrashLog>[],
    );
  }
}

class CustomTask {
  CustomTask({
    required this.id,
    required this.title,
    this.notes = '',
    required this.iconKey,
    required this.colorHex,
    required this.assigneeIds,
    required this.weekStart,
    this.repeatWeekly = false,
    required this.createdBy,
    required this.createdAt,
  });

  final String id;
  String title;
  String notes;
  String iconKey;
  String colorHex;
  List<String> assigneeIds;
  DateTime weekStart;
  bool repeatWeekly;
  final String createdBy;
  final DateTime createdAt;

  Color get color => colorFromHex(colorHex);
  bool get isUnassigned => assigneeIds.isEmpty;

  bool appliesToWeek(DateTime week) =>
      repeatWeekly ||
      dateKey(mondayOf(weekStart)) == dateKey(mondayOf(week));

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'notes': notes,
        'iconKey': iconKey,
        'colorHex': colorHex,
        'assigneeIds': assigneeIds,
        'weekStart': dateKey(weekStart),
        'repeatWeekly': repeatWeekly,
        'createdBy': createdBy,
        'createdAt': createdAt.toIso8601String(),
      };

  factory CustomTask.fromJson(Map<String, dynamic> json) {
    DateTime week;
    try {
      week = mondayOf(parseDateKey(json['weekStart']?.toString() ?? ''));
    } catch (_) {
      week = mondayOf(DateTime.now());
    }
    return CustomTask(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Tarea',
      notes: json['notes']?.toString() ?? '',
      iconKey: json['iconKey']?.toString() ?? 'checklist',
      colorHex: json['colorHex']?.toString() ?? '#0A84FF',
      assigneeIds: (json['assigneeIds'] as List?)
              ?.map((entry) => entry.toString())
              .toList() ??
          <String>[],
      weekStart: week,
      repeatWeekly: json['repeatWeekly'] == true,
      createdBy: json['createdBy']?.toString() ?? '',
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
              DateTime.now(),
    );
  }
}

class CustomTurn {
  CustomTurn({
    required this.id,
    required this.title,
    this.notes = '',
    required this.iconKey,
    required this.colorHex,
    required this.order,
    this.currentIndex = 0,
    this.lastDoneAt,
    this.lastDoneBy,
    List<TrashLog>? history,
    required this.createdBy,
    required this.createdAt,
  }) : history = history ?? <TrashLog>[];

  final String id;
  String title;
  String notes;
  String iconKey;
  String colorHex;
  List<String> order;
  int currentIndex;
  DateTime? lastDoneAt;
  String? lastDoneBy;
  List<TrashLog> history;
  final String createdBy;
  final DateTime createdAt;

  Color get color => colorFromHex(colorHex);
  bool get isUnassigned => order.isEmpty;

  String? get currentUserId =>
      order.isEmpty ? null : order[currentIndex % order.length];

  String? get nextUserId {
    if (order.isEmpty) return null;
    return order[(currentIndex + 1) % order.length];
  }

  void normalize() {
    if (order.isEmpty) {
      currentIndex = 0;
    } else {
      currentIndex = currentIndex % order.length;
    }
  }

  void advance({required String by, required DateTime at}) {
    if (order.isEmpty) return;
    lastDoneAt = at;
    lastDoneBy = by;
    history.insert(0, TrashLog(userId: by, at: at));
    if (history.length > 30) history.removeRange(30, history.length);
    currentIndex = (currentIndex + 1) % order.length;
  }

  void skip() {
    if (order.isNotEmpty) currentIndex = (currentIndex + 1) % order.length;
  }

  void reset() {
    currentIndex = 0;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'notes': notes,
        'iconKey': iconKey,
        'colorHex': colorHex,
        'order': order,
        'currentIndex': currentIndex,
        if (lastDoneAt != null) 'lastDoneAt': lastDoneAt!.toIso8601String(),
        if (lastDoneBy != null) 'lastDoneBy': lastDoneBy,
        'history': history.map((entry) => entry.toJson()).toList(),
        'createdBy': createdBy,
        'createdAt': createdAt.toIso8601String(),
      };

  factory CustomTurn.fromJson(Map<String, dynamic> json) {
    final order = (json['order'] as List?)
            ?.map((entry) => entry.toString())
            .toList() ??
        <String>[];
    var index = (json['currentIndex'] as num?)?.toInt() ?? 0;
    if (order.isNotEmpty) index = index % order.length;
    return CustomTurn(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Turno',
      notes: json['notes']?.toString() ?? '',
      iconKey: json['iconKey']?.toString() ?? 'cart',
      colorHex: json['colorHex']?.toString() ?? '#30D158',
      order: order,
      currentIndex: index,
      lastDoneAt: DateTime.tryParse(json['lastDoneAt']?.toString() ?? ''),
      lastDoneBy: json['lastDoneBy']?.toString(),
      history: (json['history'] as List?)
              ?.map((entry) =>
                  TrashLog.fromJson(Map<String, dynamic>.from(entry as Map)))
              .toList() ??
          <TrashLog>[],
      createdBy: json['createdBy']?.toString() ?? '',
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
              DateTime.now(),
    );
  }
}

enum AlertKind { payment, cleaning, bags, trash, customTask, customTurn, admin }

extension AlertKindX on AlertKind {
  String get label => switch (this) {
        AlertKind.payment => 'Pago',
        AlertKind.cleaning => 'Aseo',
        AlertKind.bags => 'Bolsas',
        AlertKind.trash => 'Basura',
        AlertKind.customTask => 'Tarea',
        AlertKind.customTurn => 'Turno',
        AlertKind.admin => 'Admin',
      };
}

class HouseAlert {
  const HouseAlert({
    required this.id,
    required this.kind,
    required this.title,
    required this.message,
    required this.date,
    this.isRead = false,
    this.urgent = false,
    this.actionTab = 0,
  });

  final String id;
  final AlertKind kind;
  final String title;
  final String message;
  final DateTime date;
  final bool isRead;
  final bool urgent;
  final int actionTab;

  HouseAlert copyWith({bool? isRead}) => HouseAlert(
        id: id,
        kind: kind,
        title: title,
        message: message,
        date: date,
        isRead: isRead ?? this.isRead,
        urgent: urgent,
        actionTab: actionTab,
      );
}

String zoneTaskId(DateTime weekStart, CleaningZone zone) =>
    'clean:${dateKey(weekStart)}:${zone.name}';

String bagsTaskId(DateTime weekStart) => 'bags:${dateKey(weekStart)}';

String formatZoneList(Iterable<CleaningZone> zones) =>
    joinSpanish(zones.map((z) => z.label.toLowerCase()).toList());
