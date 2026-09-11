import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:love_advisor/screens/onboarding_step1_screen.dart';

void main() {
  testWidgets('OnboardingStep1Screen renders Birthday calendar field as readOnly', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OnboardingStep1Screen(
            onNext: () {},
            onSkipToHome: () {},
          ),
        ),
      ),
    );

    // Initial build and settle
    await tester.pump(const Duration(milliseconds: 500));

    // Verify Birthday label exists
    expect(find.text('NGÀY SINH'), findsOneWidget);

    // Verify Calendar Icon exists
    expect(find.byIcon(Icons.calendar_month_rounded), findsOneWidget);

    // Verify Hint text exists
    expect(find.text('Chọn ngày sinh từ lịch'), findsOneWidget);

    // Verify TextField has readOnly: true to prevent manual typing
    final textFieldFinder = find.ancestor(
      of: find.text('Chọn ngày sinh từ lịch'),
      matching: find.byType(TextField),
    );
    expect(textFieldFinder, findsOneWidget);
    final TextField textField = tester.widget(textFieldFinder);
    expect(textField.readOnly, isTrue);
  });
}
