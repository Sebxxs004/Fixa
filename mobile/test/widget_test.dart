import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/main.dart';

void main() {
  testWidgets('FixaApp initialization smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const FixaApp());

    // Verify that our SplashScreen text is present.
    expect(find.text('Fixa Marketplace'), findsOneWidget);
    expect(find.text('Inicializando...'), findsOneWidget);
  });
}
