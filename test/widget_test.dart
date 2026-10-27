import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dada_flutter/main.dart';

void main() {
  testWidgets('DADA Flutter app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: DadaTranslatorApp(),
      ),
    );

    // Initial pump and frame
    expect(find.byType(DadaTranslatorApp), findsOneWidget);
  });
}
