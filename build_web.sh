#!/bin/sh
# Builds the website into build/web, ready to upload to any static host.
# If the site is public, set AI_PROXY_URL in .env and leave AI_API_KEY empty:
# anything built into a website can be read by its visitors.
cd "$(dirname "$0")" || exit 1
flutter build web --release --dart-define-from-file=.env "$@"
