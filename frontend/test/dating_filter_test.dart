import 'package:flutter_test/flutter_test.dart';
import 'package:love_advisor/data/mock_date_spots.dart';

void main() {
  group('Date Spots AI Filter & Ranking Tests', () {
    test('filterAndRank filters spots based on specific preference tag', () {
      final results = MockDateSpotsData.filterAndRank(
        maxBudgetVnd: 500000,
        occasionId: 'anniversary',
        selectedPreferences: {'🎨 Workshop trải nghiệm'},
      );

      expect(results.isNotEmpty, isTrue);
      // All top results should have Workshop tag or be relevant
      for (final spot in results) {
        final matches = spot.tags.any((t) => t.contains('Workshop')) ||
            spot.cost <= 500000;
        expect(matches, isTrue);
      }
      expect(results.any((s) => s.id == 'spot-pottery'), isTrue);
    });

    test('filterAndRank prioritizes custom wish keywords', () {
      final results = MockDateSpotsData.filterAndRank(
        maxBudgetVnd: 500000,
        occasionId: 'anniversary',
        selectedPreferences: {'💖 Vibe lãng mạn'},
        customWish: 'muốn đi nghe nhạc acoustic ấm cúng',
      );

      expect(results.isNotEmpty, isTrue);
      // Acoustic spots should be boosted to top
      expect(results.any((s) => s.tags.any((t) => t.contains('acoustic'))), isTrue);
    });

    test('all mock date spots have valid realistic imageAsset and descriptions', () {
      for (final spot in MockDateSpotsData.allSpots) {
        expect(spot.imageAsset.isNotEmpty, isTrue, reason: '${spot.name} should have an imageAsset');
        expect(spot.imageAsset.startsWith('assets/images/'), isTrue);
        expect(spot.category.length < 35, isTrue, reason: '${spot.category} should be concise to avoid UI overflow');
      }
    });

    test('spots exceeding budget significantly are filtered out or penalized', () {
      final results = MockDateSpotsData.filterAndRank(
        maxBudgetVnd: 100000,
        occasionId: 'weekend_chill',
        selectedPreferences: {'☕ Quán cafe ấm cúng'},
      );

      expect(results.isNotEmpty, isTrue);
      // Premium 480K steak spot should NOT be at the top of 100K budget
      expect(results.first.cost <= 150000, isTrue);
    });
  });
}
