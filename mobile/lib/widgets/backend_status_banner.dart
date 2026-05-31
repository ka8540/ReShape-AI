import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/api_config.dart';
import '../state/backend_health.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';

/// Compact banner that surfaces backend reachability + mock-data mode.
/// Renders nothing once the backend is reachable and we're not in mock mode,
/// so production builds stay clean.
class BackendStatusBanner extends ConsumerWidget {
  const BackendStatusBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reachable = ref.watch(backendReachableProvider);
    final inMock = useMockData;

    final isReachable = reachable.maybeWhen(
      data: (v) => v,
      orElse: () => null,
    );

    if (!inMock && isReachable == true) return const SizedBox.shrink();

    final (label, color, icon) = _resolve(inMock: inMock, reachable: isReachable);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: AppText.xs(color: color, weight: FontWeight.w700),
            ),
          ),
          Text(apiBaseUrl, style: AppText.xs(color: AppColors.ink3)),
        ],
      ),
    );
  }

  (String, Color, IconData) _resolve({
    required bool inMock,
    required bool? reachable,
  }) {
    if (reachable == false) {
      return (
        'Backend unreachable — running with mock data',
        AppColors.warn,
        Icons.cloud_off_rounded,
      );
    }
    if (reachable == null) {
      return ('Checking backend…', AppColors.ink3, Icons.sync_rounded);
    }
    if (inMock) {
      return (
        'Mock-data mode (USE_MOCK_DATA=true)',
        AppColors.warn,
        Icons.science_rounded,
      );
    }
    return ('Backend connected', AppColors.ok, Icons.cloud_done_rounded);
  }
}
