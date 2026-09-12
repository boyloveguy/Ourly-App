import 'package:flutter_test/flutter_test.dart';
import 'package:love_advisor/services/api_service.dart';

void main() {
  group('Dating Start Date & Days Together Tests', () {
    late ApiService apiService;

    setUp(() {
      apiService = ApiService();
      apiService.clearDatingStartDate();
    });

    test('default dating start date is null and days together is null', () {
      expect(apiService.getDatingStartDate(), isNull);
      expect(apiService.getDaysTogether(), isNull);
      expect(apiService.hasDatingStartDate, isFalse);
    });

    test('setting a new dating start date updates days together correctly', () {
      final now = DateTime.now();
      final oneHundredDaysAgo = now.subtract(const Duration(days: 100));
      apiService.setDatingStartDate(oneHundredDaysAgo);

      expect(apiService.hasDatingStartDate, isTrue);
      expect(apiService.getDaysTogether(), 100);
      expect(apiService.getDatingStartDate()!.year, oneHundredDaysAgo.year);
      expect(apiService.getDatingStartDate()!.month, oneHundredDaysAgo.month);
      expect(apiService.getDatingStartDate()!.day, oneHundredDaysAgo.day);
    });

    test('setting today as dating start date returns 1 day', () {
      apiService.setDatingStartDate(DateTime.now());
      expect(apiService.getDaysTogether(), 1);
    });

    test('setting future date returns at least 1 day', () {
      apiService.setDatingStartDate(DateTime.now().add(const Duration(days: 10)));
      expect(apiService.getDaysTogether(), 1);
    });

    test('clearing dating start date resets to null', () {
      apiService.setDatingStartDate(DateTime.now().subtract(const Duration(days: 50)));
      expect(apiService.getDaysTogether(), 50);

      apiService.clearDatingStartDate();
      expect(apiService.getDatingStartDate(), isNull);
      expect(apiService.getDaysTogether(), isNull);
      expect(apiService.hasDatingStartDate, isFalse);
    });
  });
}
