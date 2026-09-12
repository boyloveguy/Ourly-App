import 'package:flutter_test/flutter_test.dart';
import 'package:love_advisor/models/user_mood.dart';
import 'package:love_advisor/services/api_service.dart';

void main() {
  test('UserMood default moods has 6 options and caring hints', () {
    final moods = UserMood.defaultMoods;
    expect(moods.length, 6);
    expect(moods.any((m) => m.id == 'happy'), isTrue);
    expect(moods.any((m) => m.id == 'need_hug'), isTrue);
    expect(moods.any((m) => m.id == 'busy'), isTrue);

    final busy = moods.firstWhere((m) => m.id == 'busy');
    expect(busy.partnerHint, contains('bận'));
  });

  test('ApiService saves and retrieves today mood correctly', () {
    final api = ApiService();
    expect(api.hasCheckedInToday(), isFalse);

    final mood = UserMood.defaultMoods.first;
    api.saveTodayMood(mood);

    expect(api.hasCheckedInToday(), isTrue);
    expect(api.getTodayUserMood()?.id, mood.id);
  });
}
