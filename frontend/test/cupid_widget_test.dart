import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:love_advisor/widgets/romantic_effects.dart';

void main() {
  testWidgets('WavingCupidWidget renders image asset and animates', (WidgetTester tester) async {
    bool tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: WavingCupidWidget(
              size: 40,
              animate: true,
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      ),
    );

    // Verify Image.asset exists
    expect(find.byType(Image), findsOneWidget);
    expect(find.byType(WavingCupidWidget), findsOneWidget);

    // Tap the Cupid widget
    await tester.tap(find.byType(WavingCupidWidget));
    expect(tapped, isTrue);

    // Pump frames to test animation
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 700));
  });
}
