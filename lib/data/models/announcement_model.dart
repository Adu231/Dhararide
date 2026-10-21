class AnnouncementModel {
  final String id;
  final String title;
  final String messageEn;
  final String messageMr;
  final String targetAudience; // ALL, CUSTOMER, DRIVER
  final bool isActive;
  final String createdAt;

  const AnnouncementModel({
    required this.id,
    required this.title,
    required this.messageEn,
    required this.messageMr,
    this.targetAudience = 'ALL',
    this.isActive = true,
    this.createdAt = '2026-09-25',
  });

  String getMessage(bool isMr) => isMr ? messageMr : messageEn;
}
