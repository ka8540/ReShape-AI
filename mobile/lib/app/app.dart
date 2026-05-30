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
