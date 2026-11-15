// Turns scores into plain-language reasons, evidence, benefits, unknowns,
// risks and questions for a local expert. Every sentence is built from a
// number the engine computed or a value in the crop table.
import '../data/crops_data.dart';
import 'models.dart';
import 'scoring.dart';

const dataSource = 'NASA POWER daily data';

class ExplanationCard {
  ExplanationCard(this.tag, this.title, this.detail, this.total);
  final String tag; // "Now", "A", "B"
  final String title;
  final RotationScore detail;
  final double total;
  String headline = '';
  String confidence = '';
  String confidenceWhy = '';
  final reasons = <String>[];
  final evidence = <String>[];
  final benefits = <String>[];
  final gaps = <String>[];
  final risks = <String>[];
  final questions = <String>[];
  final tags = <String>[];

  bool get isCurrent => tag == 'Now';

  static const sectionTitles = {
    'reasons': 'Why it was suggested',
    'evidence': 'Evidence',
    'benefits': 'Benefits',
    'gaps': 'What this tool does not know',
    'risks': 'Risks to check locally',
    'questions': 'Questions for a local expert',
  };

  Map<String, List<String>> get sections => {
        'reasons': reasons,
        'evidence': evidence,
        'benefits': benefits,
        'gaps': gaps,
        'risks': risks,
        'questions': questions,
      };

  /// Plain text for copying or sending by message.
  String toText() {
    final b = StringBuffer('AgriSmart advice\n$title: ${detail.names}\n\n$headline');
    sections.forEach((key, lines) {
      final name = key == 'reasons' && isCurrent
          ? 'How it fits your field'
          : sectionTitles[key];
      b.write('\n\n$name');
      if (lines.isEmpty) b.write('\n  - None identified.');
      for (final l in lines) {
        b.write('\n  - $l');
      }
    });
    b.write('\n\nAgriSmart. Your Farm. Your next season.');
    return b.toString();
  }
}

String _f(double v, [int digits = 0]) => v.toStringAsFixed(digits);
String _signed(double v) => '${v >= 0 ? '+' : ''}${v.toStringAsFixed(0)}';
String _lower(String s) => s[0].toLowerCase() + s.substring(1);
String pts(double score) => (score * 100).round().toString();

