# mqtt5_client browser reconnect repro

A minimal reproduction for [mqtt5_client](https://pub.dev/packages/mqtt5_client): the browser client
doesn't auto-reconnect in Safari after the broker connection drops. Follow-up to
[shamblett/mqtt5_client#210](https://github.com/shamblett/mqtt5_client/issues/210).

**Fixed in mqtt5_client 5.4.1** ([#212](https://github.com/shamblett/mqtt5_client/pull/212)). The
[CI run against 5.4.0](https://github.com/ilian002/mqtt5-browser-reconnect-repro/actions/runs/44347271071)
shows the failure and the fix.

CI now runs the same test against [mqtt_client](https://pub.dev/packages/mqtt_client) (MQTT 3.1.1),
whose browser connection has the same `_startListening()` code:
[`test/mqtt_client_reconnect_test.dart`](test/mqtt_client_reconnect_test.dart), with the fix applied by
[`tool/apply_fix_mqtt_client.sh`](tool/apply_fix_mqtt_client.sh).

## The test

[`test/reconnect_test.dart`](test/reconnect_test.dart) starts a local Mosquitto with a websocket
listener and connects an `MqttBrowserClient` with `autoReconnect = true`. It then kills Mosquitto with
SIGKILL, so the connection ends without a close frame, as in a broker crash or reboot, and restarts it
2 s later. The test passes if `onAutoReconnected` fires within 20 s.

A small script records every `WebSocket` the page creates and the order of its events. The log is
printed at the end of each run.

CI runs it in Safari (macOS), Chrome and Firefox (Linux), both against mqtt5_client 5.4.0 from pub.dev
and with the one-line change below.

## What happens

On an abnormal close, Chrome fires only `close`, and the client reconnects. Safari fires `error` and
then `close`:

1. `onError()` → `disconnect(auto: true)`, and auto-reconnect opens a new socket.
2. The old socket's `close` listener is still active. `onDone()` → `disconnect(auto: true)` then
   closes the *current* socket, which is now the new one, while it is still connecting.
3. The client stays in `connecting` and doesn't try again.

`stopListening()` should cancel the old listeners, but `_startListening()` discards the subscriptions
`onListen()` returns, so `listeners` is always empty.

## The change

`lib/src/connectionhandling/browser/mqtt_browser_connection.dart`:

```diff
   void _startListening() {
     MqttLogger.log('MqttBrowserConnection::_startListening');
     try {
-      onListen();
+      listeners.addAll(onListen());
```

[`tool/apply_fix.sh`](tool/apply_fix.sh) applies it to an unpacked copy of 5.4.0 through
`pubspec_overrides.yaml`.

## Run locally

```sh
dart pub get
dart test -p chrome            # or -p safari on macOS, -p firefox
tool/apply_fix.sh && dart pub get && dart test -p safari
```

The test runs `mosquitto` from `PATH`. Set `MOSQUITTO` to point at a different binary.
