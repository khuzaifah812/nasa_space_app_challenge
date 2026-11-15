// Turns daily weather into season indicators and trends.
import 'dart:math' as math;

import 'models.dart';

const heatThreshold = 35.0; // a "very hot day" has Tmax above this (deg C)
const coldThreshold = 5.0; // a "cold night" has Tmin below this (deg C)
const heavyRain = 20.0; // a "heavy rain day" has more rain than this (mm)
const dryDayRain = 1.0; // less rain than this (mm) counts as a dry day
const drySpellDays = 7; // this many dry days in a row = one dry spell

/// Indicators for one season of one year.
class SeasonYear {
  SeasonYear(this.year, this.rain, this.et0, this.heatDays, this.drySpells,
      this.length, this.tmean, this.wet, this.heavyDays, this.coldNights);
  final int year;
  final double rain;
  final double et0;
  final int heatDays;
  final int drySpells;
  final int length;
  final double tmean;
  final double wet;
  final int heavyDays;
  final int coldNights;
  double get balance => rain - et0;
}

/// Averages and trends for one season across all years.
class SeasonSummary {
  SeasonSummary(this.season, this.records) {
    rainByYear = series((r) => r.rain);
    rain = mean(rainByYear);
    et0 = avg((r) => r.et0);
    heatDays = avg((r) => r.heatDays.toDouble());
    drySpells = avg((r) => r.drySpells.toDouble());
    length = avg((r) => r.length.toDouble());
    tmean = avg((r) => r.tmean);
    wet = avg((r) => r.wet);
    heavyDays = avg((r) => r.heavyDays.toDouble());
    coldNights = avg((r) => r.coldNights.toDouble());
    rainTrend = trend((r) => r.rain);
    var sq = 0.0;
    for (final v in rainByYear) {
      sq += (v - rain) * (v - rain);
    }
    rainCv = rain > 0 ? math.sqrt(sq / rainByYear.length) / rain : 0;
  }

  final SeasonDef season;
  final List<SeasonYear> records;
  late final List<double> rainByYear;
  late final double rain, et0, heatDays, drySpells, length, tmean, wet;
  late final double heavyDays, coldNights;
  late final double rainTrend; // mm per decade
  late final double rainCv; // year-to-year variability, 0..1

  int get nYears => records.length;
  double get balance => rain - et0;
  List<int> get years => [for (final r in records) r.year];

  List<double> series(double Function(SeasonYear) f) =>
      [for (final r in records) f(r)];
  double avg(double Function(SeasonYear) f) => mean(series(f));

  /// Change per 10 years.
  double trend(double Function(SeasonYear) f) => trendPerDecade(
      [for (final r in records) r.year.toDouble()], series(f));
}

double mean(List<double> xs) {
  if (xs.isEmpty) return 0;
  var sum = 0.0;
  for (final x in xs) {
    sum += x;
  }
  return sum / xs.length;
}

/// Least-squares slope, expressed as change per 10 years.
double trendPerDecade(List<double> x, List<double> y) {
  if (x.length < 5) return 0;
  final mx = mean(x);
  final my = mean(y);
  var num = 0.0;
  var den = 0.0;
  for (var i = 0; i < x.length; i++) {
    num += (x[i] - mx) * (y[i] - my);
    den += (x[i] - mx) * (x[i] - mx);
  }
  return den == 0 ? 0 : 10 * num / den;
}

/// Reference evaporation in mm/day (Hargreaves method, FAO-56).
double et0Hargreaves(double lat, DateTime d, double tmax, double tmin) {
  final phi = lat * math.pi / 180;
  final j = d.difference(DateTime.utc(d.year, 1, 1)).inDays + 1;
  final dr = 1 + 0.033 * math.cos(2 * math.pi * j / 365);
  final dec = 0.409 * math.sin(2 * math.pi * j / 365 - 1.39);
  final x = (-math.tan(phi) * math.tan(dec)).clamp(-1.0, 1.0).toDouble();
  final ws = math.acos(x);
  final ra = (24 * 60 / math.pi) *
      0.0820 *
      dr *
      (ws * math.sin(phi) * math.sin(dec) +
          math.cos(phi) * math.cos(dec) * math.sin(ws));
  final tmean = (tmax + tmin) / 2;
  final spread = math.max(tmax - tmin, 0.0);
  return math.max(0.0, 0.0023 * (tmean + 17.8) * math.sqrt(spread) * ra * 0.408);
}

