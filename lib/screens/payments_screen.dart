import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/dates.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../ui/navigation.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key, required this.onNavigate});

  final ValueChanged<int> onNavigate;

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  int _monthOffset = 0;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final now = state.now;
    final monthDate = DateTime(now.year, now.month + _monthOffset, 1);
    final month = monthKey(monthDate);
    final currentUser = state.currentUser;
    if (currentUser == null) return const SizedBox.shrink();

    final paidCount = state.paidCount(month);
    final total = state.users.length;
    final progress = total == 0 ? 0.0 : paidCount / total;
    final overdue = state.isOverdue(month);

    return PageBody(
      children: [
        ScreenHeaderBar(
          title: 'Pagos',
          subtitle: 'Servicios de la casa',
          unreadAlerts: state.unreadAlertCount,
          onAlerts: () => widget.onNavigate(3),
          onProfile: () => openProfileScreen(context),
        ),
        const SizedBox(height: 18),
        WeekSwitcher(
          title: formatMonthYear(monthDate),
          subtitle: 'Aporte de ${formatMoney(state.monthlyAmount)} por persona',
          onPrevious: () => setState(() => _monthOffset--),
          onNext: _monthOffset < 0
              ? () => setState(() => _monthOffset++)
              : null,
        ),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF14855C), Color(0xFF30D158)],
              ),
            ),
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                Positioned(
                  top: -70,
                  right: -40,
                  child: Container(
                    width: 170,
                    height: 170,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.09),
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'RECAUDADO',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const Spacer(),
                        Pressable(
                          onTap: () => _copyReminder(state, monthDate, month),
                          pressedScale: 0.9,
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.16),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              CupertinoIcons.doc_on_doc,
                              size: 17,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      formatMonthYear(monthDate),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 23,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          formatMoney(state.collectedAmount(month)),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 34,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -1.2,
                            height: 1.05,
                          ),
                        ),
                        const SizedBox(width: 7),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 5),
                          child: Text(
                            'de ${formatMoney(state.expectedAmount(month))}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.72),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ProgressBar(
                      value: progress,
                      color: Colors.white,
                      trackColor: Colors.white.withValues(alpha: 0.22),
                      height: 9,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Text(
                          '$paidCount de $total personas pagaron',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          overdue && paidCount < total
                              ? 'Venció el ${state.dueDateFor(month).day}'
                              : 'Vence el ${state.dueDateFor(month).day} ${monthName(monthDate.month).substring(0, 3)}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SectionHeader(title: 'Estado por persona'),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(
            children: [
              for (var i = 0; i < state.users.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: 1,
                    indent: 52,
                    color: context.appSeparator.withValues(alpha: 0.6),
                  ),
                _PaymentRow(
                  state: state,
                  month: month,
                  user: state.users[i],
                  currentUser: currentUser,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),
        OutlinedButton.icon(
          onPressed: () => _copyReminder(state, monthDate, month),
          icon: const Icon(CupertinoIcons.doc_on_doc, size: 16),
          label: const Text('Copiar recordatorio para el grupo'),
        ),
        if (state.isAdmin) ...[
          const SizedBox(height: 12),
          const InfoNote(
            icon: CupertinoIcons.shield_fill,
            text:
                'Como administrador puedes confirmar o desmarcar el pago de cualquier persona.',
            color: AppColors.orange,
          ),
        ],
        const SizedBox(height: 16),
        InfoNote(
          icon: CupertinoIcons.bell_fill,
          text:
              'Los recordatorios aparecen el ${state.reminderDays.join(', ')} de cada mes. El pago vence el ${state.dueDateFor(month).day}.',
          color: AppColors.orange,
        ),
      ],
    );
  }

  Future<void> _copyReminder(
    AppState state,
    DateTime monthDate,
    String month,
  ) async {
    final pending = state.pendingUsers(month);
    final names = pending.isEmpty
        ? '¡Todos al día!'
        : 'Pendientes: ${pending.map((user) => user.firstName).join(', ')}.';
    final text =
        'Hola casa 👋 Recuerden que el ${state.dueDateFor(month).day} de ${monthName(monthDate.month)} toca pagar ${formatMoney(state.monthlyAmount)} para los servicios.\n$names';
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    showAppToast(
      context,
      'Recordatorio copiado',
      icon: CupertinoIcons.doc_on_doc,
      color: AppColors.blue,
    );
  }
}

class _PaymentRow extends StatelessWidget {
  const _PaymentRow({
    required this.state,
    required this.month,
    required this.user,
    required this.currentUser,
  });

  final AppState state;
  final String month;
  final HouseUser user;
  final HouseUser currentUser;

  @override
  Widget build(BuildContext context) {
    final record = state.paymentFor(month, user.id);
    final overdue = !record.paid && state.isOverdue(month);
    final color = record.paid
        ? AppColors.green
        : (overdue ? AppColors.red : AppColors.orange);
    final canToggle = state.canTogglePayment(month, user.id);
    final status = record.paid
        ? 'Pagado${record.paidAt != null ? ' el ${formatDayMonth(record.paidAt!)}' : ''}'
        : (overdue ? 'Pago vencido' : 'Pendiente de pago');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        children: [
          Avatar(user: user, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        user.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    if (user.id == currentUser.id) ...[
                      const SizedBox(width: 6),
                      const Pill(
                        label: 'Tú',
                        color: AppColors.blue,
                        compact: true,
                      ),
                    ],
                    if (user.isAdmin) ...[
                      const SizedBox(width: 5),
                      const Icon(
                        CupertinoIcons.shield_fill,
                        size: 11,
                        color: AppColors.orange,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  status,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatMoney(state.monthlyAmount),
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 5),
              CheckCircle(
                done: record.paid,
                size: 26,
                color: AppColors.green,
                onTap: canToggle
                    ? () => state.setPaymentPaid(month, user.id, !record.paid)
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
