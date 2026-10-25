import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vava_translator/main.dart';

void main() {
  testWidgets('VAVA Translator app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: VavaTranslatorApp(),
      ),
    );

    // Initial pump and frame
    expect(find.byType(VavaTranslatorApp), findsOneWidget);
  });
}
