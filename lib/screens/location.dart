// Screen 4: find the field anywhere in the world, the way the AgriSmart web
// prototype does: continent, country, region, district, then a town or
// village looked up with Open-Meteo Geocoding. The pin can also be placed by
// tapping the NASA map or typing coordinates.
import 'package:flutter/material.dart';

import '../data/countries.dart';
import '../data/geo.dart';
import '../engine/models.dart';
import '../l10n/strings.dart';
import '../widgets/common.dart';
import '../widgets/nasa_map.dart';

class LocationStep extends StatefulWidget {
  const LocationStep({
    super.key,
    required this.setup,
    required this.latController,
    required this.lonController,
    required this.onChanged,
  });
  final FarmSetup setup;
  final TextEditingController latController;
  final TextEditingController lonController;

  /// Called whenever the pin or the place changes.
  final VoidCallback onChanged;

  @override
  State<LocationStep> createState() => _LocationStepState();
}

class _LocationStepState extends State<LocationStep> {
  List<CountryRef>? _countries;
  bool _offlineList = false;
  late final _region = TextEditingController(text: widget.setup.region);
  late final _district = TextEditingController(text: widget.setup.district);
  late final _locality = TextEditingController(text: widget.setup.locality);
  List<PlaceHit>? _hits;
  bool _searching = false;
  String? _searchError;

  FarmSetup get s => widget.setup;

  @override
  void initState() {
    super.initState();
    fetchCountries().then((list) {
      if (!mounted) return;
      setState(() {
        _countries = list;
        _offlineList = list.length < 100;
      });
    });
  }

  @override
  void dispose() {
    _region.dispose();
    _district.dispose();
    _locality.dispose();
    super.dispose();
  }

  List<CountryRef> get _inContinent => [
        for (final c in _countries ?? const <CountryRef>[])
          if (c.continent == s.continent) c
      ];

  void _setPin(double lat, double lon) {
    s.lat = double.parse(lat.toStringAsFixed(4));
    s.lon = double.parse(lon.toStringAsFixed(4));
    widget.latController.text = s.lat.toString();
    widget.lonController.text = s.lon.toString();
    widget.onChanged();
  }

  void _pickCountry(CountryRef c) {
    setState(() {
      s.countryName = c.name;
      s.countryCode = c.code;
      s.region = '';
      s.district = '';
      s.locality = '';
      _region.clear();
      _district.clear();
      _locality.clear();
      _hits = null;
      _searchError = null;
      final local = countryByCode(c.code);
      if (local != null) {
        // built-in capital, so the map opens somewhere sensible
        final cap = local.cities.first;
        s.locality = cap.name;
        _locality.text = cap.name;
        s.placePath = '${cap.name}, ${c.name}';
        _setPin(cap.lat, cap.lon);
      } else {
        s.placePath = c.name;
        widget.onChanged();
      }
    });
  }

