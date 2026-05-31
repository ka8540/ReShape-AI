import 'package:flutter_test/flutter_test.dart';

import 'package:respace_ai/main.dart';
import 'package:respace_ai/services/firebase_bootstrap.dart';

void main() {
  testWidgets(
    'login screen renders when Firebase is not configured',
    (tester) async {
      await tester.pumpWidget(
        const ReSpaceBootstrap(
          firebase: FirebaseBootstrapResult(FirebaseStatus.disabled),
        ),
      );
      await tester.pump();

      expect(find.text('Welcome'), findsOneWidget);
      expect(find.textContaining('disabled'), findsWidgets);
    },
  );
}
