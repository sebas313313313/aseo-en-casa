import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'data/repository.dart';
import 'state/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final repository = LocalRepository();
  final state = AppState(repository);
  await state.bootstrap();

  runApp(
    ChangeNotifierProvider<AppState>.value(
      value: state,
      child: const CasaApp(),
    ),
  );
}
