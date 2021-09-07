import 'dart:convert';
import 'dart:io';

import 'package:ably_flutter/ably_flutter.dart';
import 'package:http/http.dart' as http;

// My authentication server is hosted in a serverless function, the code written in Typescript can be found:
// https://github.com/ben-xD/Club/blob/4cc408554099a4ddebab1aa7422e8cdbb170ce5f/functions/src/index.ts#L35-L43
String _baseUrl = "https://your_auth_service_url.net/app";
// Bug in flutter: Using a local IP on Android causes connection closed before full header was received https://stackoverflow.com/questions/55879550/how-to-fix-httpexception-connection-closed-before-full-header-was-received

class AblyService {
  String _channelName = "rooms:lobby";
  late Realtime _ablyRealtimeClient;
  late Rest _ablyRestClient;
  late RealtimeChannel _mainChannel;
  String _username = 'A random superhero name';

  connect() async {
    try {
      // Used to create a clientId when a client doesn't have one.
      final clientOptions = ClientOptions()
        ..autoConnect = false
        ..authCallback = (TokenParams tokenParams) async {
          try {
            // Return either a [String] token or [TokenDetails] or [TokenRequest].
            // the quickest one is the TokenRequest. You can use this to get a
            //TokenDetails (which contains a token field) or let ably do it for you.
            // This call should respect the clientId given to it.
            final tokenRequestMap =
            await createTokenRequest(tokenParams: tokenParams);
            print(tokenRequestMap);
            return TokenRequest.fromMap(tokenRequestMap);
          } catch (e) {
            print("Something went wrong in the authCallback:");
            rethrow;
          }
        };
      this._ablyRealtimeClient = new Realtime(options: clientOptions);
      this._ablyRestClient = new Rest(options: clientOptions);
      await this._ablyRealtimeClient.connect();
    } catch (e) {
      print(e);
    }
  }

  ConnectionInterface getConnectionInterface() {
    return this._ablyRealtimeClient.connection;
  }

  Future<Map<String, dynamic>> createTokenRequest({TokenParams? tokenParams}) async {
    var createTokenRequestUrl = _baseUrl + "/createTokenRequest";
    if (tokenParams != null) {
      final queryString =
          Uri(queryParameters: {"clientId": tokenParams.clientId}).query;
      createTokenRequestUrl = createTokenRequestUrl + "?" + queryString;
    }

    try {
      var response = await http
          .post(Uri.parse(createTokenRequestUrl))
          .timeout(Duration(seconds: 5));
      if (response.statusCode != HttpStatus.ok) {
        throw HttpException("Server didn't return success."
            ' Status: ${response.statusCode}');
      }
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      print("Something went wrong in the CreateToken HTTP request...");
      throw e;
    }
  }

  Future<void> joinPresence() async {
    _mainChannel = this._ablyRealtimeClient.channels.get(_channelName);
    final presenceData = Map();
    presenceData["username"] = _username;

    print("Client id is ${_mainChannel.realtime.options.clientId}");
    await _mainChannel.presence.enter(presenceData);
  }

  Future<List<PresenceMessage>> getPresence() async {
    return await this._mainChannel.presence.get(null);
  }

  Future<void> sendMessageUsingRestClient() async {
    await this._ablyRestClient.channels.get(_channelName).publish(message: Message(name: "Hello Ben"));
  }

  close() {
    _ablyRealtimeClient.close();
  }
}
