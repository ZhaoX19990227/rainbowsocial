import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rainbow_social_frontend/app.dart';

void main() {
  testWidgets('renders splash experience', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: RainbowSocialApp()));
    expect(find.text('Luminous'), findsOneWidget);
  });
}
