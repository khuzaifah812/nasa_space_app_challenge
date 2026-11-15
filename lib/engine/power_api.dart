// Downloads daily weather for one point from NASA POWER.
// Free, no login. Docs: https://power.larc.nasa.gov/docs/
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'models.dart';

class PowerException implements Exception {
  PowerException(this.message);
  final String message;
  @override
  String toString() => message;
}

Future<List<DayRecord>> fetchPower(
    double lat, double lon, int startYear, int endYear) async {
  final uri = Uri.https('power.larc.nasa.gov', '/api/temporal/daily/point', {
    'parameters': 'PRECTOTCORR,T2M,T2M_MAX,T2M_MIN,GWETROOT,EVPTRNS',
    'community': 'AG',
    'latitude': lat.toString(),
    'longitude': lon.toString(),
    'start': '${startYear}0101',
    'end': '${endYear}1231',
    'format': 'JSON',
  });

  http.Response res;
  try {
    res = await http.get(uri).timeout(const Duration(seconds: 90));
  } catch (_) {
    throw PowerException('Could not reach NASA. Check the internet '
        'connection and try again, or switch on sample data.');
  }
  if (res.statusCode != 200) {
    throw PowerException('NASA answered with error ${res.statusCode}. '
        'Check the latitude and longitude, then try again.');
  }
  return parsePower(res.body);
}

/// Separated from the download so it can be tested without a network.
List<DayRecord> parsePower(String body) {
  final Map<String, dynamic> p;
  try {
    final json = jsonDecode(body) as Map<String, dynamic>;
    p = (json['properties'] as Map<String, dynamic>)['parameter']
        as Map<String, dynamic>;
  } catch (_) {
    throw PowerException('NASA sent data in an unexpected format.');
  }
  final rain = p['PRECTOTCORR'] as Map<String, dynamic>;
  final tmax = p['T2M_MAX'] as Map<String, dynamic>;
  final tmin = p['T2M_MIN'] as Map<String, dynamic>;
  final wet = p['GWETROOT'] as Map<String, dynamic>;
  final tmean = p['T2M'] as Map<String, dynamic>? ?? const {};
  final et = p['EVPTRNS'] as Map<String, dynamic>? ?? const {};
  double? optional(Map<String, dynamic> m, String k) {
    final v = (m[k] as num?)?.toDouble();
    return v == null || v <= -900 ? null : v;
  }

  final keys = rain.keys.toList()..sort();
  final days = <DayRecord>[];
  for (final k in keys) {
    final r = (rain[k] as num?)?.toDouble();
    final hi = (tmax[k] as num?)?.toDouble();
    final lo = (tmin[k] as num?)?.toDouble();
    final w = (wet[k] as num?)?.toDouble();
    // -999 marks a missing value
    if (r == null || hi == null || lo == null || w == null) continue;
    if (r <= -900 || hi <= -900 || lo <= -900 || w <= -900) continue;
    days.add(DayRecord(
      DateTime.utc(int.parse(k.substring(0, 4)), int.parse(k.substring(4, 6)),
          int.parse(k.substring(6, 8))),
      r,
      hi,
      lo,
      w,
      tmean: optional(tmean, k),
      et: optional(et, k),
    ));
  }
  if (days.isEmpty) {
    throw PowerException('NASA has no usable data for this location.');
  }
  return days;
}
