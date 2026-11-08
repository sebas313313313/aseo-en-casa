const List<String> _months = [
  'enero',
  'febrero',
  'marzo',
  'abril',
  'mayo',
  'junio',
  'julio',
  'agosto',
  'septiembre',
  'octubre',
  'noviembre',
  'diciembre',
];

const List<String> _weekdays = [
  'lunes',
  'martes',
  'miércoles',
  'jueves',
  'viernes',
  'sábado',
  'domingo',
];

String twoDigits(int value) => value.toString().padLeft(2, '0');

String dateKey(DateTime date) =>
    '${date.year}-${twoDigits(date.month)}-${twoDigits(date.day)}';

String monthKey(DateTime date) => '${date.year}-${twoDigits(date.month)}';

DateTime dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

DateTime mondayOf(DateTime date) {
  final day = dateOnly(date);
  return day.subtract(Duration(days: day.weekday - 1));
}

DateTime parseDateKey(String key) {
  final parts = key.split('-').map(int.parse).toList();
  return DateTime(parts[0], parts[1], parts[2]);
}

DateTime monthDate(String key) {
  final parts = key.split('-').map(int.parse).toList();
  return DateTime(parts[0], parts[1]);
}

int floorDiv(int a, int b) => (a - (a % b)) ~/ b;

String monthName(int month) => _months[month - 1];

String weekdayName(int weekday) => _weekdays[weekday - 1];

String capitalize(String value) =>
    value.isEmpty ? value : value[0].toUpperCase() + value.substring(1);

String formatDayMonth(DateTime date) {
  final month = _months[date.month - 1];
  return '${date.day} ${month.substring(0, 3)}';
}

String formatWeekRange(DateTime start) {
  final end = start.add(const Duration(days: 6));
  final startMonth = _months[start.month - 1].substring(0, 3);
  final endMonth = _months[end.month - 1].substring(0, 3);
  if (start.month == end.month) {
    return '${start.day}–${end.day} $startMonth';
  }
  return '${start.day} $startMonth – ${end.day} $endMonth';
}

String formatLongDate(DateTime date) =>
    '${weekdayName(date.weekday)}, ${date.day} de ${monthName(date.month)}';

String formatMonthYear(DateTime date) =>
    '${capitalize(monthName(date.month))} ${date.year}';

String formatMoney(num value) {
  final digits = value.round().abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
    buffer.write(digits[i]);
  }
  return '${value < 0 ? '-' : ''}\$${buffer.toString()}';
}

String joinSpanish(List<String> items) {
  if (items.isEmpty) return '';
  if (items.length == 1) return items.first;
  if (items.length == 2) return '${items[0]} y ${items[1]}';
  return '${items.sublist(0, items.length - 1).join(', ')} y ${items.last}';
}

String relativeDate(DateTime date, DateTime now) {
  final diff = dateOnly(now).difference(dateOnly(date)).inDays;
  if (diff <= 0) return 'Hoy';
  if (diff == 1) return 'Ayer';
  if (diff < 7) return 'Hace $diff días';
  return formatDayMonth(date);
}

String greetingFor(DateTime now) {
  if (now.hour < 12) return 'Buenos días';
  if (now.hour < 19) return 'Buenas tardes';
  return 'Buenas noches';
}
