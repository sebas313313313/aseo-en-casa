import 'package:flutter/material.dart';

import '../screens/profile_screen.dart';

Future<void> openProfileScreen(BuildContext context) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => const ProfileScreen(),
    ),
  );
}
