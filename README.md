# Using Token Auth in Ably Flutter 

This is a basic flutter app which shows how to use [Token Authentication](https://ably.com/documentation/core-features/authentication#token-authentication) for [Ably](https://ably.com).

Warning:
- On iOS, secure transport is disabled to allow using a local http server to perform authentication. You can remove this by deleting the `NSAppTransportSecurity` dictionary in `ios/Info.plist`
- On Android, `android:usesCleartextTraffic="true"` is set `AndroidManifest.xml`.
- To connect to a local server on your machine from an Android device, use `adb reverse tcp:8000 tcp:8000`.
