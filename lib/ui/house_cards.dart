import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/dates.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import 'custom_editors.dart';
import 'custom_icons.dart';
import 'theme.dart';
import 'widgets.dart';

IconData zoneIcon(CleaningZone zone) => switch (zone) {
  CleaningZone.bano => Icons.bathtub_rounded,
  CleaningZone.cocina => Icons.countertops_rounded,
  CleaningZone.sala => Icons.weekend_rounded,
  CleaningZone.piso => Icons.cleaning_services_rounded,
};

Color zoneColor(CleaningZone zone) => switch (zone) {
  CleaningZone.bano => AppColors.teal,
  CleaningZone.cocina => AppColors.orange,
  CleaningZone.sala => AppColors.purple,
  CleaningZone.piso => AppColors.blue,
};

IconData alertIcon(AlertKind kind) => switch (kind) {
  AlertKind.payment => CupertinoIcons.creditcard_fill,
  AlertKind.cleaning => CupertinoIcons.paintbrush_fill,
  AlertKind.bags => CupertinoIcons.bag_fill,
  AlertKind.trash => CupertinoIcons.trash_fill,
  AlertKind.customTask => CupertinoIcons.check_mark_circled_solid,
  AlertKind.customTurn => CupertinoIcons.arrow_counterclockwise,
  AlertKind.admin => CupertinoIcons.shield_fill,
};

Color alertColor(AlertKind kind) => switch (kind) {
  AlertKind.payment => AppColors.red,
  AlertKind.cleaning => AppColors.blue,
  AlertKind.bags => AppColors.orange,
  AlertKind.trash => AppColors.purple,
  AlertKind.customTask => AppColors.indigo,
  AlertKind.customTurn => AppColors.teal,
  AlertKind.admin => AppColors.indigo,
};

class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    required this.user,
    required this.unreadAlerts,
    required this.onAlerts,
    required this.onProfile,
  });

  final HouseUser user;
  final int unreadAlerts;
  final VoidCallback onAlerts;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    final moment = DateTime.now();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                capitalize(formatLongDate(moment)),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: context.appSecondary,
                  letterSpacing: 0.5,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '${greetingFor(moment)}, ${user.firstName}',
                style: Theme.of(context).textTheme.displayMedium,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        CircleIconButton(
          icon: CupertinoIcons.bell_fill,
          badgeCount: unreadAlerts,
          onTap: onAlerts,
          tooltip: 'Alertas',
        ),
        const SizedBox(width: 9),
        Pressable(
          onTap: onProfile,
          pressedScale: 0.92,
          child: Avatar(user: user, size: 42),
        ),
      ],
    );
  }
}

class HomeBanner extends StatelessWidget {
  const HomeBanner({super.key, required this.onNavigate});

  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final user = state.currentUser!;
    final moment = state.now;
    final month = state.monthKeyNow();
    final payment = state.paymentFor(month, user.id);
    final plan = state.currentPlan;
    final pendingZones = plan.zoneOwners.entries
        .where(
          (entry) =>
              entry.value == user.id && !state.isZoneDone(plan, entry.key),
        )
        .map((entry) => entry.key)
        .toList();

    late final IconData icon;
    late final Color color;
    late final String title;
    late final String message;
    late final int tab;

