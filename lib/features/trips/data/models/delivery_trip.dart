/// رحلة توصيل مربوطة بالطلب
/// الاستلام من بيت العميل للمغسلة، والتسليم من المغسلة لبيت العميل
library;

/// نفس enum DeliveryTripType في الباك إند
enum DeliveryTripType {
  pickup(apiName: 'Pickup'),
  dropoff(apiName: 'Dropoff');

  final String apiName;

  const DeliveryTripType({required this.apiName});

  /// السيرفر ممكن يرجّع الاسم "Pickup" أو الرقم 1
  static DeliveryTripType? fromApi(Object? value) {
    final number = int.tryParse('$value');
    if (number != null) {
      return number >= 1 && number <= values.length ? values[number - 1] : null;
    }
    final name = '$value'.toLowerCase();
    for (final type in values) {
      if (type.apiName.toLowerCase() == name) return type;
    }
    return null;
  }
}

class DeliveryTrip {
  final int id;
  final DeliveryTripType type;

  /// null لحد ما المغسلة توافق على طلب دليفري
  final int? driverId;
  final String driverName;
  final String driverPhone;

  /// صور الهدوم اللي الدليفري رفعها وهو بيستلم من العميل
  final List<String> photoUrls;

  /// سبب الفشل لو الدليفري معرفش يستلم أو يسلّم، زي CustomerNotAvailable
  final String failureReason;
  final String failureNote;

  /// عدد الدليفرية اللي طلبوا الرحلة ولسه المغسلة مردتش عليهم
  final int pendingRequestsCount;

  const DeliveryTrip({
    required this.id,
    required this.type,
    this.driverId,
    this.driverName = '',
    this.driverPhone = '',
    this.photoUrls = const [],
    this.failureReason = '',
    this.failureNote = '',
    this.pendingRequestsCount = 0,
  });

  /// الدليفري بيتعيّن على الرحلة بس لما المغسلة توافق على طلبه
  bool get hasDriver => driverId != null || driverName.isNotEmpty;

  /// { "id", "type", "driverId", "driverName", "driverPhoneNumber",
  /// "photoUrls", "failureReason", "failureNote", "pendingRequestsCount", .. }
  factory DeliveryTrip.fromJson(
    Map<String, dynamic> json, {
    required DeliveryTripType type,
  }) {
    return DeliveryTrip(
      id: (json['id'] as num? ?? 0).toInt(),
      type: DeliveryTripType.fromApi(json['type']) ?? type,
      driverId: json['driverId'] as int?,
      driverName: json['driverName'] as String? ?? '',
      driverPhone: json['driverPhoneNumber'] as String? ?? '',
      photoUrls: [
        for (final url in json['photoUrls'] as List? ?? const []) '$url',
      ],
      failureReason: json['failureReason'] as String? ?? '',
      failureNote: json['failureNote'] as String? ?? '',
      pendingRequestsCount: (json['pendingRequestsCount'] as num? ?? 0).toInt(),
    );
  }
}
