import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../features/requests/domain/request_models.dart';

/// Shows a location pin in the phone's own maps app. The app has no maps provider of its
/// own (it is offline by design), so the pin is handed to whatever maps app is installed.
abstract class MapLauncher {
  /// Returns false when no app could open the pin.
  Future<bool> open(GeoPoint point, {String? label});
}

class DeviceMapLauncher implements MapLauncher {
  const DeviceMapLauncher();

  @override
  Future<bool> open(GeoPoint point, {String? label}) async {
    final coords = '${point.latitude},${point.longitude}';
    final query = label == null ? coords : '$coords($label)';
    final candidates = [
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android)
        Uri.parse('geo:$coords?q=${Uri.encodeComponent(query)}'),
      Uri.https('www.google.com', '/maps/search/', {
        'api': '1',
        'query': coords,
      }),
    ];
    for (final uri in candidates) {
      try {
        if (await launchUrl(uri, mode: LaunchMode.externalApplication)) {
          return true;
        }
      } catch (_) {
        // Try the next way of showing the pin.
      }
    }
    return false;
  }
}
