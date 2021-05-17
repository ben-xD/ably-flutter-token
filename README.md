# Using Token Auth in Ably Flutter 

This is a basic flutter app which shows how to use [Token Authentication](https://ably.com/documentation/core-features/authentication#token-authentication) for [Ably](https://ably.com).

Warning: In iOS, secure transport is disabled to allow using a local http server to perform authentication. You can remove this by deleting the `NSAppTransportSecurity` dictionary in `ios/Info.plist`