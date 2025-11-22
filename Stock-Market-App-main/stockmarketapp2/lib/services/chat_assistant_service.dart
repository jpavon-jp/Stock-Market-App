// lib/services/chat_assistant_service.dart

/// ChatAssistantService
///
/// A simple holder for the static WebChat embed URL generated
/// by Copilot Studio. Your ChatAssistantScreen uses this URL
/// to load the AI assistant interface in a WebView.
class ChatAssistantService {
  /// The embeddable “WebChat” URL you obtained from Copilot Studio.
  ///
  /// Paste your bot’s WebChat link here. When the user navigates
  /// to the ChatAssistantScreen, this URL is loaded in a full-screen
  /// WebViewController with JavaScript enabled.
  static const String webChatUrl =
      'https://copilotstudio.microsoft.com/'
      'environments/Default-84c31ca0-ac3b-4eae-ad11-519d80233e6f/'
      'bots/cr5be_ticker/webchat?__version__=2';
}
