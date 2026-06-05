import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/colors.dart';
import 'router.dart';

class ReSpaceApp extends ConsumerWidget {
  const ReSpaceApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final base = ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.teal,
        primary: AppColors.teal,
        surface: AppColors.surface,
        brightness: Brightness.light,
      ),
      useMaterial3: true,
      // One consistent page transition across the whole app and every platform.
      // Without this each platform picks its own default (Android's zoom/fade vs
      // iOS's slide), which made flow navigation feel inconsistent. Pinning a
      // single builder keeps every animated route identical. Bottom-tab pages
      // opt out entirely via NoTransitionPage in the router.
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
          TargetPlatform.fuchsia: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
    final textTheme = GoogleFonts.interTextTheme(
      base.textTheme,
    ).apply(bodyColor: AppColors.ink, displayColor: AppColors.ink);
    return MaterialApp.router(
      title: 'ReSpace AI',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: base.copyWith(
        textTheme: textTheme,
        scaffoldBackgroundColor: AppColors.bg,
      ),
    );
  }
}
