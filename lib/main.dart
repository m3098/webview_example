import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  runApp(const MyApp());
}

enum _MenuOptions { youtube, github, userAgent, javascriptChannel }

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: WebViewWidgetApp(),
    );
  }
}

class WebViewWidgetApp extends StatefulWidget {
  const WebViewWidgetApp({super.key});

  @override
  State<WebViewWidgetApp> createState() => _WebViewWidgetAppState();
}

class _WebViewWidgetAppState extends State<WebViewWidgetApp> {
  late WebViewController controller;
  int loadProgress = 0;

  @override
  void initState() {
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onNavigationRequest: (request) {
          final host = Uri.parse(request.url).host;
          if (host.contains('youtube.com')) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Blocking navigation to $host',
                ),
              ),
            );
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
        onPageStarted: (url) {
          setState(() => loadProgress = 0);
        },
        onPageFinished: (url) {
          setState(() => loadProgress = 100);
        },
        onProgress: (progress) {
          setState(() => loadProgress = progress);
        },
      ))
      ..addJavaScriptChannel(
        'ShowBar',
        onMessageReceived: (message) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(message.message)));
        },
      )
      ..loadRequest(Uri.parse("https://flutter.dev/"));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final messenger = ScaffoldMessenger.of(context);
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
              onPressed: () async {
                if (await controller.canGoBack()) {
                  await controller.goBack();
                } else {
                  messenger.showSnackBar(
                    const SnackBar(content: Text('No back history item')),
                  );
                  return;
                }
              },
              icon: const Icon(Icons.arrow_back)),
          IconButton(
              onPressed: () async {
                if (await controller.canGoForward()) {
                  await controller.goForward();
                } else {
                  messenger.showSnackBar(
                    const SnackBar(content: Text('No forward history item')),
                  );
                  return;
                }
              },
              icon: const Icon(Icons.arrow_forward)),
          IconButton(
              onPressed: () async {
                controller.reload();
              },
              icon: const Icon(Icons.refresh)),
          PopupMenuButton<_MenuOptions>(
            onSelected: (value) async {
              switch (value) {
                case _MenuOptions.youtube:
                  await controller
                      .loadRequest(Uri.parse('https://youtube.com'));
                  break;
                case _MenuOptions.github:
                  await controller.loadRequest(Uri.parse('https://github.com'));
                  break;
                case _MenuOptions.userAgent:
                  final userAgent = await controller
                      .runJavaScriptReturningResult('navigator.userAgent');
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('$userAgent'),
                  ));
                  break;
                case _MenuOptions.javascriptChannel:
                  await controller.runJavaScript('''
var req = new XMLHttpRequest();
req.open('GET', "https://api.ipify.org/?format=json");
req.onload = function() {
  if (req.status == 200) {
    let response = JSON.parse(req.responseText);
    ShowBar.postMessage("IP Address: " + response.ip);
  } else {
    ShowBar.postMessage("Error: " + req.status);
  }
}
req.send();''');
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem<_MenuOptions>(
                value: _MenuOptions.youtube,
                child: Text('Navigate to YouTube'),
              ),
              const PopupMenuItem<_MenuOptions>(
                value: _MenuOptions.github,
                child: Text('Navigate to GitHub'),
              ),
              const PopupMenuItem<_MenuOptions>(
                value: _MenuOptions.userAgent,
                child: Text('Show user-agent'),
              ),
              const PopupMenuItem<_MenuOptions>(
                value: _MenuOptions.javascriptChannel,
                child: Text('Lookup IP Address'),
              ),
            ],
          )
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(
            controller: controller,
          ),
          if (loadProgress < 100)
            Align(
              alignment: Alignment.bottomCenter,
              child: LinearProgressIndicator(
                value: loadProgress / 100.0,
              ),
            ),
        ],
      ),
    );
  }
}
