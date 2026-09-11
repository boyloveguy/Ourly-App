import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:love_advisor/screens/onboarding_step2_screen.dart';
import 'package:love_advisor/widgets/romantic_effects.dart';

void main() {
  testWidgets('OnboardingStep2Screen centers heart icon between the two avatars', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        home: OnboardingStep2Screen(
          onEnterSpace: () {},
          onBack: () {},
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 300));

    // Verify User A avatar and Partner placeholder avatar exist
    final avatars = find.byType(OurlyAvatarView);
    expect(avatars, findsNWidgets(2));

    // Verify Heart icon exists
    final heart = find.text('💞');
    expect(heart, findsOneWidget);

    // Get positions of Left Avatar, Heart, and Right Avatar
    final leftAvatarBox = tester.getRect(avatars.first);
    final rightAvatarBox = tester.getRect(avatars.last);
    final heartBox = tester.getRect(heart);

    // Verify Vertical Alignment:
    // The vertical center of the heart must match the vertical center of the avatar circles within 1px
    expect(
      (heartBox.center.dy - leftAvatarBox.center.dy).abs(),
      lessThan(2.0),
      reason: 'Heart center Y (${heartBox.center.dy}) must match Avatar center Y (${leftAvatarBox.center.dy})',
    );

    // Verify Horizontal Symmetry:
    // Distance from Left Avatar center to Heart center must equal distance from Heart center to Right Avatar center
    final distLeftToHeart = heartBox.center.dx - leftAvatarBox.center.dx;
    final distHeartToRight = rightAvatarBox.center.dx - heartBox.center.dx;
    expect(
      (distLeftToHeart - distHeartToRight).abs(),
      lessThan(1.0),
      reason: 'Distance from left avatar to heart ($distLeftToHeart) must equal distance from heart to right avatar ($distHeartToRight)',
    );
  });
}
