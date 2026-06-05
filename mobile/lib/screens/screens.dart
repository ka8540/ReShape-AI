import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

import '../data/mock_data.dart';
import '../data/models.dart';
import '../services/api_config.dart';
import '../services/api_service.dart';
import '../services/media_picker.dart';
import '../state/auth_state.dart';
import '../state/project_state.dart';
import '../state/remote_projects.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../widgets/backend_status_banner.dart';
import '../widgets/design_system.dart';
import '../widgets/room_art.dart';

LayoutResult selectedResult(ProjectState project) {
  return results.firstWhere(
    (result) => result.id == project.selectedLayout,
    orElse: () => results.first,
  );
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PageShell(
      bottom: BottomBar(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RsButton(
              label: 'Get started',
              icon: Icons.arrow_forward_rounded,
              onPressed: () => context.go('/home'),
            ),
            const SizedBox(height: 4),
            RsButton(
              label: 'Continue as guest',
              variant: RsButtonVariant.quiet,
              onPressed: () => context.go('/home'),
            ),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 6, 22, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [LogoMark(size: 34), SizedBox(width: 10), _Wordmark()],
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 18),
                children: [
                  RsCard(
                    clip: Clip.antiAlias,
                    radius: AppRadii.xl,
                    shadow: true,
                    child: Column(
                      children: [
                        const RoomScene(
                          layoutKey: 'livingC',
                          paletteKey: 'warm',
                          height: 210,
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              const RsBadge(
                                label: 'AI layout preview',
                                icon: Icons.auto_awesome_rounded,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'From a quick room photo or video',
                                  style: AppText.xs(),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    'See your room rearranged before you move a thing.',
                    style: AppText.h1().copyWith(fontSize: 30),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Snap a photo or record a quick video. ReSpace finds your furniture and suggests practical layouts using what you already own.',
                    style: AppText.body(),
                  ),
                  const SizedBox(height: 22),
                  const Row(
                    children: [
                      _IntroPillar(
                        icon: Icons.document_scanner_rounded,
                        label: 'Scan',
                      ),
                      _IntroPillar(
                        icon: Icons.open_in_full_rounded,
                        label: 'Reshuffle',
                      ),
                      _IntroPillar(
                        icon: Icons.checklist_rounded,
                        label: 'Move plan',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Wordmark extends StatelessWidget {
  const _Wordmark();

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: AppText.h3(),
        children: const [
          TextSpan(text: 'ReSpace'),
          TextSpan(
            text: ' AI',
            style: TextStyle(color: AppColors.teal),
          ),
        ],
      ),
    );
  }
}

class _IntroPillar extends StatelessWidget {
  const _IntroPillar({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.tealTint,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.tealInk),
          ),
          const SizedBox(height: 7),
          Text(label, style: AppText.xs(weight: FontWeight.w700)),
        ],
      ),
    );
  }
}

/// Kicks off a new project. In mock mode this just resets the local
/// controller and routes into the flow. In real-backend mode it also
/// `POST /projects` so the rest of the flow has a real project_id to
/// hang media / items / generation off of.
Future<void> _startNewProject(
  BuildContext context,
  WidgetRef ref,
  ProjectController controller,
) async {
  controller.resetForNewProject();
  if (useMockData) {
    if (context.mounted) context.go('/mode');
    return;
  }
  try {
    final create = ref.read(createProjectProvider);
    final created = await create(
      name: 'Untitled project',
      mode: 'reshuffle',
    );
    final id = created['id']?.toString();
    if (id != null) controller.setRemoteProjectId(id);
    if (context.mounted) context.go('/mode');
  } on ApiException catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Could not start project: ${e.message}')),
    );
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Could not start project: $e')),
    );
  }
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final project = ref.watch(projectControllerProvider);
    final controller = ref.read(projectControllerProvider.notifier);
    final auth = ref.watch(appAuthControllerProvider);
    final displayName =
        auth.localUser?['display_name']?.toString() ??
        auth.firebaseUser?.displayName ??
        'Welcome';
    return PageShell(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
            child: Row(
              children: [
                const LogoMark(),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Signed in as', style: AppText.xs()),
                      Text(
                        displayName,
                        style: AppText.h3().copyWith(fontSize: 16),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                RoundIconButton(
                  icon: Icons.person_rounded,
                  onTap: () => context.go('/profile'),
                ),
              ],
            ),
          ),
          const BackendStatusBanner(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              children: [
                RsCard(
                  clip: Clip.antiAlias,
                  radius: AppRadii.xl,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          const RoomScene(
                            layoutKey: 'bedB',
                            paletteKey: 'cool',
                            height: 150,
                          ),
                          const Positioned(
                            top: 12,
                            left: 12,
                            child: RsBadge(
                              label: 'Start here',
                              icon: Icons.auto_awesome_rounded,
                              background: Colors.white,
                              color: AppColors.tealInk,
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Reshuffle a room',
                              style: AppText.h2().copyWith(fontSize: 19),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Scan it, review what we find, and get practical new layouts using your current furniture.',
                              style: AppText.sm(),
                            ),
                            const SizedBox(height: 14),
                            RsButton(
                              label: 'New project',
                              icon: Icons.add_rounded,
                              onPressed: () => _startNewProject(
                                context,
                                ref,
                                controller,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _ModeMiniCard(
                        icon: Icons.open_in_full_rounded,
                        title: 'Reshuffle',
                        caption: 'Use what you own',
                        onTap: () {
                          controller.setMode(AppMode.reshuffle);
                          context.go('/capture');
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ModeMiniCard(
                        icon: Icons.palette_rounded,
                        title: 'Redesign',
                        caption: 'Coming soon',
                        warm: true,
                        onTap: () => context.go('/redesign'),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(2, 24, 2, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Recent projects',
                          style: AppText.h2().copyWith(fontSize: 17),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.go('/saved'),
                        child: Text(
                          'See all',
                          style: AppText.sm(
                            color: AppColors.teal,
                            weight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (useMockData) ...[
                  if (project.emptyState)
                    _EmptyProjects(onStart: () => context.go('/mode'))
                  else
                    for (final saved in project.saved) ...[
                      ProjectCard(project: saved),
                      const SizedBox(height: 11),
                    ],
                ] else
                  _HomeRecentRemoteProjects(
                    onStart: () => _startNewProject(context, ref, controller),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeMiniCard extends StatelessWidget {
  const _ModeMiniCard({
    required this.icon,
    required this.title,
    required this.caption,
    required this.onTap,
    this.warm = false,
  });

  final IconData icon;
  final String title;
  final String caption;
  final VoidCallback onTap;
  final bool warm;

  @override
  Widget build(BuildContext context) {
    final bg = warm ? AppColors.warmTint : AppColors.tealTint;
    final fg = warm ? AppColors.warmInk : AppColors.tealInk;
    return RsCard(
      padding: const EdgeInsets.all(16),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: fg, size: 19),
          ),
          const SizedBox(height: 10),
          Text(title, style: AppText.h3().copyWith(fontSize: 14.5)),
          const SizedBox(height: 2),
          Text(caption, style: AppText.xs()),
        ],
      ),
    );
  }
}

class _EmptyProjects extends StatelessWidget {
  const _EmptyProjects({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return RsCard(
      padding: const EdgeInsets.fromLTRB(22, 30, 22, 30),
      child: Column(
        children: [
          const FloorPlanView(
            layout: FloorLayout.before,
            height: 110,
            showLabels: false,
          ),
          const SizedBox(height: 14),
          Text('No projects yet', style: AppText.h3()),
          const SizedBox(height: 4),
          Text(
            'Scan your first room to see AI layout ideas here.',
            style: AppText.sm(),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          RsButton(
            label: 'Start a project',
            variant: RsButtonVariant.soft,
            compact: true,
            expand: false,
            onPressed: onStart,
          ),
        ],
      ),
    );
  }
}

class ProjectCard extends StatelessWidget {
  const ProjectCard({super.key, required this.project});

  final SavedProject project;

  @override
  Widget build(BuildContext context) {
    final isRedesign = project.mode == 'redesign';
    return RsCard(
      padding: const EdgeInsets.all(11),
      onTap: () =>
          isRedesign ? context.go('/redesign') : context.go('/results'),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(13),
            child: SizedBox(
              width: 76,
              height: 64,
              child: FloorPlanView(
                layout: isRedesign
                    ? FloorLayout.workFlow
                    : FloorLayout.moreSpace,
                showLabels: false,
              ),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  project.name,
                  style: AppText.h3().copyWith(fontSize: 15.5),
                ),
                const SizedBox(height: 3),
                Text(
                  '${project.room} - ${isRedesign ? 'Redesign' : 'Reshuffle'} - ${project.edited}',
                  style: AppText.xs(),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 7),
                RsBadge(
                  label: project.status,
                  color: isRedesign ? AppColors.warmInk : AppColors.ok,
                  background: isRedesign
                      ? AppColors.warmTint
                      : AppColors.okTint,
                ),
              ],
            ),
          ),
          const Icon(Icons.more_horiz_rounded, color: AppColors.ink3),
        ],
      ),
    );
  }
}

class SavedProjectsScreen extends StatelessWidget {
  const SavedProjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final project = ref.watch(projectControllerProvider);
        return PageShell(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Saved',
                        style: AppText.h1().copyWith(fontSize: 25),
                      ),
                    ),
                    RoundIconButton(icon: Icons.search_rounded, onTap: () {}),
                  ],
                ),
              ),
              SizedBox(
                height: 42,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: const [
                    RsChip(label: 'All', selected: true, small: true),
                    SizedBox(width: 8),
                    RsChip(label: 'Reshuffle', small: true),
                    SizedBox(width: 8),
                    RsChip(label: 'Redesign', small: true, warm: true),
                    SizedBox(width: 8),
                    RsChip(label: 'Plan saved', small: true),
                  ],
                ),
              ),
              Expanded(
                child: useMockData
                    ? ListView(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        children: [
                          for (final saved in project.saved) ...[
                            ProjectCard(project: saved),
                            const SizedBox(height: 11),
                          ],
                          _NewProjectCta(),
                        ],
                      )
                    : _RemoteProjectsList(),
              ),
            ],
          ),
        );
      },
    );
  }
}

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(appAuthControllerProvider);
    final localUser = auth.localUser;
    final name = localUser?['display_name']?.toString() ??
        auth.firebaseUser?.displayName ??
        'Not signed in';
    final email = localUser?['email']?.toString() ??
        auth.firebaseUser?.email ??
        '';
    final role = localUser?['role']?.toString() ?? 'guest';
    final initial = name.isNotEmpty ? name.characters.first.toUpperCase() : '?';
    return PageShell(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Text('Profile', style: AppText.h1().copyWith(fontSize: 25)),
          const SizedBox(height: 16),
          RsCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: AppColors.teal,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(initial, style: AppText.h2(color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: AppText.h3()),
                      const SizedBox(height: 2),
                      Text(
                        email.isEmpty ? role : '$email • $role',
                        style: AppText.xs(),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          RsButton(
            label: 'Upgrade for redesign and PDF export',
            icon: Icons.auto_awesome_rounded,
            variant: RsButtonVariant.soft,
            onPressed: () {},
          ),
          const SectionLabel('Preferences'),
          RsCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: Column(
              children: const [
                SettingsRow(
                  icon: Icons.straighten_rounded,
                  label: 'Measurement units',
                  value: 'Feet / inches',
                ),
                SettingsRow(
                  icon: Icons.storefront_rounded,
                  label: 'Favourite stores',
                  value: 'IKEA, Target',
                ),
                SettingsRow(
                  icon: Icons.palette_rounded,
                  label: 'Default style',
                  value: 'Minimal',
                ),
                SettingsRow(
                  icon: Icons.brightness_6_rounded,
                  label: 'Appearance',
                  value: 'System',
                ),
              ],
            ),
          ),
          const SectionLabel('Privacy'),
          RsCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: Column(
              children: const [
                SettingsRow(
                  icon: Icons.lock_rounded,
                  label: 'Delete room media',
                  value: '',
                ),
                SettingsRow(
                  icon: Icons.info_outline_rounded,
                  label: 'Data and training consent',
                  value: 'Off',
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          RsButton(
            label: 'Log out',
            variant: RsButtonVariant.danger,
            onPressed: () async {
              await ref.read(appAuthControllerProvider.notifier).signOut();
              if (!context.mounted) return;
              context.go('/login');
            },
          ),
        ],
      ),
    );
  }
}

