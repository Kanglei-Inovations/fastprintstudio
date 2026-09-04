import 'package:flutter_test/flutter_test.dart';
import 'package:fastprintstudio/core/utils/unit_converter.dart';

void main() {
  group('UnitConverter Tests', () {
    test('mm to points conversion', () {
      // 25.4 mm = 1 inch = 72 points
      expect(UnitConverter.mmToPoints(25.4), closeTo(72.0, 0.001));

      // 4R paper: 101.6 mm = 4 inches = 288 points
      expect(UnitConverter.mmToPoints(101.6), closeTo(288.0, 0.001));

      // 4R height: 152.4 mm = 6 inches = 432 points
      expect(UnitConverter.mmToPoints(152.4), closeTo(432.0, 0.001));
    });

    test('points to mm conversion', () {
      expect(UnitConverter.pointsToMm(72.0), closeTo(25.4, 0.001));
      expect(UnitConverter.pointsToMm(288.0), closeTo(101.6, 0.001));
    });

    test('mm to pixels at 300 DPI', () {
      // 4R paper at 300 DPI: 4x6 in -> 1200 x 1800 px
      expect(UnitConverter.mmToPixels(101.6, 300), equals(1200));
      expect(UnitConverter.mmToPixels(152.4, 300), equals(1800));

      // Standard Passport 35x45mm at 300 DPI
      // (35 / 25.4) * 300 = 413.38 -> 413 px
      expect(UnitConverter.mmToPixels(35.0, 300), equals(413));
      // (45 / 25.4) * 300 = 531.49 -> 531 px
      expect(UnitConverter.mmToPixels(45.0, 300), equals(531));

      // Aadhaar Card 85.6x54mm at 300 DPI
      // (85.6 / 25.4) * 300 = 1011 px
      expect(UnitConverter.mmToPixels(85.6, 300), equals(1011));
      // (54 / 25.4) * 300 = 638 px
      expect(UnitConverter.mmToPixels(54.0, 300), equals(638));
    });

    test('format dimensions', () {
      expect(UnitConverter.formatDimensionsMm(35, 45), equals('35 × 45 mm'));
      expect(UnitConverter.formatDimensionsMm(85.6, 54), equals('85.6 × 54 mm'));
      expect(UnitConverter.formatDimensionsInches(101.6, 152.4), equals('4.0 × 6.0 in'));
    });
  });
}
