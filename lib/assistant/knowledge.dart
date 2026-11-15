// The facts the assistant reasons from: the field's NASA figures, the three
// rotations and the crop table. Written in English because it is sent to
// the AI model as grounding; the model answers in the farmer's language.
import '../analysis.dart';
import '../data/crops_data.dart';
import '../engine/explanation.dart';
import '../engine/indicators.dart';

String fieldKnowledge(Analysis? a) {
  final b = StringBuffer();
  if (a == null) {
    b.writeln('No field has been set up yet. The farmer is still on the '
        'welcome, language or set-up screens.');
  } else {
    final s = a.setup;
    b.writeln('FIELD');
    b.writeln('Place: ${s.placePath} (${s.countryName}), latitude ${s.lat}, '
        'longitude ${s.lon}.');
    b.writeln('Weather source: ${a.isSample ? 'SAMPLE data made inside the app, NOT real' : 'NASA POWER daily records'}, '
        '${a.startYear} to ${a.endYear}.');
    b.writeln('Seasons: ${a.pattern.label}.');
    b.writeln('Soil: ${s.soilType ?? 'not given'}, pH ${s.ph ?? 'not given'}, '
        'organic matter ${s.organicMatter ?? 'not given'}. Water: '
        '${['rain only', 'some irrigation', 'wetland'][s.water]}. Budget: '
        '${['low', 'medium', 'high'][s.budget]}. Market close: ${s.nearMarket}.');
    b.writeln('Field between harvests: ${['bare', 'residue left', 'cover crop'][s.between]}.');
    final ranked = s.weights.entries.toList()..sort((x, y) => y.value.compareTo(x.value));
    b.writeln('Priorities (0 to 1): ${ranked.map((e) => '${e.key} ${e.value.toStringAsFixed(1)}').join(', ')}.');
    final ex = a.weather.extras;
    b.writeln(ex.hasTerrain
        ? 'Terrain (SRTM): elevation ${ex.elevation?.toStringAsFixed(0)} m, slope ${ex.slopePct!.toStringAsFixed(1)}% (${ex.slopeWord}).'
        : 'Terrain (SRTM): not available.');
    b.writeln(ex.hasNdvi
        ? 'MODIS NDVI (250 m, 16-day), recent: ${ex.ndvi.map((p) => '${p.date.toIso8601String().substring(0, 10)} ${p.value.toStringAsFixed(2)}').join(', ')}.'
        : 'MODIS NDVI: not available.');
    b.writeln('Map-only NASA GIBS layers in the app (pictures, no numbers): SMAP brightness temperature, '
        'GPM GMI brightness temperature, GRACE water storage, MODIS NDVI.');
    b.writeln();
    b.writeln('SEASON INDICATORS (averages over the record, with trend per decade)');
    for (final def in a.pattern.seasons) {
      final sm = a.summary[def.name]!;
      b.writeln('${def.name} (${def.months}), ${sm.nYears} years: rain ${sm.rain.toStringAsFixed(0)} mm '
          '(trend ${sm.rainTrend.toStringAsFixed(0)} mm/decade, variability ${(sm.rainCv * 100).toStringAsFixed(0)}%), '
          'evapotranspiration ${sm.et0.toStringAsFixed(0)} mm, water balance ${sm.balance.toStringAsFixed(0)} mm, '
          'mean temperature ${sm.tmean.toStringAsFixed(1)} C, very hot days (>35C) ${sm.heatDays.toStringAsFixed(1)}, '
          'cold nights (<5C) ${sm.coldNights.toStringAsFixed(1)}, heavy rain days (>20mm) ${sm.heavyDays.toStringAsFixed(1)}, '
          'dry spells ${sm.drySpells.toStringAsFixed(1)}, rains last ${sm.length.toStringAsFixed(0)} days, '
          'root-zone wetness ${(sm.wet * 100).toStringAsFixed(0)}%.');
    }
    b.writeln();
    b.writeln('ROTATIONS (scores 0 to 100 against the farmer\'s priorities)');
    for (final c in a.result().cards) {
      b.writeln('${c.title}: ${c.detail.names}. Score ${pts(c.total)}. '
          'Bare months/year ${c.detail.bareMonths.toStringAsFixed(1)}, pest rests missed ${c.detail.pestBreaks}, '
          'water need ${c.detail.waterPerYear.toStringAsFixed(0)} mm/year, rough margin UGX ${c.detail.marginPerYear.toStringAsFixed(0)}/ha/year. '
          'Confidence ${c.confidence}.');
      for (final r in c.reasons.take(4)) {
        b.writeln('  why: $r');
      }
      for (final r in c.risks.take(4)) {
        b.writeln('  risk: $r');
      }
    }
  }
  b.writeln();
  b.writeln('CROP TABLE (draft, Uganda; water need mm, days to maturity, nitrogen, '
      'price UGX/kg, pests)');
  for (final c in crops) {
    b.writeln('${c.name}: water ${c.waterMin.toStringAsFixed(0)}-${c.waterMax.toStringAsFixed(0)} mm, '
        '${c.tempMin.toStringAsFixed(0)}-${c.tempMax.toStringAsFixed(0)} C, ${c.daysMin}-${c.daysMax} days, '
        '${c.nitrogenEffect}, price ${c.priceMin.toStringAsFixed(0)}-${c.priceMax.toStringAsFixed(0)}, '
        'yield ${c.yieldMin}-${c.yieldMax} t/ha, good after: ${c.goodAfterText}; avoid after: ${c.badAfterText}; '
        'pests: ${c.pests}.');
  }
  b.writeln();
  b.writeln('INDICATOR MEANINGS');
  for (final i in indicators) {
    b.writeln('${i.title}: ${i.what} ${i.why} Source: ${i.source}.');
  }
  return b.toString();
}
