import '../core/dates.dart';
import '../models/models.dart';

/// Rotación determinista por semanas.
///
/// La semana del 26 de octubre de 2026 es la semana 0. A partir de ahí, la
/// rotación avanza una posición por semana y se repite.
class RotationEngine {
  static final DateTime anchor = DateTime(2026, 10, 26);

  static int weekIndex(DateTime date) =>
      floorDiv(mondayOf(date).difference(anchor).inDays, 7);

  static WeekPlan planFor({
    required DateTime weekStart,
    required List<HouseUser> users,
    required List<List<String>> rotationPairs,
    required List<String> bagOrder,
    Map<String, WeekOverride> overrides = const {},
  }) {
    final monday = mondayOf(weekStart);
    final index = weekIndex(monday);
    final ids = users
        .where((user) => !user.isAdmin)
        .map((user) => user.id)
        .toList();

    if (ids.isEmpty) {
      return WeekPlan(
        weekStart: monday,
        index: index,
        team: const [],
        zoneOwners: const {},
        bagBuyer: '',
        isOverridden: false,
      );
    }

    final validIds = ids.toSet();

    var pairs = rotationPairs
        .map((pair) => pair.where(validIds.contains).toList())
        .where((pair) => pair.length >= 2)
        .toList();

    if (pairs.isEmpty) {
      if (ids.length >= 2) {
        pairs = [
          for (var i = 0; i < ids.length; i++)
            [ids[i], ids[(i + 1) % ids.length]],
        ];
      } else {
        pairs = [
          [ids.first, ids.first],
        ];
      }
    }

    var team = List<String>.from(pairs[index % pairs.length]);

    final bagPool = bagOrder.where(validIds.contains).toList();
    var bagBuyer = bagPool.isEmpty
        ? ids.first
        : bagPool[index % bagPool.length];

    var isOverridden = false;
    final custom = overrides[dateKey(monday)];
    if (custom != null) {
      final overrideTeam =
          custom.team?.where(validIds.contains).toList() ?? const <String>[];
      if (overrideTeam.length >= 2) {
        team = overrideTeam.take(2).toList();
        isOverridden = true;
      }
      final overrideBuyer = custom.bagBuyer;
      if (overrideBuyer != null && validIds.contains(overrideBuyer)) {
        bagBuyer = overrideBuyer;
        isOverridden = true;
      }
    }

    final first = team[0];
    final second = team.length > 1 ? team[1] : team[0];
    final even = index.isEven;

    final owners = <CleaningZone, String>{
      CleaningZone.bano: even ? first : second,
      CleaningZone.cocina: even ? second : first,
      CleaningZone.sala: even ? first : second,
      CleaningZone.piso: even ? second : first,
    };

    return WeekPlan(
      weekStart: monday,
      index: index,
      team: team,
      zoneOwners: owners,
      bagBuyer: bagBuyer,
      isOverridden: isOverridden,
    );
  }
}
