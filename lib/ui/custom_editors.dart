import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/dates.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import 'custom_icons.dart';
import 'theme.dart';
import 'widgets.dart';

Future<void> showCustomTaskEditor(
  BuildContext context, {
  CustomTask? task,
  DateTime? weekStart,
}) {
  return showAppSheet<void>(
    context,
    builder: (_) => _CustomTaskSheet(task: task, initialWeekStart: weekStart),
  );
}

Future<void> showCustomTurnEditor(
  BuildContext context, {
  CustomTurn? turn,
}) {
  return showAppSheet<void>(
    context,
    builder: (_) => _CustomTurnSheet(turn: turn),
  );
}

class _CustomTaskSheet extends StatefulWidget {
  const _CustomTaskSheet({this.task, this.initialWeekStart});

  final CustomTask? task;
  final DateTime? initialWeekStart;

  @override
  State<_CustomTaskSheet> createState() => _CustomTaskSheetState();
}

class _CustomTaskSheetState extends State<_CustomTaskSheet> {
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();

  late DateTime _weekStart;
  bool _repeatWeekly = false;
  final List<String> _assigneeIds = <String>[];
  String _iconKey = 'checklist';
  String _colorHex = '#0A84FF';
  String? _error;
  bool get _editing => widget.task != null;

  @override
  void initState() {
    super.initState();
    final task = widget.task;
    _weekStart = task != null
        ? task.weekStart
        : (widget.initialWeekStart ?? mondayOf(DateTime.now()));
    _repeatWeekly = task?.repeatWeekly ?? false;
    _assigneeIds.clear();
    _assigneeIds.addAll(task?.assigneeIds ?? <String>[]);
    _iconKey = task?.iconKey ?? 'checklist';
    _colorHex = task?.colorHex ?? '#0A84FF';
    _titleController.text = task?.title ?? '';
    _notesController.text = task?.notes ?? '';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _prevWeek() => setState(() => _weekStart = _weekStart.subtract(const Duration(days: 7)));

  void _nextWeek() => setState(() => _weekStart = _weekStart.add(const Duration(days: 7)));

  void _toggleAssignee(String id) {
    setState(() {
      if (_assigneeIds.contains(id)) {
        _assigneeIds.remove(id);
      } else {
        _assigneeIds.add(id);
      }
    });
  }

  void _save(AppState state) {
    final error = _editing
        ? state.updateCustomTask(
            id: widget.task!.id,
            title: _titleController.text,
            notes: _notesController.text,
            assigneeIds: _assigneeIds,
            weekStart: _weekStart,
            repeatWeekly: _repeatWeekly,
            iconKey: _iconKey,
            colorHex: _colorHex,
          )
        : state.addCustomTask(
            title: _titleController.text,
            notes: _notesController.text,
            assigneeIds: _assigneeIds,
            weekStart: _weekStart,
            repeatWeekly: _repeatWeekly,
            iconKey: _iconKey,
            colorHex: _colorHex,
          );
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    showAppToast(
      context,
      _editing ? 'Tarea actualizada' : 'Tarea creada',
      icon: CupertinoIcons.check_mark_circled_solid,
      color: AppColors.blue,
    );
    Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final stateField = context.read<AppState>();
    final confirmed = await showConfirmDialog(
      context,
      title: 'Eliminar tarea',
      message: '¿Eliminar la tarea "${_titleController.text}"?',
      confirmLabel: 'Eliminar',
      destructive: true,
    );
    if (!confirmed) return;
    if (!mounted) return;
    stateField.deleteCustomTask(widget.task!.id);
    showAppToast(
      context,
      'Tarea eliminada',
      icon: CupertinoIcons.trash,
      color: AppColors.red,
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final users = state.users;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SheetHeader(
          title: _editing ? 'Editar tarea' : 'Nueva tarea',
          subtitle: _editing
              ? 'Ajusta la asignación de "${_titleController.text}".'
              : 'Crea una tarea y asígnasela a una o varias personas.',
          onClose: () => Navigator.of(context).pop(),
        ),
        TextField(
          controller: _titleController,
          autofocus: !_editing,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            labelText: 'Tarea',
            hintText: 'Ej. Limpiar el balcón',
            prefixIcon: Icon(CupertinoIcons.check_mark_circled_solid, size: 18),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _notesController,
          maxLines: 2,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            labelText: 'Notas (opcional)',
            hintText: 'Ej. Barrer la terraza y recoger basura',
            prefixIcon: Icon(CupertinoIcons.pencil, size: 18),
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Text('Asignar a', style: Theme.of(context).textTheme.titleSmall),
            const Spacer(),
            Text(
              _assigneeIds.isEmpty ? 'Sin asignar' : '${_assigneeIds.length} persona(s)',
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
              _TaskPersonChoice(
                user: user,
                selected: _assigneeIds.contains(user.id),
                onTap: () => _toggleAssignee(user.id),
              ),
          ],
        ),
        const SizedBox(height: 18),
        Text('Semana', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Row(
          children: [
            _WeekArrowButton(
              icon: CupertinoIcons.chevron_left,
              onTap: _prevWeek,
              enabled: true,
            ),
            Expanded(
              child: Text(
                formatWeekRange(_weekStart),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            _WeekArrowButton(
              icon: CupertinoIcons.chevron_right,
              onTap: _nextWeek,
              enabled: true,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'La tarea solo aparece en "${_weekStart.day}/${_weekStart.month}" cuando no se repite.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Repetir cada semana',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  Text(
                    'Si se activa, la misma tarea se repite cada lunes automáticamente.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Switch(
              value: _repeatWeekly,
              onChanged: (value) => setState(() => _repeatWeekly = value),
              activeThumbColor: AppColors.blue,
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text('Icono', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final option in customIconOptions)
              _IconChoice(
                iconKey: option.key,
                icon: option.icon,
                selected: _iconKey == option.key,
                color: customColorFor(_colorHex),
                onTap: () => setState(() => _iconKey = option.key),
              ),
          ],
        ),
        const SizedBox(height: 18),
        Text('Color', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final color in customColorOptions)
              _ColorChoice(
                color: color,
                selected: _colorHex == colorValueHex(color),
                onTap: () => setState(() => _colorHex = colorValueHex(color)),
              ),
          ],
        ),
        const SizedBox(height: 18),
        if (_error != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(CupertinoIcons.exclamationmark_circle_fill, color: AppColors.red, size: 17),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _error!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.red,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        FilledButton(
          onPressed: () => _save(state),
          child: Text(_editing ? 'Guardar cambios' : 'Crear tarea'),
        ),
        if (_editing) ...[
          const SizedBox(height: 6),
          TextButton.icon(
            onPressed: _delete,
            style: TextButton.styleFrom(foregroundColor: AppColors.red),
            icon: const Icon(CupertinoIcons.trash, size: 16),
            label: const Text('Eliminar tarea'),
          ),
        ],
      ],
    );
  }
}

class _CustomTurnSheet extends StatefulWidget {
  const _CustomTurnSheet({this.turn});

  final CustomTurn? turn;

  @override
  State<_CustomTurnSheet> createState() => _CustomTurnSheetState();
}

class _CustomTurnSheetState extends State<_CustomTurnSheet> {
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();

  final List<String> _order = <String>[];
  String _iconKey = 'cart';
  String _colorHex = '#30D158';
  String? _error;
  bool get _editing => widget.turn != null;
  @override
  void initState() {
    super.initState();
    final turn = widget.turn;
    _order
      ..clear()
      ..addAll(turn?.order ?? <String>[]);
    _iconKey = turn?.iconKey ?? 'cart';
    _colorHex = turn?.colorHex ?? '#30D158';
    _titleController.text = turn?.title ?? '';
    _notesController.text = turn?.notes ?? '';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _toggleAssignee(String id) {
    setState(() {
      final index = _order.indexOf(id);
      if (index >= 0) {
        _order.removeAt(index);
      } else {
        _order.add(id);
      }
    });
  }

  void _useAll(AppState state) {
    setState(() {
      _order
        ..clear()
        ..addAll(state.users.map((user) => user.id));
    });
  }

  void _save(AppState state) {
    final error = _editing
        ? state.updateCustomTurn(
            id: widget.turn!.id,
            title: _titleController.text,
            notes: _notesController.text,
            order: _order,
            iconKey: _iconKey,
            colorHex: _colorHex,
          )
        : state.addCustomTurn(
            title: _titleController.text,
            notes: _notesController.text,
            order: _order,
            iconKey: _iconKey,
            colorHex: _colorHex,
          );
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    showAppToast(
      context,
      _editing ? 'Turno actualizado' : 'Turno creado',
      icon: CupertinoIcons.arrow_2_circlepath,
      color: AppColors.purple,
    );
    Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final stateField = context.read<AppState>();
    final confirmed = await showConfirmDialog(
      context,
      title: 'Eliminar turno',
      message: '¿Eliminar el turno "${_titleController.text}"?',
      confirmLabel: 'Eliminar',
      destructive: true,
    );
    if (!confirmed) return;
    if (!mounted) return;
    stateField.deleteCustomTurn(widget.turn!.id);
    showAppToast(
      context,
      'Turno eliminado',
      icon: CupertinoIcons.arrow_2_circlepath,
      color: AppColors.purple,
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final users = state.users;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SheetHeader(
          title: _editing ? 'Editar turno' : 'Nuevo turno',
          subtitle: _editing
              ? 'Ajusta la cola de personas que rotan.'
              : 'Crea un turno rotativo para compras, arreglos o lo que quieras.',
          onClose: () => Navigator.of(context).pop(),
        ),
        TextField(
          controller: _titleController,
          autofocus: !_editing,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            labelText: 'Turno',
            hintText: 'Ej. Comprar papel de baño',
            prefixIcon: Icon(CupertinoIcons.cart_fill, size: 18),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _notesController,
          maxLines: 2,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            labelText: 'Notas (opcional)',
            hintText: 'Ej. Dos bolsas por semana y una por día',
            prefixIcon: Icon(CupertinoIcons.pencil, size: 18),
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Text('Personas en el turno', style: Theme.of(context).textTheme.titleSmall),
            const Spacer(),
            TextButton(
              onPressed: () => _useAll(state),
              child: const Text('Todos'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final user in users)
              _TurnPersonChoice(
                user: user,
                position: _order.indexOf(user.id),
                onTap: () => _toggleAssignee(user.id),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          _order.isEmpty
              ? 'Sin personas asignadas.'
              : 'Orden: ${_order.map((id) => state.userById(id)?.firstName ?? '?').join(' → ')}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 18),
        Text('Icono', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final option in customIconOptions)
              _IconChoice(
                iconKey: option.key,
                icon: option.icon,
                selected: _iconKey == option.key,
                color: customColorFor(_colorHex),
                onTap: () => setState(() => _iconKey = option.key),
              ),
          ],
        ),
        const SizedBox(height: 18),
        Text('Color', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final color in customColorOptions)
              _ColorChoice(
                color: color,
                selected: _colorHex == colorValueHex(color),
                onTap: () => setState(() => _colorHex = colorValueHex(color)),
              ),
          ],
        ),
        const SizedBox(height: 18),
        if (_error != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(CupertinoIcons.exclamationmark_circle_fill, color: AppColors.red, size: 17),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _error!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.red,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        FilledButton(
          onPressed: () => _save(state),
          child: Text(_editing ? 'Guardar cambios' : 'Crear turno'),
        ),
        if (_editing) ...[
          const SizedBox(height: 6),
          TextButton.icon(
            onPressed: _delete,
            style: TextButton.styleFrom(foregroundColor: AppColors.red),
            icon: const Icon(CupertinoIcons.trash, size: 16),
            label: const Text('Eliminar turno'),
          ),
        ],
      ],
    );
  }
}

class _WeekArrowButton extends StatelessWidget {
  const _WeekArrowButton({required this.icon, required this.onTap, required this.enabled});

  final IconData icon;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: context.appCardAlt,
        borderRadius: BorderRadius.circular(14),
      ),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Center(
          child: Icon(
            icon,
            size: 17,
            color: enabled ? context.appText : context.appTertiary,
          ),
        ),
      ),
    );
  }
}

