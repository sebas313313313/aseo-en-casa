import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/dates.dart';
import '../state/app_state.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final user = state.currentUser;
    if (user == null) return const SizedBox.shrink();

    final monthsInHouse =
        ((state.now.year - user.joinedDate.year) * 12 +
                state.now.month -
                user.joinedDate.month)
            .clamp(0, 999);

    return Scaffold(
      body: PageBody(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
        children: [
          Row(
            children: [
              CircleIconButton(
                icon: CupertinoIcons.chevron_left,
                onTap: () => Navigator.of(context).pop(),
                tooltip: 'Volver',
              ),
              const Spacer(),
              Text('Perfil', style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              const SizedBox(width: 42),
            ],
          ),
          const SizedBox(height: 26),
          Center(
            child: Column(
              children: [
                Avatar(user: user, size: 94, ring: true),
                const SizedBox(height: 16),
                Text(
                  user.name,
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const SizedBox(height: 3),
                Text(
                  '@${user.username}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 10),
                RolePill(role: user.role),
              ],
            ),
          ),
          const SizedBox(height: 26),
          if (!user.isAdmin)
            AppCard(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                children: [
                  _ProfileStat(
                    value: '${state.tasksCompletedBy(user.id)}',
                    label: 'Tareas hechas',
                  ),
                  _StatDivider(),
                  _ProfileStat(
                    value: '${state.paymentsOnTimeBy(user.id)}',
                    label: 'Pagos al día',
                  ),
                  _StatDivider(),
                  _ProfileStat(value: '$monthsInHouse m', label: 'En la casa'),
                ],
              ),
            ),
          SectionHeader(title: 'Ajustes'),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            child: Column(
              children: [
                _SettingsRow(
                  icon: CupertinoIcons.moon_fill,
                  color: AppColors.indigo,
                  title: 'Apariencia',
                  value: switch (state.themeMode) {
                    ThemeMode.light => 'Claro',
                    ThemeMode.dark => 'Oscuro',
                    ThemeMode.system => 'Sistema',
                  },
                  onTap: () => _showThemeSheet(context, state),
                ),
                _RowDivider(),
                _SettingsRow(
                  icon: CupertinoIcons.bell_fill,
                  color: AppColors.orange,
                  title: 'Recordatorios',
                  value: 'Del 25 al 29',
                  onTap: () => _showRemindersSheet(context, state),
                ),
                _RowDivider(),
                _SettingsRow(
                  icon: CupertinoIcons.cloud_fill,
                  color: AppColors.teal,
                  title: 'Datos',
                  value: 'Modo local',
                  onTap: () => _showDataSheet(context),
                ),
                _RowDivider(),
                _SettingsRow(
                  icon: CupertinoIcons.info_circle_fill,
                  color: AppColors.blue,
                  title: 'Acerca de',
                  value: 'v1.0',
                  onTap: () => _showAboutSheet(context),
                ),
              ],
            ),
          ),
          if (state.isAdmin) ...[
            const SizedBox(height: 16),
            const InfoNote(
              icon: CupertinoIcons.shield_fill,
              text:
                  'Esta cuenta puede gestionar perfiles, reasignar el aseo y confirmar pagos.',
              color: AppColors.orange,
            ),
          ],
          const SizedBox(height: 22),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              state.logout();
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.red,
              side: BorderSide(color: AppColors.red.withValues(alpha: 0.25)),
            ),
            icon: const Icon(CupertinoIcons.arrow_left_square, size: 17),
            label: const Text('Cerrar sesión'),
          ),
          const SizedBox(height: 12),
          Text(
            'Casa Común · ${state.houseName}',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    );
  }

  Future<void> _showThemeSheet(BuildContext context, AppState state) {
    return showAppSheet<void>(
      context,
      builder: (sheetContext) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SheetHeader(
            title: 'Apariencia',
            subtitle: 'Elige cómo se ve la casa.',
            onClose: () => Navigator.of(sheetContext).pop(),
          ),
          for (final mode in ThemeMode.values)
            _ThemeOption(
              mode: mode,
              selected: state.themeMode == mode,
              onTap: () {
                state.setThemeMode(mode);
                Navigator.of(sheetContext).pop();
              },
            ),
        ],
      ),
    );
  }

  Future<void> _showRemindersSheet(BuildContext context, AppState state) {
    return showAppSheet<void>(
      context,
      builder: (sheetContext) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SheetHeader(
            title: 'Recordatorios',
            subtitle: 'Alertas dentro de la app.',
            onClose: () => Navigator.of(sheetContext).pop(),
          ),
          InfoNote(
            icon: CupertinoIcons.calendar,
            text:
                'Cada 25, 26, 27, 28 y 29 de mes aparece el recordatorio de pago de ${formatMoney(state.monthlyAmount)} por persona.',
          ),
          const SizedBox(height: 12),
          const InfoNote(
            icon: CupertinoIcons.trash_fill,
            text:
                'El turno de basura avisa a la persona actual. Al marcarlo, se activa automáticamente el siguiente turno.',
            color: AppColors.purple,
          ),
          const SizedBox(height: 12),
          const InfoNote(
            icon: CupertinoIcons.paintbrush_fill,
            text:
                'El aseo y las bolsas se avisan al equipo asignado de la semana.',
            color: AppColors.blue,
          ),
        ],
      ),
    );
  }

  Future<void> _showDataSheet(BuildContext context) {
    return showAppSheet<void>(
      context,
      builder: (sheetContext) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SheetHeader(
            title: 'Datos y Supabase',
            subtitle: 'Ahora mismo: modo local.',
            onClose: () => Navigator.of(sheetContext).pop(),
          ),
          const InfoNote(
            icon: CupertinoIcons.device_phone_portrait,
            text:
                'Toda la información se guarda en este dispositivo (localStorage en web). No se envía nada a internet.',
            color: AppColors.teal,
          ),
          const SizedBox(height: 12),
          Text(
            'Para compartir la casa entre varios teléfonos, el proyecto incluye:',
            style: Theme.of(sheetContext).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          const _Bullet(
            text: 'supabase/schema.sql con todas las tablas y permisos.',
          ),
          const _Bullet(text: 'docs/SUPABASE.md con la guía paso a paso.'),
          const _Bullet(
            text:
                'La app está separada en capas para cambiar el modo local por Supabase.',
          ),
          const SizedBox(height: 14),
          const InfoNote(
            icon: CupertinoIcons.lock_fill,
            text:
                'La contraseña local es solo para esta demo. Con Supabase se usará el login seguro de Supabase Auth.',
            color: AppColors.orange,
          ),
        ],
      ),
    );
  }

  Future<void> _showAboutSheet(BuildContext context) {
    return showAppSheet<void>(
      context,
      builder: (sheetContext) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SheetHeader(
            title: 'Casa Común',
            subtitle: 'v1.0 · Flutter + diseño tipo Apple',
            onClose: () => Navigator.of(sheetContext).pop(),
          ),
          const InfoNote(
            icon: CupertinoIcons.house_fill,
            text:
                'Una app sencilla para repartir el aseo, las bolsas, la basura y los servicios de una casa compartida.',
          ),
          const SizedBox(height: 12),
          const InfoNote(
            icon: CupertinoIcons.paintbrush_fill,
            text:
                'Diseñada con principios de Apple: jerarquía clara, materiales suaves, respuesta inmediata y movimiento con springs.',
            color: AppColors.purple,
          ),
          const SizedBox(height: 12),
          Text(
            'Hecha para Isa, Sebastián, Andrea y Sofi.',
            textAlign: TextAlign.center,
            style: Theme.of(sheetContext).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  const _ProfileStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(letterSpacing: -0.5),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 30, color: context.appSeparator);
  }
}

