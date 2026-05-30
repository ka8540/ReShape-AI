import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../state/project_state.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';

class LogoMark extends StatelessWidget {
  const LogoMark({super.key, this.size = 36});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.teal,
        borderRadius: BorderRadius.circular(size * .3),
        boxShadow: AppShadows.teal,
      ),
      child: Icon(
        Icons.home_work_rounded,
        color: Colors.white,
        size: size * .58,
      ),
    );
  }
}

class RsCard extends StatelessWidget {
  const RsCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.color,
    this.borderColor,
    this.borderStyle = BorderStyle.solid,
    this.radius = AppRadii.lg,
    this.shadow = true,
    this.onTap,
    this.clip = Clip.none,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final Color? borderColor;
  final BorderStyle borderStyle;
  final double radius;
  final bool shadow;
  final VoidCallback? onTap;
  final Clip clip;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      margin: margin,
      clipBehavior: clip,
      decoration: BoxDecoration(
        color: color ?? AppColors.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: borderColor ?? AppColors.border,
          style: borderStyle,
        ),
        boxShadow: shadow ? AppShadows.sm : null,
      ),
      child: Padding(padding: padding ?? EdgeInsets.zero, child: child),
    );
    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(radius),
        onTap: onTap,
        child: card,
      ),
    );
  }
}

enum RsButtonVariant { primary, ghost, soft, quiet, danger, warm }

class RsButton extends StatelessWidget {
  const RsButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.variant = RsButtonVariant.primary,
    this.compact = false,
    this.expand = true,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final RsButtonVariant variant;
  final bool compact;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, border, shadow) = switch (variant) {
      RsButtonVariant.primary => (
        AppColors.teal,
        Colors.white,
        AppColors.teal,
        AppShadows.teal,
      ),
      RsButtonVariant.ghost => (
        AppColors.surface,
        AppColors.ink,
        AppColors.border2,
        AppShadows.sm,
      ),
      RsButtonVariant.soft => (
        AppColors.tealTint,
        AppColors.tealInk,
        AppColors.tealTint,
        null,
      ),
      RsButtonVariant.quiet => (
        Colors.transparent,
        AppColors.ink2,
        Colors.transparent,
        null,
      ),
      RsButtonVariant.danger => (
        AppColors.dangerTint,
        AppColors.danger,
        AppColors.dangerTint,
        null,
      ),
      RsButtonVariant.warm => (
        AppColors.warm,
        Colors.white,
        AppColors.warm,
        null,
      ),
    };
    final child = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: compact ? 17 : 20),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.btn(color: fg).copyWith(fontSize: compact ? 14 : 16),
          ),
        ),
      ],
    );
    return SizedBox(
      width: expand ? double.infinity : null,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(
            compact ? AppRadii.sm : AppRadii.r,
          ),
          border: Border.all(color: border),
          boxShadow: shadow,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(
              compact ? AppRadii.sm : AppRadii.r,
            ),
            onTap: onPressed,
            child: Opacity(
              opacity: onPressed == null ? .5 : 1,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 14 : 20,
                  vertical: compact ? 11 : 15,
                ),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class RoundIconButton extends StatelessWidget {
  const RoundIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.color,
    this.iconColor,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final Color? color;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color ?? AppColors.surface,
      shape: const CircleBorder(side: BorderSide(color: AppColors.border)),
      elevation: 1,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, color: iconColor ?? AppColors.ink, size: 20),
        ),
      ),
    );
  }
}

class RsChip extends StatelessWidget {
  const RsChip({
    super.key,
    required this.label,
    this.icon,
    this.selected = false,
    this.onTap,
    this.small = false,
    this.warm = false,
  });

  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback? onTap;
  final bool small;
  final bool warm;

  @override
  Widget build(BuildContext context) {
    final active = warm ? AppColors.warm : AppColors.teal;
    final activeInk = warm ? AppColors.warmInk : AppColors.tealInk;
    return Material(
      color: selected ? active : AppColors.surface,
      shape: StadiumBorder(
        side: BorderSide(color: selected ? active : AppColors.border2),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: small ? 11 : 15,
            vertical: small ? 7 : 10,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: small ? 14 : 16,
                  color: selected ? Colors.white : activeInk,
                ),
                const SizedBox(width: 7),
              ],
              Text(
                label,
                style: AppText.sm(
                  color: selected ? Colors.white : AppColors.ink,
                  weight: FontWeight.w600,
                ).copyWith(fontSize: small ? 12.5 : 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RsBadge extends StatelessWidget {
  const RsBadge({
    super.key,
    required this.label,
    this.icon,
    this.color = AppColors.teal,
    this.background = AppColors.tealTint,
  });

  final String label;
  final IconData? icon;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: AppText.xs(color: color, weight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 24, 2, 10),
      child: Text(text.toUpperCase(), style: AppText.eyebrow(color: color)),
    );
  }
}

class RsNotice extends StatelessWidget {
  const RsNotice({
    super.key,
    required this.text,
    this.icon = Icons.info_outline_rounded,
    this.warn = false,
  });

  final String text;
  final IconData icon;
  final bool warn;

  @override
  Widget build(BuildContext context) {
    final color = warn ? AppColors.warmInk : AppColors.tealInk;
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: warn ? AppColors.warnTint : AppColors.tealTint,
        borderRadius: BorderRadius.circular(AppRadii.r),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: AppText.sm(color: color)),
          ),
        ],
      ),
    );
  }
}