/// Days from onset (20 mm within 3 days) to the last wet 10-day period.
int seasonLength(List<double> rain) {
  var onset = -1;
  for (var i = 0; i + 2 < rain.length; i++) {
    if (rain[i] + rain[i + 1] + rain[i + 2] >= 20) {
      onset = i;
      break;
    }
  }
  if (onset < 0) return 0;
  var end = onset;
  for (var i = onset; i < rain.length; i++) {
    var sum = 0.0;
    for (var k = math.max(0, i - 9); k <= i; k++) {
      sum += rain[k];
    }
    if (sum >= 10) end = i;
  }
  return end - onset + 1;
}

int countDrySpells(List<double> rain) {
  var spells = 0;
  var run = 0;
  for (final r in rain) {
    run = r < dryDayRain ? run + 1 : 0;
    if (run == drySpellDays) spells++;
  }
  return spells;
}

/// Builds one summary per season in the pattern. Seasons without enough
/// data are left out of the map.
Map<String, SeasonSummary> summarise(
    List<DayRecord> days, double lat, SeasonPattern pattern) {
  final out = <String, SeasonSummary>{};
  if (days.isEmpty) return out;
  final firstYear = days.first.date.year;
  final lastYear = days.last.date.year;

  for (final s in pattern.seasons) {
    final records = <SeasonYear>[];
    for (var y = firstYear; y <= lastYear; y++) {
      final endYear = s.endMonth >= s.startMonth ? y : y + 1;
      final start = DateTime.utc(y, s.startMonth, 1);
      final coreEnd = DateTime.utc(endYear, s.endMonth + 1, 1);
      // one extra month lets a late-finishing season show its real length
      final extEnd = DateTime.utc(endYear, s.endMonth + 2, 1);

      final core = <DayRecord>[];
      final extRain = <double>[];
      for (final d in days) {
        if (d.date.isBefore(start)) continue;
        if (!d.date.isBefore(extEnd)) break;
        extRain.add(d.rain);
        if (d.date.isBefore(coreEnd)) core.add(d);
      }
      final expected = coreEnd.difference(start).inDays;
      if (core.length < expected * 0.85) continue; // too much missing data

      var rain = 0.0, evap = 0.0, temp = 0.0, wet = 0.0;
      var heat = 0, heavy = 0, cold = 0;
      for (final d in core) {
        rain += d.rain;
        // NASA's own evapotranspiration estimate when it is there, else the
        // FAO temperature method
        evap += d.et ?? et0Hargreaves(lat, d.date, d.tmax, d.tmin);
        temp += d.tmean ?? (d.tmax + d.tmin) / 2;
        wet += d.wet;
        if (d.tmax > heatThreshold) heat++;
        if (d.rain > heavyRain) heavy++;
        if (d.tmin < coldThreshold) cold++;
      }
      records.add(SeasonYear(
        y,
        rain,
        evap,
        heat,
        countDrySpells([for (final d in core) d.rain]),
        seasonLength(extRain),
        temp / core.length,
        wet / core.length,
        heavy,
        cold,
      ));
    }
    if (records.length >= 3) out[s.name] = SeasonSummary(s, records);
  }
  return out;
}

/// Finds the two wettest three-month windows that do not overlap, from the
/// average rain of each calendar month. This is how the app discovers the
/// rainy seasons of any place on Earth. They are historical rain windows,
/// not a verified local planting calendar.
SeasonPattern detectSeasons(List<DayRecord> days) {
  final totals = List<double>.filled(13, 0);
  final years = List<Set<int>>.generate(13, (_) => <int>{});
  for (final d in days) {
    totals[d.date.month] += d.rain;
    years[d.date.month].add(d.date.year);
  }
  for (var m = 1; m <= 12; m++) {
    if (years[m].isNotEmpty) totals[m] /= years[m].length;
  }
  double windowRain(int start) =>
      totals[start] + totals[(start % 12) + 1] + totals[((start + 1) % 12) + 1];
  final starts = List<int>.generate(12, (i) => i + 1)
    ..sort((a, b) {
      final c = windowRain(b).compareTo(windowRain(a));
      return c != 0 ? c : a.compareTo(b);
    });
  Set<int> monthsOf(int start) => {start, (start % 12) + 1, ((start + 1) % 12) + 1};
  final first = starts.first;
  int? second;
  for (final s in starts.skip(1)) {
    if (monthsOf(s).intersection(monthsOf(first)).isEmpty) {
      second = s;
      break;
    }
  }
  int end(int start) => ((start + 1) % 12) + 1;
  // the drier window counts as a season only if it brings a fair share of rain
  final total = totals.fold(0.0, (a, b) => a + b);
  final twoSeasons = second != null && total > 0 && windowRain(second) >= 0.2 * total;
  final a = SeasonDef('Season A', first, end(first));
  if (!twoSeasons) {
    return SeasonPattern('Found from the rain record: ${a.months}', [a]);
  }
  final b = SeasonDef('Season B', second, end(second));
  final ordered = first <= second ? [a, b] : [b, a];
  return SeasonPattern(
      'Found from the rain record: ${ordered[0].months} and ${ordered[1].months}',
      ordered);
}

