// Screens 4 to 7: the field, current crops, soil and limits, priorities.
import 'package:flutter/material.dart';

import '../analysis.dart';
import '../data/store.dart';
import '../l10n/strings.dart';
import '../engine/indicators.dart';
import '../engine/models.dart';
import '../engine/scoring.dart';
import '../widgets/common.dart';
import 'location.dart';
import 'shell.dart';

class SetupFlow extends StatefulWidget {
  const SetupFlow({super.key, required this.setup, this.startStep = 0, this.weather});
  final FarmSetup setup;
  final int startStep;

  /// Weather already downloaded for this field, when editing a plan.
  final WeatherRecord? weather;
  @override
  State<SetupFlow> createState() => _SetupFlowState();
}

class _SetupFlowState extends State<SetupFlow> {
  late int _step = widget.startStep;
  late final _lat = TextEditingController(text: widget.setup.lat.toString());
  late final _lon = TextEditingController(text: widget.setup.lon.toString());
  late final _ph = TextEditingController(text: widget.setup.ph?.toString() ?? '');
  late WeatherRecord? _weather = widget.weather;
  bool _busy = false;
  String? _error;

  FarmSetup get s => widget.setup;

  /// The seasons the later steps work with: found in the NASA record, or
  /// the pattern the farmer chose.
  SeasonPattern get _pattern => _weather?.patternFor(s) ??
      (s.autoSeasons ? seasonPatterns[0] : seasonPatterns[s.patternIndex]);

  void _fitCurrent() {
    final n = _pattern.rotationLength;
    s.current = [for (var i = 0; i < n; i++) i < s.current.length ? s.current[i] : null];
  }

  static const _titles = ['addField', 'growNow', 'soilLimits', 'whatMatters'];

  @override
  void dispose() {
    _lat.dispose();
    _lon.dispose();
    _ph.dispose();
    super.dispose();
  }

  double? _number(String text) => double.tryParse(text.trim().replaceAll(',', '.'));

  /// Checks the step being left. Returns a message if something is wrong.
  String? _check() {
    if (_step == 0) {
      final lat = _number(_lat.text), lon = _number(_lon.text);
      if (lat == null || lat < -90 || lat > 90) {
        return 'Latitude must be a number between -90 and 90.';
      }
      if (lon == null || lon < -180 || lon > 180) {
        return 'Longitude must be a number between -180 and 180.';
      }
      s.lat = lat;
      s.lon = lon;
    }
    if (_step == 2) {
      final text = _ph.text.trim();
      final ph = text.isEmpty ? null : _number(text);
      if (text.isNotEmpty && (ph == null || ph < 3 || ph > 10)) {
        return 'Soil pH must be a number between 3 and 10, or left empty.';
      }
      s.ph = ph;
    }
    return null;
  }

