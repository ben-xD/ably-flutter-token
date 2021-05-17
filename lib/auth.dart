import 'dart:convert';
import 'dart:io';

import 'package:ably_flutter/ably_flutter.dart' as ably;
import 'package:ably_flutter/ably_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:super_hero/super_hero.dart';

// My authentication server is hosted in a serverless function (firebase function)
// Example serverless function written in typescript can be found here: https://github.com/ben-xD/Club/tree/main/functions
// String baseUrl = "https://region-app.cloudfunctions.net/app";
// For connecting to a local server from an iOS simulator
String baseUrl = "http://127.0.0.1:8000/club2d-app/europe-west2/app";
// For connecting to a local server from an Android Emulator
// String baseUrl = "http://10.0.2.2:8000/club2d-app/europe-west2/app";

class Auth {
  ably.Realtime _ablyClient;
  ably.RealtimeChannel _mainChannel;
  String _username;
  String _clientId;

  Auth() {
    _username = SuperHero.random();
  }

  connect() async {
    try {
      // Used to create a clientId when a client doesn't have one.
      final tokenRequest = await createTokenRequest();
      _clientId = tokenRequest["clientId"];
      print("Client ID from token request is $_clientId");

      final clientOptions = ably.ClientOptions()
        ..clientId = _clientId
        ..autoConnect = false
        ..authCallback = (TokenParams tokenParams) async {
          try {
            // Return either a [String] token or [TokenDetails] or [TokenRequest].
            // the quickest one is the TokenRequest. You can use this to get a
            //TokenDetails (which contains a token field) or let ably do it for you.
            // This call should respect the clientId given to it.
            final tokenRequestMap =
            await createTokenRequest(tokenParams: tokenParams);
            _clientId = tokenRequestMap["clientId"];
            print("Given clientId ${tokenRequestMap["clientId"]}");
            return ably.TokenRequest.fromMap(tokenRequestMap);
          } catch (e) {
            // Log error
            print(e);
          }
        };
      this._ablyClient = new ably.Realtime(options: clientOptions);

      await this._ablyClient.connect();
      print(this._ablyClient);
    } catch (e) {
      print("Error...");
      print(e);
    }
  }

  ConnectionInterface getConnectionInterface() {
    return this._ablyClient.connection;
  }

  createTokenRequest({TokenParams tokenParams}) async {
    var createTokenRequestUrl = baseUrl + "/createTokenRequest";
    if (tokenParams != null) {
      final queryString =
          Uri(queryParameters: {"clientId": tokenParams.clientId}).query;
      createTokenRequestUrl = createTokenRequestUrl + "?" + queryString;
    }

    try {
    var response = await http.post(Uri.parse(createTokenRequestUrl));
    if (response.statusCode != HttpStatus.ok) {
      throw HttpException("Server didn't return success."
          ' Status: ${response.statusCode}');
    }
    return jsonDecode(response.body) as Map;
    } catch (e) {
      print("ERROR!");
      print(e);
    }
  }

  Future<void> joinPresence() async {
    _mainChannel = this._ablyClient.channels.get("Marvel Universe");
    final presenceData = Map();
    presenceData["username"] = _username;

    // If your clientId is null here, that means you haven't connected?
    print("Client id is ${_mainChannel.realtime.options.clientId}");
    await _mainChannel.presence.enter(presenceData);
  }

  Future<List<ably.PresenceMessage>> getPresence() async {
    return await this._mainChannel.presence.get(null);
  }

  close() {
    _ablyClient.close();
  }
}
