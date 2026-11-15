// Screens 11 to 13: rotation options, side-by-side comparison, one in detail.
import 'package:flutter/material.dart';

import '../analysis.dart';
import '../engine/explanation.dart';
import '../engine/models.dart';
import '../engine/scoring.dart';
import '../l10n/strings.dart';
import '../widgets/common.dart';
import 'calendar.dart';

// ---- screen 11 --------------------------------------------------------------

class RotationsTab extends StatelessWidget {
  const RotationsTab({super.key, required this.analysis});
  final Analysis analysis;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cards = analysis.result().cards;
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t('rotationOptions')),
            Text(t('scoredFor'), style: const TextStyle(fontSize: 13)),
          ],
        ),
      ),
      body: PageBody(
        children: [
          for (var i = 0; i < cards.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Material(
                color: theme.colorScheme.surfaceContainerLow,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: theme.colorScheme.outlineVariant),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                      builder: (_) => DetailScreen(analysis: analysis, index: i))),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Tag(cards[i].tag, dark: cards[i].isCurrent),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(cards[i].title,
                                  style: theme.textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w700)),
                            ),
                            const Icon(Icons.chevron_right),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(cards[i].detail.names,
                            style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(t('overall')),
                            const SizedBox(width: 8),
                            Expanded(child: ScoreBar(cards[i].total, dark: cards[i].isCurrent)),
                            const SizedBox(width: 8),
                            Text(pts(cards[i].total),
                                style: const TextStyle(fontWeight: FontWeight.w700)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (final t in cards[i].tags)
                              Pill(t, warn: t.contains('missed') || (cards[i].detail.bareMonths >= 4 && t.contains('bare'))),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          FilledButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) => CompareScreen(analysis: analysis))),
            child: Text(t('compare')),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

// ---- screen 12 --------------------------------------------------------------

class CompareScreen extends StatefulWidget {
  const CompareScreen({super.key, required this.analysis});
  final Analysis analysis;
  @override
  State<CompareScreen> createState() => _CompareScreenState();
}

class _CompareScreenState extends State<CompareScreen> {
  int _scenario = 0;

  @override
  Widget build(BuildContext context) {
    final a = widget.analysis;
    final theme = Theme.of(context);
    final cards = a.result(_scenario).cards;
    final base = a.result().cards;
    final divider = BorderSide(color: theme.colorScheme.outlineVariant);

    TableRow head() => TableRow(children: [
          const SizedBox(),
          for (final c in cards)
            Padding(
              padding: const EdgeInsets.only(bottom: 8, left: 6),
              child: Align(
                  alignment: Alignment.centerLeft, child: Tag(c.tag, dark: c.isCurrent)),
            ),
        ]);

    TableRow bars(String label, double Function(ExplanationCard) f, {bool strong = false}) =>
        TableRow(
          decoration: BoxDecoration(border: Border(top: divider)),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 9),
              child: Text(label,
                  style: TextStyle(fontWeight: strong ? FontWeight.w700 : FontWeight.w400)),
            ),
            for (final c in cards)
              Padding(
                padding: const EdgeInsets.only(left: 6, top: 6, bottom: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(pts(f(c)),
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: strong ? FontWeight.w700 : FontWeight.w500)),
                    ScoreBar(f(c), dark: c.isCurrent),
                  ],
                ),
              ),
          ],
        );

    TableRow facts(String label, String Function(ExplanationCard) f) => TableRow(
          decoration: BoxDecoration(border: Border(top: divider)),
          children: [
            Padding(padding: const EdgeInsets.symmetric(vertical: 9), child: Text(label)),
            for (final c in cards)
              Padding(
                padding: const EdgeInsets.only(left: 6, top: 9, bottom: 9),
                child: Text(f(c), style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
          ],
        );

    // which rotation changes least and most under the chosen weather
    String? shift;
    if (_scenario != 0 && cards.length > 1) {
      var least = 0, most = 0;
      double drop(int i) => base[i].total - cards[i].total;
      for (var i = 1; i < cards.length; i++) {
        if (drop(i) < drop(least)) least = i;
        if (drop(i) > drop(most)) most = i;
      }
      shift = drop(most) < 0.005
          ? 'None of the rotations lose ground in this weather, because the '
              'crops still get the water and warmth they need.'
          : '${cards[least].title} holds up best, losing '
              '${(drop(least) * 100).round()} points. ${cards[most].title} '
              'loses most, ${(drop(most) * 100).round()} points.';
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t('sideBySide')),
            Text(t('longerBar'), style: const TextStyle(fontSize: 13)),
          ],
        ),
      ),
      body: PageBody(
        children: [
          Label(t('weatherIs')),
          SegmentedButton<int>(
            showSelectedIcon: false,
            segments: [
              for (var i = 0; i < scenarios.length; i++)
                ButtonSegment(value: i, label: Text(scenarios[i].label)),
            ],
            selected: {_scenario},
            onSelectionChanged: (v) => setState(() => _scenario = v.first),
          ),
          const SizedBox(height: 4),
          Text(
              '${scenarios[_scenario].note}'
              '${_scenario == 0 ? '' : ' ${t('whatIf')}'}',
              style: theme.textTheme.bodySmall),
          const SizedBox(height: 12),
          Panel(
            child: Table(
              columnWidths: const {0: FlexColumnWidth(1.7)},
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              children: [
                head(),
                bars(t('overall'), (c) => c.total, strong: true),
                for (final p in priorityKeys)
                  bars(t('p_$p'), (c) => c.detail.scores[p]!),
                facts(t('bareMonths'), (c) => c.detail.bareMonths.toStringAsFixed(1)),
                facts(t('pestRests'), (c) => '${c.detail.pestBreaks}'),
                facts(t('cashCrops'), (c) => '${c.detail.cashCrops}'),
                facts(t('waterNeed'), (c) => c.detail.waterPerYear.toStringAsFixed(0)),
                facts(t('earnings'),
                    (c) => ugx(c.detail.marginPerYear).replaceFirst('UGX ', '')),
              ],
            ),
          ),
          if (shift != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(shift, style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
          for (final c in cards)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('${c.tag}: ${c.detail.names}', style: theme.textTheme.bodySmall),
            ),
          const SizedBox(height: 4),
          Text(t('earningsNote'), style: theme.textTheme.bodySmall),
          const SizedBox(height: 12),
          for (var i = 0; i < cards.length; i++)
            if (!cards[i].isCurrent)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
                      builder: (_) => DetailScreen(analysis: a, index: i))),
                  child: Text(tf('open', {'name': cards[i].title})),
                ),
              ),
        ],
      ),
    );
  }
}