    if (!payment.paid && moment.day >= 25) {
      final overdue = moment.day > state.dueDay;
      icon = overdue
          ? CupertinoIcons.exclamationmark_triangle_fill
          : CupertinoIcons.creditcard_fill;
      color = overdue ? AppColors.red : AppColors.orange;
      title = overdue ? 'Pago vencido' : 'Pago de servicios';
      message = overdue
          ? 'Tu aporte de ${formatMoney(state.monthlyAmount)} sigue pendiente.'
          : 'Faltan ${state.dueDay - moment.day} días para el ${state.dueDay}. Aporte: ${formatMoney(state.monthlyAmount)}.';
      tab = 2;
    } else if (pendingZones.isNotEmpty) {
      icon = CupertinoIcons.paintbrush_fill;
      color = AppColors.blue;
      title = 'Tienes tareas de aseo';
      message =
          'Te toca ${formatZoneList(pendingZones)}. ${pendingZones.length == 1 ? 'Una tarea pendiente' : '${pendingZones.length} tareas pendientes'}.';
      tab = 1;
    } else if (state.trash.currentUserId == user.id) {
      icon = CupertinoIcons.trash_fill;
      color = AppColors.purple;
      title = 'Te toca botar la basura';
      message =
          'Cuando la saques, el turno pasa a ${state.userById(state.trash.nextUserId)?.firstName ?? 'la siguiente persona'}.';
      tab = 1;
    } else {
      final myCustomTasks = state
          .customTasksForWeek(plan.weekStart)
          .where(
            (task) =>
                task.assigneeIds.contains(user.id) &&
                !state.isCustomTaskDone(task, plan.weekStart),
          )
          .toList();
      CustomTurn? myCustomTurn;
      for (final turn in state.customTurns) {
        if (turn.currentUserId == user.id) {
          myCustomTurn = turn;
          break;
        }
      }
      if (myCustomTurn != null) {
        final turn = myCustomTurn;
        icon = CupertinoIcons.arrow_counterclockwise;
        color = turn.color;
        title = 'Te toca: ${turn.title}';
        message = turn.notes.isEmpty
            ? 'Cuando lo hagas, el turno pasa a ${state.userById(turn.nextUserId)?.firstName ?? 'la siguiente persona'}.'
            : turn.notes;
        tab = 1;
      } else if (myCustomTasks.isNotEmpty) {
        final task = myCustomTasks.first;
        icon = CupertinoIcons.check_mark_circled_solid;
        color = task.color;
        title = task.title;
        message = task.notes.isEmpty
            ? 'Tienes esta tarea extra esta semana.'
            : task.notes;
        tab = 1;
      } else {
        icon = CupertinoIcons.checkmark_seal_fill;
        color = AppColors.green;
        title = 'Todo en orden';
        message = 'No tienes pendientes urgentes. Disfruta la casa.';
        tab = 0;
      }
    }

    return Pressable(
      onTap: tab == 0 ? null : () => onNavigate(tab),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [context.soft(color, 0.18), context.soft(color, 0.06)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: context.soft(color, 0.22)),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 2),
                  Text(
                    message,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: context.appSecondary,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            if (tab != 0) ...[
              const SizedBox(width: 6),
              Icon(CupertinoIcons.chevron_right, size: 15, color: color),
            ],
          ],
        ),
      ),
    );
  }
}

class WeekHeroCard extends StatelessWidget {
  const WeekHeroCard({
    super.key,
    required this.plan,
    required this.onOpenTasks,
  });

