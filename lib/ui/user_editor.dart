import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import 'theme.dart';
import 'widgets.dart';

Future<void> showUserEditor(BuildContext context, {HouseUser? user}) {
  return showAppSheet<void>(
    context,
    builder: (_) => _UserEditorSheet(user: user),
  );
}

class _UserEditorSheet extends StatefulWidget {
  const _UserEditorSheet({this.user});

  final HouseUser? user;

  @override
  State<_UserEditorSheet> createState() => _UserEditorSheetState();
}

class _UserEditorSheetState extends State<_UserEditorSheet> {
  late final TextEditingController _name;
  late final TextEditingController _username;
  late final TextEditingController _password;
  late UserRole _role;
  String? _error;
  bool _obscure = true;

  bool get _editing => widget.user != null;

  @override
  void initState() {
    super.initState();
    final user = widget.user;
    _name = TextEditingController(text: user?.name ?? '');
    _username = TextEditingController(text: user?.username ?? '');
    _password = TextEditingController();
    _role = user?.role ?? UserRole.tenant;
  }

  @override
  void dispose() {
    _name.dispose();
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  void _save(AppState state) {
    final error = _editing
        ? state.updateUser(
            id: widget.user!.id,
            name: _name.text,
            password: _password.text,
          )
        : state.addUser(
            name: _name.text,
            username: _username.text,
            password: _password.text,
            role: _role,
          );
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    showAppToast(
      context,
      _editing ? 'Persona actualizada' : 'Cuenta creada',
      icon: CupertinoIcons.check_mark_circled_solid,
      color: AppColors.green,
    );
    Navigator.of(context).pop();
  }

  Future<void> _delete(AppState state) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Eliminar a ${widget.user!.name}',
      message:
          'Se quitará de la rotación y del historial de pagos de este dispositivo. Esta acción no se puede deshacer.',
      confirmLabel: 'Eliminar',
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    final error = state.deleteUser(widget.user!.id);
    if (error != null) {
      if (!mounted) return;
      showAppToast(
        context,
        error,
        icon: CupertinoIcons.exclamationmark_triangle_fill,
        color: AppColors.red,
      );
      return;
    }
    showAppToast(
      context,
      '${widget.user!.firstName} ya no está en la casa',
      icon: CupertinoIcons.person_fill,
      color: AppColors.orange,
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isSelf = widget.user?.id == state.currentUser?.id;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SheetHeader(
          title: _editing ? 'Editar persona' : 'Agregar persona',
          subtitle: _editing
              ? '@${widget.user!.username}'
              : 'Elige el acceso para la cuenta nueva.',
          onClose: () => Navigator.of(context).pop(),
        ),
        TextField(
          controller: _name,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Nombre',
            hintText: 'Ej. Isa',
            prefixIcon: Icon(CupertinoIcons.person_fill, size: 18),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _username,
          enabled: !_editing,
          autocorrect: false,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Usuario',
            hintText: 'isa',
            prefixIcon: Icon(CupertinoIcons.at, size: 18),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _password,
          obscureText: _obscure,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            labelText: _editing ? 'Nueva contraseña (opcional)' : 'Contraseña',
            hintText: _editing
                ? 'Déjala vacía para conservarla'
                : 'Mínimo 4 caracteres',
            prefixIcon: const Icon(CupertinoIcons.lock_fill, size: 18),
            suffixIcon: IconButton(
              onPressed: () => setState(() => _obscure = !_obscure),
              icon: Icon(
                _obscure
                    ? CupertinoIcons.eye_fill
                    : CupertinoIcons.eye_slash_fill,
                size: 18,
              ),
            ),
          ),
        ),
        if (!_editing) ...[
          const SizedBox(height: 18),
          Text('Rol', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          _RoleOption(
            role: UserRole.tenant,
            selected: _role == UserRole.tenant,
            title: 'Inquilino',
            subtitle: 'Ve sus tareas, su turno y sus pagos.',
            onTap: () => setState(() => _role = UserRole.tenant),
          ),
          const SizedBox(height: 8),
          _RoleOption(
            role: UserRole.admin,
            selected: _role == UserRole.admin,
            title: 'Administrador',
            subtitle: 'Gestiona cuentas, turnos y pagos de la casa.',
            onTap: () => setState(() => _role = UserRole.admin),
          ),
        ],
        if (_error != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(
                  CupertinoIcons.exclamationmark_circle_fill,
                  color: AppColors.red,
                  size: 17,
                ),
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
        ],
        const SizedBox(height: 18),
        FilledButton(
          onPressed: () => _save(state),
          child: Text(_editing ? 'Guardar cambios' : 'Crear cuenta'),
        ),
        if (_editing && !isSelf) ...[
          const SizedBox(height: 6),
          TextButton.icon(
            onPressed: () => _delete(state),
            style: TextButton.styleFrom(foregroundColor: AppColors.red),
            icon: const Icon(CupertinoIcons.trash, size: 16),
            label: const Text('Eliminar persona'),
          ),
        ],
      ],
    );
  }
}

class _RoleOption extends StatelessWidget {
  const _RoleOption({
    required this.role,
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final UserRole role;
  final bool selected;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = role == UserRole.admin ? AppColors.orange : AppColors.blue;
    return Pressable(
      onTap: onTap,
      haptic: false,
      pressedScale: 0.985,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? context.soft(color, 0.1) : context.appCardAlt,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? context.soft(color, 0.32) : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            SoftIcon(
              icon: role == UserRole.admin
                  ? CupertinoIcons.shield_fill
                  : CupertinoIcons.person_fill,
              color: color,
              size: 34,
              iconSize: 15,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 1),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? color : Colors.transparent,
                border: Border.all(
                  color: selected ? color : context.appTertiary,
                  width: 1.5,
                ),
              ),
              child: selected
                  ? const Icon(
                      CupertinoIcons.check_mark,
                      size: 12,
                      color: Colors.white,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
