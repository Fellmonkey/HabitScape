import 'package:url_launcher/url_launcher.dart';

/// Stateless wrapper over the platform URL launcher. UI code calls this seam
/// instead of the plugin, so tests can substitute a fake.
class ExternalLinkLauncher {
  const ExternalLinkLauncher();

  Future<bool> open(String url) {
    return launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }
}
