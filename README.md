# AgriSmart

Crop rotation decision support for the NASA Space Apps challenge
"Field Shift: Adapting Farms with NASA Data".

The farmer describes a field, the crops grown now, the soil, their limits and
what matters to them. The app reads 20 years of NASA POWER daily weather for
that point, scores rotations built from the team's crop table, and compares
the current rotation with two alternatives. Each comes with reasons,
evidence, benefits, unknowns and risks to review locally.

One Flutter codebase for Android, iOS, web, Windows, macOS and Linux. Phones
get a bottom tab bar; screens 840 px and wider get a side rail.

## The 15 screens

1 Welcome, 2 Language, 3 How it works, 4 Add your field, 5 What you grow now,
6 Soil and limits, 7 What matters to you, 8 Home, 9 Field conditions,
10 The year on your field, 11 Rotation options, 12 Side by side,
13 One rotation in detail, 14 Before you decide, 15 Learn.

the web view of the app: ("https://agricsmart.vercel.app/")

the insight of the system:  ("https://www.canva.com/design/DAHa8Bo9MEc/o_rmKMBA69Ao-fNMR5BBww/edit")

## Set up

1. Install Flutter 3.27 or newer (https://docs.flutter.dev/get-started/install).
2.    then:
   - **Windows:** double-click `setup.bat`
   - **Linux or macOS:** run `./setup.sh` in a terminal

That one step creates the platform folders, installs the AgriSmart logo as
the app icon and loading screen, sets the app name, sets the internet
permission, downloads the packages, and starts the app with the settings in
`.env`. To open it in a browser, add `-d chrome`.

After the first time, run `flutter run --dart-define-from-file=.env`.

then : 
     run : flutter run --dart-define-from-file=.env         
           #
           flutter build apk --dart-define-from-file=.env # to build Android APK
           #
           ./build_web.sh        # flutter build web with the same flag  the web links is ("https://agricsmart.vercel.app/"

           THE WEB LINK is "https://agricsmart.vercel.app/"

    flutter run --dart-define-from-file=.env
    flutter build apk --dart-define-from-file=.env
    ./build_web.sh        # flutter build web with the same flag



## Build

    flutter build apk          # Android
    flutter build web          # any browser; host the build/web folder
    flutter build windows      # must be run on Windows
    flutter build linux        # must be run on Linux
    flutter build macos        # must be run on a Mac
    flutter build ios          # must be run on a Mac with Xcode

## The crop table

`data/crops.csv` is the team's dataset. The app reads a Dart copy of it,
`lib/data/crops_data.dart`. location

    python3 tool/csv_to_dart.py

How the columns are used:

| Goal or rule | Columns |
| --- | --- |
| Does the crop fit the season | water_min_mm, temp_min_c, temp_max_c, days_min, drought_tolerance_1to5 |
| Using less water | water_min_mm |
| Feed for animals | residue_biomass_returned |
| Nitrogen for the soil | n_fixation_kg_ha, nutrient_demand_1to5, good_predecessors |
| Less erosion | ground_cover_score_1to5, days (months the field is covered) |
| More organic matter | soil_organic_matter_effect, residue_biomass_returned |
| Crops that sell well | yield, price_per_kg, input_labour_cost, price_variability, storability |
| Food for the household | yield, calories_kcal_per_kg |
| Pest rest periods | host_group, break_period_seasons |
| Which crops rotate | life_cycle, rotation_slots_occupied (perennials are shown in Learn only) |
| Limits | input_labour_cost (budget), planting_window "needs flooding" (water) |

Assumptions 

- Groundnuts and rice: 65% of harvested weight is sold at the shelled or
  milled price (`SALE_FRACTION` in `tool/csv_to_dart.py`).
- Sandy soil keeps 15% less rain for crops, sandy loam 7% (`rainFactor`).
- "Some irrigation" adds 150 mm a season (`irrigationMm`).
- Budget limits of UGX 2M and 4.5M a hectare (`costLimit`).
- A missed pest rest period takes 10% off a rotation's score.

## Where things live

    lib/data/crops_data.dart     generated from data/crops.csv
    lib/engine/models.dart       crop fields, places, seasons, the farmer's setup
    lib/engine/power_api.dart    NASA POWER download
    lib/engine/indicators.dart   rainfall, evaporation, dry spells, trends
    lib/engine/scoring.dart      crop fit and rotation scoring
    lib/engine/explanation.dart  reasons, evidence, benefits, unknowns, risks
    lib/engine/demo_data.dart    sample weather
    lib/analysis.dart            runs the pipeline end to end
    lib/screens/                 the 15 screens
    lib/widgets/                 logo, charts, shared pieces
    tool/check.dart              prints results without the UI
    branding/                    logo SVGs and icon PNGs

## Logo and app icon

The mark is a ring of four seasons around a seedling. Inside the app it is
drawn by `lib/widgets/logo.dart`. `branding/platform/` holds ready-made icon
files for Android, iOS, web, Windows and macOS, and `tool/setup.dart` copies
them into place.

## Known limits

- NASA POWER and SRTM slope feed the scores. MODIS NDVI is shown as
  evidence. SMAP, GPM, GRACE-FO and Landsat are map layers only.
- The map is one picture per view from NASA, redrawn after each drag or
  zoom, so it is not as smooth as a tiled map. There is no GPS button.
- The crop table is Ugandan. Outside Uganda the app still runs, and says so
  in every result, but crops and prices may not fit.
- Local languages such as Luganda are listed but not yet translated.
- Nothing is saved between launches.
- With the one-season pattern, each year holds one crop, so the calendar
  shows many bare months even where farmers would plant twice.
- The crop table is marked DRAFT. The app says so on every result.
