// Screen 10: month-by-month view of rain, crop cover, bare months and risk.
import 'package:flutter/material.dart';

import '../analysis.dart';
import '../engine/explanation.dart';
import '../engine/models.dart';
import '../l10n/strings.dart';
import '../widgets/common.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key, required this.analysis, this.initial = 0});
  final Analysis analysis;
  final int initial;
  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late int _card = widget.initial;

  bool _rainy(int month) {
    for (final s in widget.analysis.pattern.seasons) {
      final inside = s.startMonth <= s.endMonth
          ? month >= s.startMonth && month <= s.endMonth
          : month >= s.startMonth || month <= s.endMonth;
      if (inside) return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.analysis;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final cards = a.result().cards;
    final card = cards[_card.clamp(0, cards.length - 1)];
    final d = card.detail;

    Widget cells(String label, List<Color?> colors, {List<String>? letters}) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: theme.textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant)),
              const SizedBox(height: 3),
              Row(
                children: [
                  for (var m = 0; m < 12; m++)
                    Expanded(
                      child: Container(
                        height: 26,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: colors[m] ?? scheme.surface,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: scheme.outlineVariant),
                        ),
                        child: letters == null
                            ? null
                            : Text(letters[m],
                                style: const TextStyle(
                                    fontSize: 10, fontWeight: FontWeight.w700, color: inkDark)),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );

    // the planting that fits its season worst
    var worst = 0;
    for (var j = 1; j < d.fits.length; j++) {
      if (d.fits[j].fit < d.fits[worst].fit) worst = j;
    }
    final wp = d.plantings[worst];
    final wf = d.fits[worst];

    final bareNames = <String>{};
    for (var m = 0; m < d.monthCrops.length; m++) {
      if (d.monthCrops[m] == null) bareNames.add(monthNames[m % 12]);
    }
    final kinds = <String, Color>{for (final c in d.slots) cropKind(c): cropColor(c)};

    return Scaffold(
      appBar: AppBar(title: Text(t('yearOnField'))),
      body: PageBody(
        children: [
          if (cards.length > 1) ...[
            SegmentedButton<int>(
              showSelectedIcon: false,
              segments: [
                for (var i = 0; i < cards.length; i++)
                  ButtonSegment(value: i, label: Text(cards[i].isCurrent ? 'Now' : cards[i].title)),
              ],
              selected: {_card},
              onSelectionChanged: (v) => setState(() => _card = v.first),
            ),
            const SizedBox(height: 12),
          ],
          Panel(
            title: card.title,
            hint: d.names,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    for (final m in monthNames)
                      Expanded(
                        child: Text(m[0],
                            textAlign: TextAlign.center,
                            style: theme.textTheme.labelSmall
                                ?.copyWith(color: scheme.onSurfaceVariant)),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                cells('Rainy months',
                    [for (var m = 1; m <= 12; m++) _rainy(m) ? const Color(0xFF9CC9E0) : null]),
                for (var y = 0; y < a.pattern.years; y++)
                  cells(
                    'Year ${y + 1}: crop on the field (dark = bare)',
                    [
                      for (var m = 0; m < 12; m++)
                        d.monthCrops[y * 12 + m] == null
                            ? scheme.onSurface
                            : cropColor(d.monthCrops[y * 12 + m]!)
                    ],
                    letters: [
                      for (var m = 0; m < 12; m++)
                        d.monthCrops[y * 12 + m]?.name.substring(0, 1) ?? ''
                    ],
                  ),
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    for (final e in kinds.entries)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                  color: e.value, borderRadius: BorderRadius.circular(3))),
                          const SizedBox(width: 5),
                          Text(e.key, style: theme.textTheme.bodySmall),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
          Panel(
            title: 'Bare field',
            child: Text(d.bareMonths < 0.5
                ? 'A crop is on the field almost all year, so the soil stays covered.'
                : 'Nothing is growing for about ${d.bareMonths.toStringAsFixed(1)} months '
                    'a year (${bareNames.join(', ')}). That is when soil dries out '
                    'and heavy rain can wash it away.'),
          ),
          Notice(
            'Most at risk: ${wp.crop.name.toLowerCase()}, ${a.pattern.slotLabel(wp.start).toLowerCase()}',
            'It fits this season least well (${pts(wf.fit)} out of 100), mainly '
                'because of ${wf.limiting}. Rain was enough in ${wf.yearsOk} of '
                '${wf.nYears} past years.',
          ),
          Text(
              'Crop months are estimated from typical days to maturity in the '
              'crop table. Your planting and harvest dates may differ.',
              style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
