import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const ReSpaceBootstrap());
}

class ReSpaceBootstrap extends StatelessWidget {
  const ReSpaceBootstrap({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProviderScope(child: ReSpaceApp());
  }
}
