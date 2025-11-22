/*
  chat_assistant_screen.dart – In-App AI Assistant via WebView

  • StatefulWidget + WebViewController:
      – Uses a StatefulWidget to manage the lifecycle of the WebViewController.
      – In initState(), initializes the controller with:
          • JavaScriptMode.unrestricted to allow full JS execution.
          • loadRequest() pointing at ChatAssistantService.webChatUrl.

  • Scaffold & translucent AppBar:
      – backgroundColor: transparent so the underlying gradient shows.
      – AppBar:
          • transparent background and zero elevation for a seamless look.
          • title “AI Assistant” and a white BackButton to pop the screen.

  • Gradient background for body:
      – Wraps the WebViewWidget in a Container with a vertical LinearGradient
        from AppColors.backgroundEnd (dark) to AppColors.backgroundStart (lighter).

  • WebViewWidget:
      – Displays the external chat interface inside the app.
      – Controlled by the pre-configured WebViewController.

  Usage:
    Navigator.push(context,
      MaterialPageRoute(builder: (_) => const ChatAssistantScreen())
    );
*/


import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../services/chat_assistant_service.dart';

class ChatAssistantScreen extends StatefulWidget {
  const ChatAssistantScreen({Key? key}) : super(key: key);
  @override
  _ChatAssistantScreenState createState() => _ChatAssistantScreenState();
}

class _ChatAssistantScreenState extends State<ChatAssistantScreen> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    // Initialize the controller
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(ChatAssistantService.webChatUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      // translucent AppBar so gradient shows through
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('AI Assistant'),
        leading: BackButton(color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.backgroundEnd,
              AppColors.backgroundStart,
            ],
          ),
        ),
        child: WebViewWidget(controller: _controller),
      ),
    );
  }
}
