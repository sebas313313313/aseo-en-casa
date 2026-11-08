import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:casacomun/app.dart';

import 'package:casacomun/core/dates.dart';
import 'package:casacomun/data/repository.dart';
import 'package:casacomun/data/seed.dart';
import 'package:casacomun/logic/rotation.dart';
import 'package:casacomun/models/models.dart';
import 'package:casacomun/screens/admin_screen.dart';
import 'package:casacomun/state/app_state.dart';

class _MemoryRepository implements AppRepository {
  Map<String, dynamic>? data;

  @override
  Future<Map<String, dynamic>?> load() async => data;

  @override
  Future<void> save(Map<String, dynamic> value) async {
    data = Map<String, dynamic>.from(value);
  }

  @override
  Future<void> clear() async {
    data = null;
  }
}

void main() {
  testWidgets('el botón Administración abre un inicio de sesión separado', (
    tester,
  ) async {
    final state = AppState(_MemoryRepository());
    await state.bootstrap();
    addTearDown(state.dispose);
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(value: state, child: const CasaApp()),
    );
    await tester.pumpAndSettle();
    expect(find.text('Sebastián'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);

    await tester.tap(find.widgetWithText(TextButton, 'Administración'));
    await tester.pumpAndSettle();
    expect(find.text('Sebastián'), findsNothing);

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'admin');
    await tester.enterText(fields.at(1), 'admin123');
    await tester.tap(find.widgetWithText(FilledButton, 'Entrar'));
    await tester.pumpAndSettle();
    expect(state.isAdmin, isTrue);
    expect(find.byType(AdminScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  group('fechas', () {
    test('la semana empieza en lunes', () {
      expect(mondayOf(DateTime(2026, 10, 31)), DateTime(2026, 10, 26));
      expect(mondayOf(DateTime(2026, 11, 1)), DateTime(2026, 10, 26));
    });

    test('el dinero se formatea en pesos', () {
      expect(formatMoney(60000), '\$60.000');
      expect(formatMoney(240000), '\$240.000');
    });
  });

  group('rotación', () {
    final seed = SeedData.build(DateTime(2026, 10, 31));
    final users = (seed['users'] as List)
        .map(
          (entry) =>
              HouseUser.fromJson(Map<String, dynamic>.from(entry as Map)),
        )
        .toList();
    final pairs = (seed['rotationPairs'] as List)
        .map((entry) => (entry as List).map((id) => id.toString()).toList())
        .toList();
    final bagOrder = (seed['bagOrder'] as List)
        .map((entry) => entry.toString())
        .toList();

    test('la semana 0 es Isa y Sebas, con Isa en las bolsas', () {
      final plan = RotationEngine.planFor(
        weekStart: DateTime(2026, 10, 26),
        users: users,
        rotationPairs: pairs,
        bagOrder: bagOrder,
      );
      expect(plan.team, ['isa', 'sebas']);
      expect(plan.bagBuyer, 'isa');
      expect(plan.zoneOwners[CleaningZone.bano], 'isa');
      expect(plan.zoneOwners[CleaningZone.cocina], 'sebas');
    });

    test('la siguiente semana es Andrea e Isa, con Andrea en las bolsas', () {
      final plan = RotationEngine.planFor(
        weekStart: DateTime(2026, 11, 2),
        users: users,
        rotationPairs: pairs,
        bagOrder: bagOrder,
      );
      expect(plan.team, ['andrea', 'isa']);
      expect(plan.bagBuyer, 'andrea');
      expect(plan.zoneOwners[CleaningZone.bano], 'isa');
      expect(plan.zoneOwners[CleaningZone.cocina], 'andrea');
    });

    test('la tercera semana es Sebas y Sofi', () {
      final plan = RotationEngine.planFor(
        weekStart: DateTime(2026, 11, 9),
        users: users,
        rotationPairs: pairs,
        bagOrder: bagOrder,
      );
      expect(plan.team, ['sebas', 'sofi']);
      expect(plan.bagBuyer, 'sebas');
    });
  });

  group('turno de basura', () {
    test('avanza al siguiente y deja historial', () {
      final trash = TrashState(order: ['isa', 'sebas', 'andrea']);
      expect(trash.currentUserId, 'isa');
      trash.advance(by: 'isa', at: DateTime(2026, 10, 31, 10));
      expect(trash.currentUserId, 'sebas');
      expect(trash.history.first.userId, 'isa');
      expect(trash.lastEmptiedBy, 'isa');
    });
  });

  group('cuentas separadas', () {
    test('solo los inquilinos tienen pagos y turnos', () async {
      final state = AppState(_MemoryRepository());
      await state.bootstrap();

      expect(state.users.map((user) => user.id), [
        'isa',
        'sebas',
        'andrea',
        'sofi',
      ]);
      expect(state.accounts.length, 5);
      expect(state.login('admin', 'admin123'), isNotNull);
      expect(state.login('sebas', 'sebas123', role: UserRole.admin), isNotNull);
      expect(state.login('sebas', 'sebas123'), isNull);
      expect(state.isAdmin, isFalse);

      expect(state.login('admin', 'admin123', role: UserRole.admin), isNull);
      expect(state.isAdmin, isTrue);
      expect(state.trash.order, isNot(contains('admin')));
      expect(state.customTurns.first.order, isNot(contains('admin')));
      expect(state.expectedAmount(state.monthKeyNow()), 240000);
      expect(state.canTogglePayment(state.monthKeyNow(), 'admin'), isFalse);
      expect(state.canTogglePayment(state.monthKeyNow(), 'sebas'), isTrue);
      expect(state.exportJson(), isNot(contains('admin123')));
    });

    test(
      'migra la cuenta anterior de Sebastián y conserva su historial',
      () async {
        final seed = SeedData.build(DateTime(2026, 10, 31));
        final accounts = (seed['users'] as List).cast<Map<String, dynamic>>();
        accounts.removeWhere((account) => account['id'] == 'admin');
        final sebastian = accounts.firstWhere(
          (account) => account['id'] == 'sebas',
        );
        sebastian['role'] = 'admin';
        sebastian['name'] = 'Sebas';
        seed['version'] = 1;
        seed['sessionUserId'] = 'sebas';
        final repository = _MemoryRepository()..data = seed;
        final state = AppState(repository);
        await state.bootstrap();

        expect(state.isLoggedIn, isFalse);
        expect(state.userById('sebas')?.name, 'Sebastián');
        expect(state.trash.currentUserId, 'sebas');
        expect(state.paymentFor('2026-10', 'sebas').paid, isTrue);
        expect(repository.data?['version'], SeedData.version);
        expect(
          state.accounts.where((account) => account.isAdmin).single.id,
          'admin',
        );
      },
    );

    test('en febrero el pago vence el último día disponible', () async {
      final state = AppState(_MemoryRepository());
      await state.bootstrap();
      expect(state.dueDateFor('2027-02'), DateTime(2027, 2, 28));
      expect(state.dueDateFor('2028-02'), DateTime(2028, 2, 29));
    });
  });

  group('tareas y turnos personalizados', () {
    test('la tarea personalizada aplica por semana', () {
      final task = CustomTask(
        id: 'task-balcon',
        title: 'Limpiar el balcón',
        notes: '',
        iconKey: 'clean',
        colorHex: '#34C759',
        assigneeIds: ['sofi'],
        weekStart: DateTime(2026, 10, 26),
        createdBy: 'sebas',
        createdAt: DateTime(2026, 10, 26),
      );
      expect(task.appliesToWeek(DateTime(2026, 10, 31)), isTrue);
      expect(task.appliesToWeek(DateTime(2026, 11, 9)), isFalse);
    });

    test('el admin crea una tarea y la asignada la marca', () async {
      final state = AppState(_MemoryRepository());
      await state.bootstrap();
      expect(state.login('admin', 'admin123', role: UserRole.admin), isNull);
      final week = state.currentPlan.weekStart;

      final error = state.addCustomTask(
        title: 'Limpiar el balcón',
        notes: '',
        assigneeIds: ['isa'],
        weekStart: week,
      );
      expect(error, isNull);
      final task = state.customTasks.last;
      expect(task.title, 'Limpiar el balcón');
      expect(state.canToggleCustomTask(task, week), isTrue);

      expect(state.login('isa', 'isa123'), isNull);
      expect(state.canToggleCustomTask(task, week), isTrue);
      state.toggleCustomTask(task, week);
      expect(state.isCustomTaskDone(task, week), isTrue);
    });

    test('el turno personalizado avanza solo para la persona actual', () async {
      final state = AppState(_MemoryRepository());
      await state.bootstrap();
      expect(state.login('admin', 'admin123', role: UserRole.admin), isNull);
      final error = state.addCustomTurn(
        title: 'Comprar papel de baño',
        notes: '',
        order: ['isa', 'sebas'],
      );
      expect(error, isNull);
      final turn = state.customTurns.last;
      expect(state.canCompleteCustomTurn(turn), isTrue);
      expect(state.login('isa', 'isa123'), isNull);
      expect(state.canCompleteCustomTurn(turn), isTrue);
      state.completeCustomTurn(turn);
      expect(state.canCompleteCustomTurn(state.customTurns.last), isFalse);
      expect(state.login('sebas', 'sebas123'), isNull);
      expect(state.canCompleteCustomTurn(state.customTurns.last), isTrue);
    });
  });
}
