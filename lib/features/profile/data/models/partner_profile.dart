/// بيانات المغسلة زي ما بترجع من GET api/laundry/profile
class PartnerProfile {
  final int id;
  final String name;
  final String ownerName;
  final String ownerPhoneNumber;
  final String phoneNumber;
  final String address;
  final int? cityId;
  final String cityName;
  final double? latitude;
  final double? longitude;
  final String? imageUrl;
  final double baseDeliveryFee;
  final double deliveryPricePerKm;
  final bool phoneNumberConfirmed;
  final bool hasServices;
  final DateTime? createdAt;

  const PartnerProfile({
    required this.id,
    required this.name,
    required this.ownerName,
    required this.ownerPhoneNumber,
    required this.phoneNumber,
    required this.address,
    required this.cityName,
    required this.baseDeliveryFee,
    required this.deliveryPricePerKm,
    required this.phoneNumberConfirmed,
    required this.hasServices,
    this.cityId,
    this.latitude,
    this.longitude,
    this.imageUrl,
    this.createdAt,
  });

  factory PartnerProfile.fromJson(Map<String, dynamic> json) => PartnerProfile(
    id: (json['id'] as num?)?.toInt() ?? 0,
    name: json['name'] as String? ?? '',
    ownerName: json['ownerName'] as String? ?? '',
    ownerPhoneNumber: json['ownerPhoneNumber'] as String? ?? '',
    phoneNumber: json['phoneNumber'] as String? ?? '',
    address: json['address'] as String? ?? '',
    cityId: (json['cityId'] as num?)?.toInt(),
    cityName: json['cityName'] as String? ?? '',
    latitude: (json['latitude'] as num?)?.toDouble(),
    longitude: (json['longitude'] as num?)?.toDouble(),
    imageUrl: json['imageUrl'] as String?,
    // الرسوم ممكن ترجع 0 كـ int، فبنقراها كـ num
    baseDeliveryFee: (json['baseDeliveryFee'] as num?)?.toDouble() ?? 0,
    deliveryPricePerKm: (json['deliveryPricePerKm'] as num?)?.toDouble() ?? 0,
    phoneNumberConfirmed: json['phoneNumberConfirmed'] as bool? ?? false,
    hasServices: json['hasServices'] as bool? ?? false,
    createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
  );
}
