import 'dart:math' as math;

import '../core/dates.dart';
import '../logic/rotation.dart';
import '../models/models.dart';

class SeedData {
  static const version = 2;

  static HouseUser admin(DateTime now, {String username = 'admin'}) =>
      HouseUser(
        id: username,
        name: 'Administración',
        username: username,
        password: 'admin123',
        role: UserRole.admin,
        colorHex: '#FF9F0A',
        joinedAt: now.toIso8601String(),
      );

  static const List<List<String>> rotationPairs = [
    ['isa', 'sebas'],
    ['andrea', 'isa'],
    ['sebas', 'sofi'],
    ['andrea', 'sofi'],
    ['isa', 'sofi'],
    ['sebas', 'andrea'],
  ];

  static const List<String> bagOrder = ['isa', 'andrea', 'sebas', 'sofi'];

  static const List<String> trashOrder = ['isa', 'sebas', 'andrea', 'sofi'];

  static Map<String, dynamic> build(DateTime now) {
    final users = _users(now);
    final currentMonday = mondayOf(now);
    final currentPlan = RotationEngine.planFor(
      weekStart: currentMonday,
      users: users,
      rotationPairs: rotationPairs,
      bagOrder: bagOrder,
    );
    final previousPlan = RotationEngine.planFor(
      weekStart: currentMonday.subtract(const Duration(days: 7)),
      users: users,
      rotationPairs: rotationPairs,
      bagOrder: bagOrder,
    );

    final completions = <String, dynamic>{};

    // La semana pasada quedó completa.
    for (final zone in CleaningZone.values) {
      final owner = previousPlan.zoneOwners[zone];
      if (owner == null) continue;
      completions[zoneTaskId(previousPlan.weekStart, zone)] = TaskCompletion(
        at: previousPlan.weekStart.add(Duration(days: 2 + zone.index)),
        by: owner,
      ).toJson();
    }
    completions[bagsTaskId(previousPlan.weekStart)] = TaskCompletion(
      at: previousPlan.weekStart.add(const Duration(days: 1)),
      by: previousPlan.bagBuyer,
    ).toJson();

    // La semana actual va por la mitad.
    for (final zone in [CleaningZone.bano, CleaningZone.cocina]) {
      final owner = currentPlan.zoneOwners[zone];
      if (owner == null) continue;
      completions[zoneTaskId(currentPlan.weekStart, zone)] = TaskCompletion(
        at: now.subtract(Duration(days: zone == CleaningZone.bano ? 2 : 1)),
        by: owner,
      ).toJson();
    }

    final payments = <String, dynamic>{};
    for (var back = 1; back <= 2; back++) {
      final month = DateTime(now.year, now.month - back, 1);
      payments[monthKey(month)] = {
        for (final user in users)
          user.id: PaymentRecord(
            paid: true,
            paidAt: DateTime(month.year, month.month, 26, 18, 30),
            markedBy: 'sebas',
          ).toJson(),
      };
    }

    final currentPaidAt = DateTime(
      now.year,
      now.month,
      math.min(now.day, 27),
      19,
      10,
    );
    payments[monthKey(now)] = {
      for (final user in users) user.id: PaymentRecord().toJson(),
      'sebas': PaymentRecord(
        paid: true,
        paidAt: currentPaidAt,
        markedBy: 'sebas',
      ).toJson(),
      'andrea': PaymentRecord(
        paid: true,
        paidAt: currentPaidAt.add(const Duration(hours: 3)),
        markedBy: 'andrea',
      ).toJson(),
    };

    final lastTrash = now.subtract(const Duration(days: 3));

    return {
      'version': version,
      'users': [...users, admin(now)].map((user) => user.toJson()).toList(),
      'sessionUserId': null,
      'rotationPairs': rotationPairs,
      'bagOrder': bagOrder,
      'weekOverrides': <String, dynamic>{},
      'completions': completions,
      'trash': TrashState(
        order: List<String>.from(trashOrder),
        currentIndex: 1,
        lastEmptiedAt: lastTrash,
        lastEmptiedBy: 'isa',
        history: [TrashLog(userId: 'isa', at: lastTrash)],
      ).toJson(),
      'payments': payments,
      'readAlerts': <String>[],
      'themeMode': 'system',
      'houseName': 'Casa Común',
      'monthlyAmount': 60000,
      'dueDay': 29,
      'reminderDays': [25, 26, 27, 28, 29],
      'createdAt': now.toIso8601String(),
      'updatedAt': now.toIso8601String(),
      'customTasks': <Map<String, dynamic>>[
        {
          'id': 'task-balcon',
          'title': 'Limpiar el balcón',
          'notes': 'Sacar cosas del balcón y barrer.',
          'iconKey': 'clean',
          'colorHex': '#34C759',
          'assigneeIds': ['sofi'],
          'weekStart': dateKey(currentPlan.weekStart),
          'repeatWeekly': false,
          'createdBy': 'sebas',
          'createdAt': now.toIso8601String(),
        },
      ],
      'customTurns': <Map<String, dynamic>>[
        {
          'id': 'turn-papel',
          'title': 'Comprar papel de baño',
          'notes': 'Dos rollos por semana.',
          'iconKey': 'doc',
          'colorHex': '#64D2FF',
          'order': ['isa', 'sebas', 'andrea', 'sofi'],
          'currentIndex': 0,
          'lastDoneAt': lastTrash.toIso8601String(),
          'lastDoneBy': 'isa',
          'history': [
            {'userId': 'isa', 'at': lastTrash.toIso8601String()},
          ],
          'createdBy': 'sebas',
          'createdAt': now.toIso8601String(),
        },
      ],
    };
  }

  static List<HouseUser> _users(DateTime now) => [
    HouseUser(
      id: 'isa',
      name: 'Isa',
      username: 'isa',
      password: 'isa123',
      role: UserRole.tenant,
      colorHex: '#FF6B6B',
      joinedAt: DateTime(now.year, now.month - 4, 12).toIso8601String(),
    ),
    HouseUser(
      id: 'sebas',
      name: 'Sebastián',
      username: 'sebas',
      password: 'sebas123',
      role: UserRole.tenant,
      colorHex: '#4D96FF',
      joinedAt: DateTime(now.year, now.month - 6, 3).toIso8601String(),
    ),
    HouseUser(
      id: 'andrea',
      name: 'Andrea',
      username: 'andrea',
      password: 'andrea123',
      role: UserRole.tenant,
      colorHex: '#B983FF',
      joinedAt: DateTime(now.year, now.month - 3, 21).toIso8601String(),
    ),
    HouseUser(
      id: 'sofi',
      name: 'Sofi',
      username: 'sofi',
      password: 'sofi123',
      role: UserRole.tenant,
      colorHex: '#FFB443',
      joinedAt: DateTime(now.year, now.month - 2, 8).toIso8601String(),
    ),
  ];
}
