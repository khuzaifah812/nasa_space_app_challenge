// Two more NASA datasets read as numbers for the field, beside NASA POWER:
//
//  - SRTM elevation, through the public OpenTopoData and Open-Elevation
//    services, to work out how steep the field is (erosion risk).
//  - MODIS NDVI (MOD13Q1, 250 m, 16-day), through the ORNL DAAC subset
//    service, to show how green the land has been in recent months.
//
// Both are optional. If a service cannot be reached the app carries on and
// says the figure is missing; it never makes one up.
import 'dart:convert';
import 'dart:math' as math;

import 'package:http/http.dart' as http;

class NdviPoint {
  const NdviPoint(this.date, this.value);
  final DateTime date;
  final double value; // 0..1, higher is greener
}

class FieldExtras {
  const FieldExtras({this.elevation, this.slopePct, this.terrainSource = '', this.ndvi = const []});
  final double? elevation; // metres above sea level
  final double? slopePct; // rise over run, percent
  final String terrainSource;
  final List<NdviPoint> ndvi; // oldest first

  bool get hasTerrain => slopePct != null;
  bool get hasNdvi => ndvi.isNotEmpty;

  String get slopeWord {
    final s = slopePct ?? 0;
    if (s < 2) return 'almost flat';
    if (s < 5) return 'gently sloping';
    if (s < 12) return 'sloping';
    return 'steep';
  }
}

Future<FieldExtras> fetchExtras(double lat, double lon) async {
  final results = await Future.wait([
    _terrain(lat, lon).catchError((_) => const FieldExtras()),
    _ndvi(lat, lon).catchError((_) => const <NdviPoint>[]),
  ]);
  final terrain = results[0] as FieldExtras;
  return FieldExtras(
    elevation: terrain.elevation,
    slopePct: terrain.slopePct,
    terrainSource: terrain.terrainSource,
    ndvi: results[1] as List<NdviPoint>,
  );
}

/// Elevation at the field and four points about 330 m away, to get slope.
Future<FieldExtras> _terrain(double lat, double lon) async {
  const d = 0.003; // degrees
  final pts = [
    [lat, lon], [lat + d, lon], [lat - d, lon], [lat, lon + d], [lat, lon - d],
  ];
  final locations = pts.map((p) => '${p[0].toStringAsFixed(5)},${p[1].toStringAsFixed(5)}').join('|');
  const services = [
    ('https://api.opentopodata.org/v1/srtm90m?locations=', 'SRTM 90 m via OpenTopoData'),
    ('https://api.open-elevation.com/api/v1/lookup?locations=', 'SRTM via Open-Elevation'),
  ];
  for (final svc in services) {
    try {
      final res = await http.get(Uri.parse('${svc.$1}$locations')).timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) continue;
      final rows = (jsonDecode(res.body) as Map<String, dynamic>)['results'] as List<dynamic>;
      if (rows.length < 5) continue;
      final e = [for (final r in rows) ((r as Map<String, dynamic>)['elevation'] as num?)?.toDouble()];
      if (e.any((v) => v == null)) continue;
      final dy = d * 110540.0;
      final dx = d * 111320.0 * math.cos(lat * math.pi / 180);
      final gy = (e[1]! - e[2]!) / (2 * dy);
      final gx = (e[3]! - e[4]!) / (2 * dx);
      return FieldExtras(
          elevation: e[0], slopePct: math.sqrt(gx * gx + gy * gy) * 100, terrainSource: svc.$2);
    } catch (_) {
      // try the next service
    }
  }
  return const FieldExtras();
}

String _modisDate(DateTime d) {
  final doy = d.difference(DateTime.utc(d.year, 1, 1)).inDays + 1;
  return 'A${d.year}${doy.toString().padLeft(3, '0')}';
}

/// The last ten 16-day NDVI composites at the field (about five months).
Future<List<NdviPoint>> _ndvi(double lat, double lon) async {
  final end = DateTime.now().toUtc().subtract(const Duration(days: 20));
  final start = end.subtract(const Duration(days: 150));
  final uri = Uri.https('modis.ornl.gov', '/rst/api/v1/MOD13Q1/subset', {
    'latitude': lat.toString(),
    'longitude': lon.toString(),
    'band': '250m_16_days_NDVI',
    'startDate': _modisDate(start),
    'endDate': _modisDate(end),
    'kmAboveBelow': '0',
    'kmLeftRight': '0',
  });
  final res = await http.get(uri, headers: {'Accept': 'application/json'}).timeout(const Duration(seconds: 30));
  if (res.statusCode != 200) return const [];
  final json = jsonDecode(res.body) as Map<String, dynamic>;
  final scale = double.tryParse('${json['scale'] ?? ''}') ?? 0.0001;
  final out = <NdviPoint>[];
  for (final row in (json['subset'] as List<dynamic>? ?? const [])) {
    final m = row as Map<String, dynamic>;
    final data = m['data'] as List<dynamic>?;
    final date = DateTime.tryParse('${m['calendar_date'] ?? ''}');
    if (data == null || data.isEmpty || date == null) continue;
    final raw = (data.first as num).toDouble();
    if (raw <= -2000) continue; // fill value: cloud or no data
    out.add(NdviPoint(date, (raw * scale).clamp(-0.2, 1.0).toDouble()));
  }
  out.sort((a, b) => a.date.compareTo(b.date));
  return out;
}
