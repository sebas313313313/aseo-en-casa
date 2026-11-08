import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  final _usernameFocus = FocusNode();
  bool _adminMode = false;
  final FocusNode _passwordFocus = FocusNode();
  String? _selectedId;
  String? _error;
  bool _obscure = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _usernameFocus.dispose();
    _passwordController.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _select(HouseUser user) {
    setState(() {
      _selectedId = user.id;
      _error = null;
      _passwordController.clear();
    });
    _passwordFocus.requestFocus();
  }

  void _toggleMode() {
    setState(() {
      _adminMode = !_adminMode;
      _error = null;
      _obscure = true;
      _usernameController.clear();
      _passwordController.clear();
    });
    if (_adminMode) {
      _usernameFocus.requestFocus();
    } else {
      FocusScope.of(context).unfocus();
    }
  }

  void _submit(AppState state) {
    final username = _adminMode
        ? _usernameController.text.trim()
        : state.userById(_selectedId)?.username;
    if (username == null || username.isEmpty) {
      setState(() => _error = 'Escribe tu usuario de administración.');
      return;
    }
    if (_passwordController.text.isEmpty) {
      setState(() => _error = 'Escribe tu contraseña.');
      return;
    }
    final error = state.login(
      username,
      _passwordController.text,
      role: _adminMode ? UserRole.admin : UserRole.tenant,
    );
    if (error != null) setState(() => _error = error);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final selected = state.userById(_selectedId);
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 220);

    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: -150,
            right: -110,
            child: IgnorePointer(
              child: Container(
                width: 430,
                height: 430,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.blue.withValues(alpha: 0.22),
                      AppColors.blue.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -170,
            left: -140,
            child: IgnorePointer(
              child: Container(
                width: 460,
                height: 460,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.orange.withValues(alpha: 0.16),
                      AppColors.orange.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 28,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [AppColors.blue, AppColors.indigo],
                            ),
                            borderRadius: BorderRadius.circular(23),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.blue.withValues(alpha: 0.32),
                                blurRadius: 30,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: const Icon(
                            CupertinoIcons.house_fill,
                            color: Colors.white,
                            size: 34,
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      Text(
                        'Casa Común',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.displayLarge,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'La casa, en orden. Sin dramas.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: context.appSecondary,
                        ),
                      ),
                      const SizedBox(height: 28),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: context.appCard,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: context.appSeparator),
                          boxShadow: [
                            BoxShadow(
                              color: context.appShadow,
                              blurRadius: 36,
                              offset: const Offset(0, 16),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Wrap(
                              alignment: WrapAlignment.spaceBetween,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 12,
                              runSpacing: 4,
                              children: [
                                Text(
                                  _adminMode
                                      ? 'Administración'
                                      : 'Elige tu perfil',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                if (!_adminMode)
                                  Text(
                                    '${state.users.length} personas',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            if (_adminMode)
                              TextField(
                                controller: _usernameController,
                                focusNode: _usernameFocus,
                                textInputAction: TextInputAction.next,
                                autocorrect: false,
                                onSubmitted: (_) =>
                                    _passwordFocus.requestFocus(),
                                decoration: const InputDecoration(
                                  labelText: 'Usuario de administración',
                                  prefixIcon: Icon(
                                    CupertinoIcons.person_crop_circle,
                                  ),
                                ),
                              )
                            else
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final itemWidth = constraints.maxWidth < 340
                                      ? (constraints.maxWidth - 8) / 2
                                      : (constraints.maxWidth - 24) / 4;
                                  return Wrap(
                                    spacing: 8,
                                    runSpacing: 14,
                                    children: [
                                      for (final user in state.users)
                                        SizedBox(
                                          width: itemWidth,
                                          child: _ProfileTile(
                                            user: user,
                                            selected: user.id == _selectedId,
                                            onTap: () => _select(user),
                                          ),
                                        ),
                                    ],
                                  );
                                },
                              ),
                            AnimatedSize(
                              duration: duration,
                              curve: Curves.easeOutCubic,
                              alignment: Alignment.topCenter,
                              child: !_adminMode && selected == null
                                  ? const SizedBox.shrink()
                                  : Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        const SizedBox(height: 22),
                                        Text(
                                          _adminMode
                                              ? 'Acceso de administración'
                                              : 'Hola, ${selected!.firstName}',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.titleLarge,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Ingresa tu contraseña para continuar.',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodySmall,
                                        ),
                                        const SizedBox(height: 12),
                                        TextField(
                                          controller: _passwordController,
                                          focusNode: _passwordFocus,
                                          obscureText: _obscure,
                                          autofillHints: const [
                                            AutofillHints.password,
                                          ],
                                          textInputAction: TextInputAction.done,
                                          onSubmitted: (_) => _submit(state),
                                          decoration: InputDecoration(
                                            hintText: 'Contraseña',
                                            errorText: _error,
                                            prefixIcon: const Icon(
                                              CupertinoIcons.lock_fill,
                                              size: 18,
                                            ),
                                            suffixIcon: IconButton(
                                              onPressed: () => setState(
                                                () => _obscure = !_obscure,
                                              ),
                                              icon: Icon(
                                                _obscure
                                                    ? CupertinoIcons.eye_fill
                                                    : CupertinoIcons
                                                          .eye_slash_fill,
                                                size: 19,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 14),
                                        FilledButton(
                                          onPressed: () => _submit(state),
                                          child: const Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text('Entrar'),
                                              SizedBox(width: 7),
                                              Icon(
                                                CupertinoIcons
                                                    .arrow_right_circle_fill,
                                                size: 18,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: _toggleMode,
                        icon: Icon(
                          _adminMode
                              ? CupertinoIcons.chevron_left
                              : CupertinoIcons.shield_lefthalf_fill,
                          size: 18,
                        ),
                        label: Text(
                          _adminMode
                              ? 'Volver a los perfiles'
                              : 'Administración',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'v1.0 · Hecho para vivir mejor en casa',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
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
      pressedScale: 0.94,
      child: AnimatedContainer(
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: selected ? context.soft(AppColors.blue, 0.1) : null,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? context.soft(AppColors.blue, 0.28)
                : Colors.transparent,
          ),
        ),
        child: Column(
          children: [
            Avatar(
              user: user,
              size: 50,
              ring: selected,
              badge: selected
                  ? Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: AppColors.blue,
                        shape: BoxShape.circle,
                        border: Border.all(color: context.appCard, width: 2),
                      ),
                      child: const Icon(
                        CupertinoIcons.check_mark,
                        color: Colors.white,
                        size: 10,
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 7),
            Text(
              user.firstName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 3),
            RolePill(role: user.role, compact: true),
          ],
        ),
      ),
    );
  }
}
