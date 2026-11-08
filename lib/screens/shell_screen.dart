import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../ui/widgets.dart';
import 'admin_screen.dart';
import 'alerts_screen.dart';
import 'home_screen.dart';
import 'payments_screen.dart';
import 'tasks_screen.dart';

class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  int? _index;

  void _go(int index) {
    if (index == _index) return;
    setState(() => _index = index);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isAdmin = state.isAdmin;

    final items = <AppTabItem>[
      const AppTabItem(
        icon: CupertinoIcons.house,
        activeIcon: CupertinoIcons.house_fill,
        label: 'Inicio',
      ),
      const AppTabItem(
        icon: CupertinoIcons.checkmark_circle,
        activeIcon: CupertinoIcons.checkmark_circle_fill,
        label: 'Tareas',
      ),
      const AppTabItem(
        icon: CupertinoIcons.creditcard,
        activeIcon: CupertinoIcons.creditcard_fill,
        label: 'Pagos',
      ),
      AppTabItem(
        icon: CupertinoIcons.bell,
        activeIcon: CupertinoIcons.bell_fill,
        label: 'Alertas',
        badge: state.unreadAlertCount,
      ),
      if (isAdmin)
        const AppTabItem(
          icon: CupertinoIcons.slider_horizontal_3,
          activeIcon: CupertinoIcons.slider_horizontal_3,
          label: 'Admin',
        ),
    ];

    final safeIndex = (_index ?? (isAdmin ? 4 : 0)).clamp(0, items.length - 1);

    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: safeIndex,
        children: [
          HomeScreen(onNavigate: _go),
          TasksScreen(onNavigate: _go),
          PaymentsScreen(onNavigate: _go),
          AlertsScreen(onNavigate: _go),
          if (isAdmin) AdminScreen(onNavigate: _go),
        ],
      ),
      bottomNavigationBar: AppTabBar(
        index: safeIndex,
        items: items,
        onChanged: _go,
      ),
    );
  }
}
