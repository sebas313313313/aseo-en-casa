import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/dates.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import 'theme.dart';
import 'widgets.dart';

Future<void> showWeekEditor(BuildContext context, WeekPlan plan) {
  return showAppSheet<void>(
    context,
    builder: (_) => _WeekEditorSheet(plan: plan),
  );
}

class _WeekEditorSheet extends StatefulWidget {
  const _WeekEditorSheet({required this.plan});

  final WeekPlan plan;

  @override
  State<_WeekEditorSheet> createState() => _WeekEditorSheetState();
}

class _WeekEditorSheetState extends State<_WeekEditorSheet> {
  late List<String> _team;
  late String _buyer;

  @override
  void initState() {
    super.initState();
    _team = List<String>.from(widget.plan.team);
    final users = context.read<AppState>().users;
    _buyer = widget.plan.bagBuyer.isNotEmpty
        ? widget.plan.bagBuyer
        : (users.isEmpty ? '' : users.first.id);
  }

  void _toggleTeam(String id) {
    setState(() {
      if (_team.contains(id)) {
        _team.remove(id);
      } else if (_team.length < 2) {
        _team.add(id);
      } else {
        _team = [_team[1], id];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final users = state.users;
    final canSave = _team.length == 2 && _buyer.isNotEmpty;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SheetHeader(
          title: 'Editar semana',
          subtitle: formatWeekRange(widget.plan.weekStart),
          onClose: () => Navigator.of(context).pop(),
        ),
        Row(
          children: [
            Text(
              'Equipo de aseo',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const Spacer(),
            Text(
              'Elige 2',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final user in users)
              _PersonChoice(
                user: user,
                selected: _team.contains(user.id),
                color: AppColors.blue,
                onTap: () => _toggleTeam(user.id),
              ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Text(
              'Bolsas de basura',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const Spacer(),
            Text(
              'Elige 1',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final user in users)
              _PersonChoice(
                user: user,
                selected: _buyer == user.id,
                color: AppColors.orange,
                onTap: () => setState(() => _buyer = user.id),
              ),
          ],
        ),
        const SizedBox(height: 16),
        InfoNote(
          icon: CupertinoIcons.arrow_counterclockwise,
          text:
              'Esta asignación solo cambia la semana del ${formatWeekRange(widget.plan.weekStart)}. La rotación automática sigue para las demás semanas.',
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            if (state.hasOverride(widget.plan.weekStart))
              TextButton(
                onPressed: () {
                  state.clearWeekOverride(widget.plan.weekStart);
                  showAppToast(
                    context,
                    'Rotación restablecida',
                    icon: CupertinoIcons.arrow_counterclockwise,
                    color: AppColors.blue,
                  );
                  Navigator.of(context).pop();
                },
                child: const Text('Restablecer'),
              ),
            const Spacer(),
            SizedBox(
              width: 170,
              child: FilledButton(
                onPressed: canSave
                    ? () {
                        state.setWeekOverride(
                          widget.plan.weekStart,
                          team: _team,
                          bagBuyer: _buyer,
                        );
                        showAppToast(
                          context,
                          'Semana actualizada',
                          icon: CupertinoIcons.check_mark_circled_solid,
                          color: AppColors.green,
                        );
                        Navigator.of(context).pop();
                      }
                    : null,
                child: const Text('Guardar'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PersonChoice extends StatelessWidget {
  const _PersonChoice({
    required this.user,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final HouseUser user;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      haptic: false,
      pressedScale: 0.96,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.fromLTRB(8, 7, 12, 7),
        decoration: BoxDecoration(
          color: selected ? context.soft(color, 0.12) : context.appCardAlt,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? context.soft(color, 0.4) : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Avatar(user: user, size: 26),
            const SizedBox(width: 7),
            Text(
              user.firstName,
              style: Theme.of(context).textTheme.labelMedium,
            ),
            if (selected) ...[
              const SizedBox(width: 6),
              Icon(
                CupertinoIcons.check_mark_circled_solid,
                size: 15,
                color: color,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
