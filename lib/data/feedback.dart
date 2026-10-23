import 'connections.dart';
import 'portal.dart';

/// Geri bildirimin konusu (portalda `FeedbackCategory` ile aynı adlar).
enum FeedbackTopic { bug, idea, other }

/// Uygulama içi geri bildirim.
///
/// Geri bildirim kişiye bağlanmaz: takma kimlik, portal anahtarı ya da sağlık
/// verisi gönderilmez. Kullanıcı isterse yalnızca uygulama sürümü, platform
/// ve dil eklenir.
abstract class FeedbackService {
  /// En çok bu kadar karakter (portal da aynı sınırı uygular).
  static const maxLength = 2000;

  /// Gönderilemezse [ConnectionUnavailable] fırlatır.
  Future<void> send(FeedbackTopic topic, String message, {FeedbackContext? context});
}

/// İsteğe bağlı teknik bilgi.
class FeedbackContext {
  const FeedbackContext({
    required this.appVersion,
    required this.platform,
    required this.locale,
  });

  final String appVersion;
  final String platform;
  final String locale;
}

/// Portalın `POST /feedback` ucuna gönderir; oturum anahtarı kullanılmaz.
class PortalFeedbackService implements FeedbackService {
  PortalFeedbackService(this.client);

  final PortalClient client;

  @override
  Future<void> send(
    FeedbackTopic topic,
    String message, {
    FeedbackContext? context,
  }) async {
    await client.request(
      'POST',
      '/feedback',
      auth: false,
      body: {
        'category': topic.name,
        'message': message.trim(),
        if (context != null) ...{
          'appVersion': context.appVersion,
          'platform': context.platform,
          'locale': context.locale,
        },
      },
    );
  }
}

/// Demo ve testler: gönderilenleri bellekte tutar.
class FakeFeedbackService implements FeedbackService {
  final sent = <({FeedbackTopic topic, String message, FeedbackContext? context})>[];

  /// Testte ağ hatası denemek için.
  bool fail = false;

  @override
  Future<void> send(
    FeedbackTopic topic,
    String message, {
    FeedbackContext? context,
  }) async {
    if (fail) throw const ConnectionUnavailable('sahte hata');
    sent.add((topic: topic, message: message.trim(), context: context));
  }
}
