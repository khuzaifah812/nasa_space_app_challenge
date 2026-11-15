// Answers that need no AI model and no internet: built from the field's
// NASA figures, the rotations and the crop table, in the chosen language.
// Questions are matched by keywords in all six languages.
import '../analysis.dart';
import '../data/crops_data.dart';
import '../engine/explanation.dart';
import '../engine/models.dart';
import '../l10n/strings.dart';
import 'faq.dart';

/// Keywords per topic. Each list mixes the six languages; matching is on
/// lower-cased substrings, so "pluie" also matches "pluies".
const _topics = <String, List<String>>{
  'help': ['help', 'stuck', 'how do i', 'how to', 'start', 'next', 'ensuite', 'seguir', 'ahora', 'الآن', 'aide', 'bloqu', 'comment', 'msaada', 'nimekwama', 'jinsi', 'vipi', 'ajuda', 'preso', 'como', 'مساعدة', 'كيف', 'عالق', 'ayuda', 'atascad', 'cómo', 'como'],
  'rain': ['rain', 'pluie', 'mvua', 'chuva', 'مطر', 'أمطار', 'lluvia'],
  'heat': ['hot', 'heat', 'temperature', 'chaud', 'chaleur', 'températ', 'joto', 'calor', 'temperatur', 'حرار', 'حار'],
  'wet': ['moisture', 'wetness', 'soil water', 'humidité', 'unyevu', 'humidade', 'رطوبة', 'humedad'],
  'season': ['season', 'when', 'plant', 'saison', 'quand', 'semer', 'msimu', 'lini', 'kupanda', 'estaç', 'quando', 'semear', 'موسم', 'متى', 'زراع', 'temporada', 'cuándo', 'sembrar'],
  'best': ['best', 'recommend', 'option', 'suggest', 'which rotation', 'what should i', 'meilleur', 'recommand', 'bora', 'pendekez', 'melhor', 'recomend', 'أفضل', 'توصي', 'mejor'],
  'why': ['why', 'pourquoi', 'kwa nini', 'porqu', 'لماذا', 'por qué'],
  'current': ['my rotation', 'current', 'score', 'ma rotation', 'actuel', 'mzunguko wangu', 'wa sasa', 'alama', 'minha rotação', 'atual', 'pontuação', 'دورتي', 'الحالية', 'نتيجة', 'mi rotación', 'puntuación'],
  'bare': ['bare', 'cover', 'erosion', 'nu ', 'couverture', 'érosion', 'wazi', 'mmomonyoko', 'cobertura', 'erosão', 'عار', 'تعرية', 'desnudo', 'erosión'],
  'risk': ['risk', 'danger', 'risque', 'hatari', 'risco', 'خطر', 'مخاطر', 'riesgo'],
  'pest': ['pest', 'disease', 'insect', 'worm', 'ravageur', 'maladie', 'wadudu', 'magonjwa', 'praga', 'doença', 'آفة', 'آفات', 'مرض', 'plaga', 'enfermedad'],
  'market': ['price', 'sell', 'market', 'money', 'income', 'profit', 'prix', 'vendre', 'marché', 'argent', 'bei', 'soko', 'kuuza', 'pesa', 'preço', 'mercado', 'vender', 'dinheiro', 'سعر', 'سوق', 'بيع', 'مال', 'precio', 'vender', 'dinero'],
  'water': ['water', 'irrigat', 'eau', 'irrig', 'maji', 'umwagiliaji', 'água', 'rega', 'ماء', 'ري', 'agua', 'riego'],
  'nitrogen': ['nitrogen', 'fertil', 'legume', 'manure', 'azote', 'légumineuse', 'fumier', 'naitrojeni', 'rutuba', 'mikunde', 'mbolea', 'azoto', 'leguminosa', 'adubo', 'نيتروجين', 'خصوب', 'بقول', 'سماد', 'nitrógeno', 'abono'],
  'data': ['nasa', 'data', 'source', 'satellite', 'where do', 'numbers', 'chiffres', 'números', 'numeros', 'أرقام', 'zinatoka', 'données', 'takwimu', 'setilaiti', 'dados', 'fonte', 'بيانات', 'ناسا', 'مصدر', 'datos', 'fuente', 'satélite'],
  'confidence': ['sure', 'confiden', 'trust', 'accura', 'reliab', 'sûr', 'confiance', 'fiable', 'uhakika', 'certeza', 'confiança', 'ثقة', 'يقين', 'دقة', 'seguro', 'confianza', 'fiable'],
  'expert': ['expert', 'advis', 'extension', 'officer', 'conseiller', 'mshauri', 'mtaalamu', 'técnico', 'extensionista', 'مرشد', 'خبير', 'asesor', 'experto'],
  'language': ['language', 'langue', 'lugha', 'idioma', 'لغة'],
};

