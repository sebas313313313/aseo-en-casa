import 'dart:convert';

import 'package:flutter/material.dart';

import '../core/dates.dart';
import '../data/repository.dart';
import '../data/seed.dart';
import '../logic/rotation.dart';
import '../models/models.dart';

class AppState extends ChangeNotifier {
  AppState(this._repository);

  final AppRepository _repository;

  bool _ready = false;
  List<HouseUser> _users = [];
  String? _sessionUserId;
  List<List<String>> _rotationPairs = [];
  List<String> _bagOrder = [];
  Map<String, WeekOverride> _weekOverrides = {};
  Map<String, TaskCompletion> _completions = {};
  TrashState _trash = TrashState(order: []);
  List<CustomTask> _customTasks = [];
  List<CustomTurn> _customTurns = [];
  Map<String, Map<String, dynamic>> _customTurnUndo = {};
  Map<String, Map<String, PaymentRecord>> _payments = {};
  Set<String> _readAlerts = {};
  ThemeMode _themeMode = ThemeMode.system;
  String _houseName = 'Casa Común';
  int _monthlyAmount = 60000;
  int _dueDay = 29;
  List<int> _reminderDays = const [25, 26, 27, 28, 29];
  Map<String, dynamic>? _trashUndo;
  Future<void> _saveChain = Future<void>.value();

  bool get isReady => _ready;
  DateTime get now => DateTime.now();
  Iterable<HouseUser> get _tenants => _users.where((user) => !user.isAdmin);
  List<HouseUser> get users => List<HouseUser>.unmodifiable(_tenants);
  List<HouseUser> get accounts => List<HouseUser>.unmodifiable(_users);
  String get houseName => _houseName;
  int get monthlyAmount => _monthlyAmount;
  int get dueDay => dueDateFor(monthKey(now)).day;
  List<int> get reminderDays => List<int>.unmodifiable(_reminderDays);
  ThemeMode get themeMode => _themeMode;
  TrashState get trash => _trash;
  bool get canUndoTrash => _trashUndo != null;
  List<CustomTask> get customTasks =>
      List<CustomTask>.unmodifiable(_customTasks);
  List<CustomTurn> get customTurns =>
      List<CustomTurn>.unmodifiable(_customTurns);

  HouseUser? get currentUser {
    for (final user in _users) {
      if (user.id == _sessionUserId) return user;
    }
    return null;
  }

  bool get isLoggedIn => currentUser != null;
  bool get isAdmin => currentUser?.isAdmin ?? false;

