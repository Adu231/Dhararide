import 'dart:typed_data';
import 'enums.dart';

enum DocumentType {
  aadhaarFront,
  aadhaarBack,
  drivingLicenceFront,
  drivingLicenceBack,
  rcBook,
  driverProfilePhoto,
}

extension DocumentTypeExtension on DocumentType {
  String get titleEn {
    switch (this) {
      case DocumentType.aadhaarFront:
        return 'Aadhaar Card – Front Side';
      case DocumentType.aadhaarBack:
        return 'Aadhaar Card – Back Side';
      case DocumentType.drivingLicenceFront:
        return 'Driving Licence – Front Side';
      case DocumentType.drivingLicenceBack:
        return 'Driving Licence – Back Side';
      case DocumentType.rcBook:
        return 'Vehicle RC Book';
      case DocumentType.driverProfilePhoto:
        return 'Driver Profile Photo';
    }
  }

  String get titleMr {
    switch (this) {
      case DocumentType.aadhaarFront:
        return 'आधार कार्ड – पुढील बाजू';
      case DocumentType.aadhaarBack:
        return 'आधार कार्ड – मागील बाजू';
      case DocumentType.drivingLicenceFront:
        return 'ड्रायव्हिंग लायसन्स – पुढील बाजू';
      case DocumentType.drivingLicenceBack:
        return 'ड्रायव्हिंग लायसन्स – मागील बाजू';
      case DocumentType.rcBook:
        return 'वाहन आरसी बुक (RC Book)';
      case DocumentType.driverProfilePhoto:
        return 'चालकाचा प्रोफाइल फोटो';
    }
  }

  String get subtitleEn {
    switch (this) {
      case DocumentType.aadhaarFront:
        return 'Clear photo showing Name, Photo & DOB (Masked Aadhaar accepted)';
      case DocumentType.aadhaarBack:
        return 'Clear photo showing Address & QR code';
      case DocumentType.drivingLicenceFront:
        return 'Valid commercial or auto licence';
      case DocumentType.drivingLicenceBack:
        return 'Authorisation class & expiry details';
      case DocumentType.rcBook:
        return 'Registration certificate of Dharashiv auto-rickshaw';
      case DocumentType.driverProfilePhoto:
        return 'Front-facing portrait without cap or sunglasses';
    }
  }

  String get subtitleMr {
    switch (this) {
      case DocumentType.aadhaarFront:
        return 'नाव, फोटो व जन्मतारीख स्पष्ट दिसणारा फोटो (मास्क केलेले आधार चालेल)';
      case DocumentType.aadhaarBack:
        return 'पत्ता व क्यूआर कोड स्पष्ट दिसणारा फोटो';
      case DocumentType.drivingLicenceFront:
        return 'वैध व्यावसायिक किंवा वाहतूक ऑटो लायसन्स';
      case DocumentType.drivingLicenceBack:
        return 'वाहन वर्ग व मुदत तपशील';
      case DocumentType.rcBook:
        return 'धाराशिव ऑटो-रिक्षा नोंदणी प्रमाणपत्र';
      case DocumentType.driverProfilePhoto:
        return 'समोरून काढलेला स्पष्ट सेल्फी / फोटो (विना टोपी/चष्मा)';
    }
  }
}

class DriverDocumentItem {
  final DocumentType type;
  final String fileName;
  final int fileSizeBytes;
  final String? localPath;
  final Uint8List? bytes;
  final DateTime uploadedAt;
  final bool isMasked;
  final String secureStorageKey;

  const DriverDocumentItem({
    required this.type,
    required this.fileName,
    required this.fileSizeBytes,
    this.localPath,
    this.bytes,
    required this.uploadedAt,
    this.isMasked = false,
    required this.secureStorageKey,
  });

  String get formattedSize {
    if (fileSizeBytes < 1024) return '$fileSizeBytes B';
    if (fileSizeBytes < 1024 * 1024) return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'fileName': fileName,
        'fileSizeBytes': fileSizeBytes,
        'localPath': localPath,
        'uploadedAt': uploadedAt.toIso8601String(),
        'isMasked': isMasked,
        'secureStorageKey': secureStorageKey,
      };
}

class DriverDocuments {
  final DriverDocumentItem? aadhaarFront;
  final DriverDocumentItem? aadhaarBack;
  final DriverDocumentItem? drivingLicenceFront;
  final DriverDocumentItem? drivingLicenceBack;
  final DriverDocumentItem? rcBook;
  final DriverDocumentItem? driverPhoto;
  final bool documentConsentGiven;
  final DateTime? consentTimestamp;
  final String? maskedAadhaarLast4;