class RsStepper extends StatelessWidget {
  const RsStepper({
    super.key,
    required this.steps,
    required this.current,
    this.warm = false,
  });

  final List<String> steps;
  final int current;
  final bool warm;

  @override
  Widget build(BuildContext context) {
    final color = warm ? AppColors.warm : AppColors.teal;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: Row(
        children: [
          for (var i = 0; i < steps.length; i++) ...[
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadii.pill),
                child: Container(
                  height: 4,
                  color: i < current ? color : AppColors.border2,
                  alignment: Alignment.centerLeft,
                  child: i == current
                      ? FractionallySizedBox(
                          widthFactor: .55,
                          child: Container(color: color),
                        )
                      : null,
                ),
              ),
            ),
            if (i != steps.length - 1) const SizedBox(width: 6),
          ],
        ],
      ),
    );
  }
}

class FlowHeader extends StatelessWidget {
  const FlowHeader({
    super.key,
    required this.title,
    required this.step,
    required this.steps,
    this.warm = false,
  });

  final String title;
  final int step;
  final List<String> steps;
  final bool warm;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            children: [
              RoundIconButton(
                icon: Icons.arrow_back_ios_new_rounded,
                onTap: () {
                  final router = GoRouter.of(context);
                  if (router.canPop()) {
                    context.pop();
                  } else {
                    context.go('/home');
                  }
                },
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '$title - Step ${step + 1} of ${steps.length}',
                  style: AppText.xs(weight: FontWeight.w700),
                ),
              ),
              RoundIconButton(
                icon: Icons.close_rounded,
                onTap: () => context.go('/home'),
              ),
            ],
          ),
        ),
        RsStepper(steps: steps, current: step, warm: warm),
      ],
    );
  }
}

class BottomBar extends StatelessWidget {
  const BottomBar({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        13,
        16,
        13 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: child,
    );
  }
}

class AppBottomTabs extends ConsumerWidget {
  const AppBottomTabs({super.key, required this.current});

  final String current;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = [
      ('home', 'Home', Icons.home_rounded, '/home'),
      ('saved', 'Saved', Icons.folder_rounded, '/saved'),
      ('explore', 'Explore', Icons.auto_awesome_rounded, '/home'),
      ('profile', 'Profile', Icons.person_rounded, '/profile'),
    ];
    return Container(
      padding: EdgeInsets.fromLTRB(
        8,
        8,
        8,
        6 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _TabButton(item: items[0], current: current),
          ),
          Expanded(
            child: _TabButton(item: items[1], current: current),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                ref
                    .read(projectControllerProvider.notifier)
                    .resetForNewProject();
                context.go('/mode');
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Transform.translate(
                    offset: const Offset(0, -18),
                    child: Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: AppColors.teal,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: AppShadows.teal,
                      ),
                      child: const Icon(
                        Icons.add_rounded,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                ],
              ),
            ),
          ),
          Expanded(
            child: _TabButton(item: items[2], current: current),
          ),
          Expanded(
            child: _TabButton(item: items[3], current: current),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({required this.item, required this.current});

  final (String, String, IconData, String) item;
  final String current;

  @override
  Widget build(BuildContext context) {
    final (id, label, icon, route) = item;
    final on = id == current;
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadii.r),
      onTap: () => context.go(route),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 23, color: on ? AppColors.teal : AppColors.ink3),
            const SizedBox(height: 3),
            Text(
              label,
              style: AppText.xs(
                color: on ? AppColors.teal : AppColors.ink3,
                weight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PageShell extends StatelessWidget {
  const PageShell({
    super.key,
    required this.child,
    this.bottom,
    this.safeTop = true,
  });

  final Widget child;
  final Widget? bottom;
  final bool safeTop;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(top: safeTop, bottom: false, child: child),
      bottomNavigationBar: bottom,
    );
  }
}