class _TaskPersonChoice extends StatelessWidget {
  const _TaskPersonChoice({
    required this.user,
    required this.selected,
    required this.onTap,
  });

  final HouseUser user;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      haptic: false,
      pressedScale: 0.96,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.fromLTRB(10, 8, 12, 8),
        decoration: BoxDecoration(
          color: selected ? context.soft(AppColors.blue, 0.12) : context.appCardAlt,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? context.soft(AppColors.blue, 0.4) : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Avatar(user: user, size: 26),
            const SizedBox(width: 7),
            Text(user.firstName, style: Theme.of(context).textTheme.labelMedium),
            if (selected) ...[
              const SizedBox(width: 6),
              Icon(CupertinoIcons.check_mark_circled_solid, size: 15, color: AppColors.blue),
            ],
          ],
        ),
      ),
    );
  }
}

class _TurnPersonChoice extends StatelessWidget {
  const _TurnPersonChoice({
    required this.user,
    required this.position,
    required this.onTap,
  });

  final HouseUser user;
  final int? position;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.purple;
    return Pressable(
      onTap: onTap,
      haptic: false,
      pressedScale: 0.96,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.fromLTRB(10, 8, 12, 8),
        decoration: BoxDecoration(
          color: position == null ? context.appCardAlt : context.soft(color, 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: position == null ? Colors.transparent : context.soft(color, 0.4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Avatar(user: user, size: 26),
            const SizedBox(width: 7),
            Text(user.firstName, style: Theme.of(context).textTheme.labelMedium),
            if (position != null) ...[
              const SizedBox(width: 6),
              Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.purple,
                ),
                alignment: Alignment.center,
                child: Text(
                  '${position! + 1}',
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _IconChoice extends StatelessWidget {
  const _IconChoice({
    required this.iconKey,
    required this.icon,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String iconKey;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      haptic: false,
      pressedScale: 0.9,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: selected ? context.soft(color, 0.16) : context.appCardAlt,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? color.withValues(alpha: 0.55) : context.appSeparator,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Icon(icon, size: 19, color: selected ? color : context.appSecondary),
      ),
    );
  }
}

class _ColorChoice extends StatelessWidget {
  const _ColorChoice({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      haptic: false,
      pressedScale: 0.9,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: selected ? color : context.appCardAlt,
          border: Border.all(
            color: selected ? color.withValues(alpha: 0.55) : context.appSeparator,
            width: selected ? 2 : 1,
          ),
        ),
      ),
    );
  }
}

String colorValueHex(Color color) {
  final argb = color.toARGB32();
  return '#${argb.toRadixString(16).padLeft(8, '0')}';
}

Color customColorFor(String hex) {
  final clean = hex.replaceAll('#', '').trim();
  final value = clean.length == 6 ? 'FF$clean' : clean;
  return Color(int.parse(value, radix: 16));
}