  const DriverDocuments({
    this.aadhaarFront,
    this.aadhaarBack,
    this.drivingLicenceFront,
    this.drivingLicenceBack,
    this.rcBook,
    this.driverPhoto,
    bool documentConsentGiven = false,
    bool? aadhaarConsentGiven,
    this.consentTimestamp,
    this.maskedAadhaarLast4,
  }) : documentConsentGiven = documentConsentGiven || (aadhaarConsentGiven ?? false);

  // Backward-compatible alias
  bool get aadhaarConsentGiven => documentConsentGiven;

  int get uploadedCount {
    int count = 0;
    if (aadhaarFront != null) count++;
    if (aadhaarBack != null) count++;
    if (drivingLicenceFront != null) count++;
    if (drivingLicenceBack != null) count++;
    if (rcBook != null) count++;
    if (driverPhoto != null) count++;
    return count;
  }

  bool get isComplete => uploadedCount == 6 && documentConsentGiven;

  DriverDocuments copyWith({
    DriverDocumentItem? aadhaarFront,
    DriverDocumentItem? aadhaarBack,
    DriverDocumentItem? drivingLicenceFront,
    DriverDocumentItem? drivingLicenceBack,
    DriverDocumentItem? rcBook,
    DriverDocumentItem? driverPhoto,
    bool? documentConsentGiven,
    bool? aadhaarConsentGiven,
    DateTime? consentTimestamp,
    String? maskedAadhaarLast4,
  }) {
    return DriverDocuments(
      aadhaarFront: aadhaarFront ?? this.aadhaarFront,
      aadhaarBack: aadhaarBack ?? this.aadhaarBack,
      drivingLicenceFront: drivingLicenceFront ?? this.drivingLicenceFront,
      drivingLicenceBack: drivingLicenceBack ?? this.drivingLicenceBack,
      rcBook: rcBook ?? this.rcBook,
      driverPhoto: driverPhoto ?? this.driverPhoto,
      documentConsentGiven: documentConsentGiven ?? aadhaarConsentGiven ?? this.documentConsentGiven,
      consentTimestamp: consentTimestamp ?? this.consentTimestamp,
      maskedAadhaarLast4: maskedAadhaarLast4 ?? this.maskedAadhaarLast4,
    );
  }
}

class DriverModel {
  final String id;
  final String userId;
  final String name;
  final String phone;
  final String autoNumber;
  final String upiId;
  final String? upiQrUrl;
  final DriverVerificationStatus verificationStatus;
  final DriverAvailability availability;
  final double rating;
  final int totalRides;
  final double totalEarnings;
  final String? profileImage;
  final double? currentLatitude;
  final double? currentLongitude;
  final DateTime? lastLocationUpdate;
  final String? h3Index;
  final String createdAt;
  final DriverDocuments? documents;

  const DriverModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.phone,
    required this.autoNumber,
    required this.upiId,
    this.upiQrUrl,
    this.verificationStatus = DriverVerificationStatus.pending,
    this.availability = DriverAvailability.offline,
    this.rating = 4.8,
    this.totalRides = 0,
    this.totalEarnings = 0.0,
    this.profileImage,
    this.currentLatitude,
    this.currentLongitude,
    this.lastLocationUpdate,
    this.h3Index,
    this.createdAt = '2026-09-25',
    this.documents,
  });

  DriverModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? phone,
    String? autoNumber,
    String? upiId,
    String? upiQrUrl,
    DriverVerificationStatus? verificationStatus,
    DriverAvailability? availability,
    double? rating,
    int? totalRides,
    double? totalEarnings,
    String? profileImage,
    double? currentLatitude,
    double? currentLongitude,
    DateTime? lastLocationUpdate,
    String? h3Index,
    String? createdAt,
    DriverDocuments? documents,
  }) {
    return DriverModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      autoNumber: autoNumber ?? this.autoNumber,
      upiId: upiId ?? this.upiId,
      upiQrUrl: upiQrUrl ?? this.upiQrUrl,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      availability: availability ?? this.availability,
      rating: rating ?? this.rating,
      totalRides: totalRides ?? this.totalRides,
      totalEarnings: totalEarnings ?? this.totalEarnings,
      profileImage: profileImage ?? this.profileImage,
      currentLatitude: currentLatitude ?? this.currentLatitude,
      currentLongitude: currentLongitude ?? this.currentLongitude,
      lastLocationUpdate: lastLocationUpdate ?? this.lastLocationUpdate,
      h3Index: h3Index ?? this.h3Index,
      createdAt: createdAt ?? this.createdAt,
      documents: documents ?? this.documents,
    );
  }
}
