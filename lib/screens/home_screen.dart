import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../ui/custom_editors.dart';
import '../ui/house_cards.dart';
import '../ui/navigation.dart';
import '../ui/widgets.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onNavigate});

  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final user = state.currentUser;
    if (user == null) return const SizedBox.shrink();
    final plan = state.currentPlan;

    return PageBody(
      children: [
        HomeHeader(
          user: user,
          unreadAlerts: state.unreadAlertCount,
          onAlerts: () => onNavigate(3),
          onProfile: () => openProfileScreen(context),
        ),
        const SizedBox(height: 18),
        if (!state.isAdmin) HomeBanner(onNavigate: onNavigate),
        const SizedBox(height: 16),
        FadeSlideIn(
          child: WeekHeroCard(plan: plan, onOpenTasks: () => onNavigate(1)),
        ),
        const SectionHeader(title: 'Turnos de la semana'),
        CleaningTasksCard(plan: plan),
        const SizedBox(height: 12),
        BagsCard(plan: plan),
        const SizedBox(height: 12),
        if (state.isAdmin ||
            state.customTasksForWeek(plan.weekStart).isNotEmpty) ...[
          CustomTasksCard(
            weekStart: plan.weekStart,
            showCreateAction: state.isAdmin,
          ),
          const SizedBox(height: 12),
        ],
        const SectionHeader(title: 'Turnos de la casa'),
        const TrashTurnCard(),
        for (final turn in state.customTurns) ...[
          CustomTurnCard(
            turn: turn,
            onEdit: () => showCustomTurnEditor(context, turn: turn),
          ),
          const SizedBox(height: 12),
        ],
        const SectionHeader(title: 'Servicios'),
        PaymentSummaryCard(onOpen: () => onNavigate(2)),
        if (state.isAdmin) ...[
          const SizedBox(height: 12),
          AdminPulseCard(
            onOpenAdmin: () => onNavigate(4),
            onOpenPayments: () => onNavigate(2),
          ),
        ],
        const SizedBox(height: 18),
        const InfoNote(
          icon: CupertinoIcons.calendar,
          text:
              'Los recordatorios de pago aparecen automáticamente del 25 al 29 de cada mes. El pago vence el 29.',
        ),
      ],
    );
  }
}
