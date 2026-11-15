// Tries the offline assistant without the UI:  dart run tool/ask.dart
import 'package:agrismart/analysis.dart';
import 'package:agrismart/assistant/offline.dart';
import 'package:agrismart/engine/demo_data.dart';
import 'package:agrismart/engine/extra_data.dart';
import 'package:agrismart/engine/models.dart';
import 'package:agrismart/l10n/strings.dart';

void main() {
  final setup = FarmSetup()..soilType = 'Sandy loam';
  final weather = WeatherRecord(setup.lat, setup.lon, sampleWeather(seasonPatterns[0], 2006, 2025),
      true, 2006, 2025,
      extras: const FieldExtras(elevation: 1100, slopePct: 7.5, terrainSource: 'test'));
  final a = Analysis(setup, weather);
  const asks = {
    'en': ['Which rotation is best for me?', 'tell me about beans', 'what about pests', 'xyz'],
    'fr': ['Comment la pluie change-t-elle ici ?', 'Quels sont les risques ?'],
    'sw': ['Misimu ni lini?', 'Nimekwama, nifanye nini sasa?', 'bei ya soko'],
    'ar': ['كيف يتغير المطر هنا؟', 'من أين تأتي الأرقام؟'],
    'pt': ['Qual é a melhor rotação para mim?'],
    'es': ['¿Cuándo son las temporadas?'],
  };
  asks.forEach((code, qs) {
    Lang.set(code);
    for (final q in qs) {
      print('\n[$code] $q\n${offlineAnswer(q, a)}');
    }
  });
  for (final e in const {'en': 'what is crop rotation?', 'sw': 'viwavi jeshi kwenye mahindi', 'fr': 'comment faire le paillage ?', 'ar': 'ما هو محصول تغطية'}.entries) {
    Lang.set(e.key);
    print('\n[memory ${e.key}] ${e.value}\n${offlineAnswer(e.value, a)}\n${t('as_connect')} | ${t('as_intro')}');
  }
  // every quick-question chip must land on its topic in every language
  const want = {'q_best': 'best', 'q_rain': 'rain', 'q_season': 'season', 'q_risk': 'risk', 'q_stuck': 'help', 'q_data': 'data'};
  var bad = 0;
  for (final code in ['en', 'fr', 'sw', 'pt', 'ar', 'es']) {
    Lang.set(code);
    want.forEach((key, topic) {
      final got = topicOf(t(key));
      if (got != topic) {
        bad++;
        print('MISMATCH [$code] $key "${t(key)}" -> "$got" (want $topic)');
      }
    });
  }
  print('\nchip check: $bad mismatches');
  Lang.set('en');
  print('\n[no field] help\n${offlineAnswer('help', null)}');
  print('\nerosion Now/A: ${a.result().cards.map((c) => (c.detail.scores['erosion']! * 100).round()).toList()}');
  print(a.result().cards[1].risks.where((r) => r.contains('SRTM')).toList());
}
