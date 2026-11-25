#!/usr/bin/env bash
#
# Builds the Cupward web app in release mode and deploys it to Firebase Hosting.
#
# The reCAPTCHA Enterprise site key that App Check needs on the web is read from the RECAPTCHA_SITE_KEY environment
# variable, or from the first argument. See FIREBASE_SETUP.md.
#
# Usage:
#   RECAPTCHA_SITE_KEY=<site-key> ./deploy_web.sh
#   ./deploy_web.sh <site-key>
#
# Set PREVIEW=1 to deploy to a temporary preview channel instead of the live site.

set -euo pipefail

cd "$(dirname "$0")"

SITE_KEY="${1:-${RECAPTCHA_SITE_KEY:-}}"
if [[ -z "$SITE_KEY" ]]; then
  echo "Missing reCAPTCHA site key. Pass it as an argument or set RECAPTCHA_SITE_KEY." >&2
  exit 1
fi

flutter build web --release --dart-define=RECAPTCHA_SITE_KEY="$SITE_KEY"

if [[ "${PREVIEW:-}" == "1" ]]; then
  firebase hosting:channel:deploy preview --config firebase.hosting.json
else
  firebase deploy --only hosting --config firebase.hosting.json
fi
