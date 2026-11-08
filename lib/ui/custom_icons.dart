import 'package:flutter/cupertino.dart';

import '../models/models.dart';
import 'theme.dart';

class CustomIconOption {
  const CustomIconOption({
    required this.key,
    required this.icon,
    required this.label,
  });

  final String key;
  final IconData icon;
  final String label;
}

const List<CustomIconOption> customIconOptions = [
  CustomIconOption(
      key: 'checklist', icon: CupertinoIcons.check_mark_circled_solid, label: 'Tarea'),
  CustomIconOption(key: 'cart', icon: CupertinoIcons.cart_fill, label: 'Compra'),
  CustomIconOption(key: 'doc', icon: CupertinoIcons.doc_text_fill, label: 'Papel'),
  CustomIconOption(key: 'bag', icon: CupertinoIcons.bag_fill, label: 'Bolsas'),
  CustomIconOption(key: 'clean', icon: CupertinoIcons.paintbrush_fill, label: 'Aseo'),
];

IconData customIconFor(String key) {
  for (final option in customIconOptions) {
    if (option.key == key) return option.icon;
  }
  return customIconOptions.first.icon;
}

const List<Color> customColorOptions = [
  AppColors.blue,
  AppColors.green,
  AppColors.orange,
  AppColors.purple,
  AppColors.pink,
  AppColors.teal,
  AppColors.indigo,
  AppColors.red,
];

class CustomTaskPreview {
  const CustomTaskPreview({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
}

class CustomTurnPreview {
  const CustomTurnPreview({
    required this.icon,
    required this.color,
    required this.title,
  });

  final IconData icon;
  final Color color;
  final String title;
}

CustomTaskPreview taskPreview(CustomTask task) => CustomTaskPreview(
      icon: customIconFor(task.iconKey),
      color: task.color,
      title: task.title,
      subtitle: task.notes.isEmpty ? 'Tarea' : task.notes,
    );

CustomTurnPreview turnPreview(CustomTurn turn) => CustomTurnPreview(
      icon: customIconFor(turn.iconKey),
      color: turn.color,
      title: turn.title,
    );
