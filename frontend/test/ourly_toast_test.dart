import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:love_advisor/widgets/ourly_toast.dart';

void main() {
  testWidgets('OurlyToast displays message with correct icon and text', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                OurlyToast.showSuccess(context, 'Đã lưu buổi hẹn thành công!');
              },
              child: const Text('Show Toast'),
            ),
          ),
        ),
      ),
    );

    // Tap button to trigger toast
    await tester.tap(find.text('Show Toast'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Đã lưu buổi hẹn thành công!'), findsOneWidget);

    // Settle dismiss timer
    await tester.pumpAndSettle(const Duration(seconds: 4));
  });

  testWidgets('OurlyToast.showLove displays love emoji/icon', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                OurlyToast.showLove(context, 'Đã lưu vào bộ sưu tập kỷ niệm! 💖');
              },
              child: const Text('Show Love Toast'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Show Love Toast'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Đã lưu vào bộ sưu tập kỷ niệm! 💖'), findsOneWidget);

    // Settle dismiss timer
    await tester.pumpAndSettle(const Duration(seconds: 4));
  });
}
