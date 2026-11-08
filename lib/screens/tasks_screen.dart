import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/dates.dart';
import '../state/app_state.dart';
import '../ui/custom_editors.dart';
import '../ui/house_cards.dart';
import '../ui/navigation.dart';
import '../ui/theme.dart';
import '../ui/week_editor.dart';
import '../ui/widgets.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key, required this.onNavigate});

  final ValueChanged<int> onNavigate;

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  int _weekOffset = 0;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final monday = mondayOf(state.now);
    final plan = state.planFor(monday.add(Duration(days: _weekOffset * 7)));
    final isCurrent = _weekOffset == 0;
    final subtitle = switch (_weekOffset) {
      0 => 'Esta semana',
      -1 => 'Semana pasada',
      1 => 'Próxima semana',
      < 0 => 'Hace ${-_weekOffset} semanas',
      _ => 'En $_weekOffset semanas',
    };

    return PageBody(
      children: [
        ScreenHeaderBar(
          title: 'Tareas',
          subtitle: 'Aseo, bolsas y basura',
          unreadAlerts: state.unreadAlertCount,
          onAlerts: () => widget.onNavigate(3),
          onProfile: () => openProfileScreen(context),
        ),
        const SizedBox(height: 18),
        WeekSwitcher(
          title: formatWeekRange(plan.weekStart),
          subtitle: subtitle,
          onPrevious: _weekOffset > -12
              ? () => setState(() => _weekOffset--)
              : null,
          onNext: _weekOffset < 4
              ? () => setState(() => _weekOffset++)
              : null,
        ),
        const SizedBox(height: 16),
        CleaningTasksCard(plan: plan, showTeam: true),
        const SizedBox(height: 12),
        BagsCard(plan: plan),
        const SizedBox(height: 12),
        if (state.isAdmin || state.customTasksForWeek(plan.weekStart).isNotEmpty) ...[
          CustomTasksCard(
            weekStart: plan.weekStart,
            showCreateAction: state.isAdmin,
          ),
          const SizedBox(height: 12),
        ],
        const SectionHeader(title: 'Turnos de la casa'),
        if (isCurrent)
          TrashTurnCard(showAdminActions: state.isAdmin)
        else
          const InfoNote(
            icon: CupertinoIcons.trash_fill,
            text:
                'El turno de basura es en vivo: siempre muestra a quién le toca ahora, sin importar la semana que estés viendo.',
            color: AppColors.purple,
          ),
        if (isCurrent) ...[
          for (final turn in state.customTurns) ...[
            const SizedBox(height: 12),
            CustomTurnCard(
              turn: turn,
              onEdit: () => showCustomTurnEditor(context, turn: turn),
            ),
          ],
        ],
        if (state.isAdmin) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => showCustomTurnEditor(context, turn: null),
            icon: const Icon(CupertinoIcons.cart_fill, size: 16),
            label: const Text('Nuevo turno'),
          ),
          OutlinedButton.icon(
            onPressed: () => showCustomTaskEditor(context, weekStart: plan.weekStart),
            icon: const Icon(CupertinoIcons.check_mark_circled_solid, size: 16),
            label: const Text('Nueva tarea'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => showWeekEditor(context, plan),
            icon: const Icon(CupertinoIcons.pencil, size: 16),
            label: Text(
              state.hasOverride(plan.weekStart)
                  ? 'Editar asignación de la semana'
                  : 'Reasignar esta semana',
            ),
          ),
        ],
        if (!isCurrent && !state.isAdmin) ...[
          const SizedBox(height: 12),
          const InfoNote(
            icon: CupertinoIcons.lock_fill,
            text:
                'Solo el administrador puede editar semanas anteriores. Puedes consultar lo que se hizo.',
            color: AppColors.orange,
          ),
        ],
        const SizedBox(height: 16),
        const InfoNote(
          icon: CupertinoIcons.arrow_counterclockwise,
          text:
              'La rotación de aseo se repite cada 6 semanas. Cada semana, dos personas se reparten baño, cocina, sala y piso. Las bolsas rotan una persona por semana.',
        ),
      ],
    );
  }
}