/// The topic a question is about, or '' if none is recognised. A specific
/// topic (rain, risks...) wins over the general "help", because questions
/// often start with "how" in every language.
String topicOf(String q) {
  final lower = ' ${q.toLowerCase()} ';
  var best = '';
  var bestLen = 0;
  var help = false;
  _topics.forEach((topic, words) {
    for (final w in words) {
      if (!lower.contains(w)) continue;
      if (topic == 'help') {
        help = true;
      } else if (w.length > bestLen) {
        best = topic;
        bestLen = w.length;
      }
    }
  });
  return best.isNotEmpty ? best : (help ? 'help' : '');
}

Crop? _cropIn(String q) {
  final lower = q.toLowerCase();
  for (final c in crops) {
    final stem = c.name.toLowerCase().split(' ').first.replaceAll(RegExp(r'e?s$'), '');
    if (stem.length >= 4 && lower.contains(stem)) return c;
  }
  return null;
}

String _n(double v, [int d = 0]) => v.toStringAsFixed(d);

/// The quick questions offered as chips, as translation keys.
const quickQuestions = ['q_best', 'q_rain', 'q_season', 'q_risk', 'q_stuck', 'q_data'];

String offlineAnswer(String question, Analysis? a) {
  final topic = topicOf(question);
  final crop = _cropIn(question);
  final b = StringBuffer();

  if (crop != null && topic != 'best' && topic != 'why') {
    b.writeln(tf('as_crop', {'crop': crop.name}));
    b.writeln('• ${_n(crop.waterMin)}–${_n(crop.waterMax)} mm, ${_n(crop.tempMin)}–${_n(crop.tempMax)} °C, ${crop.daysMin}–${crop.daysMax} ${t('as_days')}');
    b.writeln('• ${crop.nitrogenEffect}');
    b.writeln('• UGX ${_n(crop.priceMin)}–${_n(crop.priceMax)}/kg (${crop.marketUnit})');
    b.writeln('• ${t('as_goodAfter')}: ${crop.goodAfterText}');
    b.writeln('• ${t('as_avoidAfter')}: ${crop.badAfterText}');
    b.writeln('• ${t('as_pestsAre')}: ${crop.pests}');
    b.writeln();
    b.write(t('as_englishNote'));
    return b.toString();
  }

  // the memorised answers to common questions
  final remembered = faqAnswer(question);
  if (remembered != null) return remembered;

  if (topic == 'help' || topic == '') {
    if (topic == '') b.writeln(t('as_unknown'));
    b.writeln(t('as_steps'));
    b.writeln('1. ${t('step1t')}: ${t('step1')}');
    b.writeln('2. ${t('step2t')}: ${t('step2')}');
    b.writeln('3. ${t('step3t')}: ${t('step3')}');
    b.writeln('4. ${t('step4t')}: ${t('step4')}');
    if (a == null) b.writeln('\n${t('as_noField')}');
    return b.toString().trim();
  }
  if (topic == 'language') return t('as_language');
  if (topic == 'expert') return t('as_expert');

  if (a == null) {
    return '${t('as_noField')}\n\n${t('as_steps')}\n1. ${t('step1t')}\n2. ${t('step2t')}';
  }

  final res = a.result();
  final cur = res.current;
  final best = res.options.isNotEmpty ? res.options.first : null;
  final src = a.isSample ? t('as_sampleWarn') : '';

  switch (topic) {
    case 'rain':
    case 'water':
      for (final def in a.pattern.seasons) {
        final s = a.summary[def.name]!;
        final trend = s.rainTrend.abs() < 0.05 * s.rain
            ? t('as_steady')
            : (s.rainTrend < 0 ? tf('as_fallen', {'n': _n(s.rainTrend.abs())}) : tf('as_risen', {'n': _n(s.rainTrend.abs())}));
        b.writeln(tf('as_rain', {'season': def.months, 'rain': _n(s.rain), 'et': _n(s.et0), 'balance': (s.balance >= 0 ? '+' : '') + _n(s.balance), 'years': s.nYears, 'trend': trend}));
      }
      if (topic == 'water' && best != null) {
        b.writeln(tf('as_waterNeed', {'option': best.title, 'n': _n(best.detail.waterPerYear), 'now': cur == null ? '-' : _n(cur.detail.waterPerYear)}));
      }
      break;
    case 'heat':
      for (final def in a.pattern.seasons) {
        final s = a.summary[def.name]!;
        b.writeln(tf('as_heat', {'season': def.months, 't': _n(s.tmean, 1), 'hot': _n(s.heatDays, 1), 'cold': _n(s.coldNights, 1)}));
      }
      b.writeln(t('as_heatWhy'));
      break;
    case 'wet':
      for (final def in a.pattern.seasons) {
        final s = a.summary[def.name]!;
        b.writeln(tf('as_wet', {'season': def.months, 'wet': _n(s.wet * 100), 'dry': _n(s.drySpells, 1)}));
      }
      b.writeln(t('as_wetWhy'));
      break;
    case 'season':
      b.writeln(tf('as_seasons', {'seasons': a.pattern.seasons.map((d) => d.months).join(', ')}));
      for (final def in a.pattern.seasons) {
        final s = a.summary[def.name]!;
        b.writeln(tf('as_seasonLen', {'season': def.months, 'days': _n(s.length)}));
      }
      b.writeln(t('as_seasonNote'));
      break;
    case 'best':
    case 'why':
      if (best == null) {
        b.writeln(t('as_noField'));
        break;
      }
      final target = topic == 'why' && crop == null ? best : best;
      b.writeln(tf('as_best', {'option': target.title, 'crops': target.detail.names, 'n': pts(target.total)}));
      if (cur != null) b.writeln(tf('as_vsCurrent', {'n': pts(cur.total)}));
      b.writeln(t('as_because'));
      for (final r in target.reasons.take(3)) {
        b.writeln('• $r');
      }
      b.writeln(t('as_englishNote'));
      break;
    case 'current':
      if (cur == null) {
        b.writeln(t('as_noCurrent'));
      } else {
        b.writeln(tf('as_current', {'crops': cur.detail.names, 'n': pts(cur.total), 'bare': _n(cur.detail.bareMonths, 1), 'pest': cur.detail.pestBreaks}));
        if (best != null) b.writeln(tf('as_best', {'option': best.title, 'crops': best.detail.names, 'n': pts(best.total)}));
      }
      break;
    case 'bare':
      final c = cur ?? best;
      if (c != null) {
        b.writeln(tf('as_bare', {'title': c.title, 'bare': _n(c.detail.bareMonths, 1)}));
        b.writeln(t('bareBare'));
      }
      break;
    case 'risk':
    case 'pest':
      final c = best ?? cur;
      if (c != null) {
        b.writeln(tf('as_risks', {'title': c.title}));
        for (final r in c.risks.take(topic == 'pest' ? 6 : 4)) {
          if (topic == 'pest' && !r.contains('watch for')) continue;
          b.writeln('• $r');
        }
        if (topic == 'pest' && !c.risks.any((r) => r.contains('watch for'))) {
          for (final r in c.risks.take(4)) {
            b.writeln('• $r');
          }
        }
        b.writeln(t('as_englishNote'));
      }
      break;
    case 'market':
      final c = best ?? cur;
      if (c != null) {
        b.writeln(tf('as_market', {'title': c.title, 'ugx': ugx(c.detail.marginPerYear)}));
        for (final p in c.detail.plantings) {
          b.writeln('• ${p.crop.name}: UGX ${_n(p.crop.priceMin)}–${_n(p.crop.priceMax)}/kg, ${p.crop.priceVariability}');
        }
        b.writeln(t('earningsNote'));
      }
      break;
    case 'nitrogen':
      final c = best ?? cur;
      if (c != null) {
        b.writeln(tf('as_nitrogen', {'title': c.title, 'n': _n(c.detail.nFixedPerYear)}));
      }
      b.writeln(t('as_nitrogenWhy'));
      break;
    case 'data':
      b.writeln(a.isSample
          ? t('sampleSource')
          : tf('as_data', {'lat': a.setup.lat.toStringAsFixed(3), 'lon': a.setup.lon.toStringAsFixed(3), 'from': a.startYear, 'to': a.endYear}));
      b.writeln(t('as_dataMore'));
      break;
    case 'confidence':
      final c = best ?? cur;
      if (c != null) {
        b.writeln(tf('as_confidence', {'title': c.title, 'level': t(c.confidence.toLowerCase())}));
        b.writeln(c.confidenceWhy);
      }
      for (final g in (c?.gaps ?? const <String>[]).take(3)) {
        b.writeln('• $g');
      }
      break;
  }
  if (src.isNotEmpty) b.writeln('\n$src');
  return b.toString().trim();
}