  HouseUser? userById(String? id) {
    if (id == null) return null;
    for (final user in _users) {
      if (user.id == id) return user;
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Ciclo de vida
  // ---------------------------------------------------------------------------

  Future<void> bootstrap() async {
    final loaded = await _repository.load();
    final data = loaded ?? SeedData.build(DateTime.now());
    final needsMigration = data['version'] == 1;
    _hydrate(data);
    if (loaded == null || needsMigration) {
      await _repository.save(_serialize());
    }
    _ready = true;
    notifyListeners();
  }

  void _hydrate(Map<String, dynamic> data) {
    _users =
        (data['users'] as List?)
            ?.map(
              (entry) =>
                  HouseUser.fromJson(Map<String, dynamic>.from(entry as Map)),
            )
            .toList() ??
        <HouseUser>[];

    _sessionUserId = data['sessionUserId']?.toString();
    if (data['version'] == 1) _migrateLegacyAccounts();
    if (_sessionUserId != null &&
        !_users.any((user) => user.id == _sessionUserId)) {
      _sessionUserId = null;
    }

    _rotationPairs =
        (data['rotationPairs'] as List?)
            ?.map(
              (entry) =>
                  (entry as List).map((value) => value.toString()).toList(),
            )
            .toList() ??
        <List<String>>[];

    _bagOrder =
        (data['bagOrder'] as List?)
            ?.map((entry) => entry.toString())
            .toList() ??
        <String>[];

    _weekOverrides =
        (data['weekOverrides'] as Map?)?.map(
          (key, value) => MapEntry(
            key.toString(),
            WeekOverride.fromJson(Map<String, dynamic>.from(value as Map)),
          ),
        ) ??
        <String, WeekOverride>{};

    _completions =
        (data['completions'] as Map?)?.map(
          (key, value) => MapEntry(
            key.toString(),
            TaskCompletion.fromJson(Map<String, dynamic>.from(value as Map)),
          ),
        ) ??
        <String, TaskCompletion>{};

    _trash = TrashState.fromJson(
      data['trash'] == null
          ? null
          : Map<String, dynamic>.from(data['trash'] as Map),
    );
    _normalizeTrashOrder();

    _customTasks =
        (data['customTasks'] as List?)
            ?.map(
              (entry) =>
                  CustomTask.fromJson(Map<String, dynamic>.from(entry as Map)),
            )
            .toList() ??
        <CustomTask>[];
    _customTurns =
        (data['customTurns'] as List?)
            ?.map(
              (entry) =>
                  CustomTurn.fromJson(Map<String, dynamic>.from(entry as Map)),
            )
            .toList() ??
        <CustomTurn>[];
    _customTurnUndo = {};
    _normalizeCustomData();

    _payments =
        (data['payments'] as Map?)?.map(
          (month, records) => MapEntry(
            month.toString(),
            (records as Map).map(
              (userId, record) => MapEntry(
                userId.toString(),
                PaymentRecord.fromJson(
                  Map<String, dynamic>.from(record as Map),
                ),
              ),
            ),
          ),
        ) ??
        <String, Map<String, PaymentRecord>>{};

    _readAlerts =
        (data['readAlerts'] as List?)
            ?.map((entry) => entry.toString())
            .toSet() ??
        <String>{};

    _themeMode = switch (data['themeMode']?.toString()) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };

    _houseName = data['houseName']?.toString() ?? 'Casa Común';
    _monthlyAmount = (data['monthlyAmount'] as num?)?.toInt() ?? 60000;
    _dueDay = (data['dueDay'] as num?)?.toInt() ?? 29;
    _reminderDays =
        (data['reminderDays'] as List?)
            ?.map((entry) => (entry as num).toInt())
            .toList() ??
        const [25, 26, 27, 28, 29];
  }

  void _migrateLegacyAccounts() {
    final sebastian = userById('sebas');
    if (sebastian != null) {
      if (sebastian.name == 'Sebas') sebastian.name = 'Sebastián';
      if (sebastian.isAdmin) {
        sebastian.role = UserRole.tenant;
        if (_sessionUserId == sebastian.id) _sessionUserId = null;
      }
    }
    if (_users.any((user) => user.isAdmin)) return;

    var username = 'admin';
    var suffix = 2;
    while (_users.any(
      (user) => user.id == username || user.username.toLowerCase() == username,
    )) {
      username = 'admin${suffix++}';
    }
    _users.add(SeedData.admin(now, username: username));
  }

  Map<String, dynamic> _serialize() => {
    'version': SeedData.version,
    'users': _users.map((user) => user.toJson()).toList(),
    'sessionUserId': _sessionUserId,
    'rotationPairs': _rotationPairs,
    'bagOrder': _bagOrder,
    'weekOverrides': _weekOverrides.map(
      (key, value) => MapEntry(key, value.toJson()),
    ),
    'completions': _completions.map(
      (key, value) => MapEntry(key, value.toJson()),
    ),
    'trash': _trash.toJson(),
    'customTasks': _customTasks.map((task) => task.toJson()).toList(),
    'customTurns': _customTurns.map((turn) => turn.toJson()).toList(),
    'payments': _payments.map(
      (month, records) => MapEntry(
        month,
        records.map((userId, record) => MapEntry(userId, record.toJson())),
      ),
    ),
    'readAlerts': _readAlerts.toList(),
    'themeMode': _themeMode.name,
    'houseName': _houseName,
    'monthlyAmount': _monthlyAmount,
    'dueDay': _dueDay,
    'reminderDays': _reminderDays,
    'updatedAt': now.toIso8601String(),
  };

  void _persist() {
    final snapshot = _serialize();
    _saveChain = _saveChain
        .then((_) => _repository.save(snapshot))
        .catchError((Object _) {});
  }

  String exportJson() {
    if (!isAdmin) return '';
    final data = _serialize()..remove('sessionUserId');
    for (final account in data['users'] as List<Map<String, dynamic>>) {
      account.remove('password');
    }
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  // ---------------------------------------------------------------------------
  // Sesión y preferencias
  // ---------------------------------------------------------------------------

  String? login(
    String username,
    String password, {
    UserRole role = UserRole.tenant,
  }) {
    final clean = username.trim().toLowerCase();
    HouseUser? found;
    for (final user in _users) {
      if (user.role == role && user.username.toLowerCase() == clean) {
        found = user;
        break;
      }
    }
    if (found == null) return 'No encontramos ese usuario.';
    if (found.password != password) return 'La contraseña no coincide.';
    _clearUndo();
    _sessionUserId = found.id;
    _persist();
    notifyListeners();
    return null;
  }

  void _clearUndo() {
    _trashUndo = null;
    _customTurnUndo.clear();
  }

  void logout() {
    _clearUndo();
    _sessionUserId = null;
    _persist();
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    _persist();
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Rotación y tareas
  // ---------------------------------------------------------------------------

  WeekPlan planFor(DateTime weekStart) => RotationEngine.planFor(
    weekStart: weekStart,
    users: users,
    rotationPairs: _rotationPairs,
    bagOrder: _bagOrder,
    overrides: _weekOverrides,
  );

  WeekPlan get currentPlan => planFor(mondayOf(now));

  bool isCurrentWeek(DateTime weekStart) =>
      dateKey(mondayOf(weekStart)) == dateKey(mondayOf(now));

  bool hasOverride(DateTime weekStart) =>
      _weekOverrides.containsKey(dateKey(mondayOf(weekStart)));

  bool isZoneDone(WeekPlan plan, CleaningZone zone) =>
      _completions.containsKey(zoneTaskId(plan.weekStart, zone));

  bool isBagsDone(WeekPlan plan) =>
      _completions.containsKey(bagsTaskId(plan.weekStart));

  int cleaningDoneCount(WeekPlan plan) =>
      CleaningZone.values.where((zone) => isZoneDone(plan, zone)).length;

  int weekDoneCount(WeekPlan plan) =>
      cleaningDoneCount(plan) + (isBagsDone(plan) ? 1 : 0);

  int get weekTotalCount => CleaningZone.values.length + 1;

  bool canToggleZone(WeekPlan plan, CleaningZone zone) {
    final user = currentUser;
    if (user == null) return false;
    if (!user.isAdmin && !isCurrentWeek(plan.weekStart)) return false;
    return user.isAdmin || plan.zoneOwners[zone] == user.id;
  }

  void toggleZone(WeekPlan plan, CleaningZone zone) {
    if (!canToggleZone(plan, zone)) return;
    final user = currentUser!;
    final id = zoneTaskId(plan.weekStart, zone);
    if (_completions.remove(id) == null) {
      _completions[id] = TaskCompletion(at: now, by: user.id);
    }
    _persist();
    notifyListeners();
  }

  bool canToggleBags(WeekPlan plan) {
    final user = currentUser;
    if (user == null) return false;
    if (!user.isAdmin && !isCurrentWeek(plan.weekStart)) return false;
    return user.isAdmin || plan.bagBuyer == user.id;
  }

  void toggleBags(WeekPlan plan) {
    if (!canToggleBags(plan)) return;
    final user = currentUser!;
    final id = bagsTaskId(plan.weekStart);
    if (_completions.remove(id) == null) {
      _completions[id] = TaskCompletion(at: now, by: user.id);
    }
    _persist();
    notifyListeners();
  }

  TaskCompletion? completionForZone(WeekPlan plan, CleaningZone zone) =>
      _completions[zoneTaskId(plan.weekStart, zone)];

  TaskCompletion? completionForBags(WeekPlan plan) =>
      _completions[bagsTaskId(plan.weekStart)];

  void setWeekOverride(
    DateTime weekStart, {
    required List<String> team,
    required String bagBuyer,
  }) {
    if (!isAdmin) return;
    final tenantIds = _tenants.map((user) => user.id).toSet();
    if (team.length != 2 ||
        team[0] == team[1] ||
        !team.every(tenantIds.contains) ||
        !tenantIds.contains(bagBuyer)) {
      return;
    }
    _weekOverrides[dateKey(mondayOf(weekStart))] = WeekOverride(
      team: List<String>.from(team),
      bagBuyer: bagBuyer,
    );
    _persist();
    notifyListeners();
  }

  void clearWeekOverride(DateTime weekStart) {
    if (!isAdmin) return;
    _weekOverrides.remove(dateKey(mondayOf(weekStart)));
    _persist();
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Basura
  // ---------------------------------------------------------------------------

  void _normalizeTrashOrder() {
    final validIds = _tenants.map((user) => user.id).toSet();
    final currentId = _trash.currentUserId;
    _trash.order = _trash.order.where(validIds.contains).toList();
    for (final user in _tenants) {
      if (!_trash.order.contains(user.id)) _trash.order.add(user.id);
    }
    if (_trash.order.isNotEmpty) {
      final index = _trash.order.indexOf(currentId ?? '');
      _trash.currentIndex = index >= 0
          ? index
          : _trash.currentIndex % _trash.order.length;
    } else {
      _trash.currentIndex = 0;
    }
  }

  bool get canEmptyTrash {
    final user = currentUser;
    if (user == null) return false;
    return user.isAdmin || _trash.currentUserId == user.id;
  }

  void emptyTrash() {
    if (!canEmptyTrash) return;
    _trashUndo = _trash.toJson();
    _trash.advance(by: currentUser!.id, at: now);
    _persist();
    notifyListeners();
  }

  void skipTrashTurn() {
    if (!isAdmin) return;
    _trashUndo = _trash.toJson();
    _trash.skip();
    _persist();
    notifyListeners();
  }

  void undoTrashChange() {
    if (_trashUndo == null) return;
    _trash = TrashState.fromJson(_trashUndo);
    _trashUndo = null;
    _persist();
    notifyListeners();
  }

  void resetTrashTurn() {
    if (!isAdmin) return;
    _trashUndo = _trash.toJson();
    _trash.currentIndex = 0;
    _persist();
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Tareas y turnos personalizados
  // ---------------------------------------------------------------------------

  void _normalizeCustomData() {
    final validIds = _tenants.map((user) => user.id).toSet();
    for (final task in _customTasks) {
      task.assigneeIds = task.assigneeIds
          .where(validIds.contains)
          .toList(growable: true);
    }
    for (final turn in _customTurns) {
      final currentId = turn.currentUserId;
      turn.order = turn.order.where(validIds.contains).toList(growable: true);
      final index = turn.order.indexOf(currentId ?? '');
      if (index >= 0) turn.currentIndex = index;
      turn.normalize();
    }
  }

  String _newCustomId(String prefix) {
    final base = '$prefix-${now.millisecondsSinceEpoch}';
    var id = base;
    var suffix = 2;
    bool exists(String value) =>
        _customTasks.any((task) => task.id == value) ||
        _customTurns.any((turn) => turn.id == value);
    while (exists(id)) {
      id = '$base-$suffix';
      suffix++;
    }
    return id;
  }

  List<CustomTask> customTasksForWeek(DateTime weekStart) {
    final monday = mondayOf(weekStart);
    final tasks = _customTasks
        .where((task) => task.appliesToWeek(monday))
        .toList();
    tasks.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return tasks;
  }

  CustomTask? customTaskById(String id) {
    for (final task in _customTasks) {
      if (task.id == id) return task;
    }
    return null;
  }

  CustomTurn? customTurnById(String id) {
    for (final turn in _customTurns) {
      if (turn.id == id) return turn;
    }
    return null;
  }

  String customTaskAssigneesLabel(CustomTask task) {
    final names = task.assigneeIds
        .map((id) => userById(id)?.firstName ?? '—')
        .toList();
    if (names.isEmpty) return 'Sin asignar';
    return names.join(', ');
  }

  String customTaskCompletionId(CustomTask task, DateTime weekStart) =>
      'custom:${task.id}:${dateKey(mondayOf(weekStart))}';

  bool isCustomTaskDone(CustomTask task, DateTime weekStart) =>
      _completions.containsKey(customTaskCompletionId(task, weekStart));

  TaskCompletion? completionForCustomTask(
    CustomTask task,
    DateTime weekStart,
  ) => _completions[customTaskCompletionId(task, weekStart)];

  bool canToggleCustomTask(CustomTask task, DateTime weekStart) {
    final user = currentUser;
    if (user == null) return false;
    if (!user.isAdmin && !isCurrentWeek(weekStart)) return false;
    return user.isAdmin || task.assigneeIds.contains(user.id);
  }

  void toggleCustomTask(CustomTask task, DateTime weekStart) {
    if (!canToggleCustomTask(task, weekStart)) return;
    final id = customTaskCompletionId(task, weekStart);
    if (_completions.remove(id) == null) {
      _completions[id] = TaskCompletion(at: now, by: currentUser!.id);
    }
    _persist();
    notifyListeners();
  }

  String? addCustomTask({
    required String title,
    String notes = '',
    required List<String> assigneeIds,
    required DateTime weekStart,
    bool repeatWeekly = false,
    String iconKey = 'checklist',
    String colorHex = '#0A84FF',
  }) {
    if (!isAdmin) return 'Solo el administrador puede crear tareas.';
    final cleanTitle = title.trim();
    if (cleanTitle.isEmpty) return 'Escribe un nombre para la tarea.';
    final validIds = _tenants.map((user) => user.id).toSet();
    final cleanAssignees = <String>[];
    for (final id in assigneeIds) {
      if (validIds.contains(id) && !cleanAssignees.contains(id)) {
        cleanAssignees.add(id);
      }
    }
    if (cleanAssignees.isEmpty) return 'Elige al menos una persona.';

    _customTasks.add(
      CustomTask(
        id: _newCustomId('task'),
        title: cleanTitle,
        notes: notes.trim(),
        iconKey: iconKey,
        colorHex: colorHex,
        assigneeIds: cleanAssignees,
        weekStart: mondayOf(weekStart),
        repeatWeekly: repeatWeekly,
        createdBy: currentUser!.id,
        createdAt: now,
      ),
    );
    _persist();
    notifyListeners();
    return null;
  }

  String? updateCustomTask({
    required String id,
    required String title,
    String notes = '',
    required List<String> assigneeIds,
    required DateTime weekStart,
    bool repeatWeekly = false,
    String iconKey = 'checklist',
    String colorHex = '#0A84FF',
  }) {
    if (!isAdmin) return 'Solo el administrador puede editar tareas.';
    final task = customTaskById(id);
    if (task == null) return 'No encontramos esa tarea.';
    final cleanTitle = title.trim();
    if (cleanTitle.isEmpty) return 'Escribe un nombre para la tarea.';
    final validIds = _tenants.map((user) => user.id).toSet();
    final cleanAssignees = <String>[];
    for (final assignee in assigneeIds) {
      if (validIds.contains(assignee) && !cleanAssignees.contains(assignee)) {
        cleanAssignees.add(assignee);
      }
    }
    if (cleanAssignees.isEmpty) return 'Elige al menos una persona.';

    final oldWeek = dateKey(mondayOf(task.weekStart));
    final newWeek = dateKey(mondayOf(weekStart));
    if (oldWeek != newWeek) {
      _completions.remove('custom:${task.id}:$oldWeek');
    }
    task
      ..title = cleanTitle
      ..notes = notes.trim()
      ..iconKey = iconKey
      ..colorHex = colorHex
      ..assigneeIds = cleanAssignees
      ..weekStart = mondayOf(weekStart)
      ..repeatWeekly = repeatWeekly;
    _persist();
    notifyListeners();
    return null;
  }

  void deleteCustomTask(String id) {
    if (!isAdmin) return;
    _customTasks.removeWhere((task) => task.id == id);
    _completions.removeWhere((key, _) => key.startsWith('custom:$id:'));
    _persist();
    notifyListeners();
  }

  String? addCustomTurn({
    required String title,
    String notes = '',
    required List<String> order,
    String iconKey = 'cart',
    String colorHex = '#30D158',
  }) {
    if (!isAdmin) return 'Solo el administrador puede crear turnos.';
    final cleanTitle = title.trim();
    if (cleanTitle.isEmpty) return 'Escribe un nombre para el turno.';
    final cleanOrder = _cleanTurnOrder(order);
    if (cleanOrder.isEmpty) return 'Elige al menos una persona.';

    _customTurns.add(
      CustomTurn(
        id: _newCustomId('turn'),
        title: cleanTitle,
        notes: notes.trim(),
        iconKey: iconKey,
        colorHex: colorHex,
        order: cleanOrder,
        createdBy: currentUser!.id,
        createdAt: now,
      ),
    );
    _persist();
    notifyListeners();
    return null;
  }

  List<String> _cleanTurnOrder(List<String> order) {
    final validIds = _tenants.map((user) => user.id).toSet();
    final clean = <String>[];
    for (final id in order) {
      if (validIds.contains(id) && !clean.contains(id)) clean.add(id);
    }
    return clean;
  }

  String? updateCustomTurn({
    required String id,
    required String title,
    String notes = '',
    required List<String> order,
    String iconKey = 'cart',
    String colorHex = '#30D158',
  }) {
    if (!isAdmin) return 'Solo el administrador puede editar turnos.';
    final turn = customTurnById(id);
    if (turn == null) return 'No encontramos ese turno.';
    final cleanTitle = title.trim();
    if (cleanTitle.isEmpty) return 'Escribe un nombre para el turno.';
    final cleanOrder = _cleanTurnOrder(order);
    if (cleanOrder.isEmpty) return 'Elige al menos una persona.';

    final previousCurrent = turn.currentUserId;
    turn
      ..title = cleanTitle
      ..notes = notes.trim()
      ..iconKey = iconKey
      ..colorHex = colorHex
      ..order = cleanOrder;
    if (previousCurrent != null && cleanOrder.contains(previousCurrent)) {
      turn.currentIndex = cleanOrder.indexOf(previousCurrent);
    }
    turn.normalize();
    _persist();
    notifyListeners();
    return null;
  }

  void deleteCustomTurn(String id) {
    if (!isAdmin) return;
    _customTurns.removeWhere((turn) => turn.id == id);
    _customTurnUndo.remove(id);
    _persist();
    notifyListeners();
  }

  bool canCompleteCustomTurn(CustomTurn turn) {
    final user = currentUser;
    if (user == null) return false;
    return user.isAdmin || turn.currentUserId == user.id;
  }

  void completeCustomTurn(CustomTurn turn) {
    if (!canCompleteCustomTurn(turn)) return;
    _customTurnUndo[turn.id] = turn.toJson();
    turn.advance(by: currentUser!.id, at: now);
    _persist();
    notifyListeners();
  }

  void skipCustomTurn(CustomTurn turn) {
    if (!isAdmin) return;
    _customTurnUndo[turn.id] = turn.toJson();
    turn.skip();
    _persist();
    notifyListeners();
  }

  void resetCustomTurn(CustomTurn turn) {
    if (!isAdmin) return;
    _customTurnUndo[turn.id] = turn.toJson();
    turn.reset();
    _persist();
    notifyListeners();
  }

  bool canUndoCustomTurn(String id) => _customTurnUndo.containsKey(id);

  void undoCustomTurn(String id) {
    final snapshot = _customTurnUndo.remove(id);
    if (snapshot == null) return;
    final index = _customTurns.indexWhere((turn) => turn.id == id);
    if (index >= 0) {
      _customTurns[index] = CustomTurn.fromJson(snapshot);
    }
    _persist();
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Pagos
  // ---------------------------------------------------------------------------

  PaymentRecord paymentFor(String month, String userId) =>
      _payments[month]?[userId] ?? PaymentRecord();

  void _ensureMonth(String month) {
    final records = _payments.putIfAbsent(month, () => {});
    for (final user in _tenants) {
      records.putIfAbsent(user.id, () => PaymentRecord());
    }
  }

  bool canTogglePayment(String month, String userId) {
    final user = currentUser;
    if (user == null || userById(userId)?.role != UserRole.tenant) return false;
    if (user.isAdmin) return true;
    return user.id == userId && month == monthKey(now);
  }

  void setPaymentPaid(String month, String userId, bool paid) {
    if (!canTogglePayment(month, userId)) return;
    _ensureMonth(month);
    final record = _payments[month]![userId]!;
    if (paid) {
      record
        ..paid = true
        ..paidAt = now
        ..markedBy = currentUser!.id;
    } else {
      record
        ..paid = false
        ..paidAt = null
        ..markedBy = null;
    }
    _persist();
    notifyListeners();
  }

  int paidCount(String month) {
    return _tenants.where((user) => paymentFor(month, user.id).paid).length;
  }

  int collectedAmount(String month) => paidCount(month) * _monthlyAmount;

  int expectedAmount(String month) => _tenants.length * _monthlyAmount;

  double monthProgress(String month) =>
      _tenants.isEmpty ? 0 : paidCount(month) / _tenants.length;

  List<HouseUser> pendingUsers(String month) =>
      _tenants.where((user) => !paymentFor(month, user.id).paid).toList();

  DateTime dueDateFor(String month) {
    final date = monthDate(month);
    final lastDay = DateTime(date.year, date.month + 1, 0).day;
    return DateTime(date.year, date.month, _dueDay.clamp(1, lastDay));
  }

  bool isOverdue(String month) {
    final due = dueDateFor(month);
    return now.isAfter(
      DateTime(
        due.year,
        due.month,
        due.day + 1,
      ).subtract(const Duration(microseconds: 1)),
    );
  }

  bool isDueToday(String month) => dateKey(now) == dateKey(dueDateFor(month));

  // ---------------------------------------------------------------------------
  // Alertas
  // ---------------------------------------------------------------------------

  List<HouseAlert> get alerts {
    final user = currentUser;
    if (user == null) return const [];
    final moment = now;
    final month = monthKey(moment);
    final list = <HouseAlert>[];

    final paid = user.isAdmin || paymentFor(month, user.id).paid;
    final dueDate = dueDateFor(month);
    final reminderStart = _reminderDays.fold(
      dueDate.day,
      (first, day) => day < first ? day : first,
    );

    if (!paid && moment.day >= reminderStart && moment.day <= dueDate.day) {
      final left = dueDate.day - moment.day;
      list.add(
        HouseAlert(
          id: 'pay-${dateKey(moment)}-${user.id}',
          kind: AlertKind.payment,
          title: left <= 0 ? 'Hoy vence el pago' : 'Pago de servicios',
          message: left <= 0
              ? 'Hoy es ${dueDate.day}. Te toca aportar ${formatMoney(_monthlyAmount)} para los servicios de la casa.'
              : 'Faltan ${left == 1 ? '1 día' : '$left días'} para el ${dueDate.day}. Tu aporte es de ${formatMoney(_monthlyAmount)}.',
          date: DateTime(moment.year, moment.month, moment.day, 9),
          urgent: left <= 1,
          actionTab: 2,
        ),
      );
    } else if (!paid && moment.day > dueDate.day) {
      list.add(
        HouseAlert(
          id: 'pay-overdue-$month-${user.id}',
          kind: AlertKind.payment,
          title: 'Pago vencido',
          message:
              'No registramos tu aporte de ${formatMoney(_monthlyAmount)} de ${monthName(moment.month)}. El administrador puede ayudarte a regularizarlo.',
          date: dueDate,
          urgent: true,
          actionTab: 2,
        ),
      );
    }

    final plan = currentPlan;
    final myZones = plan.zoneOwners.entries
        .where((entry) => entry.value == user.id)
        .map((entry) => entry.key)
        .toList();
    final pendingZones = myZones
        .where((zone) => !isZoneDone(plan, zone))
        .toList();
    if (pendingZones.isNotEmpty) {
      list.add(
        HouseAlert(
          id: 'clean-${dateKey(plan.weekStart)}-${user.id}',
          kind: AlertKind.cleaning,
          title: 'Tu turno de aseo',
          message:
              'Esta semana te toca ${formatZoneList(pendingZones)}. Llevas ${myZones.length - pendingZones.length} de ${myZones.length} zonas.',
          date: plan.weekStart.add(const Duration(hours: 8)),
          actionTab: 1,
        ),
      );
    }

    if (plan.bagBuyer == user.id && !isBagsDone(plan)) {
      list.add(
        HouseAlert(
          id: 'bags-${dateKey(plan.weekStart)}-${user.id}',
          kind: AlertKind.bags,
          title: 'Comprar bolsas de basura',
          message:
              'Esta semana te toca reponer las bolsas de basura de la casa.',
          date: plan.weekStart.add(const Duration(hours: 9)),
          actionTab: 1,
        ),
      );
    }

    if (_trash.currentUserId == user.id) {
      final next = userById(_trash.nextUserId);
      final reference = _trash.lastEmptiedAt ?? plan.weekStart;
      list.add(
        HouseAlert(
          id: 'trash-${reference.toIso8601String()}-${user.id}',
          kind: AlertKind.trash,
          title: 'Te toca botar la basura',
          message:
              'Cuando la saques, el turno pasa automáticamente a ${next?.firstName ?? 'la siguiente persona'}.',
          date: reference,
          actionTab: 1,
        ),
      );
    }

    final week = mondayOf(now);
    final currentTasks = customTasksForWeek(week);
    final myCustomTasks = currentTasks
        .where(
          (task) =>
              task.assigneeIds.contains(user.id) &&
              !isCustomTaskDone(task, week),
        )
        .toList();
    if (myCustomTasks.isNotEmpty) {
      final task = myCustomTasks.first;
      list.add(
        HouseAlert(
          id: 'custom-task-${task.id}-${dateKey(week)}-${user.id}',
          kind: AlertKind.customTask,
          title: task.title,
          message: task.notes.isEmpty
              ? 'Tienes esta tarea esta semana.'
              : task.notes,
          date: week.add(const Duration(hours: 8)),
          actionTab: 1,
        ),
      );
    }

    for (final turn in _customTurns) {
      if (turn.currentUserId != user.id) continue;
      final next = userById(turn.nextUserId);
      final reference = turn.lastDoneAt ?? week;
      list.add(
        HouseAlert(
          id: 'custom-turn-${turn.id}-${turn.currentIndex}-${user.id}',
          kind: AlertKind.customTurn,
          title: 'Te toca: ${turn.title}',
          message:
              'Cuando lo hagas, el turno pasa a ${next?.firstName ?? 'la siguiente persona'}.',
          date: reference,
          actionTab: 1,
        ),
      );
    }

    if (user.isAdmin) {
      final pending = pendingUsers(month);
      if (moment.day >= reminderStart && pending.isNotEmpty) {
        list.add(
          HouseAlert(
            id: 'admin-pay-$month-${user.id}',
            kind: AlertKind.admin,
            title: 'Pagos pendientes',
            message:
                '${pending.length} de ${_tenants.length} personas no han pagado ${formatMoney(_monthlyAmount)}. Pendientes: ${pending.map((u) => u.firstName).join(', ')}.',
            date: DateTime(moment.year, moment.month, moment.day, 10),
            urgent: moment.day > dueDate.day,
            actionTab: 2,
          ),
        );
      }

      final done = cleaningDoneCount(plan);
      if (done < CleaningZone.values.length) {
        list.add(
          HouseAlert(
            id: 'admin-clean-${dateKey(plan.weekStart)}-${user.id}',
            kind: AlertKind.admin,
            title: 'Aseo de la semana',
            message:
                '$done de ${CleaningZone.values.length} zonas completadas. Equipo: ${plan.team.map((id) => userById(id)?.firstName ?? '—').join(' y ')}.',
            date: plan.weekStart.add(const Duration(hours: 11)),
            actionTab: 1,
          ),
        );
      }
    }

    list.sort((a, b) {
      if (a.urgent != b.urgent) return a.urgent ? -1 : 1;
      return b.date.compareTo(a.date);
    });

    return [
      for (final alert in list)
        alert.copyWith(isRead: _readAlerts.contains(alert.id)),
    ];
  }

  int get unreadAlertCount => alerts.where((alert) => !alert.isRead).length;

  void markAlertRead(String id) {
    if (_readAlerts.add(id)) {
      _persist();
      notifyListeners();
    }
  }

  void markAllAlertsRead() {
    var changed = false;
    for (final alert in alerts) {
      changed = _readAlerts.add(alert.id) || changed;
    }
    if (changed) {
      _persist();
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // Administración
  // ---------------------------------------------------------------------------

  String? addUser({
    required String name,
    required String username,
    required String password,
    required UserRole role,
  }) {
    if (!isAdmin) {
      return 'Solo el administrador puede crear usuarios.';
    }
    final cleanName = name.trim();
    final cleanUsername = username.trim().toLowerCase().replaceAll(' ', '');
    if (cleanName.isEmpty) return 'Escribe un nombre.';
    if (cleanUsername.isEmpty) return 'Escribe un usuario.';
    if (password.trim().length < 4) {
      return 'La contraseña debe tener al menos 4 caracteres.';
    }
    if (_users.any((user) => user.username.toLowerCase() == cleanUsername)) {
      return 'Ese usuario ya existe.';
    }

    final oldPlan = currentPlan;
    var baseId = cleanUsername.replaceAll(RegExp(r'[^a-z0-9]'), '');
    if (baseId.isEmpty) baseId = 'persona';
    var id = baseId;
    var suffix = 2;
    while (_users.any((user) => user.id == id)) {
      id = '$baseId$suffix';
      suffix++;
    }

    const colors = [
      '#FF6B6B',
      '#4D96FF',
      '#B983FF',
      '#FFB443',
      '#34C759',
      '#64D2FF',
      '#FF9F0A',
      '#FF375F',
    ];

    _users.add(
      HouseUser(
        id: id,
        name: cleanName,
        username: cleanUsername,
        password: password.trim(),
        role: role,
        colorHex: colors[_users.length % colors.length],
        joinedAt: now.toIso8601String(),
      ),
    );
    if (role == UserRole.tenant) {
      _bagOrder.add(id);
      _trash.order.add(id);
      for (final existing in _tenants.where((user) => user.id != id)) {
        final alreadyThere = _rotationPairs.any(
          (pair) =>
              pair.length == 2 &&
              ((pair[0] == id && pair[1] == existing.id) ||
                  (pair[0] == existing.id && pair[1] == id)),
        );
        if (!alreadyThere) _rotationPairs.add([id, existing.id]);
      }
      _ensureMonth(monthKeyNow());

      final newPlan = currentPlan;
      if (oldPlan.team.toSet().length == 2 &&
          !_sameTeam(newPlan.team, oldPlan.team)) {
        _weekOverrides[dateKey(oldPlan.weekStart)] = WeekOverride(
          team: oldPlan.team,
          bagBuyer: oldPlan.bagBuyer,
        );
      }
    }

    _persist();
    notifyListeners();
    return null;
  }

  String? updateUser({
    required String id,
    required String name,
    String? password,
  }) {
    if (!isAdmin) return 'Solo el administrador puede editar usuarios.';
    final user = userById(id);
    if (user == null) return 'No encontramos a esa persona.';
    final cleanName = name.trim();
    if (cleanName.isEmpty) return 'Escribe un nombre.';
    if (password != null &&
        password.trim().isNotEmpty &&
        password.trim().length < 4) {
      return 'La contraseña debe tener al menos 4 caracteres.';
    }
    user.name = cleanName;
    if (password != null && password.trim().isNotEmpty) {
      user.password = password.trim();
    }
    _persist();
    notifyListeners();
    return null;
  }

  String? deleteUser(String id) {
    if (!isAdmin) return 'Solo el administrador puede eliminar usuarios.';
    final user = userById(id);
    if (user == null) return 'No encontramos a esa persona.';
    if (id == _sessionUserId) return 'No puedes eliminar tu propia cuenta.';
    if (user.isAdmin && _users.where((item) => item.isAdmin).length <= 1) {
      return 'Debe quedar al menos un administrador.';
    }

    final oldPlan = currentPlan;
    _users.removeWhere((item) => item.id == id);
    _rotationPairs.removeWhere((pair) => pair.contains(id));
    _bagOrder.remove(id);
    _normalizeTrashOrder();
    _trashUndo = null;
    _normalizeCustomData();
    _customTurnUndo.clear();
    for (final records in _payments.values) {
      records.remove(id);
    }

    if (oldPlan.team.contains(id) && _tenants.length >= 2) {
      final remaining = oldPlan.team.where((member) => member != id).toList();
      HouseUser? replacement;
      for (final candidate in _tenants) {
        if (!remaining.contains(candidate.id)) {
          replacement = candidate;
          break;
        }
      }
      replacement ??= _tenants.first;
      final team = [...remaining, replacement.id].take(2).toList();
      final buyer = oldPlan.bagBuyer == id
          ? _tenants.first.id
          : oldPlan.bagBuyer;
      _weekOverrides[dateKey(oldPlan.weekStart)] = WeekOverride(
        team: team,
        bagBuyer: buyer,
      );
    }

    _persist();
    notifyListeners();
    return null;
  }

  bool _sameTeam(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    final sortedA = [...a]..sort();
    final sortedB = [...b]..sort();
    for (var i = 0; i < sortedA.length; i++) {
      if (sortedA[i] != sortedB[i]) return false;
    }
    return true;
  }

  Future<void> resetDemoData() async {
    if (!isAdmin) return;
    final session = _sessionUserId;
    final data = SeedData.build(DateTime.now());
    final seedUsers = data['users'] as List;
    if (session != null &&
        seedUsers.any((entry) => (entry as Map)['id'] == session)) {
      data['sessionUserId'] = session;
    }
    _hydrate(data);
    _clearUndo();
    _persist();
    await _saveChain;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Estadísticas
  // ---------------------------------------------------------------------------

  int tasksCompletedBy(String userId) {
    var count = _completions.values.where((entry) => entry.by == userId).length;
    count += _trash.history.where((entry) => entry.userId == userId).length;
    for (final turn in _customTurns) {
      count += turn.history.where((entry) => entry.userId == userId).length;
    }
    return count;
  }

  int paymentsOnTimeBy(String userId) {
    var count = 0;
    for (final entry in _payments.entries) {
      final record = entry.value[userId];
      if (record == null || !record.paid || record.paidAt == null) continue;
      final due = dueDateFor(entry.key);
      final nextDay = DateTime(due.year, due.month, due.day + 1);
      if (record.paidAt!.isBefore(nextDay)) count++;
    }
    return count;
  }

  String monthKeyNow() => monthKey(now);
}
