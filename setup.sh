#!/bin/sh
# One-time setup, then start the app with the settings in .env.
cd "$(dirname "$0")" || exit 1
[ -f .env ] || cp .env.example .env
dart tool/setup.dart && flutter run --dart-define-from-file=.env "$@"