  final WeekPlan plan;
  final VoidCallback onOpenTasks;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final done = state.cleaningDoneCount(plan);
    final total = CleaningZone.values.length;
    final progress = total == 0 ? 0.0 : done / total;
    final team = plan.team
        .map((id) => state.userById(id))
        .whereType<HouseUser>()
        .toList();
    final names = joinSpanish(team.map((user) => user.firstName).toList());

    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0A84FF), Color(0xFF5E5CE6)],
          ),
        ),
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned(
              top: -78,
              right: -54,
              child: Container(
                width: 190,
                height: 190,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
            Positioned(
              bottom: -92,
              left: -50,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'ESTA SEMANA',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.72),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.3,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        formatWeekRange(plan.weekStart),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Text(
                  'Aseo de la casa',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.6,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  team.isEmpty
                      ? 'Sin equipo asignado'
                      : '$names se encargan esta semana',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.78),
                    fontSize: 13.5,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    SizedBox(
                      width: 64,
                      height: 30,
                      child: Stack(
                        children: [
                          for (var i = 0; i < team.length; i++)
                            Positioned(
                              left: i * 22,
                              child: Avatar(
                                user: team[i],
                                size: 32,
                                ring: true,
                                ringColor: Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: 58,
                      height: 58,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 58,
                            height: 58,
                            child: CircularProgressIndicator(
                              value: progress,
                              strokeWidth: 5,
                              strokeCap: StrokeCap.round,
                              backgroundColor: Colors.white.withValues(
                                alpha: 0.2,
                              ),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          ),
                          Text(
                            '${(progress * 100).round()}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Pressable(
                  onTap: onOpenTasks,
                  haptic: false,
                  pressedScale: 0.99,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 11,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.13),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          CupertinoIcons.checkmark_circle_fill,
                          color: Colors.white,
                          size: 17,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$done de $total zonas listas',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        const Text(
                          'Ver tareas',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(
                          CupertinoIcons.chevron_right,
                          color: Colors.white.withValues(alpha: 0.8),
                          size: 13,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class CleaningTasksCard extends StatelessWidget {
  const CleaningTasksCard({
    super.key,
    required this.plan,
    this.showTeam = false,
  });

  final WeekPlan plan;
  final bool showTeam;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final user = state.currentUser;
    final done = state.cleaningDoneCount(plan);
    final team = plan.team
        .map((id) => state.userById(id))
        .whereType<HouseUser>()
        .toList();

    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SoftIcon(
                icon: CupertinoIcons.paintbrush_fill,
                color: AppColors.blue,
                size: 38,
                iconSize: 17,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Aseo',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      'Baño, cocina, sala y piso',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Text(
                '$done/${CleaningZone.values.length}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: done == CleaningZone.values.length
                      ? AppColors.green
                      : context.appSecondary,
                ),
              ),
            ],
          ),
          if (showTeam && team.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                for (final member in team) ...[
                  Avatar(user: member, size: 22),
                  const SizedBox(width: 6),
                  Text(
                    member.firstName,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: context.appSecondary,
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
              ],
            ),
          ],
          const SizedBox(height: 8),
          for (var i = 0; i < CleaningZone.values.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                color: context.appSeparator.withValues(alpha: 0.55),
              ),
            _ZoneRow(
              plan: plan,
              zone: CleaningZone.values[i],
              user: user,
              state: state,
            ),
          ],
        ],
      ),
    );
  }
}

class _ZoneRow extends StatelessWidget {
  const _ZoneRow({
    required this.plan,
    required this.zone,
    required this.user,
    required this.state,
  });

  final WeekPlan plan;
  final CleaningZone zone;
  final HouseUser? user;
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final owner = state.userById(plan.zoneOwners[zone]);
    final done = state.isZoneDone(plan, zone);
    final isMine = owner?.id == user?.id;
    final canToggle = state.canToggleZone(plan, zone);
    final color = zoneColor(zone);

    return Pressable(
      onTap: canToggle ? () => state.toggleZone(plan, zone) : null,
      haptic: false,
      pressedScale: 0.99,
      child: Opacity(
        opacity: done ? 0.62 : 1,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 11),
          child: Row(
            children: [
              SoftIcon(
                icon: zoneIcon(zone),
                color: color,
                size: 34,
                iconSize: 16,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      zone.label,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 1),
                    Text(
                      zone.hint,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (isMine && !done) ...[
                const Pill(label: 'Tú', color: AppColors.blue, compact: true),
                const SizedBox(width: 8),
              ],
              if (owner != null) ...[
                Avatar(user: owner, size: 24),
                const SizedBox(width: 6),
                SizedBox(
                  width: 46,
                  child: Text(
                    owner.firstName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              const SizedBox(width: 6),
              CheckCircle(done: done),
            ],
          ),
        ),
      ),
    );
  }
}

class BagsCard extends StatelessWidget {
  const BagsCard({super.key, required this.plan});

  final WeekPlan plan;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final user = state.currentUser;
    final buyer = state.userById(plan.bagBuyer);
    final done = state.isBagsDone(plan);
    final isMine = buyer?.id == user?.id;
    final canToggle = state.canToggleBags(plan);

