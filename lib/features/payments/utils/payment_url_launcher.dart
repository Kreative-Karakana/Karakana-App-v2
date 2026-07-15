import 'package:url_launcher/url_launcher.dart';

typedef LaunchUrlDelegate = Future<bool> Function(
  Uri uri,
  LaunchMode mode,
);

class PaymentUrlLauncher {
  PaymentUrlLauncher({LaunchUrlDelegate? launchUrlDelegate})
      : _launchUrl =
            launchUrlDelegate ?? ((uri, mode) => launchUrl(uri, mode: mode));

  final LaunchUrlDelegate _launchUrl;

  Future<bool> openCheckoutUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;

    var opened = await _launchUrl(uri, LaunchMode.externalApplication);
    if (!opened) {
      opened = await _launchUrl(uri, LaunchMode.inAppBrowserView);
    }
    if (!opened) {
      opened = await _launchUrl(uri, LaunchMode.platformDefault);
    }
    return opened;
  }
}
