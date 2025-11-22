/*
  news_webview.dart – In-app web view for reading full articles

  • NewsWebView (StatefulWidget):
      – Accepts a required `url` to load and an optional `title` (defaults to 'Article').
      – Displays a full‐screen WebView with a translucent AppBar.

  • _NewsWebViewState:
      – Holds a WebViewController (`_controller`) and a loading flag (`_isLoading`).
      – initState():
          • Initializes `_controller`:
              – Enables JavaScript via `setJavaScriptMode(JavaScriptMode.unrestricted)`.
              – Attaches a NavigationDelegate to update `_isLoading`:
                  – onPageStarted → `_isLoading = true`
                  – onPageFinished → `_isLoading = false`
          • Calls `loadRequest(Uri.parse(widget.url))` to begin loading.

  • build():
      – Returns a Scaffold with:
          AppBar:
            – Transparent background (so any gradient behind can show through).
            – Zero elevation.
            – Title text from `widget.title`, with ellipsis overflow.
            – White back button to pop the view.
          Body:
            – A Stack containing:
                1. `WebViewWidget(controller: _controller)` to render the web page.
                2. If `_isLoading` is true, overlays a centered `CircularProgressIndicator` (white).

  • Usage:
      – Push this screen with `Navigator.push(context, MaterialPageRoute(builder: (_) => NewsWebView(url: url, title: title)))`.
      – Provides a seamless in‐app browsing experience with loading feedback.
*/


import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class NewsWebView extends StatefulWidget {
  final String url;
  final String title;

  const NewsWebView({
    Key? key,
    required this.url,
    this.title = 'Article',
  }) : super(key: key);

  @override
  _NewsWebViewState createState() => _NewsWebViewState();
}

class _NewsWebViewState extends State<NewsWebView> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_)  => setState(() => _isLoading = true),
          onPageFinished: (_) => setState(() => _isLoading = false),
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // translucent AppBar so any gradient behind can show
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(widget.title, overflow: TextOverflow.ellipsis),
        leading: const BackButton(color: Colors.white),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(child: CircularProgressIndicator(color: Colors.white)),
        ],
      ),
    );
  }
}