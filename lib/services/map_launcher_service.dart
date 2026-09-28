import 'package:url_launcher/url_launcher.dart';

class MapLauncherException implements Exception {
  const MapLauncherException(this.message);
  final String message;

  @override
  String toString() => message;
}

class MapLauncherService {
  static Future<void> open(String mapUrl) async {
    final uri = Uri.tryParse(mapUrl);
    if (uri == null || uri.scheme != 'https') {
      throw const MapLauncherException('The location link is invalid.');
    }

    final opened = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
      webOnlyWindowName: '_blank',
    );
    if (!opened) {
      throw const MapLauncherException('Unable to open the location link.');
    }
  }
}
