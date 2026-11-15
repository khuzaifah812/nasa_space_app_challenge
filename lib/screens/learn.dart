// Screen 15: plain-language guide and the crop table.
import 'package:flutter/material.dart';

import '../data/crops_data.dart';
import '../engine/models.dart';
import '../l10n/strings.dart';
import 'sources.dart';
import '../widgets/common.dart';

class LearnTab extends StatelessWidget {
  const LearnTab({super.key});

  static const _codes = ['en', 'fr', 'sw', 'pt', 'ar', 'es'];

  static const _terms = [
    ('NDVI (greenness)',
        'A greenness score that satellites measure from space. High means '
            'dense, healthy plants. A drop below normal for the time of year '
            'means crops are under stress. AgriSmart does not use it yet.'),
    ('Evapotranspiration',
        'Water leaving the field, from the soil surface and through plant '
            'leaves. When it is more than the rain, the field is losing water.'),
    ('Soil moisture anomaly',
        'How much wetter or drier the soil is than usual for that time of year.'),
    ('Water balance',
        'Rain minus evapotranspiration. Below zero means the season runs '
            'short of water.'),
    ('Frost risk',
        'The chance of nights cold enough to freeze and damage crops. Rare '
            'in Uganda outside the highlands.'),
    ('Satellite and ground data',
        'Satellites see every place regularly, but only in large squares. A '
            'soil test or a rain gauge is exact, but covers one spot. Used '
            'together they check each other.'),
    ('Rest period',
        'The number of seasons to wait before growing a crop from the same '
            'group again, so its pests and diseases die back.'),
  ];

  String _names(bool Function(Crop) test) =>
      [for (final c in crops) if (test(c)) c.name].join(', ');

  void _open(BuildContext context, Crop c) {
    final theme = Theme.of(context);
    Widget row(String k, String v) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(k,
                  style: theme.textTheme.labelMedium
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              Text(v),
            ],
          ),
        );
    String n(double v) => v.toStringAsFixed(v == v.roundToDouble() ? 0 : 1);
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
              Text(c.name,
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
              Text('${c.scientificName}, ${c.family}',
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
              const SizedBox(height: 12),
              if (c.perennial)
                row('In a rotation', 'Stays in one place for years, so it is not rotated.'),
              row('When to plant', c.plantingWindow),
              row('Water it needs', '${n(c.waterMin)} to ${n(c.waterMax)} mm'),
              row('Comfortable temperature', '${n(c.tempMin)} to ${n(c.tempMax)}°C'),
              row('Days to harvest', '${c.daysMin} to ${c.daysMax}'),
              row('Effect on nitrogen',
                  c.fixesNitrogen
                      ? '${c.nitrogenEffect}, about ${n(c.nFixMin)} to ${n(c.nFixMax)} kg per hectare'
                      : c.nitrogenEffect),
              row('Effect on organic matter', c.somEffect),
              row('Roots', c.rootDepth),
              row('Typical yield', '${n(c.yieldMin)} to ${n(c.yieldMax)} (${c.yieldBasis})'),
              row('Price',
                  'UGX ${n(c.priceMin)} to ${n(c.priceMax)} per kg. Sold ${c.marketUnit}. ${c.marketNotes}'),
              row('Input and labour cost', '${ugx(c.costMin)} to ${ugx(c.costMax)} per hectare'),
              row('Keeps after harvest', c.storability),
              row('Pests and diseases', c.pests),
              row('Grows well after', c.goodAfterText),
              row('Avoid growing after', c.badAfterText),
              row('Rest period',
                  c.breakSeasons == 0 ? 'Not applicable' : '${c.breakSeasons} season(s)'),
              row('How sure the table is', c.confidence),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t('learn')),
            Text(t('plainWords'), style: const TextStyle(fontSize: 13)),
          ],
        ),
      ),
      body: PageBody(
        children: [
          PickField<String>(
            label: t('language'),
            value: Lang.code,
            items: {for (final c in _codes) c: languageNames[c]!},
            onChanged: Lang.set,
          ),
          const SizedBox(height: 4),
          Text(t('adviceLang'), style: theme.textTheme.bodySmall),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const SourcesScreen())),
            icon: const Icon(Icons.satellite_alt_outlined),
            label: Text(t('dataSources')),
          ),
          Label(t('wordsUsed')),
          Panel(
            child: Column(
              children: [
                for (final t in _terms)
                  Theme(
                    data: theme.copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      childrenPadding: const EdgeInsets.only(bottom: 10),
                      expandedCrossAxisAlignment: CrossAxisAlignment.start,
                      title: Text(t.$1, style: const TextStyle(fontWeight: FontWeight.w600)),
                      children: [Text(t.$2)],
                    ),
                  ),
              ],
            ),
          ),
          Label(t('cropsBuild')),
          Panel(
            title: 'Nitrogen-fixing crops',
            hint: _names((c) => c.fixesNitrogen),
            child: const Text('They take nitrogen from the air and leave some in '
                'the soil for the next crop.'),
          ),
          Panel(
            title: 'Crops that cover the ground',
            hint: _names((c) => c.groundCover >= 5),
            child: const Text('Their leaves shade the soil, so it holds water and '
                'is not washed away by heavy rain.'),
          ),
          Panel(
            title: 'Deep-rooting crops',
            hint: _names((c) => c.deepRooted),
            child: const Text('Their roots open up hard soil so rain soaks in, and '
                'bring up nutrients from below.'),
          ),
          Panel(
            title: 'Drought-tolerant crops',
            hint: _names((c) => c.drought >= 4),
            child: const Text('They still yield in dry seasons, so the soil is not '
                'left bare when the rains fail.'),
          ),
          Label(t('cropTable')),
          Panel(
            hint: tf('tapCrop', {'status': cropDataStatus}),
            child: Column(
              children: [
                for (final c in crops)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                        radius: 8, backgroundColor: cropColor(c)),
                    title: Text(c.name),
                    subtitle: Text(c.perennial
                        ? '${c.cropType}, permanent block'
                        : '${c.cropType}, ${c.daysMin} to ${c.daysMax} days'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _open(context, c),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
