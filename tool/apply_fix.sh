#!/usr/bin/env bash
# Replaces mqtt5_client 5.4.0 with a copy that keeps the subscriptions
# returned by onListen(), so stopListening() can cancel them.
set -euo pipefail
cd "$(dirname "$0")/.."
rm -rf fixed
dart pub unpack mqtt5_client:5.4.0 --output fixed >/dev/null
f=fixed/mqtt5_client-5.4.0/lib/src/connectionhandling/browser/mqtt_browser_connection.dart
grep -q '^      onListen();$' "$f"
sed -i.bak 's/^      onListen();$/      listeners.addAll(onListen());/' "$f"
rm "$f.bak"
grep -n 'listeners.addAll(onListen())' "$f"
cat > pubspec_overrides.yaml <<'YAML'
dependency_overrides:
  mqtt5_client:
    path: fixed/mqtt5_client-5.4.0
YAML