    return AppCard(
      onTap: canToggle ? () => state.toggleBags(plan) : null,
      padding: const EdgeInsets.all(16),
      child: Opacity(
        opacity: done ? 0.62 : 1,
        child: Row(
          children: [
            const SoftIcon(
              icon: CupertinoIcons.bag_fill,
              color: AppColors.orange,
              size: 40,
              iconSize: 18,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Bolsas de basura',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (isMine && !done) ...[
                        const SizedBox(width: 6),
                        const Pill(
                          label: 'Tú',
                          color: AppColors.orange,
                          compact: true,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      if (buyer != null) ...[
                        Avatar(user: buyer, size: 18),
                        const SizedBox(width: 5),
                      ],
                      Text(
                        done
                            ? 'Compradas esta semana'
                            : 'Esta semana le toca a ${buyer?.firstName ?? '—'}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            CheckCircle(done: done),
          ],
        ),
      ),
    );
  }
}

class TrashTurnCard extends StatelessWidget {
  const TrashTurnCard({super.key, this.showAdminActions = false});

  final bool showAdminActions;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final user = state.currentUser;
    final current = state.userById(state.trash.currentUserId);
    final next = state.userById(state.trash.nextUserId);
    final isMyTurn = current?.id == user?.id;
    final lastBy = state.userById(state.trash.lastEmptiedBy);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SoftIcon(
                icon: CupertinoIcons.trash_fill,
                color: AppColors.purple,
                size: 38,
                iconSize: 17,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Botar la basura',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      'Turno rotativo',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (current != null)
                Pill(
                  label: 'Ahora: ${current.firstName}',
                  color: AppColors.purple,
                  compact: true,
                ),
            ],
          ),
          const SizedBox(height: 16),
          _TurnQueue(
            users: state.trash.order
                .map((id) => state.userById(id))
                .whereType<HouseUser>()
                .toList(),
            currentId: state.trash.currentUserId,
            color: AppColors.purple,
          ),
          const SizedBox(height: 16),
          if (current != null) ...[
            Text(
              isMyTurn ? 'Te toca a ti' : 'Le toca a ${current.name}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 2),
            Text(
              next == null
                  ? 'Después se reinicia el turno.'
                  : 'Después sigue ${next.name}.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          if (lastBy != null && state.trash.lastEmptiedAt != null) ...[
            const SizedBox(height: 6),
            Text(
              '${lastBy.firstName} la botó ${relativeDate(state.trash.lastEmptiedAt!, state.now).toLowerCase()}.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: context.appTertiary),
            ),
          ],
          const SizedBox(height: 16),
          if (state.canEmptyTrash)
            FilledButton.icon(
              onPressed: () {
                state.emptyTrash();
                final after = state.userById(state.trash.currentUserId);
                showAppToast(
                  context,
                  'Turno pasado a ${after?.firstName ?? 'la siguiente persona'}',
                  icon: CupertinoIcons.arrow_right_circle_fill,
                  color: AppColors.purple,
                  actionLabel: 'Deshacer',
                  onAction: state.undoTrashChange,
                );
              },
              icon: const Icon(CupertinoIcons.trash_fill, size: 18),
              label: const Text('Ya la boté'),
            )
          else
            InfoNote(
              icon: CupertinoIcons.clock_fill,
              text: current == null
                  ? 'No hay turno asignado.'
                  : 'Esperando a que ${current.firstName} la bote para activar el siguiente turno.',
              color: AppColors.purple,
            ),
          if (showAdminActions && state.isAdmin) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () {
                    state.skipTrashTurn();
                    showAppToast(
                      context,
                      'Turno saltado',
                      icon: CupertinoIcons.arrow_right_circle_fill,
                      color: AppColors.purple,
                      actionLabel: 'Deshacer',
                      onAction: state.undoTrashChange,
                    );
                  },
                  icon: const Icon(CupertinoIcons.forward_fill, size: 14),
                  label: const Text('Pasar turno'),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    state.resetTrashTurn();
                    showAppToast(
                      context,
                      'Turno reiniciado en ${state.userById(state.trash.currentUserId)?.firstName ?? 'la primera persona'}',
                      icon: CupertinoIcons.arrow_counterclockwise,
                      color: AppColors.purple,
                      actionLabel: 'Deshacer',
                      onAction: state.undoTrashChange,
                    );
                  },
                  child: const Text('Reiniciar'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class CustomTurnCard extends StatelessWidget {
  const CustomTurnCard({super.key, required this.turn, this.onEdit});

  final CustomTurn turn;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final current = state.userById(turn.currentUserId);
    final next = state.userById(turn.nextUserId);
    final isMyTurn = turn.currentUserId == state.currentUser?.id;
    final lastBy = state.userById(turn.lastDoneBy);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SoftIcon(
                icon: customIconFor(turn.iconKey),
                color: turn.color,
                size: 38,
                iconSize: 17,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      turn.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      turn.notes.isEmpty ? 'Turno rotativo' : turn.notes,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (current != null)
                Pill(
                  label: 'Ahora: ${current.firstName}',
                  color: turn.color,
                  compact: true,
                ),
            ],
          ),
          const SizedBox(height: 16),
          _TurnQueue(
            users: turn.order
                .map((id) => state.userById(id))
                .whereType<HouseUser>()
                .toList(),
            currentId: turn.currentUserId,
            color: turn.color,
          ),
          const SizedBox(height: 16),
          if (current != null) ...[
            Text(
              isMyTurn ? 'Te toca a ti' : 'Le toca a ${current.name}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 2),
            Text(
              next == null
                  ? 'Después se reinicia el turno.'
                  : 'Después sigue ${next.firstName}.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          if (lastBy != null && turn.lastDoneAt != null) ...[
            const SizedBox(height: 6),
            Text(
              '${lastBy.firstName} lo hizo ${relativeDate(turn.lastDoneAt!, state.now).toLowerCase()}.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: context.appTertiary),
            ),
          ],
          const SizedBox(height: 16),
          if (state.canCompleteCustomTurn(turn))
            FilledButton.icon(
              onPressed: () {
                state.completeCustomTurn(turn);
                final after = state.userById(
                  state.customTurnById(turn.id)?.nextUserId,
                );
                showAppToast(
                  context,
                  'Turno pasado a ${after?.firstName ?? 'la siguiente persona'}',
                  icon: CupertinoIcons.arrow_right_circle_fill,
                  color: turn.color,
                  actionLabel: 'Deshacer',
                  onAction: () => state.undoCustomTurn(turn.id),
                );
              },
              icon: const Icon(
                CupertinoIcons.check_mark_circled_solid,
                size: 18,
                color: Colors.white,
              ),
              label: Text(isMyTurn ? 'Ya lo hice' : 'Marcar como hecho'),
            )
          else
            InfoNote(
              icon: CupertinoIcons.clock_fill,
              text: current == null
                  ? 'No hay turno asignado.'
                  : 'Esperando a que ${current.firstName} haga ${turn.title.toLowerCase()}.',
              color: turn.color,
            ),
          if (state.isAdmin) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () {
                    state.skipCustomTurn(turn);
                    showAppToast(
                      context,
                      'Turno saltado',
                      icon: CupertinoIcons.arrow_right_circle_fill,
                      color: turn.color,
                      actionLabel: 'Deshacer',
                      onAction: () => state.undoCustomTurn(turn.id),
                    );
                  },
                  icon: const Icon(CupertinoIcons.forward_fill, size: 14),
                  label: const Text('Pasar turno'),
                ),
                TextButton.icon(
                  onPressed: () {
                    state.resetCustomTurn(turn);
                    final after = state.userById(
                      state.customTurnById(turn.id)?.currentUserId,
                    );
                    showAppToast(
                      context,
                      'Turno reiniciado en ${after?.firstName ?? 'la primera persona'}',
                      icon: CupertinoIcons.arrow_counterclockwise,
                      color: turn.color,
                      actionLabel: 'Deshacer',
                      onAction: () => state.undoCustomTurn(turn.id),
                    );
                  },
                  icon: const Icon(
                    CupertinoIcons.arrow_counterclockwise,
                    size: 14,
                  ),
                  label: const Text('Reiniciar'),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(CupertinoIcons.pencil, size: 14),
                  label: const Text('Editar'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class CustomTasksCard extends StatelessWidget {
  const CustomTasksCard({
    super.key,
    required this.weekStart,
    this.showCreateAction = false,
  });

  final DateTime weekStart;
  final bool showCreateAction;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final tasks = state.customTasksForWeek(weekStart);
    final pendingCount = tasks
        .where((task) => !state.isCustomTaskDone(task, weekStart))
        .length;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SoftIcon(
                icon: CupertinoIcons.check_mark_circled_solid,
                color: AppColors.indigo,
                size: 38,
                iconSize: 17,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tareas extra',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      tasks.isEmpty
                          ? 'Creadas por el administrador'
                          : '$pendingCount de ${tasks.length} pendientes esta semana',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Text(
                '$pendingCount/${tasks.length}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: pendingCount == tasks.length
                      ? context.appSecondary
                      : AppColors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (tasks.isEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Aún no hay tareas extra. El administrador puede crear una y asignársela a quien quiera.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (showCreateAction) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: () => showCustomTaskEditor(context),
                  icon: const Icon(
                    CupertinoIcons.check_mark_circled_solid,
                    size: 16,
                  ),
                  label: const Text('Crear tarea'),
                ),
              ),
            ],
          ] else ...[
            for (var i = 0; i < tasks.length; i++) ...[
              if (i > 0)
                const Divider(
                  height: 1,
                  indent: 46,
                  color: AppColors.separatorLight,
                ),
              _CustomTaskRow(
                task: tasks[i],
                weekStart: weekStart,
                state: state,
              ),
              const SizedBox(height: 10),
            ],
          ],
        ],
      ),
    );
  }
}

class _CustomTaskRow extends StatelessWidget {
  const _CustomTaskRow({
    required this.task,
    required this.weekStart,
    required this.state,
  });

  final CustomTask task;
  final DateTime weekStart;
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final done = state.isCustomTaskDone(task, weekStart);
    return Row(
      children: [
        SoftIcon(
          icon: customIconFor(task.iconKey),
          color: task.color,
          size: 34,
          iconSize: 16,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                task.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 1),
              Text(
                task.notes,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 2),
              Text(
                'Asignada a ${state.customTaskAssigneesLabel(task)}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: context.appSecondary),
              ),
            ],
          ),
        ),
        CheckCircle(
          done: done,
          onTap: state.canToggleCustomTask(task, weekStart)
              ? () => state.toggleCustomTask(task, weekStart)
              : null,
        ),
      ],
    );
  }
}

