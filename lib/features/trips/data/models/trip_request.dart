/// طلب دليفري واحد على رحلة، المغسلة بتختار واحد منهم والباقي بيترفض
class TripRequest {
  final int id;
  final String driverName;
  final String driverPhone;

  /// زي ما السيرفر بيبعته، زي Motorcycle أو Car
  final String vehicleType;

  /// Pending أو Approved أو Rejected
  final String status;

  const TripRequest({
    required this.id,
    required this.driverName,
    this.driverPhone = '',
    this.vehicleType = '',
    this.status = '',
  });

  /// { "id", "status", "driverName", "driverPhoneNumber", "vehicleType" }
  /// بيانات الدليفري ممكن تيجي جوه "driver" بدل ما تبقى في الطلب نفسه
  factory TripRequest.fromJson(Map<String, dynamic> json) {
    final driver = json['driver'] as Map<String, dynamic>? ?? const {};
    return TripRequest(
      id: (json['id'] as num? ?? 0).toInt(),
      driverName:
          (json['driverName'] ?? driver['fullName'] ?? driver['name'])
              as String? ??
          '',
      driverPhone:
          (json['driverPhoneNumber'] ?? driver['phoneNumber']) as String? ?? '',
      vehicleType: '${json['vehicleType'] ?? driver['vehicleType'] ?? ''}',
      status: '${json['status'] ?? ''}',
    );
  }

  bool get isApproved => status.toLowerCase() == 'approved';

  bool get isRejected => status.toLowerCase() == 'rejected';

  TripRequest copyWith({required String status}) => TripRequest(
    id: id,
    driverName: driverName,
    driverPhone: driverPhone,
    vehicleType: vehicleType,
    status: status,
  );
}
