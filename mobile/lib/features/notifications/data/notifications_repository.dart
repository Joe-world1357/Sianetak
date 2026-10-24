import '../../../demo/demo_backend.dart';

/// In-app notices for key state changes (offers, assignment, quotes, chat, verification).
class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.at,
    required this.read,
    this.requestId,
    this.reference,
    this.applicationId,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: json['id'] as String,
        type: json['type'] as String,
        at: DateTime.parse(json['at'] as String),
        read: json['read'] as bool? ?? false,
        requestId: json['requestId'] as String?,
        reference: json['reference'] as String?,
        applicationId: json['applicationId'] as String?,
      );

  final String id;
  final String type;
  final DateTime at;
  final bool read;
  final String? requestId;
  final String? reference;
  final String? applicationId;
}

abstract class NotificationsRepository {
  Future<List<AppNotification>> list();
  Future<void> markAllRead();

  /// Unread count for the signed-in user; cheap enough to call on every rebuild.
  int unreadCount();
}

class LocalNotificationsRepository implements NotificationsRepository {
  LocalNotificationsRepository(this._backend);

  final DemoBackend _backend;

  @override
  Future<List<AppNotification>> list() async => (await _backend.notifications())
      .map(AppNotification.fromJson)
      .toList(growable: false);

  @override
  Future<void> markAllRead() => _backend.markNotificationsRead();

  @override
  int unreadCount() => _backend.unreadCount();
}
