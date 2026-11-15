// Screen 9: what NASA records show for this field.
import 'package:flutter/material.dart';

import '../analysis.dart';
import '../engine/indicators.dart';
import '../widgets/charts.dart';
import '../l10n/strings.dart';
import '../widgets/common.dart';
import '../widgets/nasa_map.dart';
import '../data/countries.dart';
import 'calendar.dart';

class ConditionsTab extends StatefulWidget {
  const ConditionsTab({super.key, required this.analysis});
  final Analysis analysis;
  @override
  State<ConditionsTab> createState() => _ConditionsTabState();
}

class _ConditionsTabState extends State<ConditionsTab> {
  int _season = 0;

  /// "rising", "falling" or "steady", judged against the size of the value.
  static String trendWord(SeasonSummary s, Indicator ind) {
    final values = s.series(ind.value);
    final t = s.trend(ind.value);
    var hi = values.first, lo = values.first;
    for (final v in values) {
      if (v > hi) hi = v;
      if (v < lo) lo = v;
    }
    final scale = (hi - lo).abs() < 1e-9 ? 1.0 : hi - lo;
    if (t.abs() < 0.15 * scale) return 'steady';
    return t > 0 ? 'rising' : 'falling';
  }

  void _open(SeasonSummary s, Indicator ind) {
    final theme = Theme.of(context);
    final t = s.trend(ind.value);
    final word = trendWord(s, ind);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${ind.title}, ${s.season.months}',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(ind.what),
              const SizedBox(height: 12),
              YearBars(years: s.years, values: s.series(ind.value), unit: ind.unit),
              const SizedBox(height: 8),
              Text(
                  word == 'steady'
                      ? 'It has stayed about level over ${s.nYears} years.'
                      : 'It has been $word by about '
                          '${t.abs().toStringAsFixed(ind.digits == 0 ? 0 : 1)} ${ind.unit} every ten years.',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              const Label('What it means for your crops and soil'),
              Text(ind.why),
              const Label('Where the number comes from'),
              Text('${widget.analysis.isSample ? 'Sample data standing in for: ' : ''}${ind.source}. '
                  'It describes an area about 50 km across. A rain gauge or '
                  'your own notes for this field are more exact, and the two '
                  'together are better than either alone.'),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.analysis;
    final theme = Theme.of(context);
    final seasons = a.pattern.seasons;
    final s = a.summary[seasons[_season].name]!;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t('conditions')),
            Text(tf('records', {'source': a.isSample ? t('sample') : t('nasa'), 'from': a.startYear, 'to': a.endYear}),
                style: const TextStyle(fontSize: 13)),
          ],
        ),
      ),
      body: PageBody(
        maxWidth: 980,
        children: [
          if (seasons.length > 1) ...[
            SegmentedButton<int>(
              showSelectedIcon: false,
              segments: [
                for (var i = 0; i < seasons.length; i++)
                  ButtonSegment(value: i, label: Text(seasons[i].months)),
              ],
              selected: {_season},
              onSelectionChanged: (v) => setState(() => _season = v.first),
            ),
            const SizedBox(height: 12),
          ],
          LayoutBuilder(builder: (context, box) {
            final cols = box.maxWidth >= 820 ? 4 : box.maxWidth >= 560 ? 3 : 2;
            final w = (box.maxWidth - 10 * (cols - 1)) / cols;
            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final ind in indicators)
                  SizedBox(
                    width: w,
                    child: Material(
                      color: theme.colorScheme.surfaceContainerLow,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: theme.colorScheme.outlineVariant),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => _open(s, ind),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(ind.title,
                                  style: const TextStyle(fontWeight: FontWeight.w600)),
                              Text(
                                  '${s.avg(ind.value).toStringAsFixed(ind.digits)} ${ind.unit}',
                                  style: theme.textTheme.titleLarge
                                      ?.copyWith(fontWeight: FontWeight.w700)),
                              Sparkline(s.series(ind.value)),
                              Text(trendWord(s, ind),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          }),
          const SizedBox(height: 8),
          Text(t('tapCard'),
              textAlign: TextAlign.center, style: theme.textTheme.bodySmall),
          const SizedBox(height: 12),
          Panel(
            title: t('terrain'),
            child: Text(a.weather.extras.hasTerrain
                ? '${a.weather.extras.elevation!.toStringAsFixed(0)} m ${t('elevation')}, '
                    '${t('slope')} ${a.weather.extras.slopePct!.toStringAsFixed(1)}%. '
                    '${a.weather.extras.terrainSource}.'
                : t('notLoaded')),
          ),
          Panel(
            title: t('greenness'),
            hint: t('ndviNote'),
            child: a.weather.extras.hasNdvi
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(a.weather.extras.ndvi.last.value.toStringAsFixed(2),
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                      Sparkline([for (final p in a.weather.extras.ndvi) p.value]),
                      Text(
                          '${a.weather.extras.ndvi.first.date.toIso8601String().substring(0, 10)} → '
                          '${a.weather.extras.ndvi.last.date.toIso8601String().substring(0, 10)}',
                          style: theme.textTheme.bodySmall),
                    ],
                  )
                : Text(t('notLoaded')),
          ),
          NasaMap(
            countryName: a.setup.countryName,
            cities: countryByCode(a.setup.countryCode)?.cities ?? const [],
            lat: a.setup.lat,
            lon: a.setup.lon,
            onPick: (_, __) {},
            pickable: false,
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) => CalendarScreen(analysis: a))),
            icon: const Icon(Icons.calendar_month_outlined),
            label: Text(t('yearOnField')),
          ),
        ],
      ),
    );
  }
}