  Future<void> _next() async {
    final problem = _check();
    if (problem != null) {
      setState(() => _error = problem);
      return;
    }
    if (_step == 0) {
      // Download the NASA record now, so the seasons are known before the
      // farmer enters the crops grown in each one.
      final cached = _weather;
      final fresh = cached == null ||
          cached.isSample != s.useSample ||
          (cached.lat - s.lat).abs() > 1e-6 ||
          (cached.lon - s.lon).abs() > 1e-6;
      if (fresh) {
        setState(() {
          _busy = true;
          _error = null;
        });
        try {
          _weather = await fetchWeather(s.lat, s.lon, sample: s.useSample);
        } catch (e) {
          if (mounted) setState(() => _error = e.toString());
          return;
        } finally {
          if (mounted) setState(() => _busy = false);
        }
      }
      try {
        // make sure the seasons found give usable data
        summarise(_weather!.days, s.lat, _pattern);
        _fitCurrent();
      } catch (e) {
        setState(() => _error = e.toString());
        return;
      }
    }
    if (_step < 3) {
      setState(() {
        _error = null;
        _step++;
      });
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final analysis = await runAnalysis(s, _weather);
      await savePlan(analysis.toSaved());
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute<void>(builder: (_) => Shell(analysis: analysis)),
          (route) => false);
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceFirst('Bad state: ', ''));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _back() {
    if (_step == 0) {
      Navigator.of(context).maybePop();
    } else {
      setState(() {
        _error = null;
        _step--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
              tooltip: t('back'), icon: const Icon(Icons.arrow_back), onPressed: _back),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t(_titles[_step])),
              Text(tf('stepOf', {'n': _step + 1}), style: const TextStyle(fontSize: 13)),
            ],
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(4),
            child: LinearProgressIndicator(
              value: (_step + 1) / 4,
              backgroundColor: scheme.primaryContainer,
              color: Colors.white,
            ),
          ),
        ),
        body: PageBody(
          maxWidth: 620,
          children: [
            ...switch (_step) {
              0 => _field(),
              1 => _crops(),
              2 => _soil(),
              _ => _priorities(),
            },
            if (_error != null)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: scheme.errorContainer,
                    borderRadius: BorderRadius.circular(12)),
                child: Text(_error!, style: TextStyle(color: scheme.onErrorContainer)),
              ),
            FilledButton(
              onPressed: _busy ? null : _next,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_busy) ...[
                    const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2)),
                    const SizedBox(width: 12),
                  ],
                  Flexible(
                    child: Text(_busy
                        ? (_step == 0 ? t('reading') : t('working'))
                        : _step == 0
                            ? t('readNasa')
                            : _step < 3
                                ? t('next')
                                : t('seeField')),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---- step 1 ---------------------------------------------------------------

  List<Widget> _field() {
    return [
      LocationStep(
        setup: s,
        latController: _lat,
        lonController: _lon,
        onChanged: () => setState(() {}),
      ),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        value: s.useSample,
        onChanged: _busy ? null : (v) => setState(() => s.useSample = v),
        title: Text(t('useSample')),
        subtitle: Text(t('useSampleHint')),
      ),
      const SizedBox(height: 8),
    ];
  }

  Widget _numberField(TextEditingController c, String label) {
    return TextField(
      controller: c,
      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
    );
  }

  // ---- step 2 ---------------------------------------------------------------

  List<Widget> _crops() {
    final options = rotationCrops;
    return [
      Panel(
        title: s.autoSeasons ? t('seasonsFound') : t('seasons'),
        hint: s.autoSeasons ? t('seasonsFoundHint') : t('patternChosen'),
        child: Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [for (final d in _pattern.seasons) Pill('${d.name}: ${d.months}')],
        ),
      ),
      Text(t('pickCrop'),
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
      const SizedBox(height: 12),
      for (var i = 0; i < s.current.length; i++) ...[
        PickField<String>(
          label: _pattern.slotLabel(i),
          value: s.current[i] ?? '',
          items: {'': t('notSure'), for (final c in options) c.name: c.name},
          onChanged: (v) => setState(() => s.current[i] = v.isEmpty ? null : v),
        ),
        const SizedBox(height: 12),
      ],
      Label(t('between')),
      SegmentedButton<int>(
        showSelectedIcon: false,
        segments: [
          for (var i = 0; i < betweenLabels.length; i++)
            ButtonSegment(value: i, label: Text(t(['bare', 'residue', 'coverCrop'][i]))),
        ],
        selected: {s.between},
        onSelectionChanged: (v) => setState(() => s.between = v.first),
      ),
      const SizedBox(height: 8),
      Text(t('perennialNote'),
          style: Theme.of(context).textTheme.bodySmall),
      const SizedBox(height: 16),
    ];
  }

  // ---- step 3 ---------------------------------------------------------------

  List<Widget> _soil() {
    Widget chips(List<String> names, String? value, ValueChanged<String?> set) => Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final n in [...names, 'Not sure'])
              ChoiceChip(
                label: Text(n == 'Not sure' ? t('notSure') : n),
                selected: n == 'Not sure' ? value == null : value == n,
                onSelected: (_) => setState(() => set(n == 'Not sure' ? null : n)),
              ),
          ],
        );
    Widget segments(List<String> names, int value, ValueChanged<int> set) =>
        SegmentedButton<int>(
          showSelectedIcon: false,
          segments: [
            for (var i = 0; i < names.length; i++)
              ButtonSegment(value: i, label: Text(names[i])),
          ],
          selected: {value},
          onSelectionChanged: (v) => setState(() => set(v.first)),
        );
    return [
      Label(t('soilType')),
      chips(soilTypes, s.soilType, (v) => s.soilType = v),
      Label(t('organic')),
      chips(organicLevels, s.organicMatter, (v) => s.organicMatter = v),
      const SizedBox(height: 12),
      _numberField(_ph, t('phLabel')),
      Label(t('water')),
      segments([t('rainOnly'), t('someIrrigation'), t('wetland')], s.water, (v) => s.water = v),
      Label(t('money')),
      segments([t('low'), t('medium'), t('high')], s.budget, (v) => s.budget = v),
      Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
            const [
              'Low: only crops costing up to UGX 2M a hectare are suggested.',
              'Medium: crops costing up to UGX 4.5M a hectare are suggested.',
              'High: every crop is considered, including tomatoes.',
            ][s.budget],
            style: Theme.of(context).textTheme.bodySmall),
      ),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        value: s.nearMarket,
        onChanged: (v) => setState(() => s.nearMarket = v),
        title: Text(t('nearMarket')),
        subtitle: Text(t('nearMarketHint')),
      ),
      const SizedBox(height: 8),
    ];
  }

  // ---- step 4 ---------------------------------------------------------------

  List<Widget> _priorities() {
    final muted = TextStyle(
        fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant);
    return [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(t('mattersLittle'), style: muted), Text(t('mattersMost'), style: muted)],
      ),
      for (final p in priorityKeys) ...[
        const SizedBox(height: 6),
        Text(t('p_$p'), style: const TextStyle(fontWeight: FontWeight.w500)),
        Slider(
          value: s.weights[p] ?? 0,
          divisions: 10,
          label: '${((s.weights[p] ?? 0) * 10).round()} out of 10',
          semanticFormatterCallback: (v) => '${(v * 10).round()} out of 10',
          onChanged: (v) => setState(() => s.weights[p] = v),
        ),
      ],
      const SizedBox(height: 8),
    ];
  }
}
