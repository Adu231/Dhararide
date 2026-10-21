class LocationPointModel {
  final String address;
  final String placeName;
  final double latitude;
  final double longitude;

  const LocationPointModel({
    required this.address,
    required this.placeName,
    this.latitude = 18.1861,
    this.longitude = 76.0419,
  });
}

class PopularPlaceModel {
  final String id;
  final String nameEn;
  final String nameMr;
  final String address;
  final double latitude;
  final double longitude;
  final String category;

  const PopularPlaceModel({
    required this.id,
    required this.nameEn,
    required this.nameMr,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.category,
  });

  String getName(bool isMr) => isMr ? nameMr : nameEn;

  LocationPointModel toLocationPoint() {
    return LocationPointModel(
      address: address,
      placeName: nameEn,
      latitude: latitude,
      longitude: longitude,
    );
  }
}
