// Screen 14: confidence, questions for an adviser, sharing.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../analysis.dart';
import '../l10n/strings.dart';
import '../widgets/common.dart';

class ReviewTab extends StatefulWidget {
  const ReviewTab({super.key, required this.analysis});
  final Analysis analysis;
  @override
  State<ReviewTab> createState() => _ReviewTabState();
}

class _ReviewTabState extends State<ReviewTab> {
  int _pick = 0;
  final _asked = <String>{};

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final all = widget.analysis.result().cards;
    final options = widget.analysis.result().options;
    final cards = options.isEmpty ? all : options;
    final card = cards[_pick.clamp(0, cards.length - 1)];

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t('beforeDecide')),
            Text(t('checkLocal'), style: const TextStyle(fontSize: 13)),
          ],
        ),
      ),
      body: PageBody(
        children: [
          if (cards.length > 1) ...[
            SegmentedButton<int>(
              showSelectedIcon: false,
              segments: [
                for (var i = 0; i < cards.length; i++)
                  ButtonSegment(value: i, label: Text(cards[i].title)),
              ],
              selected: {_pick},
              onSelectionChanged: (v) => setState(() => _pick = v.first),
            ),
            const SizedBox(height: 12),
          ],
          Panel(
            title: t('howSure'),
            hint: card.detail.names,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    for (final level in const ['Low', 'Medium', 'High'])
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: card.confidence == level
                                ? scheme.primary
                                : scheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(t(level.toLowerCase()),
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: card.confidence == level
                                      ? scheme.onPrimary
                                      : scheme.onSurface)),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(card.confidenceWhy,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant)),
              ],
            ),
          ),
          Panel(
            title: t('askAdviser'),
            hint: t('tickEach'),
            child: Column(
              children: [
                for (final q in card.questions)
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    value: _asked.contains(q),
                    onChanged: (v) => setState(() => v == true ? _asked.add(q) : _asked.remove(q)),
                    title: Text(q),
                  ),
              ],
            ),
          ),
          Panel(
            title: t('risksLocal'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final r in card.risks)
                  Padding(padding: const EdgeInsets.only(bottom: 6), child: Text('• $r')),
              ],
            ),
          ),
          FilledButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: card.toText()));
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t('copied'))));
            },
            icon: const Icon(Icons.copy),
            label: Text(t('copyAdvice')),
          ),
        ],
      ),
    );
  }
}