// ---- screen 13 --------------------------------------------------------------

class DetailScreen extends StatelessWidget {
  const DetailScreen({super.key, required this.analysis, required this.index});
  final Analysis analysis;
  final int index;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final card = analysis.result().cards[index];
    final d = card.detail;
    final pattern = analysis.pattern;

    return Scaffold(
      appBar: AppBar(title: Text(card.title)),
      body: PageBody(
        children: [
          Semantics(
            label: '${card.title}: ${d.names}, then repeat',
            child: Row(
              children: [
                for (final p in d.plantings)
                  Expanded(
                    flex: p.len,
                    child: Container(
                      height: 78,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                          color: cropColor(p.crop), borderRadius: BorderRadius.circular(10)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                              'Y${pattern.yearOf(p.start)} ${monthNames[pattern.seasonAt(p.start).startMonth - 1]}',
                              style: const TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.w600, color: inkDark)),
                          Text(p.crop.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 13,
                                  height: 1.1,
                                  fontWeight: FontWeight.w700,
                                  color: inkDark)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(t('thenRepeat'), style: theme.textTheme.bodySmall),
          const SizedBox(height: 12),
          Text(card.headline,
              style: theme.textTheme.titleMedium?.copyWith(height: 1.35)),
          const SizedBox(height: 12),
          Panel(
            child: Column(
              children: [
                for (final e in card.sections.entries)
                  Theme(
                    data: theme.copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      childrenPadding: const EdgeInsets.only(bottom: 8),
                      initiallyExpanded: e.key == 'reasons',
                      expandedCrossAxisAlignment: CrossAxisAlignment.start,
                      title: Text(
                          e.key == 'reasons' && card.isCurrent
                              ? 'How it fits your field'
                              : ExplanationCard.sectionTitles[e.key]!,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      children: [
                        if (e.value.isEmpty) const Text('None identified.'),
                        for (final line in e.value)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 7, right: 10),
                                  child: CircleAvatar(
                                      radius: 2.5,
                                      backgroundColor: theme.colorScheme.primary),
                                ),
                                Expanded(child: Text(line, style: const TextStyle(height: 1.4))),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) => CalendarScreen(analysis: analysis, initial: index))),
            icon: const Icon(Icons.calendar_month_outlined),
            label: Text(t('seeCalendar')),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
