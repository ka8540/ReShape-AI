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
  Timer? _anim;
  Timer? _poll;
  double progress = .04;
  bool _navigated = false;
  bool _backendReady = false;

  bool get _backendMode =>
      !useMockData &&
      ref.read(projectControllerProvider).remoteProjectId != null;

  @override
  void initState() {
    super.initState();
    final backend = _backendMode;
    // Visual progress animation.
    _anim = Timer.periodic(const Duration(milliseconds: 240), (_) {
      if (!mounted) return;
      setState(() => progress = (progress + .045).clamp(0, 1));
      // Mock flow: drive entirely off the animation. Backend flow: advance once
      // the server reports items are ready (with the animation as a floor).
      if (!backend && progress >= 1) {
        _go();
      } else if (backend && _backendReady && progress >= 1) {
        _go();
      }
    });
    if (backend) {
      // Poll the real processing status; detection usually finished during
      // /media/complete, so this resolves quickly.
      _poll = Timer.periodic(
        const Duration(milliseconds: 700),
        (_) => _checkStatus(),
      );
      // Safety net so we never hang on this screen.
      Future<void>.delayed(const Duration(seconds: 10), () {
        if (mounted) _go();
      });
    }
  }

  Future<void> _checkStatus() async {
    final projectId = ref.read(projectControllerProvider).remoteProjectId;
    if (projectId == null) return;
    try {
      final res = await ref
          .read(apiServiceProvider)
          .processingStatus(projectId);
      if (_reviewReady((res['status'] ?? '').toString())) {
        _backendReady = true;
        // Keep a minimum on-screen time so the animation doesn't flash by.
        if (progress >= .5) _go();
      }
    } catch (_) {
      // Transient errors: keep polling; the safety-net timer still applies.
    }
  }

  static bool _reviewReady(String status) => const {
    'awaiting_user_review',
    'ready',
    'review',
    'detected',
    'completed',
    'complete',
  }.contains(status);

  void _go() {
    if (_navigated || !mounted) return;
    _navigated = true;
    _anim?.cancel();
    _poll?.cancel();
    context.go('/review');
  }

  @override
  void dispose() {
    _anim?.cancel();
    _poll?.cancel();
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

class ReviewItemsScreen extends ConsumerStatefulWidget {
  const ReviewItemsScreen({super.key});

  @override
  ConsumerState<ReviewItemsScreen> createState() => _ReviewItemsScreenState();
}

class _ReviewItemsScreenState extends ConsumerState<ReviewItemsScreen> {
  bool _loading = false;

  /// True when we should talk to the backend rather than the local mock state.
  bool get _backendMode =>
      !useMockData &&
      ref.read(projectControllerProvider).remoteProjectId != null;

  @override
  void initState() {
    super.initState();
    // Fetch the items the backend detected during processing.
    if (_backendMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
    }
  }

  Future<void> _refresh() async {
    final projectId = ref.read(projectControllerProvider).remoteProjectId;
    if (projectId == null) return;
    setState(() => _loading = true);
    try {
      final rows = await ref.read(apiServiceProvider).listItems(projectId);
      ref
          .read(projectControllerProvider.notifier)
          .setItems(rows.map(DetectedItem.fromJson).toList());
    } catch (e) {
      _snack('Could not load items: ${_msg(e)}');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _retryProcessing() async {
    final projectId = ref.read(projectControllerProvider).remoteProjectId;
    if (projectId == null) return;
    setState(() => _loading = true);
    try {
      await ref.read(apiServiceProvider).retryProcessing(projectId);
    } catch (_) {
      // Surface the failure via the follow-up refresh / empty state.
    }
    await _refresh();
  }

  Future<void> _delete(DetectedItem item) async {
    final notifier = ref.read(projectControllerProvider.notifier);
    if (!_backendMode) {
      notifier.deleteItem(item.id);
      return;
    }
    final projectId = ref.read(projectControllerProvider).remoteProjectId!;
    notifier.deleteItem(item.id); // optimistic removal
    try {
      await ref
          .read(apiServiceProvider)
          .deleteItem(projectId: projectId, itemId: item.id);
    } catch (e) {
      await _refresh(); // restore server truth
      _snack('Could not delete ${item.name}: ${_msg(e)}');
    }
  }

  Future<void> _setFixed(DetectedItem item, bool fixed) async {
    final notifier = ref.read(projectControllerProvider.notifier);
    notifier.toggleFixed(item.id, fixed); // optimistic
    if (!_backendMode) return;
    final projectId = ref.read(projectControllerProvider).remoteProjectId!;
    try {
      await ref.read(apiServiceProvider).patchItem(
        projectId: projectId,
        itemId: item.id,
        changes: {'fixed': fixed},
      );
    } catch (e) {
      notifier.toggleFixed(item.id, !fixed); // revert
      _snack('Could not update ${item.name}: ${_msg(e)}');
    }
  }

  Future<void> _rename(DetectedItem item, String name) async {
    final notifier = ref.read(projectControllerProvider.notifier);
    notifier.renameItem(item.id, name); // optimistic
    if (!_backendMode) return;
    final projectId = ref.read(projectControllerProvider).remoteProjectId!;
    try {
      await ref.read(apiServiceProvider).patchItem(
        projectId: projectId,
        itemId: item.id,
        changes: {'name': name},
      );
    } catch (e) {
      await _refresh();
      _snack('Could not rename item: ${_msg(e)}');
    }
  }

  Future<void> _add(String name) async {
    final notifier = ref.read(projectControllerProvider.notifier);
    if (!_backendMode) {
      notifier.addItem(name);
      return;
    }
    final projectId = ref.read(projectControllerProvider).remoteProjectId!;
    try {
      await ref.read(apiServiceProvider).createItem(
        projectId: projectId,
        name: name,
        type: name.toLowerCase().split(' ').first,
      );
      await _refresh();
    } catch (e) {
      _snack('Could not add $name: ${_msg(e)}');
    }
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _msg(Object e) => e is ApiException ? e.message : '$e';

  @override
  Widget build(BuildContext context) {
    final project = ref.watch(projectControllerProvider);
    final furniture = project.items.where((item) => !item.structural).toList();
    final structure = project.items.where((item) => item.structural).toList();
    final fixedCount = furniture.where((item) => item.fixed).length;
    final isEmpty = project.items.isEmpty;
    final showLoader = _loading && isEmpty;

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
            child: showLoader
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.teal),
                  )
                : RefreshIndicator(
                    onRefresh: _backendMode ? _refresh : () async {},
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
                        if (isEmpty) ...[
                          const SizedBox(height: 14),
                          _EmptyItemsCard(
                            onRetry: _backendMode ? _retryProcessing : null,
                            onAdd: () => _showAddItemSheet(context),
                          ),
                        ] else ...[
                          const SectionLabel('Furniture and objects'),
                          for (final item in furniture) ...[
                            ItemReviewCard(
                              item: item,
                              onSetFixed: (fixed) => _setFixed(item, fixed),
                              onDelete: () => _delete(item),
                              onRename: (name) => _rename(item, name),
                            ),
                            const SizedBox(height: 10),
                          ],
                          RsCard(
                            padding: const EdgeInsets.all(15),
                            shadow: false,
                            onTap: () => _showAddItemSheet(context),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.add_rounded,
                                  color: AppColors.teal,
                                ),
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
                          if (structure.isNotEmpty) ...[
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
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 10,
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 36,
                                            height: 36,
                                            decoration: BoxDecoration(
                                              color: AppColors.surface3,
                                              borderRadius:
                                                  BorderRadius.circular(10),
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
                                              style: AppText.h3().copyWith(
                                                fontSize: 14.5,
                                              ),
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
                        ],
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _showAddItemSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.xl)),
      ),
      builder: (sheetContext) {
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
                          Navigator.pop(sheetContext);
                          _add(item);
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

class _EmptyItemsCard extends StatelessWidget {
  const _EmptyItemsCard({this.onRetry, required this.onAdd});

  final VoidCallback? onRetry;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return RsCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.tealTint,
              borderRadius: BorderRadius.circular(17),
            ),
            child: const Icon(Icons.search_off_rounded, color: AppColors.teal),
          ),
          const SizedBox(height: 14),
          Text('No items detected', style: AppText.h3()),
          const SizedBox(height: 5),
          Text(
            'Add items manually or retry the scan.',
            style: AppText.sm(),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          RsButton(
            label: 'Add missing item',
            icon: Icons.add_rounded,
            onPressed: onAdd,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 4),
            RsButton(
              label: 'Retry processing',
              icon: Icons.refresh_rounded,
              variant: RsButtonVariant.quiet,
              onPressed: onRetry,
            ),
          ],
        ],
      ),
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

class ItemReviewCard extends StatelessWidget {
  const ItemReviewCard({
    super.key,
    required this.item,
    required this.onSetFixed,
    required this.onDelete,
    required this.onRename,
  });

  final DetectedItem item;
  final ValueChanged<bool> onSetFixed;
  final VoidCallback onDelete;
  final ValueChanged<String> onRename;

  @override
  Widget build(BuildContext context) {
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
                onPressed: () => _rename(context),
                icon: const Icon(
                  Icons.edit_rounded,
                  color: AppColors.ink2,
                  size: 18,
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: onDelete,
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
                    onTap: () => onSetFixed(false),
                  ),
                ),
                Expanded(
                  child: _SegmentButton(
                    label: 'Fixed',
                    icon: Icons.lock_rounded,
                    selected: item.fixed,
                    warm: true,
                    onTap: () => onSetFixed(true),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _rename(BuildContext context) async {
    final textController = TextEditingController(text: item.name);
    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Rename item'),
        content: TextField(controller: textController, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, textController.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (value != null && value.trim().isNotEmpty) {
      onRename(value.trim());
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
    // The Results screen owns the generation lifecycle (request → poll →
    // fetch designs), so we just navigate there and let it show the loading
    // state and call POST /generate-layouts when there are no designs yet.
    setState(() => generating = true);
    context.go('/results');
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

enum _ResultsPhase { loading, generating, ready, empty, failed }

/// Step 6 — shows the actual generated layout image(s) for this project.
/// No mock gallery, tabs, fake names, percentages or mini-maps: it renders the
/// real designs the backend returned, or an honest loading/empty/error state.
class ResultsScreen extends ConsumerStatefulWidget {
  const ResultsScreen({super.key});

  @override
  ConsumerState<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends ConsumerState<ResultsScreen> {
  _ResultsPhase _phase = _ResultsPhase.loading;
  String? _error;
  String? _selectedId;
  bool _autoGenerated = false;
  bool _busy = false;
  Timer? _poll;
  int _pollCount = 0;
  static const _maxPolls = 6;

  bool get _backendMode =>
      !useMockData &&
      ref.read(projectControllerProvider).remoteProjectId != null;

  String get _projectId => ref.read(projectControllerProvider).remoteProjectId!;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_backendMode) {
        _load(initial: true);
      } else {
        _loadMock();
      }
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  /// Design-pass mode only: clearly-labelled sample layouts (never in real mode).
  void _loadMock() {
    final views = [
      for (final r in results)
        GeneratedDesignView(
          id: '${r.id}',
          status: 'succeeded',
          imageUrl: r.imageUrl,
        ),
    ];
    ref.read(projectControllerProvider.notifier).setDesigns(views);
    setState(() {
      _selectedId = views.isNotEmpty ? views.first.id : null;
      _phase = views.isEmpty ? _ResultsPhase.empty : _ResultsPhase.ready;
    });
  }

  Future<void> _load({bool initial = false}) async {
    if (_busy) return;
    _busy = true;
    if (initial) setState(() => _phase = _ResultsPhase.loading);
    try {
      final api = ref.read(apiServiceProvider);
      final rows = await api.listDesigns(_projectId);

      if (rows.isEmpty) {
        if (!_autoGenerated) {
          _autoGenerated = true;
          _busy = false;
          await _generate();
          return;
        }
        ref.read(projectControllerProvider.notifier).setDesigns(const []);
        setState(() => _phase = _ResultsPhase.empty);
        return;
      }

      final views = <GeneratedDesignView>[];
      var anyReady = false;
      var anyPending = false;
      String? failureMessage;
      for (final row in rows) {
        final status = (row['generation_status'] ?? '').toString();
        if (status == 'succeeded') {
          String? url;
          try {
            final detail = await api.getDesign(
              projectId: _projectId,
              designId: (row['id'] ?? '').toString(),
            );
            url = detail['output_read_url']?.toString();
          } catch (_) {
            // fall through; treated as not-yet-ready below
          }
          final view = GeneratedDesignView.fromJson(row, imageUrl: url);
          if (view.imageUrl != null) anyReady = true;
          views.add(view);
        } else {
          final view = GeneratedDesignView.fromJson(row);
          if (view.isPending) anyPending = true;
          if (view.isFailed) failureMessage = view.errorMessage ?? failureMessage;
          views.add(view);
        }
      }
      ref.read(projectControllerProvider.notifier).setDesigns(views);

      if (anyReady) {
        _stopPolling();
        setState(() {
          _selectedId ??= views.firstWhere((v) => v.imageUrl != null).id;
          _phase = _ResultsPhase.ready;
        });
      } else if (anyPending && _pollCount < _maxPolls) {
        setState(() => _phase = _ResultsPhase.generating);
        _schedulePoll();
      } else if (failureMessage != null && !anyPending) {
        _stopPolling();
        setState(() {
          _error = failureMessage;
          _phase = _ResultsPhase.failed;
        });
      } else {
        // No image came back (generation still queued past the poll budget, or
        // not wired). Show an honest empty state — never fabricate a result.
        _stopPolling();
        setState(() => _phase = _ResultsPhase.empty);
      }
    } catch (e) {
      _stopPolling();
      setState(() {
        _error = e is ApiException ? e.message : '$e';
        _phase = _ResultsPhase.failed;
      });
    } finally {
      _busy = false;
    }
  }

  void _schedulePoll() {
    _poll?.cancel();
    _poll = Timer(const Duration(milliseconds: 1500), () {
      _pollCount++;
      _load();
    });
  }

  void _stopPolling() {
    _poll?.cancel();
    _poll = null;
  }

  Future<void> _generate() async {
    setState(() {
      _phase = _ResultsPhase.generating;
      _error = null;
    });
    try {
      await ref
          .read(apiServiceProvider)
          .generateLayouts(projectId: _projectId, variants: 2);
    } catch (e) {
      setState(() {
        _error = e is ApiException ? e.message : '$e';
        _phase = _ResultsPhase.failed;
      });
      return;
    }
    _pollCount = 0;
    await _load();
  }

  Future<void> _regenerate() async {
    _autoGenerated = true;
    _selectedId = null;
    await _generate();
  }

  Future<void> _useSelected() async {
    final id = _selectedId;
    if (id == null) return;
    final notifier = ref.read(projectControllerProvider.notifier);
    if (_backendMode) {
      try {
        await ref
            .read(apiServiceProvider)
            .selectDesign(projectId: _projectId, designId: id);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not select layout: ${e is ApiException ? e.message : e}',
            ),
          ),
        );
        return;
      }
    }
    notifier.setSelectedDesign(id);
    if (mounted) context.go('/final');
  }

  @override
  Widget build(BuildContext context) {
    final designs = ref.watch(
      projectControllerProvider.select((s) => s.designs),
    );
    final ready = designs.where((d) => d.imageUrl != null).toList();
    return PageShell(
      bottom: _phase == _ResultsPhase.ready
          ? BottomBar(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RsButton(
                    label: 'Use this layout',
                    icon: Icons.arrow_forward_rounded,
                    onPressed: _selectedId == null ? null : _useSelected,
                  ),
                  if (_backendMode) ...[
                    const SizedBox(height: 4),
                    RsButton(
                      label: 'Regenerate',
                      variant: RsButtonVariant.quiet,
                      onPressed: _regenerate,
                    ),
                  ],
                ],
              ),
            )
          : null,
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
                if (_backendMode)
                  RoundIconButton(
                    icon: Icons.refresh_rounded,
                    onTap: _regenerate,
                  ),
              ],
            ),
          ),
          const RsStepper(steps: reshuffleSteps, current: 5),
          Expanded(child: _body(ready)),
        ],
      ),
    );
  }

  Widget _body(List<GeneratedDesignView> ready) {
    switch (_phase) {
      case _ResultsPhase.loading:
      case _ResultsPhase.generating:
        return _ResultsLoading(
          message: _phase == _ResultsPhase.generating
              ? 'Generating your room layout…'
              : 'Loading your layouts…',
        );
      case _ResultsPhase.failed:
        return _ResultsMessage(
          icon: Icons.error_outline_rounded,
          title: 'Generation failed',
          body: _error ?? 'Something went wrong while generating layouts.',
          actionLabel: _backendMode ? 'Try again' : null,
          onAction: _backendMode ? _regenerate : null,
        );
      case _ResultsPhase.empty:
        return _ResultsMessage(
          icon: Icons.image_not_supported_outlined,
          title: 'No layouts yet',
          body: _backendMode
              ? 'No generated layout was returned from the backend yet. '
                    'Generation may still be running or is not available.'
              : 'No layouts to show.',
          actionLabel: _backendMode ? 'Regenerate' : null,
          onAction: _backendMode ? _regenerate : null,
        );
      case _ResultsPhase.ready:
        return _readyBody(ready);
    }
  }

  Widget _readyBody(List<GeneratedDesignView> ready) {
    final match = ready.where((d) => d.id == _selectedId).toList();
    final hero = match.isNotEmpty ? match.first : ready.first;
    final heroIndex = ready.indexOf(hero);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Text('Generated layouts', style: AppText.h1().copyWith(fontSize: 24)),
        const SizedBox(height: 3),
        Text('Choose the layout you want to use.', style: AppText.sm()),
        if (!_backendMode) ...[
          const SizedBox(height: 8),
          const RsBadge(label: 'Sample data (mock mode)'),
        ],
        const SizedBox(height: 14),
        RsCard(
          clip: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DesignImage(url: hero.imageUrl!, height: 280),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Text('Layout ${heroIndex + 1}', style: AppText.h3()),
              ),
            ],
          ),
        ),
        if (ready.length > 1) ...[
          const SizedBox(height: 14),
          SizedBox(
            height: 92,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: ready.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, i) {
                final design = ready[i];
                final isSel = design.id == hero.id;
                return GestureDetector(
                  onTap: () => setState(() => _selectedId = design.id),
                  child: Container(
                    width: 124,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSel ? AppColors.teal : AppColors.border,
                        width: isSel ? 2.5 : 1,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _DesignImage(url: design.imageUrl!, height: 92),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

class _ResultsLoading extends StatelessWidget {
  const _ResultsLoading({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppColors.teal),
          const SizedBox(height: 16),
          Text(message, style: AppText.h3(), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _ResultsMessage extends StatelessWidget {
  const _ResultsMessage({
    required this.icon,
    required this.title,
    required this.body,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.surface3,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, color: AppColors.ink3, size: 30),
            ),
            const SizedBox(height: 16),
            Text(title, style: AppText.h2(), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(body, style: AppText.sm(), textAlign: TextAlign.center),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 18),
              RsButton(
                label: actionLabel!,
                icon: Icons.refresh_rounded,
                expand: false,
                onPressed: onAction,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DesignImage extends StatelessWidget {
  const _DesignImage({required this.url, required this.height});

  final String url;
  final double height;

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: url,
      height: height,
      width: double.infinity,
      fit: BoxFit.cover,
      placeholder: (_, _) => Container(
        height: height,
        color: AppColors.surface3,
        alignment: Alignment.center,
        child: const CircularProgressIndicator(color: AppColors.teal),
      ),
      errorWidget: (_, _, _) => Container(
        height: height,
        color: AppColors.surface3,
        alignment: Alignment.center,
        child: const Icon(Icons.broken_image_rounded, color: AppColors.ink3),
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
    final project = ref.watch(projectControllerProvider);
    final result = selectedResult(project);
    final progress = done.length / result.steps.length;
    // Use the real generated image of the layout the user selected, if any.
    final selectedDesigns = project.designs
        .where((d) => d.id == project.selectedDesignId && d.imageUrl != null)
        .toList();
    final selectedImageUrl = selectedDesigns.isNotEmpty
        ? selectedDesigns.first.imageUrl
        : null;
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
                        (selectedImageUrl != null
                            ? _DesignImage(url: selectedImageUrl, height: 196)
                            : GeneratedRoomImage(result: result, height: 196))
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
