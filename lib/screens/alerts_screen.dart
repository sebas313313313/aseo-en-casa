import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../ui/house_cards.dart';
import '../ui/navigation.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key, required this.onNavigate});

  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final alerts = state.alerts;
    final unread = alerts.where((alert) => !alert.isRead).length;

    return PageBody(
      children: [
        ScreenHeaderBar(
          title: 'Alertas',
          subtitle: unread == 0 ? 'Todo al día' : '$unread sin leer',
          unreadAlerts: unread,
          onAlerts: () {},
          onProfile: () => openProfileScreen(context),
          showAlerts: false,
        ),
        if (unread > 0) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: state.markAllAlertsRead,
              icon: const Icon(CupertinoIcons.checkmark_alt, size: 16),
              label: const Text('Marcar todas como leídas'),
            ),
          ),
        ],
        const SizedBox(height: 12),
        if (alerts.isEmpty)
          const AppCard(
            child: EmptyState(
              icon: CupertinoIcons.bell_slash,
              title: 'Sin alertas por ahora',
              message:
                  'Cuando haya un pago próximo, una tarea de aseo o un turno de basura, aparecerá aquí.',
              color: AppColors.green,
            ),
          )
        else
          for (final alert in alerts) ...[
            AlertTile(
              alert: alert,
              onTap: () {
                state.markAlertRead(alert.id);
                if (alert.actionTab != 0) onNavigate(alert.actionTab);
              },
            ),
            const SizedBox(height: 10),
          ],
        const SizedBox(height: 8),
        const InfoNote(
          icon: CupertinoIcons.calendar,
          text:
              'Los recordatorios de pago se generan automáticamente del 25 al 29 de cada mes. Las alertas de aseo, bolsas y basura se activan según la rotación.',
        ),
        const SizedBox(height: 10),
        const InfoNote(
          icon: CupertinoIcons.checkmark_seal_fill,
          text:
              'Las alertas se guardan en este dispositivo. Al marcar una como leída, deja de resaltarse.',
          color: AppColors.green,
        ),
      ],
    );
  }
}
