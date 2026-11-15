// A tiled satellite map from NASA GIBS (Global Imagery Browse Services).
//
// Tiles come from the GIBS WMTS REST service in Web Mercator:
//   https://gibs.earthdata.nasa.gov/wmts/epsg3857/best/
//       {Layer}/default/{Time}/{TileMatrixSet}/{z}/{y}/{x}.{ext}
//
// A cloud-free or recent-photo base sits underneath; a data layer (SMAP,
// GPM, GRACE, NDVI) can be drawn over it. The data layers are pictures
// only: the app does not read their numbers, which would need a NASA
// Earthdata login.
//
// Docs: https://nasa-gibs.github.io/gibs-api-docs/
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/countries.dart';
import '../l10n/strings.dart';
import 'common.dart';

const _gibs = 'https://gibs.earthdata.nasa.gov/wmts/epsg3857/best';

class MapLayer {
  const MapLayer(this.name, this.ids, this.matrixSet, this.maxZoom, this.ext,
      {this.dated = true, this.note = ''});
  final String name; // shown in the picker
  /// GIBS layer identifiers to try, in order. The first is the one to use;
  /// the others are fallbacks in case NASA serves the layer under another
  /// name.
  final List<String> ids;
  final String matrixSet;
  final int maxZoom; // deepest zoom the tile matrix set has
  final String ext;
  final bool dated; // false = one fixed picture, no date
  final String note;
}

/// Base pictures.
const baseLayers = <MapLayer>[
  MapLayer('Cloud-free view (Blue Marble)', ['BlueMarble_ShadedRelief_Bathymetry'],
      'GoogleMapsCompatible_Level8', 8, 'jpeg', dated: false),
  MapLayer('Recent satellite photo (MODIS Terra)', ['MODIS_Terra_CorrectedReflectance_TrueColor'],
      'GoogleMapsCompatible_Level9', 9, 'jpg'),
];

/// Data layers drawn over the base. Identifiers are taken from the GIBS
/// WMTSCapabilities file for this endpoint.
const dataLayers = <MapLayer>[
  MapLayer('No data layer', [], '', 0, 'png'),
  MapLayer('SMAP: soil moisture signal', ['SMAP_L3_Passive_Brightness_Temp_V'],
      'GoogleMapsCompatible_Level6', 6, 'png',
      note: 'SMAP brightness temperature. Wetter soil looks colder to the satellite, '
          'so this picture follows soil moisture.'),
  MapLayer('GPM: rain signal', ['GMI_Brightness_Temp_Dsc'],
      'GoogleMapsCompatible_Level6', 6, 'png',
      note: 'Brightness temperature from the GPM satellite\'s microwave imager, '
          'the instrument behind NASA\'s rainfall estimates.'),
  MapLayer('GRACE: water stored in the ground',
      ['GRACE_Tellus_Liquid_Water_Equivalent_Thickness_Mascon_CRI'],
      'GoogleMapsCompatible_Level6', 6, 'png',
      note: 'Change in water held in soil and rock, measured by GRACE and GRACE-FO '
          'across areas hundreds of kilometres wide.'),
  MapLayer('MODIS: plant greenness (NDVI)',
      ['MODIS_Terra_L3_NDVI_16DayWMS', 'MODIS_Terra_L3_NDVI_16Day', 'MODIS_Terra_NDVI_8Day'],
      'GoogleMapsCompatible_Level6', 6, 'png',
      note: 'How green the land is. Dark green is dense, healthy plants; '
          'pale colours are bare or dry ground.'),
];

class NasaMap extends StatefulWidget {
  const NasaMap({
    super.key,
    required this.countryName,
    required this.cities,
    required this.lat,
    required this.lon,
    required this.onPick,
    this.pickable = true,
  });
  final String countryName;
  final List<City> cities;
  final double lat;
  final double lon;
  final void Function(double lat, double lon) onPick;

  /// False where the map is only for looking, not for moving the pin.
  final bool pickable;

  @override
  State<NasaMap> createState() => _NasaMapState();
}

class _NasaMapState extends State<NasaMap> {
  int _zoom = 6;
  double? _centreLat, _centreLon; // null = follow the pin
  int _base = 0;
  int _data = 0;
  Offset _drag = Offset.zero;

  /// Which identifier and which date worked for the current data layer.
  int _idTry = 0;
  int _timeTry = 0;

  static const _minZoom = 2, _maxZoom = 11;

  @override
  void didUpdateWidget(NasaMap old) {
    super.didUpdateWidget(old);
    if (old.countryName != widget.countryName) {
      _zoom = 6;
      _centreLat = null;
      _centreLon = null;
    }
  }

