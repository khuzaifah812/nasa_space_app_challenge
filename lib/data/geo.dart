// Finding the farm anywhere in the world: continent, country, then a town
// or village. Countries come from the World Bank country list and places
// from Open-Meteo Geocoding, the same services the AgriSmart web prototype
// uses. If the internet is down, the built-in African country list is used.
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'countries.dart';

const continents = [
  'Africa', 'Asia', 'Europe', 'North America', 'South America', 'Oceania',
];

class CountryRef {
  const CountryRef(this.name, this.code, this.continent);
  final String name;
  final String code; // ISO 3166-1 alpha-2
  final String continent;
}

class PlaceHit {
  const PlaceHit(this.name, this.country, this.countryCode, this.admin1,
      this.admin2, this.admin3, this.lat, this.lon);
  final String name, country, countryCode, admin1, admin2, admin3;
  final double lat, lon;

  /// "Mukono, Central Region, Uganda"
  String get path => [name, admin2, admin1, country]
      .where((s) => s.isNotEmpty)
      .toSet()
      .join(', ');
}

class GeoException implements Exception {
  GeoException(this.message);
  final String message;
  @override
  String toString() => message;
}

List<CountryRef>? _countryCache;

/// All countries, grouped by continent. Cached after the first call.
Future<List<CountryRef>> fetchCountries() async {
  if (_countryCache != null) return _countryCache!;
  try {
    final res = await http
        .get(Uri.parse('https://api.worldbank.org/v2/country?format=json&per_page=400'))
        .timeout(const Duration(seconds: 20));
    if (res.statusCode != 200) throw GeoException('World Bank answered ${res.statusCode}');
    final body = jsonDecode(res.body) as List<dynamic>;
    final rows = body[1] as List<dynamic>;
    final out = <CountryRef>[];
    for (final r in rows) {
      final m = r as Map<String, dynamic>;
      final code = (m['iso2Code'] as String?) ?? '';
      final region = ((m['region'] as Map<String, dynamic>?)?['value'] as String?)?.trim() ?? '';
      final continent = _continentOf(code, region);
      if (continent.isEmpty || code.length != 2) continue; // skips aggregates
      out.add(CountryRef((m['name'] as String).trim(), code, continent));
    }
    if (out.length < 100) throw GeoException('World Bank list looked incomplete');
    out.sort((a, b) => a.name.compareTo(b.name));
    return _countryCache = out;
  } catch (_) {
    // offline: the African list shipped with the app
    return [
      for (final c in countries) CountryRef(c.name, isoCodes[c.name] ?? '', 'Africa')
    ];
  }
}

const _asia = {
  'AF', 'AM', 'AZ', 'BH', 'BD', 'BT', 'BN', 'KH', 'CN', 'CY', 'GE', 'IN', 'ID', 'IR',
  'IQ', 'IL', 'JP', 'JO', 'KZ', 'KW', 'KG', 'LA', 'LB', 'MY', 'MV', 'MN', 'MM', 'NP',
  'KP', 'OM', 'PK', 'PS', 'PH', 'QA', 'SA', 'SG', 'KR', 'LK', 'SY', 'TW', 'TJ', 'TH',
  'TL', 'TR', 'TM', 'AE', 'UZ', 'VN', 'YE', 'HK', 'MO',
};
const _oceania = {
  'AS', 'AU', 'CK', 'FJ', 'PF', 'GU', 'KI', 'MH', 'FM', 'NR', 'NC', 'NZ', 'NU', 'NF',
  'MP', 'PW', 'PG', 'WS', 'SB', 'TK', 'TO', 'TV', 'VU', 'WF',
};
const _southAmerica = {
  'AR', 'BO', 'BR', 'CL', 'CO', 'EC', 'FK', 'GF', 'GY', 'PE', 'PY', 'SR', 'UY', 'VE',
};

String _continentOf(String code, String region) {
  switch (region) {
    case 'Sub-Saharan Africa':
      return 'Africa';
    case 'North America':
      return 'North America';
    case 'Latin America & Caribbean':
      return _southAmerica.contains(code) ? 'South America' : 'North America';
    case 'South Asia':
      return 'Asia';
    case 'East Asia & Pacific':
      return _oceania.contains(code) ? 'Oceania' : 'Asia';
    case 'Europe & Central Asia':
      return _asia.contains(code) ? 'Asia' : 'Europe';
    case 'Middle East, North Africa, Afghanistan & Pakistan':
    case 'Middle East & North Africa':
      return _asia.contains(code) ? 'Asia' : 'Africa';
    default:
      return '';
  }
}

/// Towns and villages matching [name] inside one country. [region] and
/// [district] narrow the list when the country uses them.
Future<List<PlaceHit>> searchPlaces(String name, String countryCode,
    {String region = '', String district = '', String language = 'en'}) async {
  final uri = Uri.https('geocoding-api.open-meteo.com', '/v1/search', {
    'name': name.trim(),
    'count': '20',
    'language': language,
    'format': 'json',
    if (countryCode.isNotEmpty) 'countryCode': countryCode,
  });
  http.Response res;
  try {
    res = await http.get(uri).timeout(const Duration(seconds: 20));
  } catch (_) {
    throw GeoException('Place search needs internet. Check the connection, '
        'or tap the map or type the coordinates instead.');
  }
  if (res.statusCode != 200) {
    throw GeoException('Place search is unavailable right now (${res.statusCode}).');
  }
  final json = jsonDecode(res.body) as Map<String, dynamic>;
  final results = (json['results'] as List<dynamic>?) ?? const [];
  bool has(String hay, String needle) =>
      needle.trim().isEmpty || hay.toLowerCase().contains(needle.trim().toLowerCase());
  final out = <PlaceHit>[];
  for (final r in results) {
    final m = r as Map<String, dynamic>;
    final hit = PlaceHit(
      (m['name'] as String?) ?? '',
      (m['country'] as String?) ?? '',
      (m['country_code'] as String?) ?? '',
      (m['admin1'] as String?) ?? '',
      (m['admin2'] as String?) ?? '',
      (m['admin3'] as String?) ?? '',
      (m['latitude'] as num).toDouble(),
      (m['longitude'] as num).toDouble(),
    );
    if (countryCode.isNotEmpty && hit.countryCode.toUpperCase() != countryCode.toUpperCase()) continue;
    if (hit.admin1.isNotEmpty && !has(hit.admin1, region)) continue;
    final lower = '${hit.admin2} ${hit.admin3}';
    if (lower.trim().isNotEmpty && !has(lower, district)) continue;
    out.add(hit);
  }
  return out;
}
