import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/main.dart';

void main() {
  testWidgets('FixaApp initialization smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const FixaApp());

    // Verify that our SplashScreen text is present.
    expect(find.text('Fixa Marketplace'), findsOneWidget);
    expect(find.text('Inicializando...'), findsOneWidget);

    // Permitimos que la temporización de redirección se complete para evitar fugas de timers en el test
    await tester.pump(const Duration(seconds: 3));
  });
}
