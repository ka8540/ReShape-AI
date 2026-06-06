import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Go back one step with a correct reverse (iOS-style pop) animation.
///
/// When there is a real back stack we [GoRouter.pop] so the current page slides
/// out to the right and the previous page is revealed underneath. Only when
/// there is genuinely nothing to pop (e.g. a deep link straight into a screen)
/// do we fall back to [GoRouter.go], which navigates to a sensible location.
///
/// Never use `context.go('/previous')` as a back action: `go` replaces the
/// stack and animates the destination in from the right like a *forward* push,
/// which is exactly the wrong direction for "back".
void safePop(BuildContext context, {String fallback = '/home'}) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go(fallback);
  }
}
