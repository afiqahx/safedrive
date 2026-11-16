import 'package:flutter_test/flutter_test.dart';

import 'package:safedrive/main.dart';

void main() {
  testWidgets('login screen displays the app branding and actions', (tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('BLINK'), findsOneWidget);
    expect(find.text('Welcome Back!'), findsOneWidget);
    expect(find.text('LOG IN'), findsOneWidget);
  });
}
