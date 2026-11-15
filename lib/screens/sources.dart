// What data the app uses, and how. Kept in plain English so judges and
// extension officers can check every claim against the code.
import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../widgets/common.dart';

class SourcesScreen extends StatelessWidget {
  const SourcesScreen({super.key});

  static const _power = [
    ('PRECTOTCORR', 'Daily corrected precipitation, summed to compare three-month rainfall windows and to work out average rainfall, dry spells, heavy-rain days and the historical trend.'),
    ('T2M', 'Daily 2-metre air temperature, averaged within each season.'),
    ('T2M_MAX', 'Daily maximum 2-metre air temperature, used to count days above 35°C.'),
    ('T2M_MIN', 'Daily minimum 2-metre air temperature, used to count cold nights below 5°C.'),
    ('EVPTRNS', 'Daily evapotranspiration estimate, summed for a rainfall-minus-evapotranspiration indicator.'),
    ('GWETROOT', 'Modelled root-zone wetness index, averaged as a climate indicator. It is not a field soil test.'),
  ];

  static const _datasets = [
    ('NASA POWER', 'Numbers, used in the scores', 'Rain, temperature, evapotranspiration and root-zone wetness for the field, every day for 20 years.'),
    ('SRTM', 'Numbers, used in the scores; also a map layer', 'Elevation at the field and around it gives the slope. On sloping land, rotations that leave soil bare score lower for erosion.'),
    ('MODIS NDVI', 'Numbers, shown in Conditions; also a map layer', 'Plant greenness at the field for the last five months (MOD13Q1, 250 m). Shown as evidence, not used in the scores.'),
    ('MODIS true colour and Blue Marble', 'Base map', 'A recent satellite photo, or a cloud-free view, for geographic context.'),
    ('SMAP', 'Map layer from GIBS', 'SMAP brightness temperature, which follows soil moisture, across the region. The numbers are not read, because that needs a NASA Earthdata login.'),
    ('GPM', 'Map layer from GIBS', 'Brightness temperature from the GPM microwave imager, the instrument behind NASA rainfall estimates. Picture only.'),
    ('ECOSTRESS', 'Through Worldview', 'Fine-scale land surface temperature and evapotranspiration, opened in NASA Worldview from the map.'),
    ('GRACE and GRACE-FO', 'Map layer from GIBS', 'Changes in water stored in the ground, at a scale of hundreds of kilometres.'),
    ('FIRMS fire detections', 'Not included', 'A possible future addition for fire awareness.'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget para(String s) => Padding(
        padding: const EdgeInsets.only(bottom: 8), child: Text(s, style: const TextStyle(height: 1.4)));
    Widget row(String a, String b, [String? c]) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(a, style: const TextStyle(fontWeight: FontWeight.w700)),
              if (c != null)
                Text(b,
                    style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.primary)),
              Text(c ?? b, style: const TextStyle(height: 1.35)),
            ],
          ),
        );
    return Scaffold(
      appBar: AppBar(title: Text(t('dataSources'))),
      body: PageBody(
        children: [
          Panel(
            title: 'NASA POWER',
            hint: 'Daily point data for the previous 20 complete calendar years.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final p in _power) row(p.$1, p.$2),
                para('The two highest-rainfall non-overlapping three-month windows are '
                    'selected separately for each location. These are historical climate '
                    'windows, not verified local planting seasons or forecasts.'),
                para('NASA POWER is gridded data and may not represent conditions on an '
                    'individual farm. If the service is unavailable, the app reports an '
                    'error; it does not display made-up weather. The only exception is the '
                    'sample-data mode, which is switched on by hand and labelled on every '
                    'screen.'),
              ],
            ),
          ),
          Panel(
            title: 'NASA datasets in this app',
            hint: 'What each one is used for, and how far that use goes.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [for (final d in _datasets) row(d.$1, d.$2, d.$3)],
            ),
          ),
          Panel(
            title: 'NASA mapping',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                para('The map uses NASA EOSDIS GIBS imagery to give geographic context. '
                    'It can be dragged and zoomed, the layer can be changed, and NASA '
                    'Worldview opens the same area to explore other layers.'),
                para('An image is not a crop-health diagnosis or a field boundary map. '
                    'Coloured layers describe wide areas, and a layer may be blank on a '
                    'date when NASA has no picture.'),
              ],
            ),
          ),
          Panel(
            title: 'Other services',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                row('World Bank country API',
                    'Country names and broad regional groupings for the location selector.'),
                row('Open-Meteo Geocoding',
                    'Place-name lookup, administrative hierarchy and coordinates. Search uses the app language where supported.'),
                row('OpenTopoData and Open-Elevation',
                    'Public services that return SRTM elevation for a point.'),
                row('ORNL DAAC MODIS subsets', 'Returns MODIS NDVI values for a point.'),
                row('Leaflet',
                    'Interactive map display in the AgriSmart web prototype. This app draws its own map; in both, the imagery is supplied by NASA GIBS.'),
                row('Crop table',
                    'The team\'s table of 15 Ugandan crops. It is a draft that still needs an agronomist\'s review.'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
