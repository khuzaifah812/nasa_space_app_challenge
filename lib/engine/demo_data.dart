// Simulated weather so the app can be shown without internet.
// It is NOT real data and the app says so on screen.
import 'dart:math';

import 'models.dart';

List<DayRecord> sampleWeather(SeasonPattern pattern, int startYear, int endYear) {
  final rng = Random(7);
  final wetMonths = <int>{};
  for (final s in pattern.seasons) {
    var m = s.startMonth;
    while (true) {
      wetMonths.add(m);
      if (m == s.endMonth) break;
      m = m % 12 + 1;
    }
  }
  // spread a similar yearly total over however many wet months there are
  final meanWetDay = 9.5 * 6 / wetMonths.length;
  final days = <DayRecord>[];
  var d = DateTime.utc(startYear, 1, 1);
  final end = DateTime.utc(endYear, 12, 31);
  while (!d.isAfter(end)) {
    final wetSeason = wetMonths.contains(d.month);
    // the later part of each year slowly dries, so there is a trend to find
    final drift = d.month >= 7 ? 1 - 0.012 * (d.year - startYear) : 1.0;
    final rains = rng.nextDouble() < (wetSeason ? 0.52 : 0.12);
    final rain = rains ? -log(1 - rng.nextDouble()) * meanWetDay * drift : 0.0;
    final tmax = 28 + (rng.nextDouble() - 0.5) * 6 + (wetSeason ? 0 : 2);
    days.add(DayRecord(d, rain, tmax, tmax - 10, wetSeason ? 0.65 : 0.45));
    d = d.add(const Duration(days: 1));
  }
  return days;
}
