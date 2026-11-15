// Prints results without the UI:  dart run tool/check.dart
import 'package:agrismart/analysis.dart';
import 'package:agrismart/engine/demo_data.dart';
import 'package:agrismart/engine/models.dart';
import 'package:agrismart/engine/scoring.dart';

void main() {
  for (var pi = 0; pi <= seasonPatterns.length; pi++) {
    for (final budget in [0, 2]) {
      final setup = FarmSetup()
        ..patternIndex = pi - 1 // -1 = detect seasons from the rain record
        ..budget = budget
        ..soilType = 'Sandy loam';
      final sw = Stopwatch()..start();
      final weather = WeatherRecord(setup.lat, setup.lon,
          sampleWeather(seasonPatterns[pi == 0 ? 0 : pi - 1], 2006, 2025), true, 2006, 2025);
      final n = weather.patternFor(setup).rotationLength;
      if (n == 3) setup.current = ['Maize', 'Maize', 'Beans'];
      final a = Analysis(setup, weather);
      final summary = a.summary;
      print('\n=== ${a.pattern.label} | budget ${budgetLabels[budget]} (${sw.elapsedMilliseconds} ms)');
      summary.forEach((k, s) => print('$k: rain ${s.rain.toStringAsFixed(0)} len ${s.length.toStringAsFixed(0)} t ${s.tmean.toStringAsFixed(1)} trend ${s.rainTrend.toStringAsFixed(0)}'));
      final e = a.result().engine;
      print('fits: ${[for (final c in rotationCrops) '${c.name} ${e.fit(Planting(c, 0, e.usedSlots(c))).fit.toStringAsFixed(2)}'].join(', ')}');
      for (var s = 0; s < scenarios.length; s++) {
        print('-- ${scenarios[s].label}');
        for (final c in a.result(s).cards) {
          print('${c.tag.padRight(3)} ${(c.total * 100).toStringAsFixed(0).padLeft(3)}  ${c.detail.names}  ${c.detail.scores.map((k, v) => MapEntry(k, (v * 100).round()))} pest ${c.detail.pestBreaks} bare ${c.detail.bareMonths}');
        }
      }
      if (pi == 0 && budget == 0) print(a.result().cards[1].toText());
    }
  }
}