class _TurnQueue extends StatelessWidget {
  const _TurnQueue({
    required this.users,
    required this.currentId,
    required this.color,
  });

  final List<HouseUser> users;
  final String? currentId;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < users.length; i++) ...[
            if (i > 0)
              Container(
                width: 18,
                height: 1.5,
                margin: const EdgeInsets.only(bottom: 16),
                color: context.appSeparator,
              ),
            SizedBox(
              width: 52,
              child: Column(
                children: [
                  Avatar(
                    user: users[i],
                    size: 38,
                    ring: users[i].id == currentId,
                    ringColor: color,
                    dimmed: users[i].id != currentId,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    users[i].firstName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: users[i].id == currentId
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: users[i].id == currentId
                          ? color
                          : context.appSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class PaymentSummaryCard extends StatelessWidget {
  const PaymentSummaryCard({super.key, required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final user = state.currentUser!;
    final moment = state.now;
    final month = state.monthKeyNow();
    final record = state.paymentFor(month, user.id);
    final progress = state.monthProgress(month);
    final overdue = !record.paid && state.isOverdue(month);
    final statusColor = record.paid
        ? AppColors.green
        : (overdue ? AppColors.red : AppColors.orange);
    final statusLabel = record.paid
        ? 'Pagado'
        : (overdue ? 'Vencido' : 'Pendiente');

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SoftIcon(
                icon: CupertinoIcons.creditcard_fill,
                color: AppColors.green,
                size: 38,
                iconSize: 17,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Servicios',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      formatMonthYear(moment),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (!user.isAdmin) Pill(label: statusLabel, color: statusColor),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatMoney(state.monthlyAmount),
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Text(
                  'por persona',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'Vence el ${state.dueDay} de ${monthName(moment.month)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          ProgressBar(value: progress, color: AppColors.green),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '${state.paidCount(month)} de ${state.users.length} pagaron',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Text(
                '${formatMoney(state.collectedAmount(month))} / ${formatMoney(state.expectedAmount(month))}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: onOpen,
            icon: const Icon(CupertinoIcons.creditcard, size: 17),
            label: Text(record.paid ? 'Ver pagos' : 'Ir a pagos'),
          ),
        ],
      ),
    );
  }
}

class AdminPulseCard extends StatelessWidget {
  const AdminPulseCard({
    super.key,
    required this.onOpenAdmin,
    required this.onOpenPayments,
  });

  final VoidCallback onOpenAdmin;
  final VoidCallback onOpenPayments;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final month = state.monthKeyNow();
    final pending = state.pendingUsers(month).length;
    final plan = state.currentPlan;
    final done = state.cleaningDoneCount(plan);

    return AppCard(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          context.soft(AppColors.orange, 0.2),
          context.soft(AppColors.orange, 0.06),
        ],
      ),
      borderColor: context.soft(AppColors.orange, 0.2),
      onTap: onOpenAdmin,
      child: Row(
        children: [
          const SoftIcon(
            icon: CupertinoIcons.shield_fill,
            color: AppColors.orange,
            size: 42,
            iconSize: 19,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Panel de administrador',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  '$pending pagos pendientes · $done/${CleaningZone.values.length} zonas de aseo',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Pressable(
            onTap: onOpenPayments,
            pressedScale: 0.9,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: context.appCard,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                CupertinoIcons.creditcard,
                size: 16,
                color: AppColors.orange,
              ),
            ),
          ),
          const SizedBox(width: 6),
          const Icon(
            CupertinoIcons.chevron_right,
            size: 15,
            color: AppColors.orange,
          ),
        ],
      ),
    );
  }
}

