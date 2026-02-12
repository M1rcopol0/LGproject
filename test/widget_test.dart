import 'package:flutter_test/flutter_test.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:fluffer/globals.dart';
import 'package:fluffer/main.dart';

void main() {
  setUp(() {
    // Initialisation minimale identique à main()
    globalTalker = TalkerFlutter.init(
      settings: TalkerSettings(
        maxHistoryItems: 100,
        useConsoleLogs: false,
      ),
    );
  });

  testWidgets('LoupGarouApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const LoupGarouApp());
    await tester.pump();

    // Vérifie que l'app se lance sans crash
    expect(find.byType(LoupGarouApp), findsOneWidget);
  });
}
