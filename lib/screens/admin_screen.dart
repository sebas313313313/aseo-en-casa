import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/dates.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../ui/custom_editors.dart';
import '../ui/custom_icons.dart';
import '../ui/house_cards.dart';
import '../ui/navigation.dart';
import '../ui/theme.dart';
import '../ui/user_editor.dart';
import '../ui/week_editor.dart';
import '../ui/widgets.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key, required this.onNavigate});

  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final user = state.currentUser;
    if (user == null || !user.isAdmin) return const SizedBox.shrink();

    final month = state.monthKeyNow();
    final pending = state.pendingUsers(month);
    final plan = state.currentPlan;
    final done = state.cleaningDoneCount(plan);
    final currentTrash = state.userById(state.trash.currentUserId);
    final nextTrash = state.userById(state.trash.nextUserId);
    final team = plan.team
        .map((id) => state.userById(id))
        .whereType<HouseUser>()
        .toList();
    final buyer = state.userById(plan.bagBuyer);

    return PageBody(
      children: [
        ScreenHeaderBar(
          title: 'Administración',
          subtitle: 'Personas, turnos y pagos',
          unreadAlerts: state.unreadAlertCount,
          onAlerts: () => onNavigate(3),
          onProfile: () => openProfileScreen(context),
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = (constraints.maxWidth - 10) / 2;
            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                SizedBox(
                  width: width,
                  child: StatCard(
                    label: 'Pagos pendientes',
                    value: '${pending.length}',
                    icon: CupertinoIcons.creditcard_fill,
                    color: AppColors.orange,
                    hint: 'de ${state.users.length} personas',
                  ),
                ),
                SizedBox(
                  width: width,
                  child: StatCard(
                    label: 'Zonas de aseo',
                    value: '$done/${CleaningZone.values.length}',
                    icon: CupertinoIcons.paintbrush_fill,
                    color: AppColors.blue,
                    hint: 'esta semana',
                  ),
                ),
                SizedBox(
                  width: width,
                  child: StatCard(
                    label: 'Turno de basura',
                    value: currentTrash?.firstName ?? '—',
                    icon: CupertinoIcons.trash_fill,
                    color: AppColors.purple,
                    hint: 'siguiente: ${nextTrash?.firstName ?? '—'}',
                  ),
                ),
                SizedBox(
                  width: width,
                  child: StatCard(
                    label: 'Personas',
                    value: '${state.users.length}',
                    icon: CupertinoIcons.person_2_fill,
                    color: AppColors.green,
                    hint: 'en la casa',
                  ),
                ),
              ],
            );
          },
        ),
        SectionHeader(
          title: 'Semana actual',
          actionLabel: 'Editar',
          onAction: () => showWeekEditor(context, plan),
        ),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    formatWeekRange(plan.weekStart),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(width: 8),
                  if (plan.isOverridden)
                    const Pill(
                      label: 'Ajustada',
                      color: AppColors.blue,
                      compact: true,
                    ),
                  const Spacer(),
                  Text(
                    '$done/${CleaningZone.values.length} listas',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text('Aseo', style: Theme.of(context).textTheme.bodySmall),
                  const Spacer(),
                  for (final member in team) ...[
                    Avatar(user: member, size: 24),
                    const SizedBox(width: 5),
                    Text(
                      member.firstName,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text('Bolsas', style: Theme.of(context).textTheme.bodySmall),
                  const Spacer(),
                  if (buyer != null) ...[
                    Avatar(user: buyer, size: 24),
                    const SizedBox(width: 5),
                    Text(
                      buyer.firstName,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 14),
              ProgressBar(
                value: CleaningZone.values.isEmpty
                    ? 0
                    : done / CleaningZone.values.length,
                color: AppColors.green,
              ),
            ],
          ),
        ),
        SectionHeader(
          title: 'Tareas personalizadas',
          actionLabel: 'Nueva',
          onAction: () =>
              showCustomTaskEditor(context, weekStart: plan.weekStart),
        ),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < state.customTasks.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: 1,
                    indent: 52,
                    color: context.appSeparator.withValues(alpha: 0.6),
                  ),
                _AdminCustomTaskRow(
                  task: state.customTasks[i],
                  weekStart: plan.weekStart,
                  state: state,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        SectionHeader(
          title: 'Turnos personalizados',
          actionLabel: 'Nuevo',
          onAction: () => showCustomTurnEditor(context, turn: null),
        ),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < state.customTurns.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: 1,
                    indent: 52,
                    color: context.appSeparator.withValues(alpha: 0.6),
                  ),
                _AdminCustomTurnRow(turn: state.customTurns[i], state: state),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        SectionHeader(
          title: 'Cuentas de acceso',
          actionLabel: 'Agregar',
          onAction: () => showUserEditor(context),
        ),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(
            children: [
              for (var i = 0; i < state.accounts.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: 1,
                    indent: 52,
                    color: context.appSeparator.withValues(alpha: 0.6),
                  ),
                UserRow(
                  user: state.accounts[i],
                  subtitle:
                      '@${state.accounts[i].username} · ${state.accounts[i].role.label}',
                  onTap: () => showUserEditor(context, user: state.accounts[i]),
                ),
              ],
            ],
          ),
        ),
        SectionHeader(
          title: 'Pagos del mes',
          actionLabel: 'Ver pagos',
          onAction: () => onNavigate(2),
        ),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: double.infinity,
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    Text(
                      '${state.paidCount(month)} de ${state.users.length} pagaron',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    Text(
                      '${formatMoney(state.collectedAmount(month))} / ${formatMoney(state.expectedAmount(month))}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              ProgressBar(
                value: state.monthProgress(month),
                color: AppColors.green,
              ),
              if (pending.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  'Pendientes: ${pending.map((item) => item.firstName).join(', ')}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.orange,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SectionHeader(title: 'Datos'),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          child: Column(
            children: [
              _DataRow(
                icon: CupertinoIcons.doc_on_doc,
                color: AppColors.blue,
                title: 'Copiar respaldo',
                subtitle: 'JSON de la casa sin credenciales',
                onTap: () async {
                  await Clipboard.setData(
                    ClipboardData(text: state.exportJson()),
                  );
                  if (!context.mounted) return;
                  showAppToast(
                    context,
                    'Respaldo copiado al portapapeles',
                    icon: CupertinoIcons.doc_on_doc,
                    color: AppColors.blue,
                  );
                },
              ),
              Divider(
                height: 1,
                indent: 52,
                color: context.appSeparator.withValues(alpha: 0.6),
              ),
              _DataRow(
                icon: CupertinoIcons.arrow_counterclockwise,
                color: AppColors.orange,
                title: 'Restablecer demo',
                subtitle: 'Vuelve a los datos iniciales',
                destructive: true,
                onTap: () async {
                  final confirmed = await showConfirmDialog(
                    context,
                    title: 'Restablecer datos',
                    message:
                        'Se borrarán los cambios de tareas, pagos y personas de este dispositivo. La sesión se mantiene si tu usuario existe en los datos iniciales.',
                    confirmLabel: 'Restablecer',
                    destructive: true,
                  );
                  if (!confirmed || !context.mounted) return;
                  await state.resetDemoData();
                  if (!context.mounted) return;
                  showAppToast(
                    context,
                    'Datos de demo restablecidos',
                    icon: CupertinoIcons.arrow_counterclockwise,
                    color: AppColors.orange,
                  );
                },
              ),
              Divider(
                height: 1,
                indent: 52,
                color: context.appSeparator.withValues(alpha: 0.6),
              ),
              _DataRow(
                icon: CupertinoIcons.cloud_fill,
                color: AppColors.teal,
                title: 'Conexión Supabase',
                subtitle: 'Modo local · sincronización pendiente',
                onTap: () => _showSupabaseInfo(context),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const InfoNote(
          icon: CupertinoIcons.shield_fill,
          text:
              'Gestiona los turnos, las tareas y los pagos de los inquilinos de la casa.',
          color: AppColors.orange,
        ),
      ],
    );
  }

  Future<void> _showSupabaseInfo(BuildContext context) {
    return showAppSheet<void>(
      context,
      builder: (sheetContext) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SheetHeader(
            title: 'Conectar Supabase',
            subtitle: 'Para compartir la casa entre dispositivos.',
            onClose: () => Navigator.of(sheetContext).pop(),
          ),
          const InfoNote(
            icon: CupertinoIcons.checkmark_seal_fill,
            text:
                'La app ya funciona sin internet. Los datos viven en este dispositivo.',
            color: AppColors.green,
          ),
          const SizedBox(height: 12),
          Text(
            'Pasos para la versión compartida:',
            style: Theme.of(sheetContext).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          const _Step(
            number: '1',
            text: 'Crea un proyecto para la casa en Supabase.',
          ),
          const _Step(
            number: '2',
            text: 'Abre el SQL Editor y ejecuta supabase/schema.sql.',
          ),
          const _Step(
            number: '3',
            text:
                'Crea cuatro cuentas de inquilinos y una de administración en Auth.',
          ),
          const _Step(
            number: '4',
            text:
                'La app aún usa datos locales. La guía describe el trabajo pendiente.',
          ),
          const SizedBox(height: 12),
          const InfoNote(
            icon: CupertinoIcons.doc_text_fill,
            text:
                'La guía completa está en docs/SUPABASE.md dentro del proyecto.',
            color: AppColors.teal,
          ),
        ],
      ),
    );
  }
}