ExplanationCard explain(
  Engine engine,
  String tag,
  String title,
  RotationScore detail,
  Map<String, double> weights, {
  RotationScore? current,
}) {
  final pattern = engine.pattern;
  final setup = engine.setup;
  final card = ExplanationCard(tag, title, detail, detail.total(weights));
  final fits = detail.fits;
  final plantings = detail.plantings;
  var nYears = 1000;
  var maxCv = 0.0;
  for (final s in engine.summary.values) {
    if (s.nYears < nYears) nYears = s.nYears;
    if (s.rainCv > maxCv) maxCv = s.rainCv;
  }
  final ranked = [
    for (final p in priorityKeys)
      if ((weights[p] ?? 0) > 0) p
  ]..sort((a, b) => weights[b]!.compareTo(weights[a]!));

  String where(Planting p) => p.len > 1
      ? '${pattern.slotLabel(p.start)} to ${pattern.seasonAt(p.start + p.len - 1).months}'
      : pattern.slotLabel(p.start);

  // ---- 1. Reasons ---------------------------------------------------------
  for (var j = 0; j < plantings.length; j++) {
    final p = plantings[j];
    final c = p.crop;
    final f = fits[j];
    final why = <String>[];
    if (f.water >= 1) {
      why.add('the rain it gets (about ${_f(f.rain)} mm) covers its need '
          '(at least ${_f(c.waterMin)} mm)');
    } else if (f.water >= 0.9) {
      why.add('the rain it gets (about ${_f(f.rain)} mm) is just short of '
          'its need (at least ${_f(c.waterMin)} mm)');
    } else {
      why.add('the rain it gets (about ${_f(f.rain)} mm) is below its need '
          '(at least ${_f(c.waterMin)} mm)');
    }
    if (c.fixesNitrogen) {
      why.add('it fixes nitrogen, about ${_f(c.nFixMin)} to ${_f(c.nFixMax)} '
          'kg per hectare');
    }
    if (c.drought >= 4) why.add('it tolerates dry spells well');
    if (c.groundCover >= 5) why.add('it covers the ground fully');
    if (c.deepRooted) {
      why.add('its deep roots open the soil and help rain soak in');
    }
    final prev = detail.slots[(p.start - 1 + detail.slots.length) % detail.slots.length];
    if (plantings.length > 1 && c.goodAfter.contains(prev.name)) {
      why.add('it does well after ${_lower(prev.name)}');
    }
    card.reasons.add('${where(p)}, ${_lower(c.name)}: ${why.join('; ')}.');
  }
  if (detail.pestBreaks == 0) {
    card.reasons.add('No crop group returns before its rest period, which '
        'interrupts pest and disease cycles.');
  }
  if (current != null && detail.bareMonths < current.bareMonths - 0.4) {
    card.reasons.add('The field is bare about ${_f(detail.bareMonths, 1)} '
        'months a year instead of ${_f(current.bareMonths, 1)}.');
  }
  if (current != null && detail.waterPerYear < current.waterPerYear * 0.9) {
    card.reasons.add('The crops need about ${_f(detail.waterPerYear)} mm of '
        'water a year, less than the ${_f(current.waterPerYear)} mm your '
        'current crops need.');
  }

  // ---- 2. Evidence --------------------------------------------------------
  for (final def in pattern.seasons) {
    final s = engine.summary[def.name]!;
    card.evidence.add('${def.months} ($dataSource, ${s.nYears} years): average '
        'rain ${_f(s.rain)} mm, evaporation demand ${_f(s.et0)} mm, water '
        'balance ${_signed(s.balance)} mm, rains last about ${_f(s.length)} '
        'days, ${_f(s.drySpells, 1)} dry spells and ${_f(s.heatDays, 1)} very '
        'hot days a season.');
    if (s.rainTrend.abs() >= 0.05 * s.rain) {
      card.evidence.add('${def.months} rain has '
          '${s.rainTrend < 0 ? 'fallen' : 'risen'} by about '
          '${_f(s.rainTrend.abs())} mm per decade.');
    }
  }
  for (var j = 0; j < plantings.length; j++) {
    final f = fits[j];
    card.evidence.add('${plantings[j].crop.name} (${_lower(where(plantings[j]))}): '
        'rain was enough in ${f.yearsOk} of ${f.nYears} past years.');
  }
  final ex = engine.extras;
  if (ex.hasTerrain) {
    card.evidence.add('The land is ${ex.slopeWord}: about ${_f(ex.slopePct!, 1)}% slope at '
        '${_f(ex.elevation ?? 0)} m above sea level (${ex.terrainSource}).');
  }
  if (ex.hasNdvi) {
    card.evidence.add('Plant greenness (MODIS NDVI, 250 m) was ${_f(ex.ndvi.last.value, 2)} on '
        '${ex.ndvi.last.date.toIso8601String().substring(0, 10)}, on a scale where bare soil is '
        'about 0.1 to 0.2 and dense crops 0.6 to 0.9.');
  }
  card.evidence.add('Crop needs, yields, prices and pest groups come from '
      'the team\'s crop table of ${crops.length} Ugandan crops.');

  // ---- 3. Benefits --------------------------------------------------------
  for (final p in ranked) {
    final v = detail.scores[p]!;
    var line = '${priorityLabels[p]}: ${pts(v)} out of 100';
    if (current != null && !card.isCurrent) {
      final diff = v - current.scores[p]!;
      if (diff.abs() < 0.03) {
        line += ', about the same as your current rotation';
      } else {
        line += ', ${diff > 0 ? 'up' : 'down'} from '
            '${pts(current.scores[p]!)} with your current rotation';
      }
    }
    card.benefits.add('$line.');
  }
  if (detail.nFixedPerYear > 0) {
    card.benefits.add('Legumes add roughly ${_f(detail.nFixedPerYear)} kg of '
        'nitrogen per hectare a year.');
  }
  card.benefits.add('Rough earnings after input and labour costs: about '
      '${ugx(detail.marginPerYear)} per hectare a year, at the middle yields '
      'and prices in the crop table. Real results vary widely.');
  if (current != null && !card.isCurrent) {
    for (final p in priorityKeys) {
      final v = detail.scores[p]!;
      final was = current.scores[p]!;
      if (!ranked.take(3).contains(p) && v - was <= -0.1) {
        card.benefits.add('Trade-off: ${_lower(priorityLabels[p]!)} drops to '
            '${pts(v)} from ${pts(was)}.');
      }
    }
  }

  // ---- 4. Risks -----------------------------------------------------------
  final seen = <String>{};
  for (var j = 0; j < plantings.length; j++) {
    final p = plantings[j];
    final c = p.crop;
    final f = fits[j];
    final s = engine.seasonAt(p.start);
    final tag2 = '${c.name} (${_lower(where(p))})';
    if (f.reliability < 0.7) {
      card.risks.add('$tag2: rain fell short in ${f.nYears - f.yearsOk} of '
          '${f.nYears} years.');
    }
    if (f.length < 0.9) {
      card.risks.add('$tag2: needs at least ${c.daysMin} days but the rains '
          'last about ${_f(s.length)}. An early-maturing variety is safer.');
    }
    if (f.temp < 0.9) {
      card.risks.add('$tag2: the season averages ${_f(s.tmean, 1)}°C, outside '
          'the ${_f(c.tempMin)} to ${_f(c.tempMax)}°C range in the crop table.');
    }
    if (s.rainTrend <= -0.05 * s.rain && c.drought <= 2) {
      card.risks.add('$tag2: this season is getting drier and the crop '
          'handles drought poorly.');
    }
    if (!seen.add(c.name)) continue; // crop-level notes once per crop
    final pests = c.pests.split(';').take(3).map((e) => e.trim()).join(', ');
    card.risks.add('${c.name}: watch for ${_lower(pests)}.');
    if (c.priceRisk >= 4) {
      card.risks.add('${c.name}: prices swing a lot '
          '(${c.priceVariability}). ${c.marketNotes}');
    }
    if (c.storeScore <= 2) {
      card.risks.add('${c.name}: keeps poorly once harvested (rated '
          '${c.storability.split(' (').first}), so it must be eaten or sold '
          'quickly.');
    }
    if (c.costMid >= 3000000) {
      card.risks.add('${c.name}: needs about ${ugx(c.costMin)} to '
          '${ugx(c.costMax)} per hectare for inputs and labour.');
    }
    if (c.confidence == 'low') {
      card.risks.add('${c.name}: the crop table marks its figures as low '
          'confidence.');
    }
  }
  if (detail.pestBreaks > 0) {
    card.risks.add('${detail.pestBreaks} planting(s) return to the same crop '
        'group before its rest period is over, which lets pests and diseases '
        'build up.');
  }
  if (ex.hasTerrain && ex.slopePct! >= 5 && detail.bareMonths >= 2) {
    card.risks.add('The land slopes about ${_f(ex.slopePct!, 1)}% (SRTM) and is bare '
        '${_f(detail.bareMonths, 1)} months a year, so heavy rain can carry soil away. '
        'Contour planting, mulch or a cover crop would help.');
  }
  final hasLegume = detail.slots.any((c) => c.fixesNitrogen);
  if (setup.ph != null && setup.ph! < 5.5 && hasLegume) {
    card.risks.add('Soil pH of ${_f(setup.ph!, 1)} is acidic. Legumes fix '
        'less nitrogen in acid soil unless lime is applied.');
  }
  if (setup.organicMatter == 'Low') {
    card.risks.add('Organic matter is low, so the soil holds less water and '
        'fewer nutrients. Leaving crop residues on the field helps.');
  }

  // ---- 5. Gaps ------------------------------------------------------------
  card.gaps.add('Weather data covers a square roughly 50 km wide, so it '
      'describes the area, not this exact field.');
  card.gaps.add('The crop table is a draft: "$cropDataStatus".');
  if (setup.countryCode != 'UG') {
    card.gaps.add('The crop table was written for Uganda. Its crops, yields '
        'and prices (in Uganda shillings) may not fit ${setup.countryName}.');
  }
  if (setup.autoSeasons) {
    card.gaps.add('The seasons are the two wettest three-month windows in '
        'the rain record, not a confirmed local planting calendar. Check '
        'planting dates with an extension worker.');
  }
  if (nYears < 15) {
    card.gaps.add('Only $nYears years of data were usable, so trends are '
        'uncertain.');
  }
  if (setup.soilEmpty) {
    card.gaps.add('No soil information was entered, so soil type, pH and '
        'organic matter were not considered.');
  } else {
    final missing = [
      if (setup.soilType == null) 'soil type',
      if (setup.ph == null) 'pH',
      if (setup.organicMatter == null) 'organic matter',
    ];
    if (missing.isNotEmpty) {
      card.gaps.add('Soil details not provided: ${missing.join(', ')}.');
    }
  }
  if (setup.rainFactor < 1) {
    card.gaps.add('${setup.soilType} soil was assumed to keep '
        '${_f((1 - setup.rainFactor) * 100)}% less rain available to crops. '
        'This is a rule of thumb, not a measurement.');
  }
  if (setup.water == 1) {
    card.gaps.add('Irrigation was assumed to add about '
        '${_f(setup.irrigationMm)} mm of water a season.');
  }
  if (detail.slots.any((c) => c.saleFraction < 1)) {
    card.gaps.add('For groundnuts and rice, 65% of the harvested weight was '
        'assumed to be sold at the shelled or milled price.');
  }
  card.gaps.addAll([
    if (!ex.hasTerrain) 'Slope from SRTM could not be read, so erosion risk ignores the lie of the land.',
    if (!ex.hasNdvi) 'Plant greenness from MODIS could not be read for this field.',
    'SMAP soil moisture, GPM rainfall, ECOSTRESS and GRACE-FO are shown as '
        'map layers only. Their numbers are not yet part of the scores.',
    'Seed supply, labour, and pest outbreaks in a given year are not '
        'included.',
    'Coming seasons are assumed to resemble the past record. This is not a '
        'forecast.',
  ]);

  // ---- 6. Questions -------------------------------------------------------
  card.questions.addAll([
    'Are these crops and suitable varieties sold near here?',
    'Do the planting months used here match what works on this land?',
    'Are there local pests or diseases that rule out any of these crops?',
  ]);
  if (fits.any((f) => f.length < 0.9)) {
    card.questions.add('Which early-maturing varieties suit this area?');
  }
  if (setup.ph == null) {
    card.questions.add('Has this field had a soil test?');
  }
  if (detail.slots.any((c) => c.priceRisk >= 4 || c.storeScore <= 2)) {
    card.questions.add('Is there a reliable buyer for the crops that do not '
        'keep?');
  }

  // ---- 7. Tags, confidence, headline --------------------------------------
  if (detail.slots.any((c) => c.fixesNitrogen)) card.tags.add('Adds nitrogen');
  if (detail.pestBreaks == 0) {
    card.tags.add('Breaks pest cycles');
  } else {
    card.tags.add('${detail.pestBreaks} pest rest break(s) missed');
  }
  card.tags.add('${_f(detail.bareMonths, 1)} bare months a year');
  if (detail.cashCrops > 0) card.tags.add('Has a cash crop');

  final lowData = detail.slots.any((c) => c.confidence == 'low');
  final points = (nYears >= 15 ? 1 : 0) +
      (setup.soilEmpty ? 0 : 1) +
      (maxCv < 0.25 ? 1 : 0) +
      (fits.every((f) => f.reliability >= 0.7) ? 1 : 0) -
      (lowData ? 1 : 0);
  card.confidence =
      const ['Low', 'Low', 'Medium', 'Medium', 'High'][points.clamp(0, 4)];
  card.confidenceWhy = 'Based on $nYears years of records, how much rain '
      'varies from year to year, how often rain covered each crop\'s need, '
      'and how much you told us about your soil. The crop table is still a '
      'draft, which lowers trust in every result.';
  final top = ranked.isEmpty ? 'a balance of goals' : _lower(priorityLabels[ranked.first]!);
  card.headline = card.isCurrent
      ? 'Your current rotation scores ${pts(card.total)} out of 100 for what '
          'matters to you.'
      : '$title scores ${pts(card.total)} out of 100, mainly for $top. '
          'Confidence: ${_lower(card.confidence)}. Review with a local '
          'expert before planting.';
  return card;
}
