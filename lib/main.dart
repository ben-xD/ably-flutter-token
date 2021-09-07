import 'package:ably_flutter/ably_flutter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'auth.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Ably Token Authentication'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({required this.title, Key? key}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _ably = AblyService();
  bool buttonsEnabled = false;
  Future<List<PresenceMessage>> _presence = Future.value([]);

  @override
  initState() {
    super.initState();
    asyncInitState();
  }

  Future<void> asyncInitState() async {
    await _ably.connect();
    // Enable the buttons
    setState(() {
      buttonsEnabled = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextButton(
                onPressed: buttonsEnabled
                    ? () {
                  final interface = _ably.getConnectionInterface();
                  print(
                      "Connection state: ${interface.state}. Error reason?: ${interface.errorReason}");
                }
                    : null,
                child: Text("Print connection status")),
            TextButton(
                onPressed: buttonsEnabled
                    ? () async {
                  _ably.sendMessageUsingRestClient();
                }
                    : null,
                child: Text("Publish a rest message")),
            TextButton(
                onPressed: buttonsEnabled
                    ? () async {
                  await _ably.joinPresence();
                  print(await _ably.getPresence());
                }
                    : null,
                child: Text("Join presence")),
            TextButton(
                onPressed: buttonsEnabled
                    ? () async {
                  setState(() {
                    _presence = _ably.getPresence();
                  });
                }
                    : null,
                child: Text("Get presence")),
            Flexible(
              child: FutureBuilder(
                  future: _presence,
                  builder: (context,
                      AsyncSnapshot<List<PresenceMessage>> snapshot) {
                    if (snapshot.hasData) {
                      final presenceMessages = snapshot.data;
                      return Align(
                        alignment: Alignment.center,
                        child: ListView.builder(
                            itemCount: presenceMessages!.length,
                            itemBuilder: (context, index) {
                              return Text(presenceMessages[index].clientId ?? "No client ID");
                            }),
                      );
                    }
                    if (snapshot.hasError) {
                      return Text("Error: ${snapshot.error}");
                    }
                    return Text("No presence yet");
                  }),
            ),
            TextButton(onPressed: () {
              _ably.sendMessageUsingRestClient();
            }, child: Text("Send message from rest to realtime"))
          ],
        ),
      ),
    );
  }
}
