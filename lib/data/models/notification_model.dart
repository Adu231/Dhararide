class NotificationModel {
  final String id;
  final String titleEn;
  final String titleMr;
  final String bodyEn;
  final String bodyMr;
  final String timestamp;
  final bool isRead;

  const NotificationModel({
    required this.id,
    required this.titleEn,
    required this.titleMr,
    required this.bodyEn,
    required this.bodyMr,
    this.timestamp = 'Just now',
    this.isRead = false,
  });

  String getTitle(bool isMr) => isMr ? titleMr : titleEn;
  String getBody(bool isMr) => isMr ? bodyMr : bodyEn;
}
