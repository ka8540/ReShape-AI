import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'services/firebase_bootstrap.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  // Best-effort: failures are logged and the app keeps booting so the
  // design-pass build still runs without Firebase config files.
  await bootstrapFirebase();
  runApp(const ReSpaceBootstrap());
}

class ReSpaceBootstrap extends StatelessWidget {
  const ReSpaceBootstrap({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProviderScope(child: ReSpaceApp());
  }
}
