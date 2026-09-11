import 'package:flutter_test/flutter_test.dart';
import 'package:love_advisor/widgets/ourly_date_picker.dart';

void main() {
  group('OurlyDatePicker Tests', () {
    test('formatDate formats DateTime to dd/MM/yyyy', () {
      final date = DateTime(2000, 8, 15);
      expect(OurlyDatePicker.formatDate(date), '15/08/2000');

      final date2 = DateTime(1995, 1, 5);
      expect(OurlyDatePicker.formatDate(date2), '05/01/1995');
    });

    test('parseDate correctly parses dd/MM/yyyy and other formats', () {
      final d1 = OurlyDatePicker.parseDate('15/08/2000');
      expect(d1, isNotNull);
      expect(d1!.day, 15);
      expect(d1.month, 8);
      expect(d1.year, 2000);

      final d2 = OurlyDatePicker.parseDate('01-05-1998');
      expect(d2, isNotNull);
      expect(d2!.day, 1);
      expect(d2.month, 5);
      expect(d2.year, 1998);

      final d3 = OurlyDatePicker.parseDate('2001-12-25');
      expect(d3, isNotNull);
      expect(d3!.day, 25);
      expect(d3.month, 12);
      expect(d3.year, 2001);

      // Invalid formats return null
      expect(OurlyDatePicker.parseDate('invalid-date'), isNull);
      expect(OurlyDatePicker.parseDate(''), isNull);
      expect(OurlyDatePicker.parseDate(null), isNull);
    });
  });
}
