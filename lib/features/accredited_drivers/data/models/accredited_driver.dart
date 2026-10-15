/// دليفري معتمد عند المغسلة زي ما بيرجع من api/laundry/accredited-drivers
class AccreditedDriver {
  final int driverId;
  final String fullName;

  /// بصيغة +2189XXXXXXXX
  final String phoneNumber;

  /// null لو الدليفري مارفعش صورة
  final String? profileImageUrl;

  /// بالتوقيت المحلي
  final DateTime? accreditedAt;

  const AccreditedDriver({
    required this.driverId,
    required this.fullName,
    this.phoneNumber = '',
    this.profileImageUrl,
    this.accreditedAt,
  });

  /// { "driverId", "fullName", "phoneNumber", "profileImageUrl", "accreditedAt" }
  factory AccreditedDriver.fromJson(Map<String, dynamic> json) =>
      AccreditedDriver(
        driverId: (json['driverId'] as num? ?? 0).toInt(),
        fullName: json['fullName'] as String? ?? '',
        phoneNumber: json['phoneNumber'] as String? ?? '',
        profileImageUrl: json['profileImageUrl'] as String?,
        accreditedAt: _parseUtc(json['accreditedAt']),
      );

  /// التاريخ جاي UTC، ولو من غير Z الـ tryParse بيعتبره محلي فبنثبّته UTC الأول
  static DateTime? _parseUtc(Object? value) {
    final parsed = DateTime.tryParse('${value ?? ''}');
    if (parsed == null) return null;
    final utc = parsed.isUtc
        ? parsed
        : DateTime.utc(
            parsed.year,
            parsed.month,
            parsed.day,
            parsed.hour,
            parsed.minute,
            parsed.second,
            parsed.millisecond,
            parsed.microsecond,
          );
    return utc.toLocal();
  }
}