class _DataRow extends StatelessWidget {
  const _DataRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      haptic: false,
      pressedScale: 0.995,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            SoftIcon(icon: icon, color: color, size: 34, iconSize: 16),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: destructive ? AppColors.red : null,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            Icon(
              CupertinoIcons.chevron_right,
              size: 14,
              color: context.appTertiary,
            ),
          ],
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.number, required this.text});

  final String number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: context.soft(AppColors.blue, 0.12),
              shape: BoxShape.circle,
            ),
            child: Text(
              number,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.blue,
              ),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminCustomTaskRow extends StatelessWidget {
  const _AdminCustomTaskRow({
    required this.task,
    required this.weekStart,
    required this.state,
  });

  final CustomTask task;
  final DateTime weekStart;
  final AppState state;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: () =>
          showCustomTaskEditor(context, task: task, weekStart: weekStart),
      haptic: false,
      pressedScale: 0.99,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 11),
        child: Row(
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
                  const SizedBox(height: 2),
                  Text(
                    '${state.customTaskAssigneesLabel(task)} · ${task.repeatWeekly ? 'Cada semana desde ' : 'Semana del '}${formatWeekRange(task.weekStart)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Icon(
              CupertinoIcons.chevron_right,
              size: 14,
              color: context.appTertiary,
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminCustomTurnRow extends StatelessWidget {
  const _AdminCustomTurnRow({required this.turn, required this.state});

  final CustomTurn turn;
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final current = state.userById(turn.currentUserId);
    final next = state.userById(turn.nextUserId);
    return Pressable(
      onTap: () => showCustomTurnEditor(context, turn: turn),
      haptic: false,
      pressedScale: 0.99,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 11),
        child: Row(
          children: [
            SoftIcon(
              icon: customIconFor(turn.iconKey),
              color: turn.color,
              size: 34,
              iconSize: 16,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    turn.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Ahora: ${current?.firstName ?? '—'} · Siguiente: ${next?.firstName ?? '—'}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Icon(
              CupertinoIcons.chevron_right,
              size: 14,
              color: context.appTertiary,
            ),
          ],
        ),
      ),
    );
  }
}
