import 'dart:convert';
import 'dart:io';

import 'package:ably_flutter/ably_flutter.dart' as ably;
import 'package:ably_flutter/ably_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:super_hero/super_hero.dart';

// My authentication server is hosted in a serverless function (firebase function)
// Example serverless function written in typescript can be found here: https://github.com/ben-xD/Club/tree/main/functions
String _baseUrl = "https://your_auth_service_url.net/app";
// Bug in flutter: Using a local IP on Android causes connection closed before full header was received https://stackoverflow.com/questions/55879550/how-to-fix-httpexception-connection-closed-before-full-header-was-received

class AuthService {
  ably.Realtime _ablyClient;
  ably.RealtimeChannel _mainChannel;
  String _username;
  String _clientId;

  AuthService() {
    _username = SuperHero.random();
  }

  connect() async {
    try {
      // Used to create a clientId when a client doesn't have one.
      final tokenRequest = await createTokenRequest();
      _clientId = tokenRequest["clientId"];

      final clientOptions = ably.ClientOptions()
        ..clientId = _clientId
        ..autoConnect = false
        ..authCallback = (TokenParams tokenParams) async {
          try {
            // Return either a [String] token or [TokenDetails] or [TokenRequest].
            // the quickest one is the TokenRequest. You can use this to get a
            //TokenDetails (which contains a token field) or let ably do it for you.
            // This call should respect the clientId given to it.
            final tokenRequestMap = await createTokenRequest(tokenParams: tokenParams);
            print(tokenRequestMap);
            if (_clientId != tokenRequestMap["clientId"]) {
              throw "clientId provided by server ${tokenRequestMap["clientId"]} doesn't match current clientId $_clientId.";
            }
            return ably.TokenRequest.fromMap(tokenRequestMap);
          } catch (e) {
            print("Something went wrong in the authCallback:");
            print(e);
          }
        };
      this._ablyClient = new ably.Realtime(options: clientOptions);

      await this._ablyClient.connect();
      print(this._ablyClient);
    } catch (e) {
      print(e);
    }
  }

  ConnectionInterface getConnectionInterface() {
    return this._ablyClient.connection;
  }

  createTokenRequest({TokenParams tokenParams}) async {
    var createTokenRequestUrl = _baseUrl + "/createTokenRequest";
    if (tokenParams != null) {
      final queryString =
          Uri(queryParameters: {"clientId": tokenParams.clientId}).query;
      createTokenRequestUrl = createTokenRequestUrl + "?" + queryString;
    }

    try {
    var response = await http.post(Uri.parse(createTokenRequestUrl)).timeout(Duration(seconds: 10));
    if (response.statusCode != HttpStatus.ok) {
      throw HttpException("Server didn't return success."
          ' Status: ${response.statusCode}');
    }
    return jsonDecode(response.body) as Map;
    } catch (e) {
      print("Something went wrong in the CreateToken HTTP request...");
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
