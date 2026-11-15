// Data definitions shared by the whole app. No Flutter imports here, so the
// engine can be run and tested with plain Dart.

import '../data/countries.dart';

const monthNames = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// One day of weather from NASA POWER.
class DayRecord {
  const DayRecord(this.date, this.rain, this.tmax, this.tmin, this.wet,
      {this.tmean, this.et});
  final DateTime date; // UTC, midnight
  final double rain; // mm
  final double tmax; // deg C
  final double tmin; // deg C
  final double wet; // root-zone soil wetness, 0..1
  final double? tmean; // deg C, NASA's daily mean when available
  final double? et; // mm, NASA's evapotranspiration estimate when available
}

/// A growing season. If endMonth < startMonth it runs into the next year.
class SeasonDef {
  const SeasonDef(this.name, this.startMonth, this.endMonth);
  final String name;
  final int startMonth;
  final int endMonth;
  String get months =>
      '${monthNames[startMonth - 1]} to ${monthNames[endMonth - 1]}';
}

class SeasonPattern {
  const SeasonPattern(this.label, this.seasons);
  final String label;
  final List<SeasonDef> seasons;

  /// Two seasons a year: plan 2 years (4 plantings). One season: plan 3 years.
  int get rotationLength => seasons.length >= 2 ? 4 : 3;
  int get years => rotationLength ~/ seasons.length;
  SeasonDef seasonAt(int slot) => seasons[slot % seasons.length];
  int yearOf(int slot) => slot ~/ seasons.length + 1;
  String slotLabel(int slot) => 'Year ${yearOf(slot)}, ${seasonAt(slot).months}';
}

const seasonPatterns = <SeasonPattern>[
  SeasonPattern('Two rainy seasons (Mar to May, Sep to Nov)',
      [SeasonDef('First rains', 3, 5), SeasonDef('Second rains', 9, 11)]),
  SeasonPattern('Two rainy seasons (Mar to May, Oct to Dec)',
      [SeasonDef('Long rains', 3, 5), SeasonDef('Short rains', 10, 12)]),
  SeasonPattern('One long rainy season (Apr to Oct)',
      [SeasonDef('Main season', 4, 10)]),
  SeasonPattern('One rainy season (Jun to Sep)',
      [SeasonDef('Main season', 6, 9)]),
  SeasonPattern('One rainy season (May to Oct)',
      [SeasonDef('Main season', 5, 10)]),
  SeasonPattern('Two rainy seasons (Apr to Jul, Sep to Nov)',
      [SeasonDef('Major season', 4, 7), SeasonDef('Minor season', 9, 11)]),
  SeasonPattern('One rainy season (Nov to Apr)',
      [SeasonDef('Main season', 11, 4)]),
  SeasonPattern('Winter rains (Oct to Apr)',
      [SeasonDef('Winter season', 10, 4)]),
];

/// One row of data/crops.csv. See tool/csv_to_dart.py for how the text
/// columns are turned into the numeric scores.
class Crop {
  const Crop({
    required this.name,
    required this.family,
    required this.scientificName,
    required this.cropType,
    required this.perennial,
    required this.waterMin,
    required this.waterMax,
    required this.tempMin,
    required this.tempMax,
    required this.daysMin,
    required this.daysMax,
    required this.slots,
    required this.nitrogenEffect,
    required this.nFixMin,
    required this.nFixMax,
    required this.nutrientDemand,
    required this.drought,
    required this.waterlogging,
    required this.groundCover,
    required this.residue,
    required this.residueScore,
    required this.rootDepth,
    required this.somEffect,
    required this.somScore,
    required this.pests,
    required this.hostGroup,
    required this.breakSeasons,
    required this.yieldMin,
    required this.yieldMax,
    required this.yieldBasis,
    required this.costMin,
    required this.costMax,
    required this.priceMin,
    required this.priceMax,
    required this.marketUnit,
    required this.marketNotes,
    required this.priceVariability,
    required this.priceRisk,
    required this.marketAccess,
    required this.storability,
    required this.storeScore,
    required this.kcalPerKg,
    required this.proteinPerKg,
    required this.staple,
    required this.plantingWindow,
    required this.goodAfter,
    required this.badAfter,
    required this.goodAfterText,
    required this.badAfterText,
    required this.confidence,
    required this.saleFraction,
    required this.needsFlooding,
  });