class AlertTile extends StatelessWidget {
  const AlertTile({super.key, required this.alert, required this.onTap});

  final HouseAlert alert;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = alertColor(alert.kind);
    return AppCard(
      padding: const EdgeInsets.all(14),
      color: alert.isRead ? null : context.soft(color, 0.05),
      borderColor: alert.isRead ? null : context.soft(color, 0.22),
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SoftIcon(
            icon: alertIcon(alert.kind),
            color: color,
            size: 40,
            iconSize: 18,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        alert.title,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    if (!alert.isRead)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.blue,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  alert.message,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.appSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Pill(label: alert.kind.label, color: color, compact: true),
                    const SizedBox(width: 8),
                    Text(
                      relativeDate(alert.date, DateTime.now()),
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Icon(
              CupertinoIcons.chevron_right,
              size: 14,
              color: context.appTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

class UserRow extends StatelessWidget {
  const UserRow({
    super.key,
    required this.user,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  final HouseUser user;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      haptic: false,
      pressedScale: 0.99,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(
          children: [
            Avatar(user: user, size: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          user.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                      const SizedBox(width: 6),
                      RolePill(role: user.role, compact: true),
                    ],
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 1),
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
            ?trailing,
            if (onTap != null)
              Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Icon(
                  CupertinoIcons.chevron_right,
                  size: 14,
                  color: context.appTertiary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
