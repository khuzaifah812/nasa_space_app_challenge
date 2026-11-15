// Scores crops against seasons, then scores whole rotations on each goal.
import 'dart:math' as math;

import '../data/crops_data.dart';
import 'extra_data.dart';
import 'indicators.dart';
import 'models.dart';

/// A "what if" change to the weather record.
class Scenario {
  const Scenario(this.label, this.rainScale, this.tempShift, this.heatScale,
      this.heatExtra, this.note);
  final String label;
  final double rainScale;
  final double tempShift;
  final double heatScale;
  final double heatExtra;
  final String note;
}

const scenarios = <Scenario>[
  Scenario('As now', 1, 0, 1, 0, 'The weather record as it is.'),
  Scenario('Drier', 0.8, 0, 1, 0, 'Every season gets one fifth less rain.'),
  Scenario('Hotter', 1, 2, 2, 3,
      'Every season is 2°C warmer, with more very hot days.'),
];

/// One crop in the ground, from slot [start] for [len] seasons.
class Planting {
  const Planting(this.crop, this.start, this.len);
  final Crop crop;
  final int start;
  final int len;
}

/// How well one planting fits its season(s). Every number is 0..1.
class PlantFit {
  const PlantFit(this.fit, this.water, this.temp, this.length,
      this.reliability, this.rain, this.nYears);
  final double fit;
  final double water;
  final double temp;
  final double length;
  final double reliability; // share of past years with enough rain
  final double rain; // water available to the crop, mm
  final int nYears;

  int get yearsOk => (reliability * nYears).round();

  /// The factor holding this crop back most, in plain words.
  String get limiting {
    if (water <= temp && water <= length) return 'too little rain';
    if (temp <= length) return 'temperatures outside its comfortable range';
    return 'rains that end before it matures';
  }
}

class RotationScore {
  RotationScore({
    required this.slots,
    required this.plantings,
    required this.fits,
    required this.scores,
    required this.pestBreaks,
    required this.goodSequences,
    required this.bareMonths,
    required this.monthCrops,
    required this.cashCrops,
    required this.marginPerYear,
    required this.nFixedPerYear,
    required this.waterPerYear,
  });
  final List<Crop> slots;
  final List<Planting> plantings;
  final List<PlantFit> fits;
  final Map<String, double> scores; // one 0..1 score per goal
  final int pestBreaks; // plantings that return before their rest period
  final int goodSequences; // plantings that follow a recommended crop
  final double bareMonths; // months per year with nothing growing
  final List<Crop?> monthCrops; // crop in the ground, month by month
  final int cashCrops;
  final double marginPerYear; // UGX per ha per year, mid values times fit
  final double nFixedPerYear; // kg N per ha per year
  final double waterPerYear; // mm per year the crops need

  String get names {
    final out = <String>[];
    for (final p in plantings) {
      out.add(p.crop.name);
    }
    return out.join(', ');
  }

  double total(Map<String, double> weights) {
    var t = 0.0, w = 0.0;
    for (final p in priorityKeys) {
      final wi = weights[p] ?? 0;
      t += wi * scores[p]!;
      w += wi;
    }
    if (w == 0) {
      for (final p in priorityKeys) {
        t += scores[p]!;
      }
      w = priorityKeys.length.toDouble();
    }
    return t / w * (1 - math.min(0.4, 0.1 * pestBreaks));
  }
}

class Recommendation {
  Recommendation(this.detail, this.total);
  final RotationScore detail;
  final double total;
}

Crop? cropByName(String? name) {
  if (name == null) return null;
  for (final c in crops) {
    if (c.name == name) return c;
  }
  return null;
}

/// Crops that move from season to season. Perennial blocks are left out.
List<Crop> get rotationCrops => [
      for (final c in crops)
        if (!c.perennial && c.slots > 0) c
    ];

List<Crop> get blockCrops => [
      for (final c in crops)
        if (c.perennial || c.slots == 0) c
    ];