  final String name, family, scientificName, cropType;
  final bool perennial;
  final double waterMin, waterMax; // mm over the crop's life
  final double tempMin, tempMax; // deg C
  final int daysMin, daysMax; // days to maturity
  final int slots; // seasons occupied; 0 = permanent block
  final String nitrogenEffect;
  final double nFixMin, nFixMax; // kg N per ha
  final int nutrientDemand; // 1..5
  final int drought; // tolerance 1..5
  final int waterlogging; // tolerance 1..5
  final int groundCover; // 1..5
  final String residue;
  final int residueScore; // 1..5
  final String rootDepth;
  final String somEffect;
  final double somScore; // -0.5..2
  final String pests;
  final String hostGroup;
  final int breakSeasons; // seasons before the same host group returns
  final double yieldMin, yieldMax; // t per ha
  final String yieldBasis;
  final double costMin, costMax; // UGX per ha
  final double priceMin, priceMax; // UGX per kg
  final String marketUnit, marketNotes, priceVariability;
  final double priceRisk; // 1..5
  final String marketAccess, storability;
  final int storeScore; // 1..5
  final double kcalPerKg, proteinPerKg;
  final String staple, plantingWindow;
  final List<String> goodAfter, badAfter; // crop names
  final String goodAfterText, badAfterText;
  final String confidence;
  final double saleFraction; // assumption, see csv_to_dart.py
  final bool needsFlooding;

  bool get fixesNitrogen => nFixMax > 0;
  bool get deepRooted => rootDepth.contains('deep');
  double get nFixMid => (nFixMin + nFixMax) / 2;
  double get yieldMid => (yieldMin + yieldMax) / 2;
  double get costMid => (costMin + costMax) / 2;
  double get priceMid => (priceMin + priceMax) / 2;
  int get daysMid => (daysMin + daysMax) ~/ 2;

  /// Rough sales minus costs for one hectare, UGX, at mid yield and price.
  double get marginMid => yieldMid * 1000 * saleFraction * priceMid - costMid;
  double get marginLow => yieldMin * 1000 * saleFraction * priceMin - costMax;
  double get marginHigh => yieldMax * 1000 * saleFraction * priceMax - costMin;
  double get kcalPerHa => yieldMid * 1000 * saleFraction * kcalPerKg;
}

/// The goals a farmer can weigh. Order is the order shown on screen.
const priorityKeys = [
  'water', 'forage', 'nitrogen', 'erosion', 'organic', 'market', 'food',
];

/// Shown through t('p_<key>') so each language has its own words.
const priorityLabels = {
  'water': 'Using less water',
  'forage': 'Feed for animals',
  'nitrogen': 'Nitrogen for the soil',
  'erosion': 'Less erosion',
  'organic': 'More organic matter',
  'market': 'Crops that sell well',
  'food': 'Food for the household',
};

const priorityShort = {
  'water': 'Less water',
  'forage': 'Animal feed',
  'nitrogen': 'Nitrogen',
  'erosion': 'Less erosion',
  'organic': 'Organic matter',
  'market': 'Sells well',
  'food': 'Food',
};

const soilTypes = ['Sandy', 'Sandy loam', 'Loam', 'Clay loam', 'Clay'];
const organicLevels = ['Low', 'Medium', 'High'];
const betweenLabels = ['Bare', 'Residue left', 'Cover crop'];
const waterLabels = ['Rain only', 'Some irrigation', 'Wetland'];
const budgetLabels = ['Low', 'Medium', 'High'];

/// Everything the farmer told us. All of it can be edited later.
class FarmSetup {
  // Where the field is. Country and place come from the location services;
  // the built-in African list fills them in when offline.
  String continent = 'Africa';
  String countryName = 'Uganda';
  String countryCode = 'UG';
  String region = '';
  String district = '';
  String locality = 'Luweero';
  String placePath = 'Luweero, Uganda';
  double lat = 0.84;
  double lon = 32.49;