/// What the Conditions screen shows, one entry per card.
class Indicator {
  const Indicator(this.key, this.title, this.unit, this.digits, this.value,
      this.source, this.what, this.why);
  final String key;
  final String title;
  final String unit;
  final int digits;
  final double Function(SeasonYear) value;
  final String source;
  final String what; // what the number is
  final String why; // what it means for crops and soil
}

final indicators = <Indicator>[
  Indicator('rain', 'Rainfall', 'mm', 0, (r) => r.rain,
      'NASA POWER (rain estimate from satellites and gauges)',
      'All the rain that fell in the season.',
      'Each crop needs a certain amount of water. When a season brings less, '
          'yields drop. Falling rain over the years means thirstier crops '
          'such as maize become a bigger gamble.'),
  Indicator('heat', 'Very hot days', 'days', 1, (r) => r.heatDays.toDouble(),
      'NASA POWER daily maximum temperature',
      'Days in the season when it was hotter than 35°C.',
      'Heat at flowering stops many crops setting grain or fruit. Hot days '
          'also dry the soil faster and speed up the loss of organic matter.'),
  Indicator('wet', 'Soil wetness', '%', 0, (r) => r.wet * 100,
      'NASA POWER root-zone soil wetness (a model estimate, not a field reading)',
      'How full of water the soil is where roots grow. 100% is soaked, 0% is '
          'completely dry.',
      'This is the water roots can actually reach. Dry soil at planting '
          'delays germination, and dry soil at flowering cuts yield most. '
          'Soil that stays covered holds water longer.'),
  Indicator('et0', 'Evaporation', 'mm', 0, (r) => r.et0,
      'NASA POWER evapotranspiration estimate (EVPTRNS), or the FAO '
          'temperature method where it is missing',
      'How much water the air could pull out of the soil and leaves in the '
          'season. The scientific name is evapotranspiration.',
      'When this is larger than the rainfall, the field loses more water '
          'than it gets. Bare soil loses the most.'),
  Indicator('balance', 'Water balance', 'mm', 0, (r) => r.balance,
      'Rainfall minus evaporation',
      'Rain minus evaporation demand. Below zero means the season runs short '
          'of water.',
      'A season that is often below zero suits crops that need less water '
          'or tolerate dry spells.'),
  Indicator('heavy', 'Heavy rain days', 'days', 1, (r) => r.heavyDays.toDouble(),
      'NASA POWER daily rainfall',
      'Days with more than 20 mm of rain.',
      'Heavy rain on bare or sloping ground washes soil and nutrients away. '
          'Crops that cover the ground protect it. Satellite data smooths '
          'out local storms, so the true number on your field may be higher.'),
  Indicator('dry', 'Dry spells', 'spells', 1, (r) => r.drySpells.toDouble(),
      'NASA POWER daily rainfall',
      'Times in the season when a week or more passed with almost no rain.',
      'A dry spell in the middle of the season can ruin a crop even when the '
          'season total looks normal.'),
  Indicator('length', 'Length of the rains', 'days', 0,
      (r) => r.length.toDouble(),
      'NASA POWER daily rainfall',
      'Days from the first good rain to the last wet week.',
      'A crop needs the rains to last about as long as it takes to mature. '
          'Shorter rains favour fast crops such as beans.'),
  Indicator('cold', 'Cold nights', 'nights', 1, (r) => r.coldNights.toDouble(),
      'NASA POWER daily minimum temperature',
      'Nights colder than 5°C. Frost happens at 0°C.',
      'Cold nights slow growth and frost kills most crops. In most of '
          'Uganda this stays at zero, except in the highlands.'),
];