class Engine {
  Engine(this.summary, this.setup, this.pattern,
      {this.scenario = const Scenario('As now', 1, 0, 1, 0, ''),
      this.slopePct,
      this.extras = const FieldExtras()}) {
    for (final s in pattern.seasons) {
      if (!summary.containsKey(s.name)) {
        throw StateError(
            'Not enough weather data for the ${s.months} season at this location.');
      }
    }
    // scales are fixed across the whole crop table, so a score means the
    // same thing whatever the farmer's limits are
    final all = rotationCrops;
    // flooded rice is left out of the water scale: it would stretch it so
    // far that every rain-fed crop looked the same
    final rainFed = [for (final c in all) if (!c.needsFlooding) c];
    _maxWaterPerSlot = rainFed.map((c) => c.waterMin / usedSlots(c)).reduce(math.max);
    _minWaterPerSlot = rainFed.map((c) => c.waterMin / usedSlots(c)).reduce(math.min);
    _maxMarginPerSlot = math.max(
        1.0, all.map((c) => c.marginMid / usedSlots(c)).reduce(math.max));
    _maxKcalPerSlot = math.max(
        1.0, all.map((c) => c.kcalPerHa / usedSlots(c)).reduce(math.max));
  }

  final Map<String, SeasonSummary> summary;
  final FarmSetup setup;
  final SeasonPattern pattern;
  final Scenario scenario;

  /// Slope of the field from SRTM, percent. Null when it could not be read.
  final double? slopePct;
  final FieldExtras extras;
  late final double _minWaterPerSlot, _maxWaterPerSlot, _maxMarginPerSlot, _maxKcalPerSlot;
  final _cache = <String, PlantFit>{};

  int get n => pattern.rotationLength;
  SeasonSummary seasonAt(int slot) => summary[pattern.seasonAt(slot).name]!;

  /// Seasons a crop holds the land. With one season a year, even a long
  /// crop such as cassava is done within the year.
  int usedSlots(Crop c) =>
      pattern.seasons.length == 1 ? 1 : math.max(1, c.slots);

  /// Crops the farmer could grow, given water and budget limits.
  List<Crop> get eligible => [
        for (final c in rotationCrops)
          if ((!c.needsFlooding || setup.water == 2) &&
              c.costMid <= setup.costLimit)
            c
      ];

  PlantFit fit(Planting p) {
    final key = '${p.crop.name}|${p.start % pattern.seasons.length}|${p.len}';
    return _cache.putIfAbsent(key, () => _fit(p));
  }

  PlantFit _fit(Planting p) {
    final c = p.crop;
    final k = setup.rainFactor * scenario.rainScale;
    var rain = 0.0, temp = 0.0, heat = 0.0, length = 0.0;
    var nYears = 1000;
    for (var i = p.start; i < p.start + p.len; i++) {
      final s = seasonAt(i);
      rain += s.rain * k + setup.irrigationMm;
      temp += s.tmean;
      heat += s.heatDays;
      length += s.length;
      nYears = math.min(nYears, s.nYears);
    }
    temp = temp / p.len + scenario.tempShift;
    heat = heat / p.len * scenario.heatScale + scenario.heatExtra;

    final water = math.min(1.0, rain / c.waterMin);
    double tempScore;
    if (temp >= c.tempMin && temp <= c.tempMax) {
      tempScore = 1;
    } else {
      final gap = temp < c.tempMin ? c.tempMin - temp : temp - c.tempMax;
      tempScore = math.max(0.0, 1 - gap / 8);
    }
    // a crop that holds the land for more than one season outlasts the rains
    final lengthScore =
        c.slots > 1 ? 1.0 : math.min(1.0, length / p.len / c.daysMin);

    // share of past years in which rain covered at least 80% of the need
    var ok = 0;
    for (var j = 0; j < nYears; j++) {
      var r = 0.0;
      for (var i = p.start; i < p.start + p.len; i++) {
        r += seasonAt(i).rainByYear[j] * k + setup.irrigationMm;
      }
      if (r >= 0.8 * c.waterMin) ok++;
    }
    final reliability = ok / nYears;

    // the weakest factor limits the crop, then stress is subtracted
    final stress = 0.4 * (1 - c.drought / 5) * (1 - reliability) +
        math.min(0.2, 0.01 * heat);
    final base = math.min(water, math.min(tempScore, lengthScore));
    return PlantFit(math.max(0.0, base * (1 - stress)), water, tempScore,
        lengthScore, reliability, rain, nYears);
  }