  static String _day(int daysBack) {
    final d = DateTime.now().toUtc().subtract(Duration(days: daysBack));
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  /// Dates to try for a data layer: yesterday first, then NASA's latest
  /// available picture ("default"), since some products lag by days or
  /// months.
  List<String> get _times => [_day(1), 'default', _day(3)];

  // ---- Web Mercator ---------------------------------------------------------

  static double _worldSize(int z) => 256.0 * math.pow(2, z);
  static double _x(double lon, int z) => (lon + 180) / 360 * _worldSize(z);
  static double _y(double lat, int z) {
    final r = lat.clamp(-85.0, 85.0) * math.pi / 180;
    return (1 - math.log(math.tan(r) + 1 / math.cos(r)) / math.pi) / 2 * _worldSize(z);
  }

  static double _lon(double x, int z) => x / _worldSize(z) * 360 - 180;
  static double _lat(double y, int z) {
    final n = math.pi - 2 * math.pi * y / _worldSize(z);
    return 180 / math.pi * math.atan((math.exp(n) - math.exp(-n)) / 2);
  }

  String _tileUrl(String id, String time, MapLayer l, int z, int x, int y) =>
      '$_gibs/$id/default/$time/${l.matrixSet}/$z/$y/$x.${l.ext}';

  /// The tiles of one layer that cover the view.
  List<Widget> _tiles(MapLayer layer, String id, String time, double left, double top, Size size,
      {VoidCallback? onError}) {
    final lz = math.min(_zoom, layer.maxZoom);
    final ts = 256.0 * math.pow(2, _zoom - lz); // size a tile is drawn at
    final n = math.pow(2, lz).toInt();
    final out = <Widget>[];
    for (var ty = (top / ts).floor(); ty <= ((top + size.height) / ts).floor(); ty++) {
      if (ty < 0 || ty >= n) continue;
      for (var tx = (left / ts).floor(); tx <= ((left + size.width) / ts).floor(); tx++) {
        final wrapped = ((tx % n) + n) % n;
        out.add(Positioned(
          left: tx * ts - left,
          top: ty * ts - top,
          width: ts + 0.5, // hides hairline gaps between tiles
          height: ts + 0.5,
          child: Image.network(
            _tileUrl(id, time, layer, lz, wrapped, ty),
            fit: BoxFit.fill,
            gaplessPlayback: true,
            errorBuilder: (context, error, stack) {
              if (onError != null) WidgetsBinding.instance.addPostFrameCallback((_) => onError());
              return const SizedBox();
            },
          ),
        ));
      }
    }
    return out;
  }

  /// A data layer failed to load: try the next date, then the next name.
  void _nextCandidate() {
    if (!mounted) return;
    final layer = dataLayers[_data];
    setState(() {
      if (_timeTry < _times.length - 1) {
        _timeTry++;
      } else if (_idTry < layer.ids.length - 1) {
        _idTry++;
        _timeTry = 0;
      } else {
        _idTry = layer.ids.length; // nothing worked; stop asking
      }
    });
  }

  String get _worldviewUrl {
    final lon = _centreLon ?? widget.lon, lat = _centreLat ?? widget.lat;
    final span = 360 / math.pow(2, _zoom) * 1.5;
    return 'https://worldview.earthdata.nasa.gov/?v=${(lon - span).toStringAsFixed(3)},'
        '${(lat - span / 1.5).toStringAsFixed(3)},${(lon + span).toStringAsFixed(3)},'
        '${(lat + span / 1.5).toStringAsFixed(3)}&t=${_day(2)}';
  }

  Future<void> _openWorldview() async {
    var ok = false;
    try {
      ok = await launchUrl(Uri.parse(_worldviewUrl), mode: LaunchMode.externalApplication);
    } catch (_) {}
    if (!ok && mounted) {
      await Clipboard.setData(ClipboardData(text: _worldviewUrl));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Could not open a browser. The Worldview link was copied.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final base = baseLayers[_base];
    final data = dataLayers[_data];
    final dataOk = data.ids.isNotEmpty && _idTry < data.ids.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          label: 'NASA satellite map around ${widget.countryName}. Field at latitude '
              '${widget.lat.toStringAsFixed(3)}, longitude ${widget.lon.toStringAsFixed(3)}.',
          child: AspectRatio(
            aspectRatio: 1.5,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: LayoutBuilder(
                builder: (context, box) {
                  final size = Size(box.maxWidth, box.maxHeight);
                  final cx = _x(_centreLon ?? widget.lon, _zoom);
                  final cy = _y(_centreLat ?? widget.lat, _zoom);
                  final left = cx - size.width / 2, top = cy - size.height / 2;
                  Offset project(double lat, double lon) =>
                      Offset(_x(lon, _zoom) - left, _y(lat, _zoom) - top);

                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapUp: widget.pickable
                        ? (d) => widget.onPick(_lat(top + d.localPosition.dy, _zoom),
                            _lon(left + d.localPosition.dx, _zoom))
                        : null,
                    onPanUpdate: (d) => setState(() => _drag += d.delta),
                    onPanEnd: (_) => setState(() {
                      _centreLon = _lon(cx - _drag.dx, _zoom);
                      _centreLat = _lat(cy - _drag.dy, _zoom);
                      _drag = Offset.zero;
                    }),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ColoredBox(color: scheme.surfaceContainerHigh),
                        Transform.translate(
                          offset: _drag,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              ..._tiles(base, base.ids.first, base.dated ? _day(2) : 'default',
                                  left, top, size),
                              if (dataOk)
                                Positioned.fill(
                                  child: Opacity(
                                    opacity: 0.8,
                                    child: Stack(
                                      clipBehavior: Clip.none,
                                      children: _tiles(data, data.ids[_idTry], _times[_timeTry],
                                          left, top, size,
                                          onError: _nextCandidate),
                                    ),
                                  ),
                                ),
                              ..._tiles(
                                  const MapLayer('', ['Reference_Features_15m'],
                                      'GoogleMapsCompatible_Level9', 9, 'png',
                                      dated: false),
                                  'Reference_Features_15m', 'default', left, top, size),
                              Positioned.fill(
                                child: CustomPaint(
                                  painter: _PinPainter(project(widget.lat, widget.lon), [
                                    for (final c in widget.cities) (c.name, project(c.lat, c.lon))
                                  ]),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          left: 8,
                          bottom: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            color: const Color(0xB3000000),
                            child: const Text('Imagery: NASA EOSDIS GIBS',
                                style: TextStyle(color: Colors.white, fontSize: 10)),
                          ),
                        ),
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Column(
                            children: [
                              _button(Icons.add, 'Zoom in',
                                  _zoom < _maxZoom ? () => setState(() => _zoom++) : null),
                              const SizedBox(height: 6),
                              _button(Icons.remove, 'Zoom out',
                                  _zoom > _minZoom ? () => setState(() => _zoom--) : null),
                              const SizedBox(height: 6),
                              _button(Icons.my_location, 'Centre on the field',
                                  () => setState(() {
                                        _centreLat = null;
                                        _centreLon = null;
                                      })),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 280,
              child: PickField<int>(
                label: t('mapLayer'),
                value: _data,
                items: {for (var i = 0; i < dataLayers.length; i++) i: dataLayers[i].name},
                onChanged: (i) => setState(() {
                  _data = i;
                  _idTry = 0;
                  _timeTry = 0;
                }),
              ),
            ),
            SegmentedButton<int>(
              showSelectedIcon: false,
              style: const ButtonStyle(visualDensity: VisualDensity.compact),
              segments: [
                ButtonSegment(value: 0, label: Text(t('cloudFree'))),
                ButtonSegment(value: 1, label: Text(t('recentSat'))),
              ],
              selected: {_base},
              onSelectionChanged: (v) => setState(() => _base = v.first),
            ),
            TextButton.icon(
              onPressed: _openWorldview,
              icon: const Icon(Icons.open_in_new, size: 18),
              label: const Text('Worldview'),
            ),
          ],
        ),
        if (data.ids.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(dataOk ? data.note : t('notLoaded'), style: theme.textTheme.bodySmall),
        ],
        const SizedBox(height: 4),
        Text(t('layerNote'), style: theme.textTheme.bodySmall),
      ],
    );
  }

  Widget _button(IconData icon, String tip, VoidCallback? onTap) => Material(
        color: Colors.white,
        shape: const CircleBorder(),
        elevation: 2,
        child: IconButton(
          tooltip: tip,
          icon: Icon(icon),
          color: const Color(0xFF14261B),
          disabledColor: const Color(0xFFB0B8B3),
          onPressed: onTap,
        ),
      );
}

class _PinPainter extends CustomPainter {
  _PinPainter(this.pin, this.cities);
  final Offset pin;
  final List<(String, Offset)> cities;

  @override
  void paint(Canvas canvas, Size size) {
    final dark = Paint()..color = const Color(0xFF14261B);
    final white = Paint()..color = Colors.white;
    for (final c in cities) {
      final p = c.$2;
      if (p.dx < 0 || p.dy < 0 || p.dx > size.width || p.dy > size.height) continue;
      canvas.drawCircle(p, 4.5, dark);
      canvas.drawCircle(p, 3, white);
      final tp = TextPainter(
        text: TextSpan(
          text: c.$1,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            shadows: [Shadow(color: Colors.black, blurRadius: 3), Shadow(color: Colors.black, blurRadius: 3)],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final dx = p.dx + 7 + tp.width > size.width ? p.dx - 7 - tp.width : p.dx + 7;
      tp.paint(canvas, Offset(dx, p.dy - 7));
    }
    final p = pin;
    if (p.dx >= -20 && p.dy >= -20 && p.dx <= size.width + 20 && p.dy <= size.height + 20) {
      final path = Path()
        ..moveTo(p.dx, p.dy)
        ..quadraticBezierTo(p.dx - 14, p.dy - 18, p.dx - 14, p.dy - 28)
        ..arcToPoint(Offset(p.dx + 14, p.dy - 28), radius: const Radius.circular(14))
        ..quadraticBezierTo(p.dx + 14, p.dy - 18, p.dx, p.dy)
        ..close();
      canvas.drawPath(path, Paint()..color = const Color(0xFFD7263D));
      canvas.drawPath(
          path,
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2);
      canvas.drawCircle(Offset(p.dx, p.dy - 28), 5, white);
    }
  }

  @override
  bool shouldRepaint(_PinPainter old) => old.pin != pin || old.cities.length != cities.length;
}