class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.surface3,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.ink2, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(label, style: AppText.h3().copyWith(fontSize: 15)),
              ),
              if (value.isNotEmpty)
                Text(value, style: AppText.sm(weight: FontWeight.w700)),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded, color: AppColors.ink3),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.border),
      ],
    );
  }
}

class ModeSelectionScreen extends ConsumerWidget {
  const ModeSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(projectControllerProvider.notifier);
    return PageShell(
      child: Column(
        children: [
          const FlowHeader(
            title: 'New project',
            step: 0,
            steps: reshuffleSteps,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
              children: [
                Text('What do you want to do?', style: AppText.h1()),
                const SizedBox(height: 6),
                Text(
                  'Pick how you would like to improve your space. Reshuffle is ready for MVP.',
                  style: AppText.body(),
                ),
                const SizedBox(height: 18),
                _LargeModeCard(
                  title: 'Reshuffle my room',
                  badge: 'Recommended',
                  description:
                      'Rearrange the furniture you already own into a better layout with no shopping needed.',
                  bullets: const [
                    'Uses your stuff',
                    '3-5 layouts',
                    'Move checklist',
                  ],
                  layoutKey: 'livingC',
                  paletteKey: 'cool',
                  icon: Icons.open_in_full_rounded,
                  onTap: () {
                    controller.setMode(AppMode.reshuffle);
                    context.go('/capture');
                  },
                ),
                const SizedBox(height: 14),
                _LargeModeCard(
                  title: 'Redesign my room',
                  badge: 'Coming soon',
                  description:
                      'New furniture, measurements, budgets and shopping lists are scaffolded for a later phase.',
                  bullets: const ['New products', 'Measurements', 'Fit-aware'],
                  layoutKey: 'livingA',
                  paletteKey: 'warm',
                  icon: Icons.palette_rounded,
                  warm: true,
                  onTap: () => context.go('/redesign'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LargeModeCard extends StatelessWidget {
  const _LargeModeCard({
    required this.title,
    required this.badge,
    required this.description,
    required this.bullets,
    required this.layoutKey,
    required this.paletteKey,
    required this.icon,
    required this.onTap,
    this.warm = false,
  });

  final String title;
  final String badge;
  final String description;
  final List<String> bullets;
  final String layoutKey;
  final String paletteKey;
  final IconData icon;
  final VoidCallback onTap;
  final bool warm;

  @override
  Widget build(BuildContext context) {
    final accent = warm ? AppColors.warm : AppColors.teal;
    final tint = warm ? AppColors.warmTint : AppColors.tealTint;
    final ink = warm ? AppColors.warmInk : AppColors.tealInk;
    return RsCard(
      clip: Clip.antiAlias,
      borderColor: warm ? AppColors.border : AppColors.teal,
      shadow: true,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              RoomScene(
                layoutKey: layoutKey,
                paletteKey: paletteKey,
                height: 118,
              ),
              Positioned(
                top: 11,
                left: 11,
                child: RsBadge(label: badge, background: tint, color: ink),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: tint,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Icon(icon, color: ink, size: 18),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        title,
                        style: AppText.h2().copyWith(fontSize: 18),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(description, style: AppText.sm()),
                const SizedBox(height: 11),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final bullet in bullets)
                      RsBadge(
                        label: bullet,
                        background: AppColors.surface3,
                        color: warm ? accent : AppColors.ink2,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CaptureInstructionsScreen extends StatelessWidget {
  const CaptureInstructionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const tips = [
      (
        Icons.access_time_rounded,
        'Move slowly',
        'Pan smoothly around the room with no fast sweeps.',
      ),
      (
        Icons.document_scanner_rounded,
        'Show every corner',
        'Capture all four corners, the floor and the walls.',
      ),
      (
        Icons.pin_drop_rounded,
        'Doors and windows',
        'Keep doors and windows in frame so AI maps the space.',
      ),
      (
        Icons.chair_rounded,
        'Keep furniture visible',
        'Make sure each big piece appears clearly.',
      ),
      (
        Icons.lightbulb_outline_rounded,
        'Good lighting',
        'Turn on lights or scan during the day.',
      ),
      (
        Icons.straighten_rounded,
        'Optional reference',
        'A known object can help later estimates.',
      ),
    ];
    return PageShell(
      bottom: BottomBar(
        child: RsButton(
          label: 'I am ready to scan',
          onPressed: () => context.go('/upload'),
        ),
      ),
      child: Column(
        children: [
          const FlowHeader(title: 'Capture', step: 1, steps: reshuffleSteps),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
              children: [
                Text(
                  'Scan your room slowly so AI understands it',
                  style: AppText.h1(),
                ),
                const SizedBox(height: 16),
                RsCard(
                  clip: Clip.antiAlias,
                  child: Stack(
                    children: [
                      const RoomScene(
                        layoutKey: 'bedA',
                        paletteKey: 'warm',
                        height: 150,
                      ),
                      Positioned.fill(
                        child: CustomPaint(painter: ScanPathPainter()),
                      ),
                      const Positioned(
                        left: 10,
                        bottom: 10,
                        child: RsBadge(
                          label: '30-60s walkthrough',
                          icon: Icons.play_arrow_rounded,
                          color: Colors.white,
                          background: Color(0x99000000),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                for (final tip in tips)
                  _TipRow(icon: tip.$1, title: tip.$2, body: tip.$3),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ScanPathPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * .13, size.height * .73)
      ..quadraticBezierTo(
        size.width * .5,
        size.height * .38,
        size.width * .87,
        size.height * .73,
      );
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.teal
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
    canvas.drawCircle(
      Offset(size.width * .13, size.height * .73),
      5,
      Paint()..color = AppColors.teal,
    );
    canvas.drawCircle(
      Offset(size.width * .87, size.height * .73),
      5,
      Paint()..color = AppColors.teal,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TipRow extends StatelessWidget {
  const _TipRow({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.tealTint,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: AppColors.tealInk, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.h3().copyWith(fontSize: 14.5)),
                const SizedBox(height: 1),
                Text(body, style: AppText.xs()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum UploadPhase { choose, uploading, preview, error }

class UploadMediaScreen extends ConsumerStatefulWidget {
  const UploadMediaScreen({super.key});

  @override
  ConsumerState<UploadMediaScreen> createState() => _UploadMediaScreenState();
}

class _UploadMediaScreenState extends ConsumerState<UploadMediaScreen> {
  UploadPhase phase = UploadPhase.choose;
  int pct = 0;
  String? errorMessage;
  bool _picking = false;

  Future<void> _pick({
    required MediaKind kind,
    required ImageSource source,
  }) async {
    if (_picking) return;
    _picking = true;
    try {
      final picker = ref.read(mediaPickerProvider);
      final media = kind == MediaKind.image
          ? await picker.pickImage(source: source)
          : await picker.pickVideo(source: source);
      if (media == null) return; // user cancelled
      ref.read(projectControllerProvider.notifier).setMedia(media);
      if (mounted) setState(() => phase = UploadPhase.preview);
    } catch (e) {
      if (!mounted) return;
      final where = source == ImageSource.camera ? 'camera' : 'gallery';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open $where: $e')),
      );
    } finally {
      _picking = false;
    }
  }

  /// Sends the picked media to the backend (upload-url → PUT → complete) when a
  /// real project is available, then advances to processing. In the design-pass
  /// mock flow (or when no backend project exists) it just advances.
  Future<void> _analyse() async {
    final project = ref.read(projectControllerProvider);
    final media = project.media;
    final projectId = project.remoteProjectId;

    if (useMockData || projectId == null || media == null) {
      context.go('/processing');
      return;
    }

    setState(() {
      phase = UploadPhase.uploading;
      pct = 10;
      errorMessage = null;
    });

    try {
      final api = ref.read(apiServiceProvider);
      final res = await api.requestUploadUrl(
        projectId: projectId,
        fileName: media.fileName,
        mimeType: media.mimeType,
        fileSize: media.sizeBytes,
        mediaKind: media.kindName, // 'image' for photos, 'video' for clips
      );
      final mediaId = res['media_id']?.toString();
      final uploadUrl = res['upload_url']?.toString();
      if (mounted) setState(() => pct = 55);

      if (uploadUrl != null) {
        // No-op (returns false) when R2 isn't configured and the URL is a
        // mock:// placeholder, so local dev still works end-to-end.
        await api.putToSignedUrl(
          uploadUrl: uploadUrl,
          file: File(media.path),
          contentType: media.mimeType,
        );
      }
      if (mounted) setState(() => pct = 85);

      if (mediaId != null) {
        await api.completeUpload(projectId: projectId, mediaId: mediaId);
      }
      if (!mounted) return;
      setState(() => pct = 100);
      context.go('/processing');
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        phase = UploadPhase.error;
        errorMessage = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        phase = UploadPhase.error;
        errorMessage = '$e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = ref.watch(
      projectControllerProvider.select((s) => s.media),
    );
    return PageShell(
      child: Column(
        children: [
          const FlowHeader(title: 'Upload', step: 2, steps: reshuffleSteps),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
              children: [
                Text('Add a room photo or video', style: AppText.h1()),
                const SizedBox(height: 6),
                Text(
                  'Take a photo, record a video, or pick one from your gallery. '
                  'ReSpace works from either.',
                  style: AppText.body(),
                ),
                const SizedBox(height: 18),
                if (phase == UploadPhase.choose) ...[
                  const _ChooseSectionLabel('Photo'),
                  const SizedBox(height: 8),
                  _UploadChoice(
                    icon: Icons.photo_camera_rounded,
                    title: 'Take a photo',
                    subtitle: 'Snap your room now',
                    primary: true,
                    onTap: () => _pick(
                      kind: MediaKind.image,
                      source: ImageSource.camera,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _UploadChoice(
                    icon: Icons.photo_library_rounded,
                    title: 'Choose a photo',
                    subtitle: 'Pick an existing image',
                    onTap: () => _pick(
                      kind: MediaKind.image,
                      source: ImageSource.gallery,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const _ChooseSectionLabel('Video'),
                  const SizedBox(height: 8),
                  _UploadChoice(
                    icon: Icons.videocam_rounded,
                    title: 'Record a video',
                    subtitle: 'Guided in-app capture',
                    onTap: () => _pick(
                      kind: MediaKind.video,
                      source: ImageSource.camera,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _UploadChoice(
                    icon: Icons.video_library_rounded,
                    title: 'Upload a video',
                    subtitle: 'Pick an existing clip',
                    onTap: () => _pick(
                      kind: MediaKind.video,
                      source: ImageSource.gallery,
                    ),
                  ),
                  const SizedBox(height: 16),
                  RsCard(
                    padding: const EdgeInsets.all(16),
                    color: AppColors.surface2,
                    shadow: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'File requirements',
                          style: AppText.h3().copyWith(fontSize: 13.5),
                        ),
                        const SizedBox(height: 9),
                        for (final item in [
                          'Photo: JPG, PNG, WebP or HEIC (up to 15 MB)',
                          'Video: MP4 or MOV (up to 250 MB)',
                          'Show every corner in good lighting',
                        ])
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.check_rounded,
                                  color: AppColors.teal,
                                  size: 16,
                                ),
                                const SizedBox(width: 9),
                                Expanded(
                                  child: Text(item, style: AppText.sm()),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ] else if (phase == UploadPhase.uploading) ...[
                  _UploadingCard(
                    pct: pct,
                    media: media,
                    onCancel: () =>
                        setState(() => phase = UploadPhase.preview),
                  ),
                ] else if (phase == UploadPhase.preview) ...[
                  if (media != null)
                    _MediaPreview(media: media)
                  else
                    const SizedBox.shrink(),
                  const SizedBox(height: 14),
                  RsNotice(
                    text: (media?.isVideo ?? false)
                        ? 'Make sure all four corners and the window are visible. '
                              'You will review AI detections before any layout is generated.'
                        : 'Make sure the whole room is visible. '
                              'You will review AI detections before any layout is generated.',
                    icon: Icons.check_rounded,
                  ),
                  const SizedBox(height: 18),
                  RsButton(
                    label: 'Looks good - analyse',
                    icon: Icons.auto_awesome_rounded,
                    onPressed: _analyse,
                  ),
                  const SizedBox(height: 4),
                  RsButton(
                    label: 'Choose another',
                    variant: RsButtonVariant.quiet,
                    onPressed: () => setState(() => phase = UploadPhase.choose),
                  ),
                ] else ...[
                  RsCard(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: AppColors.dangerTint,
                            borderRadius: BorderRadius.circular(17),
                          ),
                          child: const Icon(
                            Icons.warning_rounded,
                            color: AppColors.danger,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text('Upload interrupted', style: AppText.h3()),
                        const SizedBox(height: 5),
                        Text(
                          errorMessage ??
                              'Nothing was lost. Try again with a steady connection.',
                          style: AppText.sm(),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        RsButton(
                          label: 'Retry upload',
                          icon: Icons.refresh_rounded,
                          onPressed: _analyse,
                        ),
                        const SizedBox(height: 4),
                        RsButton(
                          label: 'Choose another',
                          variant: RsButtonVariant.quiet,
                          onPressed: () =>
                              setState(() => phase = UploadPhase.choose),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChooseSectionLabel extends StatelessWidget {
  const _ChooseSectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        label.toUpperCase(),
        style: AppText.xs(weight: FontWeight.w800, color: AppColors.ink3),
      ),
    );
  }
}

String _prettySize(int bytes) {
  if (bytes <= 0) return '';
  const mb = 1024 * 1024;
  if (bytes >= mb) return '${(bytes / mb).toStringAsFixed(1)} MB';
  return '${(bytes / 1024).toStringAsFixed(0)} KB';
}

class _UploadChoice extends StatelessWidget {
  const _UploadChoice({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.primary = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    return RsCard(
      padding: const EdgeInsets.all(16),
      borderColor: primary ? AppColors.teal : AppColors.border,
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: primary ? AppColors.teal : AppColors.surface3,
              borderRadius: BorderRadius.circular(14),
              boxShadow: primary ? AppShadows.teal : null,
            ),
            child: Icon(
              icon,
              color: primary ? Colors.white : AppColors.ink2,
              size: 23,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.h3()),
                const SizedBox(height: 2),
                Text(subtitle, style: AppText.xs()),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.ink3),
        ],
      ),
    );
  }
}

class _UploadingCard extends StatelessWidget {
  const _UploadingCard({
    required this.pct,
    required this.onCancel,
    this.media,
  });

  final int pct;
  final VoidCallback onCancel;
  final SelectedMedia? media;

  @override
  Widget build(BuildContext context) {
    final name = media?.fileName ?? 'room_scan';
    final sizeText = media != null ? _prettySize(media!.sizeBytes) : '';
    final isVideo = media?.isVideo ?? false;
    return Column(
      children: [
        RsCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppColors.tealTint,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(
                      isVideo ? Icons.movie_rounded : Icons.image_rounded,
                      color: AppColors.teal,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: AppText.h3().copyWith(fontSize: 14.5),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(sizeText, style: AppText.xs()),
                      ],
                    ),
                  ),
                  Text('$pct%', style: AppText.h3(color: AppColors.teal)),
                ],
              ),
              const SizedBox(height: 14),
              LinearProgressIndicator(
                value: pct / 100,
                minHeight: 8,
                borderRadius: BorderRadius.circular(99),
                color: AppColors.teal,
                backgroundColor: AppColors.surface3,
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Uploading securely...', style: AppText.xs()),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        RsButton(
          label: 'Cancel',
          variant: RsButtonVariant.quiet,
          compact: true,
          expand: false,
          onPressed: onCancel,
        ),
      ],
    );
  }
}

/// Previews the picked media: a still photo via [Image.file], or a real video
/// via the [video_player] plugin.
class _MediaPreview extends StatelessWidget {
  const _MediaPreview({required this.media});

  final SelectedMedia media;

  @override
  Widget build(BuildContext context) {
    if (media.isVideo) {
      return _VideoPreview(path: media.path, fileName: media.fileName);
    }
    return RsCard(
      clip: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 260),
            child: Image.file(
              File(media.path),
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const SizedBox(
                height: 160,
                child: Center(
                  child: Icon(Icons.broken_image_rounded, color: AppColors.ink3),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Icon(Icons.image_rounded, size: 16, color: AppColors.teal),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    media.fileName,
                    style: AppText.xs(),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(_prettySize(media.sizeBytes), style: AppText.xs()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VideoPreview extends StatefulWidget {
  const _VideoPreview({required this.path, required this.fileName});

  final String path;
  final String fileName;

  @override
  State<_VideoPreview> createState() => _VideoPreviewState();
}

class _VideoPreviewState extends State<_VideoPreview> {
  VideoPlayerController? _controller;
  bool _ready = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    final controller = VideoPlayerController.file(File(widget.path));
    _controller = controller;
    controller
        .initialize()
        .then((_) {
          if (!mounted) return;
          controller.setLooping(true);
          setState(() => _ready = true);
        })
        .catchError((Object _) {
          if (!mounted) return;
          setState(() => _failed = true);
        });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _toggle() {
    final controller = _controller;
    if (controller == null || !_ready) return;
    setState(() {
      controller.value.isPlaying ? controller.pause() : controller.play();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    // Some platforms (e.g. the iOS Simulator) can't decode every clip — fall
    // back to a labelled placeholder instead of breaking the flow.
    if (_failed || controller == null) {
      return RsCard(
        clip: Clip.antiAlias,
        child: Container(
          height: 210,
          color: AppColors.surface3,
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.movie_rounded, size: 36, color: AppColors.ink3),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  widget.fileName,
                  style: AppText.xs(),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (!_ready) {
      return RsCard(
        clip: Clip.antiAlias,
        child: const SizedBox(
          height: 210,
          child: Center(
            child: CircularProgressIndicator(color: AppColors.teal),
          ),
        ),
      );
    }
    final aspect = controller.value.aspectRatio == 0
        ? 16 / 9
        : controller.value.aspectRatio;
    return RsCard(
      clip: Clip.antiAlias,
      child: GestureDetector(
        onTap: _toggle,
        child: Stack(
          alignment: Alignment.center,
          children: [
            AspectRatio(aspectRatio: aspect, child: VideoPlayer(controller)),
            if (!controller.value.isPlaying)
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .92),
                  shape: BoxShape.circle,
                  boxShadow: AppShadows.sh,
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: AppColors.ink,
                  size: 34,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class ProcessingScreen extends ConsumerStatefulWidget {
  const ProcessingScreen({super.key});

  @override
  ConsumerState<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends ConsumerState<ProcessingScreen> {
  late Timer timer;
  double progress = .04;

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(milliseconds: 240), (_) {
      if (!mounted) return;
      setState(() => progress = (progress + .045).clamp(0, 1));
      if (progress >= 1) {
        timer.cancel();
        Future<void>.delayed(const Duration(milliseconds: 450), () {
          if (mounted) context.go('/review');
        });
      }
    });
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaKind = ref.watch(
      projectControllerProvider.select((s) => s.media?.kind),
    );
    final stages = processingStagesFor(mediaKind);
    final stage = (progress * stages.length).floor().clamp(
      0,
      stages.length - 1,
    );
    return PageShell(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 30),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: RoundIconButton(
                icon: Icons.close_rounded,
                onTap: () => context.go('/upload'),
              ),
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 206,
                    height: 206,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.tealTint,
                          ),
                        ),
                        SizedBox(
                          width: 188,
                          height: 188,
                          child: CircularProgressIndicator(
                            value: progress,
                            strokeWidth: 6,
                            color: AppColors.teal,
                            backgroundColor: AppColors.border,
                          ),
                        ),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(22),
                          child: const SizedBox(
                            width: 144,
                            height: 144,
                            child: RoomScene(layoutKey: 'livingC', height: 144),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          child: RsBadge(
                            label: '${(progress * 100).round()}%',
                            background: AppColors.surface,
                            color: AppColors.teal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 26),
                  Text(
                    'Analysing your space',
                    style: AppText.h1(),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'This usually takes under a minute.',
                    style: AppText.sm(),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 22),
                  RsCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    child: Column(
                      children: [
                        for (var i = 0; i < stages.length; i++)
                          _ProcessingRow(
                            title: stages[i].$1,
                            subtitle: stages[i].$2,
                            index: i,
                            stage: stage,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  const RsNotice(
                    text:
                        'AI detections are suggestions. Your corrections become the final truth.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProcessingRow extends StatelessWidget {
  const _ProcessingRow({
    required this.title,
    required this.subtitle,
    required this.index,
    required this.stage,
  });

  final String title;
  final String subtitle;
  final int index;
  final int stage;

  @override
  Widget build(BuildContext context) {
    final done = index < stage;
    final current = index == stage;
    return Opacity(
      opacity: index > stage ? .42 : 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done
                    ? AppColors.teal
                    : (current ? AppColors.tealTint : AppColors.surface3),
              ),
              child: done
                  ? const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 15,
                    )
                  : current
                  ? const Padding(
                      padding: EdgeInsets.all(7),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.teal,
                      ),
                    )
                  : Center(
                      child: Text(
                        '${index + 1}',
                        style: AppText.xs(weight: FontWeight.w700),
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppText.h3().copyWith(fontSize: 14)),
                  if (current) Text(subtitle, style: AppText.xs()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ReviewItemsScreen extends ConsumerWidget {
  const ReviewItemsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final project = ref.watch(projectControllerProvider);
    final controller = ref.read(projectControllerProvider.notifier);
    final furniture = project.items.where((item) => !item.structural).toList();
    final structure = project.items.where((item) => item.structural).toList();
    final fixedCount = furniture.where((item) => item.fixed).length;
    return PageShell(
      bottom: BottomBar(
        child: RsButton(
          label: 'Looks right - continue',
          icon: Icons.arrow_forward_rounded,
          onPressed: () => context.go('/preferences'),
        ),
      ),
      child: Column(
        children: [
          const FlowHeader(
            title: 'Review items',
            step: 3,
            steps: reshuffleSteps,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
              children: [
                Text('Review detected items', style: AppText.h1()),
                const SizedBox(height: 6),
                Text(
                  'Fix anything we got wrong, then mark what should stay put. Layouts always respect fixed items.',
                  style: AppText.body(),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        value: '${furniture.length}',
                        label: 'items found',
                        color: AppColors.teal,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _StatCard(
                        value: '$fixedCount',
                        label: 'marked fixed',
                        color: AppColors.warmInk,
                      ),
                    ),
                  ],
                ),
                const SectionLabel('Furniture and objects'),
                for (final item in furniture) ...[
                  ItemReviewCard(item: item),
                  const SizedBox(height: 10),
                ],
                RsCard(
                  padding: const EdgeInsets.all(15),
                  shadow: false,
                  onTap: () => _showAddItemSheet(context, controller),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_rounded, color: AppColors.teal),
                      const SizedBox(width: 9),
                      Text(
                        'Add missing item',
                        style: AppText.sm(
                          color: AppColors.teal,
                          weight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SectionLabel('Room structure'),
                RsCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 4,
                  ),
                  child: Column(
                    children: [
                      for (final item in structure)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: AppColors.surface3,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  itemIcons[item.type],
                                  color: AppColors.ink2,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  item.name,
                                  style: AppText.h3().copyWith(fontSize: 14.5),
                                ),
                              ),
                              const RsBadge(
                                label: 'Structure',
                                icon: Icons.lock_rounded,
                                background: AppColors.surface3,
                                color: AppColors.ink2,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddItemSheet(BuildContext context, ProjectController controller) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.xl)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: AppColors.border2,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                Text('Add a missing item', style: AppText.h2()),
                const SizedBox(height: 6),
                Text('Pick anything the scan missed.', style: AppText.sm()),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final item in addableItems)
                      RsChip(
                        label: item,
                        icon: Icons.add_rounded,
                        onTap: () {
                          controller.addItem(item);
                          Navigator.pop(context);
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.value,
    required this.label,
    required this.color,
  });

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return RsCard(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      color: AppColors.surface2,
      shadow: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: AppText.h2(color: color).copyWith(fontSize: 19)),
          Text(label, style: AppText.xs()),
        ],
      ),
    );
  }
}

class ItemReviewCard extends ConsumerWidget {
  const ItemReviewCard({super.key, required this.item});

  final DetectedItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(projectControllerProvider.notifier);
    final accentBg = item.fixed ? AppColors.warmTint : AppColors.tealTint;
    final accentFg = item.fixed ? AppColors.warmInk : AppColors.tealInk;
    return RsCard(
      padding: const EdgeInsets.all(13),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: accentBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  itemIcons[item.type] ?? Icons.grid_view_rounded,
                  color: accentFg,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            item.name,
                            style: AppText.h3().copyWith(fontSize: 15.5),
                          ),
                        ),
                        if (item.added) ...[
                          const SizedBox(width: 7),
                          const RsBadge(label: 'Added'),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    item.added
                        ? Text('Added by you', style: AppText.xs())
                        : ConfidenceMeter(value: item.confidence),
                  ],
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: () => _rename(context, controller),
                icon: const Icon(
                  Icons.edit_rounded,
                  color: AppColors.ink2,
                  size: 18,
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: () => controller.deleteItem(item.id),
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.ink2,
                  size: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: AppColors.surface3,
              borderRadius: BorderRadius.circular(AppRadii.pill),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _SegmentButton(
                    label: 'Movable',
                    icon: Icons.open_in_full_rounded,
                    selected: !item.fixed,
                    onTap: () => controller.toggleFixed(item.id, false),
                  ),
                ),
                Expanded(
                  child: _SegmentButton(
                    label: 'Fixed',
                    icon: Icons.lock_rounded,
                    selected: item.fixed,
                    warm: true,
                    onTap: () => controller.toggleFixed(item.id, true),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _rename(
    BuildContext context,
    ProjectController controller,
  ) async {
    final textController = TextEditingController(text: item.name);
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename item'),
        content: TextField(controller: textController, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, textController.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (value != null && value.trim().isNotEmpty) {
      controller.renameItem(item.id, value.trim());
    }
  }
}

class ConfidenceMeter extends StatelessWidget {
  const ConfidenceMeter({super.key, required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    final color = value >= .8
        ? AppColors.ok
        : (value >= .55 ? AppColors.warn : AppColors.danger);
    final label = value >= .8 ? 'High' : (value >= .55 ? 'Medium' : 'Low');
    return Row(
      children: [
        for (var i = 0; i < 3; i++)
          Container(
            width: 5,
            height: 11,
            margin: const EdgeInsets.only(right: 2),
            decoration: BoxDecoration(
              color: value * 3 > i ? color : AppColors.border2,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppText.xs(color: color, weight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.warm = false,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final bool warm;

  @override
  Widget build(BuildContext context) {
    final fg = warm ? AppColors.warmInk : AppColors.ink;
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadii.pill),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadii.pill),
          boxShadow: selected ? AppShadows.sm : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: selected ? fg : AppColors.ink2),
            const SizedBox(width: 5),
            Text(
              label,
              style: AppText.xs(
                color: selected ? fg : AppColors.ink2,
                weight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PreferencesScreen extends ConsumerStatefulWidget {
  const PreferencesScreen({super.key});

  @override
  ConsumerState<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends ConsumerState<PreferencesScreen> {
  bool generating = false;

  @override
  Widget build(BuildContext context) {
    final project = ref.watch(projectControllerProvider);
    final controller = ref.read(projectControllerProvider.notifier);
    final fixed = project.items
        .where((item) => item.fixed && !item.structural)
        .toList();
    return PageShell(
      bottom: BottomBar(
        child: RsButton(
          label: generating ? 'Generating layouts...' : 'Generate layouts',
          icon: generating
              ? Icons.hourglass_top_rounded
              : Icons.auto_awesome_rounded,
          onPressed: generating || project.goals.isEmpty ? null : _generate,
        ),
      ),
      child: Column(
        children: [
          const FlowHeader(
            title: 'Preferences',
            step: 4,
            steps: reshuffleSteps,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
              children: [
                Text('What should improve?', style: AppText.h1()),
                const SizedBox(height: 6),
                Text(
                  'Pick one or more goals. AI balances them against your fixed items.',
                  style: AppText.body(),
                ),
                const SectionLabel('Goals - pick any'),
                Wrap(
                  spacing: 9,
                  runSpacing: 9,
                  children: [
                    for (final goal in goals)
                      RsChip(
                        label: goal.label,
                        icon: goal.icon,
                        selected: project.goals.contains(goal.id),
                        onTap: () => controller.toggleGoal(goal.id),
                      ),
                  ],
                ),
                const SectionLabel('Style feeling - pick one'),
                Wrap(
                  spacing: 9,
                  runSpacing: 9,
                  children: [
                    for (final style in styles)
                      RsChip(
                        label: style,
                        selected: project.style == style,
                        onTap: () => controller.setStyle(style),
                      ),
                  ],
                ),
                const SectionLabel('How much moving are you up for?'),
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: AppColors.surface3,
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                  ),
                  child: Row(
                    children: [
                      for (final d in const [
                        ('Easy', 'Light only'),
                        ('Medium', 'Some lifting'),
                        ('Heavy', 'Anything goes'),
                      ])
                        Expanded(
                          child: _DifficultySegment(
                            title: d.$1,
                            subtitle: d.$2,
                            selected: project.difficulty == d.$1,
                            onTap: () => controller.setDifficulty(d.$1),
                          ),
                        ),
                    ],
                  ),
                ),
                SectionLabel('Staying put (${fixed.length})'),
                RsCard(
                  padding: const EdgeInsets.all(16),
                  color: AppColors.surface2,
                  shadow: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (fixed.isEmpty)
                        Text(
                          'Nothing locked. AI can move everything.',
                          style: AppText.sm(),
                        )
                      else
                        Wrap(
                          spacing: 7,
                          runSpacing: 7,
                          children: [
                            for (final item in fixed)
                              RsBadge(
                                label: item.name,
                                icon: Icons.lock_rounded,
                                color: AppColors.warmInk,
                                background: AppColors.warmTint,
                              ),
                          ],
                        ),
                      const SizedBox(height: 10),
                      RsButton(
                        label: 'Edit fixed items',
                        icon: Icons.edit_rounded,
                        compact: true,
                        expand: false,
                        variant: RsButtonVariant.quiet,
                        onPressed: () => context.pop(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                const RsNotice(
                  text:
                      'Generated room images are suggestions based on your room scan and choices, not exact engineering plans.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _generate() {
    setState(() => generating = true);
    Future<void>.delayed(const Duration(milliseconds: 1100), () {
      if (mounted) context.go('/results');
    });
  }
}

class _DifficultySegment extends StatelessWidget {
  const _DifficultySegment({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadii.pill),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 5),
        decoration: BoxDecoration(
          color: selected ? AppColors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadii.pill),
          boxShadow: selected ? AppShadows.sm : null,
        ),
        child: Column(
          children: [
            Text(
              title,
              style: AppText.xs(
                color: AppColors.ink,
                weight: FontWeight.w700,
              ).copyWith(fontSize: 13),
            ),
            Text(subtitle, style: AppText.xs().copyWith(fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

class ResultsScreen extends ConsumerWidget {
  const ResultsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final project = ref.watch(projectControllerProvider);
    final controller = ref.read(projectControllerProvider.notifier);
    return PageShell(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                RoundIconButton(
                  icon: Icons.arrow_back_ios_new_rounded,
                  onTap: () => context.go('/preferences'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Results - Step 6 of ${reshuffleSteps.length}',
                    style: AppText.xs(weight: FontWeight.w700),
                  ),
                ),
                RoundIconButton(icon: Icons.refresh_rounded, onTap: () {}),
              ],
            ),
          ),
          const RsStepper(steps: reshuffleSteps, current: 5),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${results.length} layouts for you',
                    style: AppText.h1().copyWith(fontSize: 24),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Tuned for ${project.goals.length} goals - ${project.style}',
                    style: AppText.sm(),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: AppColors.surface3,
                borderRadius: BorderRadius.circular(AppRadii.pill),
              ),
              child: Row(
                children: [
                  for (final view in const [
                    ('grid', 'Grid', Icons.grid_view_rounded),
                    ('swipe', 'Swipe', Icons.layers_rounded),
                    ('compare', 'Compare', Icons.swap_horiz_rounded),
                  ])
                    Expanded(
                      child: _SegmentButton(
                        label: view.$2,
                        icon: view.$3,
                        selected: project.resultsView == view.$1,
                        onTap: () => controller.setResultsView(view.$1),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            child: switch (project.resultsView) {
              'compare' => const CompareResultsView(),
              'swipe' => const SwipeResultsView(),
              _ => const GridResultsView(),
            },
          ),
        ],
      ),
    );
  }
}

class GridResultsView extends ConsumerWidget {
  const GridResultsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(projectControllerProvider.notifier);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        for (final result in results) ...[
          LayoutResultCard(
            result: result,
            onTap: () {
              controller.selectLayout(result.id);
              context.go('/layout/${result.id}');
            },
          ),
          const SizedBox(height: 14),
        ],
      ],
    );
  }
}

class SwipeResultsView extends ConsumerWidget {
  const SwipeResultsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(projectControllerProvider.notifier);
    return PageView.builder(
      padEnds: false,
      itemCount: results.length,
      itemBuilder: (context, index) {
        final result = results[index];
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            RsCard(
              clip: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      GeneratedRoomImage(result: result, height: 216),
                      Positioned(
                        top: 11,
                        left: 11,
                        child: RsBadge(
                          label: 'Option ${index + 1} of ${results.length}',
                          background: const Color(0x99000000),
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 15, 16, 17),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          result.title,
                          style: AppText.h2().copyWith(fontSize: 20),
                        ),
                        const SizedBox(height: 6),
                        Text(result.reason, style: AppText.sm()),
                        const SizedBox(height: 12),
                        ResultMetaRow(result: result),
                        const SizedBox(height: 14),
                        RsCard(
                          color: AppColors.surface2,
                          clip: Clip.antiAlias,
                          shadow: false,
                          child: Column(
                            children: [
                              FloorPlanView(
                                layout: result.floorLayout,
                                height: 190,
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  13,
                                  0,
                                  13,
                                  11,
                                ),
                                child: Wrap(
                                  spacing: 14,
                                  runSpacing: 6,
                                  children: const [
                                    LegendItem(
                                      color: AppColors.teal,
                                      label: 'Moved',
                                    ),
                                    LegendItem(
                                      color: AppColors.warm,
                                      label: 'Fixed',
                                    ),
                                    LegendItem(
                                      color: AppColors.ink3,
                                      label: 'Unchanged',
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 15),
                        RsButton(
                          label: 'Open full plan',
                          icon: Icons.arrow_forward_rounded,
                          onPressed: () {
                            controller.selectLayout(result.id);
                            context.go('/layout/${result.id}');
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class CompareResultsView extends ConsumerWidget {
  const CompareResultsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(projectControllerProvider.notifier);
    final a = results[0];
    final b = results[1];
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        Text('Compare two strong options side by side.', style: AppText.sm()),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(child: _CompareMini(result: a)),
            const SizedBox(width: 10),
            Expanded(child: _CompareMini(result: b)),
          ],
        ),
        const SizedBox(height: 12),
        RsCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _MetricRow(
                label: 'Goal match',
                left: '${a.goal}%',
                right: '${b.goal}%',
                leftWins: true,
              ),
              _MetricRow(
                label: 'Difficulty',
                left: a.diff,
                right: b.diff,
                leftWins: true,
              ),
              _MetricRow(
                label: 'Items moved',
                left: '${a.moved}',
                right: '${b.moved}',
                leftWins: true,
              ),
              const SizedBox(height: 13),
              Row(
                children: [
                  Expanded(
                    child: RsButton(
                      label: 'Open A',
                      compact: true,
                      variant: RsButtonVariant.ghost,
                      onPressed: () {
                        controller.selectLayout(a.id);
                        context.go('/layout/${a.id}');
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: RsButton(
                      label: 'Open B',
                      compact: true,
                      onPressed: () {
                        controller.selectLayout(b.id);
                        context.go('/layout/${b.id}');
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CompareMini extends StatelessWidget {
  const _CompareMini({required this.result});

  final LayoutResult result;

  @override
  Widget build(BuildContext context) {
    return RsCard(
      clip: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GeneratedRoomImage(result: result, height: 92),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Text(
              result.title,
              style: AppText.h3().copyWith(fontSize: 13.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({
    required this.label,
    required this.left,
    required this.right,
    required this.leftWins,
  });

  final String label;
  final String left;
  final String right;
  final bool leftWins;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 92,
            child: Text(label, style: AppText.sm(weight: FontWeight.w700)),
          ),
          Expanded(
            child: Text(
              left,
              textAlign: TextAlign.center,
              style: AppText.sm(
                color: leftWins ? AppColors.teal : AppColors.ink,
                weight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            child: Text(
              right,
              textAlign: TextAlign.center,
              style: AppText.sm(
                color: !leftWins ? AppColors.teal : AppColors.ink,
                weight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LayoutResultCard extends ConsumerWidget {
  const LayoutResultCard({
    super.key,
    required this.result,
    required this.onTap,
  });

  final LayoutResult result;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final project = ref.watch(projectControllerProvider);
    final controller = ref.read(projectControllerProvider.notifier);
    final saved = project.savedLayoutIds.contains(result.id);
    return RsCard(
      clip: Clip.antiAlias,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              GeneratedRoomImage(result: result, height: 158),
              Positioned(
                bottom: 10,
                right: 10,
                child: RsCard(
                  clip: Clip.antiAlias,
                  padding: EdgeInsets.zero,
                  radius: 10,
                  shadow: true,
                  child: SizedBox(
                    width: 78,
                    height: 64,
                    child: FloorPlanView(
                      layout: result.floorLayout,
                      showLabels: false,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 11,
                left: 11,
                child: RsBadge(
                  label: 'Option ${result.id + 1}',
                  background: const Color(0x99000000),
                  color: Colors.white,
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: RoundIconButton(
                  icon: saved
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  iconColor: saved ? AppColors.danger : AppColors.ink3,
                  onTap: () => controller.toggleSavedLayout(result.id),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 13, 15, 15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(result.title, style: AppText.h2().copyWith(fontSize: 18)),
                const SizedBox(height: 5),
                Text(result.reason, style: AppText.sm()),
                const SizedBox(height: 11),
                ResultMetaRow(result: result),
                const SizedBox(height: 13),
                Row(
                  children: [
                    Expanded(
                      child: RsButton(
                        label: 'View plan',
                        variant: RsButtonVariant.soft,
                        compact: true,
                        onPressed: onTap,
                      ),
                    ),
                    const SizedBox(width: 8),
                    RsButton(
                      label: '',
                      icon: Icons.refresh_rounded,
                      variant: RsButtonVariant.ghost,
                      compact: true,
                      expand: false,
                      onPressed: () {},
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class GeneratedRoomImage extends StatelessWidget {
  const GeneratedRoomImage({
    super.key,
    required this.result,
    this.height = 160,
  });

  final LayoutResult result;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CachedNetworkImage(
        imageUrl: result.imageUrl,
        fit: BoxFit.cover,
        placeholder: (context, url) => RoomScene(
          layoutKey: result.id.isEven ? 'bedB' : 'bedA',
          paletteKey: result.palette == const Color(0xFFF1DDC0)
              ? 'warm'
              : 'cool',
          height: height,
        ),
        errorWidget: (context, url, error) => RoomScene(
          layoutKey: result.id.isEven ? 'bedB' : 'bedA',
          paletteKey: result.id == 2 ? 'cozy' : 'cool',
          height: height,
        ),
      ),
    );
  }
}

class ResultMetaRow extends StatelessWidget {
  const ResultMetaRow({super.key, required this.result});

  final LayoutResult result;

  @override
  Widget build(BuildContext context) {
    final diff = difficultyColor(result.diff);
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        RsBadge(
          label: '${result.goal}% goal match',
          icon: Icons.auto_awesome_rounded,
        ),
        RsBadge(
          label: '${result.diff} move',
          background: diff.withValues(alpha: .14),
          color: diff,
        ),
        RsBadge(
          label: '${result.moved} moved',
          icon: Icons.open_in_full_rounded,
          background: AppColors.surface3,
          color: AppColors.ink2,
        ),
      ],
    );
  }
}

class LegendItem extends StatelessWidget {
  const LegendItem({super.key, required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 8,
          decoration: BoxDecoration(
            border: Border.all(color: color, width: 2),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: AppText.xs()),
      ],
    );
  }
}

class LayoutDetailScreen extends ConsumerStatefulWidget {
  const LayoutDetailScreen({super.key, required this.layoutId});

  final int layoutId;

  @override
  ConsumerState<LayoutDetailScreen> createState() => _LayoutDetailScreenState();
}

class _LayoutDetailScreenState extends ConsumerState<LayoutDetailScreen> {
  String tab = 'render';
  bool tuning = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref
          .read(projectControllerProvider.notifier)
          .selectLayout(widget.layoutId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final project = ref.watch(projectControllerProvider);
    final controller = ref.read(projectControllerProvider.notifier);
    final result = selectedResult(project);
    final fixed = project.items
        .where((item) => item.fixed && !item.structural)
        .toList();
    return PageShell(
      bottom: BottomBar(
        child: Row(
          children: [
            Expanded(
              child: RsButton(
                label: 'Modify',
                icon: Icons.auto_awesome_rounded,
                variant: RsButtonVariant.ghost,
                onPressed: () => _showModifySheet(context, controller),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: RsButton(
                label: 'Save this plan',
                icon: Icons.check_rounded,
                onPressed: () => context.go('/final'),
              ),
            ),
          ],
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
            child: Row(
              children: [
                RoundIconButton(
                  icon: Icons.arrow_back_ios_new_rounded,
                  onTap: () => context.go('/results'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    result.title,
                    style: AppText.h3().copyWith(fontSize: 15.5),
                  ),
                ),
                RoundIconButton(icon: Icons.share_rounded, onTap: () {}),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 22),
              children: [
                RsCard(
                  clip: Clip.antiAlias,
                  child: Stack(
                    children: [
                      if (tab == 'render')
                        GeneratedRoomImage(result: result, height: 210)
                      else
                        FloorPlanView(layout: result.floorLayout, height: 210),
                      if (tuning)
                        Positioned.fill(
                          child: Container(
                            color: AppColors.surface.withValues(alpha: .8),
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: AppColors.teal,
                              ),
                            ),
                          ),
                        ),
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: .38),
                            borderRadius: BorderRadius.circular(AppRadii.pill),
                          ),
                          child: Row(
                            children: [
                              _OverlayTab(
                                label: 'Render',
                                selected: tab == 'render',
                                onTap: () => setState(() => tab = 'render'),
                              ),
                              _OverlayTab(
                                label: 'Top-down',
                                selected: tab == 'plan',
                                onTap: () => setState(() => tab = 'plan'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (project.modNote != null) ...[
                  const SizedBox(height: 12),
                  RsNotice(
                    text:
                        'Adjusted: "${project.modNote}". Updated render and steps below.',
                    icon: Icons.auto_awesome_rounded,
                  ),
                ],
                const SizedBox(height: 14),
                ResultMetaRow(result: result),
                const SizedBox(height: 14),
                Text(result.title, style: AppText.h1().copyWith(fontSize: 22)),
                const SectionLabel('Why this works'),
                Text(result.reason, style: AppText.body()),
                const SectionLabel('What changed'),
                RsCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      for (final change in result.changed)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.open_in_full_rounded,
                                size: 16,
                                color: AppColors.teal,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  change,
                                  style: AppText.sm(color: AppColors.ink),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _ProsConsCard(
                        title: 'Pros',
                        icon: Icons.check_rounded,
                        color: AppColors.ok,
                        items: result.pros,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ProsConsCard(
                        title: 'Trade-offs',
                        icon: Icons.info_outline_rounded,
                        color: AppColors.warmInk,
                        items: result.cons,
                      ),
                    ),
                  ],
                ),
                const SectionLabel('Respected as fixed'),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: [
                    for (final item in fixed)
                      RsBadge(
                        label: item.name,
                        icon: Icons.lock_rounded,
                        color: AppColors.warmInk,
                        background: AppColors.warmTint,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showModifySheet(BuildContext context, ProjectController controller) {
    final textController = TextEditingController();
    const quick = [
      'Make it more spacious',
      'Keep the sofa where it is',
      'Move the desk near the window',
      'Make it more modern',
      'Use only existing furniture',
    ];
    void apply(String text) {
      Navigator.pop(context);
      setState(() => tuning = true);
      Future<void>.delayed(const Duration(milliseconds: 1100), () {
        if (mounted) {
          controller.setModNote(text);
          setState(() => tuning = false);
        }
      });
    }

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.xl)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            18,
            8,
            18,
            18 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppColors.border2,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              Text('Ask AI to modify', style: AppText.h2()),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: textController,
                      decoration: InputDecoration(
                        hintText: 'e.g. add a reading corner',
                        filled: true,
                        fillColor: AppColors.surface2,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadii.r),
                          borderSide: const BorderSide(
                            color: AppColors.border2,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  RoundIconButton(
                    icon: Icons.arrow_forward_rounded,
                    color: AppColors.teal,
                    iconColor: Colors.white,
                    onTap: () {
                      if (textController.text.trim().isNotEmpty) {
                        apply(textController.text.trim());
                      }
                    },
                  ),
                ],
              ),
              const SectionLabel('Quick actions'),
              for (final action in quick) ...[
                RsCard(
                  padding: const EdgeInsets.all(13),
                  color: AppColors.surface2,
                  shadow: false,
                  onTap: () => apply(action),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.auto_awesome_rounded,
                        color: AppColors.teal,
                        size: 17,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          action,
                          style: AppText.sm(
                            color: AppColors.ink,
                            weight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _OverlayTab extends StatelessWidget {
  const _OverlayTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadii.pill),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadii.pill),
        ),
        child: Text(
          label,
          style: AppText.xs(
            color: selected ? AppColors.ink : Colors.white,
            weight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _ProsConsCard extends StatelessWidget {
  const _ProsConsCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.items,
  });

  final String title;
  final IconData icon;
  final Color color;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return RsCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: AppText.h3(color: color).copyWith(fontSize: 13.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Text(item, style: AppText.sm(color: AppColors.ink)),
            ),
        ],
      ),
    );
  }
}

class FinalPlanScreen extends ConsumerStatefulWidget {
  const FinalPlanScreen({super.key});

  @override
  ConsumerState<FinalPlanScreen> createState() => _FinalPlanScreenState();
}

class _FinalPlanScreenState extends ConsumerState<FinalPlanScreen> {
  final done = <int>{};
  bool after = true;

  @override
  Widget build(BuildContext context) {
    final result = selectedResult(ref.watch(projectControllerProvider));
    final progress = done.length / result.steps.length;
    return PageShell(
      bottom: BottomBar(
        child: Row(
          children: [
            Expanded(
              child: RsButton(
                label: '',
                icon: Icons.share_rounded,
                variant: RsButtonVariant.ghost,
                onPressed: () {},
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: RsButton(
                label: '',
                icon: Icons.download_rounded,
                variant: RsButtonVariant.ghost,
                onPressed: () {},
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              flex: 3,
              child: RsButton(
                label: 'Done',
                icon: Icons.check_rounded,
                onPressed: () => context.go('/home'),
              ),
            ),
          ],
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
            child: Row(
              children: [
                RoundIconButton(
                  icon: Icons.arrow_back_ios_new_rounded,
                  onTap: () => context.go('/layout/${result.id}'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Final plan - Step 7 of ${reshuffleSteps.length}',
                    style: AppText.xs(weight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          const RsStepper(steps: reshuffleSteps, current: 6),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 22),
              children: [
                Row(
                  children: [
                    const RsBadge(
                      label: 'Plan saved',
                      icon: Icons.check_rounded,
                      color: AppColors.ok,
                      background: AppColors.okTint,
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(result.title, style: AppText.sm())),
                  ],
                ),
                const SizedBox(height: 10),
                Text('Your move plan', style: AppText.h1()),
                const SizedBox(height: 14),
                RsCard(
                  clip: Clip.antiAlias,
                  child: Column(
                    children: [
                      if (after)
                        GeneratedRoomImage(result: result, height: 196)
                      else
                        const RoomScene(
                          layoutKey: 'livingA',
                          paletteKey: 'warm',
                          height: 196,
                        ),
                      Padding(
                        padding: const EdgeInsets.all(7),
                        child: Row(
                          children: [
                            Expanded(
                              child: RsButton(
                                label: 'Before',
                                compact: true,
                                variant: after
                                    ? RsButtonVariant.quiet
                                    : RsButtonVariant.soft,
                                onPressed: () => setState(() => after = false),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: RsButton(
                                label: 'After',
                                compact: true,
                                variant: after
                                    ? RsButtonVariant.soft
                                    : RsButtonVariant.quiet,
                                onPressed: () => setState(() => after = true),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                RsCard(
                  clip: Clip.antiAlias,
                  color: AppColors.surface2,
                  shadow: false,
                  child: FloorPlanView(layout: result.floorLayout, height: 196),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Moved items',
                        style: AppText.h2().copyWith(fontSize: 17),
                      ),
                    ),
                    Text(
                      '${result.movedItems.length}',
                      style: AppText.sm(
                        color: AppColors.teal,
                        weight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: [
                    for (final item in result.movedItems)
                      RsBadge(label: item, icon: Icons.open_in_full_rounded),
                    for (final item in result.unchangedItems)
                      RsBadge(
                        label: item,
                        icon: Icons.lock_rounded,
                        background: AppColors.surface3,
                        color: AppColors.ink2,
                      ),
                  ],
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Move checklist',
                        style: AppText.h2().copyWith(fontSize: 18),
                      ),
                    ),
                    Text(
                      '${done.length}/${result.steps.length}',
                      style: AppText.sm(
                        color: AppColors.teal,
                        weight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(99),
                  color: AppColors.teal,
                  backgroundColor: AppColors.surface3,
                ),
                const SizedBox(height: 14),
                for (var i = 0; i < result.steps.length; i++) ...[
                  ChecklistRow(
                    index: i,
                    text: result.steps[i],
                    done: done.contains(i),
                    onTap: () {
                      setState(
                        () => done.contains(i) ? done.remove(i) : done.add(i),
                      );
                    },
                  ),
                  const SizedBox(height: 9),
                ],
                const RsNotice(
                  text:
                      'Lift heavy items with help and check clearances for doors and outlets as you go.',
                  warn: true,
                  icon: Icons.warning_rounded,
                ),
                const SizedBox(height: 14),
                RsButton(
                  label: 'Save or export placeholder',
                  icon: Icons.download_rounded,
                  variant: RsButtonVariant.ghost,
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ChecklistRow extends StatelessWidget {
  const ChecklistRow({
    super.key,
    required this.index,
    required this.text,
    required this.done,
    required this.onTap,
  });

  final int index;
  final String text;
  final bool done;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return RsCard(
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: done ? AppColors.teal : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: done
                  ? null
                  : Border.all(color: AppColors.border2, width: 2),
            ),
            child: done
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 15)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${index + 1}. $text',
              style: AppText.sm(color: AppColors.ink).copyWith(
                decoration: done
                    ? TextDecoration.lineThrough
                    : TextDecoration.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class RedesignComingSoonScreen extends StatelessWidget {
  const RedesignComingSoonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PageShell(
      bottom: BottomBar(
        child: RsButton(
          label: 'Start reshuffle instead',
          icon: Icons.open_in_full_rounded,
          onPressed: () => context.go('/capture'),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                RoundIconButton(
                  icon: Icons.arrow_back_ios_new_rounded,
                  onTap: () => context.go('/mode'),
                ),
                const SizedBox(width: 12),
                const RsBadge(
                  label: 'Coming soon',
                  background: AppColors.warmTint,
                  color: AppColors.warmInk,
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
              children: [
                RsCard(
                  clip: Clip.antiAlias,
                  child: const RoomScene(
                    layoutKey: 'livingA',
                    paletteKey: 'warm',
                    height: 180,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Redesign mode is scaffolded for a later phase',
                  style: AppText.h1(),
                ),
                const SizedBox(height: 8),
                Text(
                  'The MVP keeps the trustworthy reshuffle pipeline focused. Product recommendations, exact measurements, shopping lists, AR and 3D editing come later.',
                  style: AppText.body(),
                ),
                const SectionLabel(
                  'Later backend and AI scope',
                  color: AppColors.warmInk,
                ),
                const RsNotice(
                  text:
                      'Future redesign outputs must label measurements as estimated unless a user corrects or calibrates them.',
                  warn: true,
                  icon: Icons.straighten_rounded,
                ),
                const SizedBox(height: 14),
                for (final item in const [
                  'Measurement review and calibration',
                  'Style, budget and store preferences',
                  'Fit-aware product cards',
                  'Shopping list and redesign setup plan',
                ])
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.schedule_rounded,
                          color: AppColors.warm,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            item,
                            style: AppText.sm(color: AppColors.ink),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NewProjectCta extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return RsCard(
      padding: const EdgeInsets.all(18),
      borderStyle: BorderStyle.solid,
      shadow: false,
      onTap: () => context.go('/mode'),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.add_rounded, color: AppColors.teal),
          const SizedBox(width: 9),
          Text(
            'New project',
            style: AppText.sm(
              color: AppColors.teal,
              weight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _RemoteProjectsList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(appAuthControllerProvider);
    if (auth.status != AppAuthStatus.authenticated) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: const [_SignInRequiredCard()],
      );
    }
    final async = ref.watch(remoteProjectsProvider);
    return async.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(color: AppColors.teal),
        ),
      ),
      error: (e, _) {
        final unauthorized = e is ApiException && e.isUnauthorized;
        if (unauthorized) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: const [_SignInRequiredCard()],
          );
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            RsCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Could not load projects',
                    style: AppText.h3(color: AppColors.danger),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    e is ApiException ? e.message : e.toString(),
                    style: AppText.xs(),
                  ),
                  const SizedBox(height: 12),
                  RsButton(
                    label: 'Retry',
                    icon: Icons.refresh_rounded,
                    variant: RsButtonVariant.soft,
                    compact: true,
                    expand: false,
                    onPressed: () => ref.invalidate(remoteProjectsProvider),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 11),
            _NewProjectCta(),
          ],
        );
      },
      data: (rows) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            if (rows.isEmpty)
              RsCard(
                padding: const EdgeInsets.all(22),
                child: Column(
                  children: [
                    Text('No projects yet', style: AppText.h3()),
                    const SizedBox(height: 4),
                    Text(
                      'Create your first reshuffle project to get started.',
                      style: AppText.sm(),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              for (final row in rows) ...[
                _RemoteProjectCard(row: row),
                const SizedBox(height: 11),
              ],
            const SizedBox(height: 4),
            _NewProjectCta(),
          ],
        );
      },
    );
  }
}

class _RemoteProjectCard extends StatelessWidget {
  const _RemoteProjectCard({required this.row});

  final Map<String, dynamic> row;

  @override
  Widget build(BuildContext context) {
    final name = row['name']?.toString() ?? 'Untitled';
    final mode = row['mode']?.toString() ?? 'reshuffle';
    final status = row['status']?.toString() ?? 'draft';
    return RsCard(
      padding: const EdgeInsets.all(13),
      onTap: () => context.go('/results'),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.tealTint,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.home_work_rounded,
              color: AppColors.tealInk,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppText.h3().copyWith(fontSize: 15.5)),
                const SizedBox(height: 4),
                Text('$mode • $status', style: AppText.xs()),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.ink3),
        ],
      ),
    );
  }
}

class _HomeRecentRemoteProjects extends ConsumerWidget {
  const _HomeRecentRemoteProjects({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(appAuthControllerProvider);
    if (auth.status != AppAuthStatus.authenticated) {
      return const _SignInRequiredCard();
    }
    final async = ref.watch(remoteProjectsProvider);
    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator(color: AppColors.teal)),
      ),
      error: (e, _) {
        final unauthorized = e is ApiException && e.isUnauthorized;
        if (unauthorized) return const _SignInRequiredCard();
        return RsCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Backend error',
                style: AppText.h3(color: AppColors.danger),
              ),
              const SizedBox(height: 6),
              Text(
                e is ApiException ? e.message : e.toString(),
                style: AppText.xs(),
              ),
              const SizedBox(height: 12),
              RsButton(
                label: 'Retry',
                icon: Icons.refresh_rounded,
                variant: RsButtonVariant.soft,
                compact: true,
                expand: false,
                onPressed: () => ref.invalidate(remoteProjectsProvider),
              ),
            ],
          ),
        );
      },
      data: (rows) {
        if (rows.isEmpty) {
          return RsCard(
            padding: const EdgeInsets.fromLTRB(22, 26, 22, 26),
            child: Column(
              children: [
                Text('No projects yet', style: AppText.h3()),
                const SizedBox(height: 4),
                Text(
                  'Start your first reshuffle to see it here.',
                  style: AppText.sm(),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 14),
                RsButton(
                  label: 'Start a project',
                  variant: RsButtonVariant.soft,
                  compact: true,
                  expand: false,
                  onPressed: onStart,
                ),
              ],
            ),
          );
        }
        return Column(
          children: [
            for (final row in rows.take(3)) ...[
              _RemoteProjectCard(row: row),
              const SizedBox(height: 11),
            ],
          ],
        );
      },
    );
  }
}

class _SignInRequiredCard extends StatelessWidget {
  const _SignInRequiredCard();

  @override
  Widget build(BuildContext context) {
    // Reachable only if the auth gate has a bug — under normal flow the
    // router redirects unauthenticated users to /login before any screen
    // backed by /projects gets built. Kept as a safety net.
    return RsCard(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lock_outline_rounded, color: AppColors.teal),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Sign in to view your projects', style: AppText.h3()),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Your projects live on the backend. Sign in to load them.',
            style: AppText.sm(),
          ),
          const SizedBox(height: 14),
          RsButton(
            label: 'Sign in',
            icon: Icons.login_rounded,
            onPressed: () => context.go('/login'),
          ),
        ],
      ),
    );
  }
}