  /// -1 = find the two wettest three-month windows in the NASA record
  /// (the default). Otherwise an index into seasonPatterns.
  int patternIndex = -1;
  List<String?> current = ['Maize', 'Maize', 'Maize', 'Beans'];
  int between = 0; // index into betweenLabels
  String? soilType;
  double? ph;
  String? organicMatter;
  int water = 0; // index into waterLabels
  int budget = 0; // index into budgetLabels
  bool nearMarket = true;
  Map<String, double> weights = {
    'water': 0.5, 'forage': 0.2, 'nitrogen': 0.8, 'erosion': 0.6,
    'organic': 0.5, 'market': 0.7, 'food': 0.7,
  };
  bool useSample = false;

  /// The built-in entry for this country, if it is African.
  Country? get country => countryByCode(countryCode);
  String get placeName => locality.isNotEmpty
      ? locality
      : '${lat.toStringAsFixed(2)}, ${lon.toStringAsFixed(2)}';
  bool get autoSeasons => patternIndex < 0;
  bool get soilEmpty => soilType == null && ph == null && organicMatter == null;

  Map<String, dynamic> toJson() => {
        'continent': continent, 'countryName': countryName, 'countryCode': countryCode,
        'region': region, 'district': district, 'locality': locality,
        'placePath': placePath, 'lat': lat, 'lon': lon, 'patternIndex': patternIndex,
        'current': current, 'between': between, 'soilType': soilType, 'ph': ph,
        'organicMatter': organicMatter, 'water': water, 'budget': budget,
        'nearMarket': nearMarket, 'weights': weights, 'useSample': useSample,
      };

  static FarmSetup fromJson(Map<String, dynamic> m) {
    final s = FarmSetup()
      ..continent = m['continent'] as String? ?? 'Africa'
      ..countryName = m['countryName'] as String? ?? 'Uganda'
      ..countryCode = m['countryCode'] as String? ?? 'UG'
      ..region = m['region'] as String? ?? ''
      ..district = m['district'] as String? ?? ''
      ..locality = m['locality'] as String? ?? ''
      ..placePath = m['placePath'] as String? ?? ''
      ..lat = (m['lat'] as num).toDouble()
      ..lon = (m['lon'] as num).toDouble()
      ..patternIndex = m['patternIndex'] as int? ?? -1
      ..current = [for (final c in m['current'] as List<dynamic>) c as String?]
      ..between = m['between'] as int? ?? 0
      ..soilType = m['soilType'] as String?
      ..ph = (m['ph'] as num?)?.toDouble()
      ..organicMatter = m['organicMatter'] as String?
      ..water = m['water'] as int? ?? 0
      ..budget = m['budget'] as int? ?? 0
      ..nearMarket = m['nearMarket'] as bool? ?? true
      ..useSample = m['useSample'] as bool? ?? false;
    final w = m['weights'] as Map<String, dynamic>?;
    if (w != null) {
      s.weights = {for (final e in w.entries) e.key: (e.value as num).toDouble()};
    }
    return s;
  }

  /// Share of rain assumed to stay available to roots. A rule of thumb:
  /// sandy soils drain fast and hold less water.
  double get rainFactor {
    switch (soilType) {
      case 'Sandy':
        return 0.85;
      case 'Sandy loam':
        return 0.93;
      default:
        return 1.0;
    }
  }

  /// Extra water per season from irrigation, mm. A rough allowance.
  double get irrigationMm => water == 1 ? 150 : 0;

  /// Highest input and labour cost per hectare the farmer can carry, UGX.
  double get costLimit => const [2000000.0, 4500000.0, double.infinity][budget];
}

String ugx(double v) {
  final neg = v < 0;
  final a = v.abs();
  String s;
  if (a >= 1000000) {
    s = '${(a / 1000000).toStringAsFixed(a >= 10000000 ? 0 : 1)}M';
  } else if (a >= 1000) {
    s = '${(a / 1000).toStringAsFixed(0)}k';
  } else {
    s = a.toStringAsFixed(0);
  }
  return '${neg ? '-' : ''}UGX $s';
}