  /// Groups a season-by-season list into plantings. A crop that needs two
  /// seasons and appears twice in a row is one planting.
  List<Planting> plantingsFromSlots(List<Crop> slots) {
    final out = <Planting>[];
    var i = 0;
    while (i < slots.length) {
      final c = slots[i];
      var len = 1;
      while (len < usedSlots(c) && i + len < slots.length && slots[i + len] == c) {
        len++;
      }
      out.add(Planting(c, i, len));
      i += len;
    }
    return out;
  }

  RotationScore score(List<Crop> slots) {
    final plantings = plantingsFromSlots(slots);
    final fits = [for (final p in plantings) fit(p)];
    final count = slots.length;

    // which planting holds each slot
    final owner = List<int>.filled(count, 0);
    for (var j = 0; j < plantings.length; j++) {
      for (var i = plantings[j].start; i < plantings[j].start + plantings[j].len; i++) {
        owner[i] = j;
      }
    }

    // pest rule: the same host group must not return within its rest period.
    // The rotation repeats, so look back past the start as well.
    var pestBreaks = 0, good = 0;
    for (var j = 0; j < plantings.length; j++) {
      final p = plantings[j];
      var broken = false;
      for (var b = 1; b <= p.crop.breakSeasons && b < count; b++) {
        final i = ((p.start - b) % count + count) % count;
        if (owner[i] != j && slots[i].hostGroup == p.crop.hostGroup) broken = true;
      }
      if (broken) pestBreaks++;
      final prev = slots[((p.start - 1) % count + count) % count];
      if (plantings.length > 1 && p.crop.goodAfter.contains(prev.name)) good++;
    }

    // month-by-month cover over the whole cycle
    final months = 12 * pattern.years;
    final monthCrops = List<Crop?>.filled(months, null);
    for (final p in plantings) {
      final first = (pattern.yearOf(p.start) - 1) * 12 +
          pattern.seasonAt(p.start).startMonth - 1;
      final span = math.min(months, (p.crop.daysMid / 30).ceil());
      for (var m = 0; m < span; m++) {
        monthCrops[(first + m) % months] ??= p.crop;
      }
    }
    final bare = monthCrops.where((c) => c == null).length;
    final betweenValue = const [0.0, 0.5, 0.8][setup.between];
    final coveredShare = (months - bare + bare * betweenValue) / months;

    var water = 0.0, forage = 0.0, nBal = 0.0, cover = 0.0, som = 0.0;
    var market = 0.0, food = 0.0, margin = 0.0, nFixed = 0.0;
    var cash = 0;
    for (var j = 0; j < plantings.length; j++) {
      final p = plantings[j];
      final c = p.crop;
      final f = fits[j].fit;
      final w = p.len.toDouble(); // weight by seasons held
      final perSlot = p.len / usedSlots(c); // share of a full crop grown
      water += c.waterMin * perSlot;
      forage += w * f * c.residueScore / 5;
      nBal += w *
          (c.fixesNitrogen
              ? math.min(1.0, c.nFixMid / 70)
              : -c.nutrientDemand / 5);
      cover += w * c.groundCover / 5;
      som += w *
          (0.7 * ((c.somScore + 0.5) / 2.5).clamp(0.0, 1.0) +
              0.3 * c.residueScore / 5);
      final m = math.max(0.0, c.marginMid / usedSlots(c)) / _maxMarginPerSlot;
      final sell = (!setup.nearMarket && c.storeScore <= 2) ? 0.5 : 1.0;
      market += w * f * math.sqrt(m) * sell * (1 - 0.08 * (c.priceRisk - 2));
      food += w * f * math.sqrt((c.kcalPerHa / usedSlots(c)) / _maxKcalPerSlot);
      margin += c.marginMid * perSlot * f;
      nFixed += c.nFixMid * perSlot * f;
      if (!c.staple.startsWith('staple')) cash++;
    }
    final sequence = plantings.length > 1 ? good / plantings.length : 0.0;

    return RotationScore(
      slots: slots,
      plantings: plantings,
      fits: fits,
      scores: {
        'water': (1 -
                (water / count - _minWaterPerSlot) /
                    math.max(1.0, _maxWaterPerSlot - _minWaterPerSlot))
            .clamp(0.0, 1.0),
        'forage': forage / count,
        'nitrogen':
            (0.7 * ((nBal / count + 1) / 2) + 0.3 * sequence).clamp(0.0, 1.0),
        // on sloping land (SRTM), poor ground cover costs more
        'erosion': (0.6 * cover / count + 0.4 * coveredShare) *
            (1 -
                math.min(0.3, (slopePct ?? 0) / 40) *
                    (1 - (0.6 * cover / count + 0.4 * coveredShare))),
        'organic': som / count,
        'market': (market / count).clamp(0.0, 1.0),
        'food': (food / count).clamp(0.0, 1.0),
      },
      pestBreaks: pestBreaks,
      goodSequences: good,
      bareMonths: bare / pattern.years,
      monthCrops: monthCrops,
      cashCrops: cash,
      marginPerYear: margin / pattern.years,
      nFixedPerYear: nFixed / pattern.years,
      waterPerYear: water / pattern.years,
    );
  }

