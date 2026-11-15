import 'package:agrismart/analysis.dart';
import 'package:agrismart/engine/demo_data.dart';
import 'package:agrismart/engine/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('seasons are found in the record and every option is explained', () {
    final setup = FarmSetup()..patternIndex = -1;
    final weather = WeatherRecord(
        setup.lat, setup.lon, sampleWeather(seasonPatterns[0], 2006, 2025), true, 2006, 2025);
    expect(weather.detected.seasons.length, 2);
    setup.current = List.filled(weather.detected.rotationLength, 'Maize');
    final cards = Analysis(setup, weather).result().cards;
    expect(cards.first.isCurrent, isTrue);
    expect(cards.length, 3);
    for (final c in cards) {
      expect(c.reasons, isNotEmpty);
      expect(c.gaps, isNotEmpty);
      expect(c.total, inInclusiveRange(0, 1));
    }
  });

  test('a setup survives being saved and loaded', () {
    final s = FarmSetup()
      ..countryCode = 'KE'
      ..countryName = 'Kenya'
      ..lat = -1.29
      ..lon = 36.82
      ..ph = 6.1;
    final back = FarmSetup.fromJson(s.toJson());
    expect(back.countryCode, 'KE');
    expect(back.lat, -1.29);
    expect(back.ph, 6.1);
  });
}
