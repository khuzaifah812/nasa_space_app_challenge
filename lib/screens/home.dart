// Screen 8: home.
import 'package:flutter/material.dart';

import '../analysis.dart';
import '../engine/explanation.dart';
import '../engine/models.dart';
import '../l10n/strings.dart';
import '../widgets/common.dart';
import '../widgets/logo.dart';
import 'calendar.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key, required this.analysis, required this.onTab, required this.onEdit});
  final Analysis analysis;
  final ValueChanged<int> onTab;
  final VoidCallback onEdit;

  /// The season we are in, or the next one to start.
  SeasonDef _season() {
    final m = DateTime.now().month;
    final seasons = analysis.pattern.seasons;
    for (final s in seasons) {
      final inside = s.startMonth <= s.endMonth
          ? m >= s.startMonth && m <= s.endMonth
          : m >= s.startMonth || m <= s.endMonth;
      if (inside) return s;
    }
    for (final s in seasons) {
      if (s.startMonth > m) return s;
    }
    return seasons.first;
  }

  @override
  Widget build(BuildContext context) {
    final a = analysis;
    final s = a.setup;
    final theme = Theme.of(context);
    final res = a.result();
    final cur = res.current;
    final best = res.options.isEmpty ? null : res.options.first;
    final def = _season();
    final season = a.summary[def.name]!;

    Widget stat(String value, String label) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
              Text(label,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
        );

    return Scaffold(
      appBar: AppBar(
        leading: const Padding(
            padding: EdgeInsets.all(10), child: AgriSmartLogo(size: 36)),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.placeName),
            Text(
                '${s.countryName}'
                '${s.soilType == null ? '' : ', ${s.soilType!.toLowerCase()}'}',
                style: const TextStyle(fontSize: 13)),
          ],
        ),
        actions: [
          IconButton(tooltip: t('editField'), icon: const Icon(Icons.edit_outlined), onPressed: onEdit),
        ],
      ),
      body: PageBody(
        children: [
          if (cur != null && cur.detail.bareMonths >= 1)
            Notice(
              tf('bareTitle', {'n': cur.detail.bareMonths.toStringAsFixed(1)}),
              s.between == 0 ? t('bareBare') : t('bareCovered'),
            ),
          Panel(
            title: tf('typicalSeason', {'season': def.name}),
            hint: tf('averageOf', {
              'months': def.months,
              'n': season.nYears,
              'source': a.isSample ? t('sample') : t('nasa'),
            }),
            child: Row(
              children: [
                stat('${season.rain.toStringAsFixed(0)} mm', t('rain')),
                stat('${(season.wet * 100).toStringAsFixed(0)}%', t('soilWetness')),
                stat(season.heatDays.toStringAsFixed(1), t('hotDays')),
              ],
            ),
          ),
          if (cur != null)
            Panel(
              title: t('yourRotation'),
              hint: cur.detail.names,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(t('match'))),
                      Text(tf('outOf100', {'n': pts(cur.total)}),
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ScoreBar(cur.total, dark: true),
                  if (best != null) ...[
                    const SizedBox(height: 10),
                    Text(tf('optionScores', {'option': best.title, 'n': pts(best.total), 'crops': best.detail.names})),
                  ],
                  const SizedBox(height: 12),
                  FilledButton(
                      onPressed: () => onTab(2), child: Text(t('seeOptions'))),
                ],
              ),
            )
          else
            Panel(
              title: t('rotationOptions'),
              hint: t('noCurrent'),
              child: FilledButton(
                  onPressed: () => onTab(2), child: Text(t('seeOptions'))),
            ),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => onTab(1),
                  icon: const Icon(Icons.wb_sunny_outlined),
                  label: Text(t('tab_conditions')),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
                      builder: (_) => CalendarScreen(analysis: a))),
                  icon: const Icon(Icons.calendar_month_outlined),
                  label: Text(t('fieldYear')),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Panel(
            title: t('dataSource'),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(a.isSample ? Icons.science_outlined : Icons.satellite_alt_outlined,
                    color: theme.colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(a.isSample
                      ? t('sampleSource')
                      : 'NASA POWER daily records (rain, temperature, soil '
                          'wetness${a.weather.hasMeasuredEt ? ', evapotranspiration' : ''}) '
                          'for latitude ${s.lat.toStringAsFixed(3)}, longitude '
                          '${s.lon.toStringAsFixed(3)}, ${a.startYear} to '
                          '${a.endYear}. Seasons: ${a.pattern.label.toLowerCase()}.'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
