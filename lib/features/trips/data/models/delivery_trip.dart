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

  /// زي ما السيرفر بيبعتها، بتتعرض بس ومش بنبني عليها منطق
  final String status;

  const DeliveryTrip({
    required this.id,
    required this.type,
    this.driverId,
    this.driverName = '',
    this.driverPhone = '',
    this.status = '',
  });

  /// الدليفري بيتعيّن على الرحلة بس لما المغسلة توافق على طلبه
  bool get hasDriver => driverId != null || driverName.isNotEmpty;

  /// { "id", "type", "status", "driverId", "driverName", "driverPhoneNumber" }
  /// بيانات الدليفري ممكن تيجي جوه "driver" بدل ما تبقى في الرحلة نفسها
  factory DeliveryTrip.fromJson(
    Map<String, dynamic> json, {
    required DeliveryTripType type,
  }) {
    final driver = json['driver'] as Map<String, dynamic>? ?? const {};
    return DeliveryTrip(
      id: (json['id'] as num? ?? 0).toInt(),
      type: DeliveryTripType.fromApi(json['type']) ?? type,
      driverId: (json['driverId'] ?? driver['id']) as int?,
      driverName:
          (json['driverName'] ?? driver['fullName'] ?? driver['name'])
              as String? ??
          '',
      driverPhone:
          (json['driverPhoneNumber'] ?? driver['phoneNumber']) as String? ?? '',
      status: '${json['status'] ?? ''}',
    );
  }
}
