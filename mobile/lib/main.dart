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
  // Initialise Firebase before any provider can read FirebaseAuth.
  // Failures are surfaced through `firebaseStatusProvider` so the login
  // screen can show setup instructions instead of crashing the app.
  final firebase = await bootstrapFirebase();
  runApp(ReSpaceBootstrap(firebase: firebase));
}

class ReSpaceBootstrap extends StatelessWidget {
  const ReSpaceBootstrap({super.key, required this.firebase});

  final FirebaseBootstrapResult firebase;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [
        firebaseStatusProvider.overrideWith((ref) => firebase),
      ],
      child: const ReSpaceApp(),
    );
  }
}
