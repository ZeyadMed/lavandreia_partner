/// مغسلة معتمدة الدليفري، بترجع في driverAccreditedBy على طلبات الرحلة
/// وعلى الرحلة نفسها لما يبقى عليها دليفري
class AccreditingLaundry {
  final int laundryId;
  final String laundryName;

  const AccreditingLaundry({
    required this.laundryId,
    required this.laundryName,
  });

  /// { "laundryId", "laundryName" }
  factory AccreditingLaundry.fromJson(Map<String, dynamic> json) =>
      AccreditingLaundry(
        laundryId: (json['laundryId'] as num? ?? 0).toInt(),
        laundryName: json['laundryName'] as String? ?? '',
      );

  /// السيرفر دايماً بيبعت لستة، بس لو الحقل ناقص (ريسبونس قديم) بترجع فاضية
  static List<AccreditingLaundry> listFromJson(Object? json) => [
    for (final item in json is List ? json : const [])
      if (item is Map<String, dynamic>) AccreditingLaundry.fromJson(item),
  ];
}

extension AccreditingLaundriesX on List<AccreditingLaundry> {
  /// false لو [laundryId] لسه مش معروف
  bool isAccreditedBy(int? laundryId) =>
      laundryId != null && any((laundry) => laundry.laundryId == laundryId);
}