  Future<void> _search() async {
    final name = _locality.text.trim();
    if (name.isEmpty) {
      setState(() => _searchError = t('typePlace'));
      return;
    }
    setState(() {
      _searching = true;
      _searchError = null;
      _hits = null;
    });
    try {
      final lang = Localizations.maybeLocaleOf(context)?.languageCode ?? 'en';
      final hits = await searchPlaces(name, s.countryCode,
          region: _region.text, district: _district.text, language: lang);
      if (!mounted) return;
      setState(() {
        _hits = hits;
        if (hits.isEmpty) {
          _searchError = tf('noPlace', {'country': s.countryName});
        }
      });
    } catch (e) {
      if (mounted) setState(() => _searchError = e.toString());
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  void _choose(PlaceHit h) {
    setState(() {
      s.locality = h.name;
      s.region = h.admin1.isNotEmpty ? h.admin1 : _region.text.trim();
      s.district = h.admin2.isNotEmpty ? h.admin2 : _district.text.trim();
      s.placePath = h.path;
      _region.text = s.region;
      _district.text = s.district;
      _hits = null;
      _setPin(h.lat, h.lon);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final small = theme.textTheme.bodySmall;
    final list = _inContinent;
    final hasCountry = list.any((c) => c.code == s.countryCode);
    final local = countryByCode(s.countryCode);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Panel(
          title: t('whereFarm'),
          hint: _countries == null
              ? t('loadingCountries')
              : _offlineList
                  ? t('offlineCountries')
                  : t('onlineCountries'),
          child: Column(
            children: [
              PickField<String>(
                label: t('continent'),
                value: s.continent,
                items: {for (final c in continents) c: c},
                onChanged: (v) => setState(() {
                  s.continent = v;
                  final first = _inContinent;
                  if (first.isNotEmpty) _pickCountry(first.first);
                }),
              ),
              const SizedBox(height: 12),
              PickField<String>(
                label: t('country'),
                value: hasCountry ? s.countryCode : '',
                items: {
                  if (!hasCountry) '': s.countryName,
                  for (final c in list) c.code: c.name,
                },
                onChanged: (code) {
                  final c = list.where((x) => x.code == code);
                  if (c.isNotEmpty) _pickCountry(c.first);
                },
              ),
              if (local != null) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (var i = 0; i < local.cities.length; i++)
                      ActionChip(
                        label: Text(i == 0
                            ? '${local.cities[i].name} (${t('capital')})'
                            : local.cities[i].name),
                        onPressed: () => setState(() {
                          s.locality = local.cities[i].name;
                          s.region = '';
                          s.district = '';
                          _locality.text = s.locality;
                          s.placePath = '${s.locality}, ${local.name}';
                          _hits = null;
                          _setPin(local.cities[i].lat, local.cities[i].lon);
                        }),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              TextField(
                controller: _region,
                decoration: InputDecoration(
                    labelText: t('region'), border: const OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _district,
                decoration: InputDecoration(
                    labelText: t('district'), border: const OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _locality,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _search(),
                decoration: InputDecoration(
                    labelText: t('town'), border: const OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _searching ? null : _search,
                icon: _searching
                    ? const SizedBox(
                        width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.search),
                label: Text(_searching ? t('searching') : t('findPlace')),
              ),
              if (_searchError != null) ...[
                const SizedBox(height: 8),
                Text(_searchError!, style: TextStyle(color: theme.colorScheme.error)),
              ],
              if (_hits != null && _hits!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(t('chooseOne'), style: small),
                for (final h in _hits!.take(8))
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.place_outlined),
                    title: Text(h.path),
                    subtitle: Text(
                        '${h.lat.toStringAsFixed(3)}, ${h.lon.toStringAsFixed(3)}'),
                    onTap: () => _choose(h),
                  ),
              ],
            ],
          ),
        ),
        Text('${t('field')}: ${s.placePath}',
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        NasaMap(
          countryName: s.countryName,
          cities: local?.cities ?? const [],
          lat: s.lat,
          lon: s.lon,
          onPick: (lat, lon) => setState(() {
            s.placePath = '${s.locality.isEmpty ? t('field') : s.locality} '
                '(${lat.toStringAsFixed(3)}, ${lon.toStringAsFixed(3)})';
            _setPin(lat, lon);
          }),
        ),
        const SizedBox(height: 4),
        Text(t('tapMap'), style: small),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: widget.latController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                decoration: InputDecoration(labelText: t('latitude'), border: const OutlineInputBorder()),
                onChanged: (_) => widget.onChanged(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: widget.lonController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                decoration: InputDecoration(labelText: t('longitude'), border: const OutlineInputBorder()),
                onChanged: (_) => widget.onChanged(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        PickField<int>(
          label: t('rainySeasons'),
          value: s.patternIndex,
          items: {
            -1: t('findSeasons'),
            for (var i = 0; i < seasonPatterns.length; i++) i: seasonPatterns[i].label,
          },
          onChanged: (i) => setState(() {
            s.patternIndex = i;
            widget.onChanged();
          }),
        ),
        const SizedBox(height: 4),
        Text(t('findSeasonsNote'), style: small),
        const SizedBox(height: 16),
      ],
    );
  }
}
