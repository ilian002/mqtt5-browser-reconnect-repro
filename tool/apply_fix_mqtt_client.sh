#!/usr/bin/env bash
# Replaces mqtt_client 10.14.0 with a copy that keeps the subscriptions
# returned by onListen() in the browser connection, so stopListening() can
# cancel them (the same change as mqtt5_client 5.4.1).
set -euo pipefail
cd "$(dirname "$0")/.."
rm -rf fixed
dart pub unpack mqtt_client:10.14.0 --output fixed >/dev/null
f=fixed/mqtt_client-10.14.0/lib/src/connectionhandling/browser/mqtt_client_mqtt_browser_connection.dart
[ "$(grep -c '^      onListen();$' "$f")" = 1 ]
sed -i.bak 's/^      onListen();$/      listeners.addAll(onListen());/' "$f"
rm "$f.bak"
grep -n 'listeners.addAll(onListen())' "$f"
cat > pubspec_overrides.yaml <<'YAML'
dependency_overrides:
  mqtt_client:
    path: fixed/mqtt_client-10.14.0
YAML
