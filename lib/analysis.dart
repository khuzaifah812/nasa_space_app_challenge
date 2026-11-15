// Runs the whole pipeline: weather -> seasons -> indicators -> scoring ->
// explanation. The weather is downloaded once, when the field is chosen,
// and reused for every later step.
import 'engine/demo_data.dart';
import 'engine/explanation.dart';
import 'engine/extra_data.dart';
import 'engine/indicators.dart';
import 'engine/models.dart';
import 'engine/power_api.dart';
import 'engine/scoring.dart';

/// NASA's daily records for one point, plus the seasons found in them.
class WeatherRecord {
  WeatherRecord(this.lat, this.lon, this.days, this.isSample, this.startYear, this.endYear,
      {this.extras = const FieldExtras()})
      : detected = detectSeasons(days);

  /// SRTM slope and MODIS NDVI for the field, when they could be read.
  final FieldExtras extras;
  final double lat;
  final double lon;
  final List<DayRecord> days;
  final bool isSample;
  final int startYear;
  final int endYear;
  final SeasonPattern detected;

  /// Whether NASA's own evapotranspiration estimate was in the download.
  bool get hasMeasuredEt => days.any((d) => d.et != null);

  SeasonPattern patternFor(FarmSetup setup) =>
      setup.autoSeasons ? detected : seasonPatterns[setup.patternIndex];
}

Future<WeatherRecord> fetchWeather(double lat, double lon, {bool sample = false}) async {
  // NASA POWER lags a few days behind, so stop at the last complete year.
  final endYear = DateTime.now().year - 1;
  final startYear = endYear - 19;
  if (sample) {
    return WeatherRecord(
        lat, lon, sampleWeather(seasonPatterns[0], startYear, endYear), true, startYear, endYear);
  }
  // NASA POWER is required; SRTM and MODIS are read alongside and may fail
  // without stopping the app.
  final extras = fetchExtras(lat, lon).catchError((_) => const FieldExtras());
  final days = await fetchPower(lat, lon, startYear, endYear);
  return WeatherRecord(lat, lon, days, false, startYear, endYear, extras: await extras);
}

/// The cards for one weather scenario: current rotation first (if given),
/// then the suggested options.
class ScenarioResult {
  ScenarioResult(this.engine, this.cards);
  final Engine engine;
  final List<ExplanationCard> cards;
  ExplanationCard? get current =>
      cards.isNotEmpty && cards.first.isCurrent ? cards.first : null;
  List<ExplanationCard> get options =>
      [for (final c in cards) if (!c.isCurrent) c];
}

class Analysis {
  Analysis(this.setup, this.weather)
      : pattern = weather.patternFor(setup),
        summary = summarise(weather.days, weather.lat, weather.patternFor(setup)) {
    final engine = Engine(summary, setup, pattern, slopePct: weather.extras.slopePct);
    _optionSlots = [
      for (final r in engine.recommend(setup.weights, exclude: currentSlots)) r.detail.slots
    ];
  }

  final FarmSetup setup;
  final WeatherRecord weather;
  final SeasonPattern pattern;
  final Map<String, SeasonSummary> summary;
  late final List<List<Crop>> _optionSlots;
  final _results = <int, ScenarioResult>{};

  bool get isSample => weather.isSample;
  int get startYear => weather.startYear;
  int get endYear => weather.endYear;

  /// The farmer's rotation, or null if any season was left blank.
  List<Crop>? get currentSlots {
    final out = <Crop>[];
    for (final name in setup.current) {
      final c = cropByName(name);
      if (c == null) return null;
      out.add(c);
    }
    return out.length == pattern.rotationLength ? out : null;
  }

  /// The same rotations re-scored under scenario [index].
  ScenarioResult result([int index = 0]) => _results.putIfAbsent(index, () {
        final engine = Engine(summary, setup, pattern,
            scenario: scenarios[index], extras: weather.extras, slopePct: weather.extras.slopePct);
        final cur = currentSlots;
        final curScore = cur == null ? null : engine.score(cur);
        final cards = <ExplanationCard>[
          if (curScore != null)
            explain(engine, 'Now', 'Your current rotation', curScore, setup.weights),
          for (var i = 0; i < _optionSlots.length; i++)
            explain(engine, 'AB'[i], 'Option ${'AB'[i]}',
                engine.score(_optionSlots[i]), setup.weights,
                current: curScore),
        ];
        return ScenarioResult(engine, cards);
      });

  /// A short record of this plan, kept on the device.
  Map<String, dynamic> toSaved() {
    final res = result();
    final best = res.options.isNotEmpty ? res.options.first : null;
    return {
      'savedAt': DateTime.now().toIso8601String(),
      'setup': setup.toJson(),
      'place': setup.placePath,
      'seasons': pattern.label,
      'best': best?.detail.names ?? '',
      'bestScore': best?.total ?? 0,
      'currentScore': res.current?.total,
      'years': '$startYear to $endYear',
      'isSample': isSample,
    };
  }
}

Future<Analysis> runAnalysis(FarmSetup setup, [WeatherRecord? weather]) async {
  final w = weather != null && weather.isSample == setup.useSample
      ? weather
      : await fetchWeather(setup.lat, setup.lon, sample: setup.useSample);
  return Analysis(setup, w);
}