  /// Tries every sensible combination and returns the best few, leaving out
  /// [exclude] (the farmer's current rotation).
  List<Recommendation> recommend(Map<String, double> weights,
      {int top = 2, double minFit = 0.35, List<Crop>? exclude}) {
    final pool = eligible.isEmpty ? rotationCrops : eligible;

    List<Crop> optionsAt(int i) {
      final usable = [
        for (final c in pool)
          if (i + usedSlots(c) <= n) c
      ];
      double f(Crop c) => fit(Planting(c, i, usedSlots(c))).fit;
      usable.sort((a, b) => f(b).compareTo(f(a)));
      final ok = [
        for (final c in usable)
          if (f(c) >= minFit) c
      ];
      return ok.isNotEmpty ? ok : usable.take(3).toList();
    }

    final all = <Recommendation>[];
    void fill(int i, List<Crop> sofar) {
      if (i == n) {
        final detail = score(List.of(sofar));
        all.add(Recommendation(detail, detail.total(weights)));
        return;
      }
      for (final c in optionsAt(i)) {
        final len = usedSlots(c);
        for (var k = 0; k < len; k++) {
          sofar.add(c);
        }
        fill(i + len, sofar);
        sofar.removeRange(sofar.length - len, sofar.length);
      }
    }

    fill(0, []);
    all.sort((a, b) => b.total.compareTo(a.total));

    // keep the best, then one that differs in at least two seasons. A
    // rotation is a cycle, so the same cycle started in another year is the
    // same plan.
    final picks = <Recommendation>[];
    final seen = <String>{if (exclude != null) _cycleKey(exclude)};
    final mixes = <String>{};
    for (final r in all) {
      final key = _cycleKey(r.detail.slots);
      // the second option must use a different mix of crops, not the same
      // crops in another order
      final mix = ([for (final c in r.detail.slots) c.name]..sort()).join('>');
      if (seen.contains(key) || mixes.contains(mix)) continue;
      picks.add(r);
      seen.add(key);
      mixes.add(mix);
      if (picks.length == top) break;
    }
    return picks;
  }

  /// Same text for every whole-year shift of the same cycle.
  String _cycleKey(List<Crop> rot) {
    final count = rot.length;
    final step = pattern.seasons.length;
    String? best;
    for (var shift = 0; shift < count; shift += step) {
      final key =
          [for (var i = 0; i < count; i++) rot[(i + shift) % count].name].join('>');
      if (best == null || key.compareTo(best) < 0) best = key;
    }
    return best!;
  }
}