class _RowDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: 52,
      color: context.appSeparator.withValues(alpha: 0.6),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String value;
  final VoidCallback onTap;

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
              child: Text(title, style: Theme.of(context).textTheme.titleSmall),
            ),
            Text(value, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(width: 6),
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

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.mode,
    required this.selected,
    required this.onTap,
  });

  final ThemeMode mode;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final icon = switch (mode) {
      ThemeMode.system => CupertinoIcons.device_phone_portrait,
      ThemeMode.light => CupertinoIcons.sun_max_fill,
      ThemeMode.dark => CupertinoIcons.moon_fill,
    };
    final label = switch (mode) {
      ThemeMode.system => 'Sistema',
      ThemeMode.light => 'Claro',
      ThemeMode.dark => 'Oscuro',
    };
    return Pressable(
      onTap: onTap,
      haptic: false,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? context.soft(AppColors.blue, 0.1)
              : context.appCardAlt,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? context.soft(AppColors.blue, 0.25)
                : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: selected ? AppColors.blue : context.appSecondary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(label, style: Theme.of(context).textTheme.titleSmall),
            ),
            if (selected)
              const Icon(
                CupertinoIcons.check_mark_circled_solid,
                size: 20,
                color: AppColors.blue,
              ),
          ],
        ),
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 7),
            child: Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: context.appTertiary,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}
