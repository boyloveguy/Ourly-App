import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:love_advisor/widgets/romantic_effects.dart';

void main() {
  group('OurlyAvatarView Initial Letter & Fallback Tests', () {
    test('getInitialLetter extracts strictly the single first letter (uppercase)', () {
      expect(OurlyAvatarView.getInitialLetter('Bé Chó'), 'B');
      expect(OurlyAvatarView.getInitialLetter('bé chó'), 'B');
      expect(OurlyAvatarView.getInitialLetter('Đạt'), 'Đ');
      expect(OurlyAvatarView.getInitialLetter('Ánh'), 'Á');
      expect(OurlyAvatarView.getInitialLetter('tinshpy119@gmail.com'), 'T');
      expect(OurlyAvatarView.getInitialLetter('   Nam   '), 'N');
      expect(OurlyAvatarView.getInitialLetter(''), 'U');
    });

    test('isEmoji accurately differentiates emojis from normal Vietnamese names', () {
      expect(OurlyAvatarView.isEmoji('🐶'), isTrue);
      expect(OurlyAvatarView.isEmoji('🌸'), isTrue);
      expect(OurlyAvatarView.isEmoji('💖'), isTrue);
      expect(OurlyAvatarView.isEmoji('✨'), isTrue);

      // Normal text should NOT be detected as emoji
      expect(OurlyAvatarView.isEmoji('Bé Chó'), isFalse);
      expect(OurlyAvatarView.isEmoji('Bé'), isFalse);
      expect(OurlyAvatarView.isEmoji('Đạt'), isFalse);
      expect(OurlyAvatarView.isEmoji('B'), isFalse);
      expect(OurlyAvatarView.isEmoji(''), isFalse);
    });

    testWidgets('OurlyAvatarView displays initial letter "B" and not "Bé" when avatar is null', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OurlyAvatarView(
              avatar: null,
              fallbackText: 'Bé Chó',
              size: 40,
            ),
          ),
        ),
      );

      // Must find single letter 'B'
      expect(find.text('B'), findsOneWidget);
      // Must NOT find 'Bé' or 'Bé Chó'
      expect(find.text('Bé'), findsNothing);
      expect(find.text('Bé Chó'), findsNothing);
    });

    testWidgets('OurlyAvatarView displays emoji avatar when avatar is an emoji', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OurlyAvatarView(
              avatar: '🐶',
              fallbackText: 'Bé Chó',
              size: 40,
            ),
          ),
        ),
      );

      expect(find.text('🐶'), findsOneWidget);
      expect(find.text('B'), findsNothing);
    });
  });
}
