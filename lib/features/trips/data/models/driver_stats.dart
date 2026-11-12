/// تقييم الدليفري وعدد رحلاته ومن إمتى على التطبيق
/// نفس الأسماء اللي أبلكيشن العميل بيقراها، وكلها null لحد ما السيرفر يبعتها
class DriverStats {
  /// متوسط تقييمات العملاء من 5
  final double? rating;
  final int? reviewsCount;

  /// الرحلات اللي خلّصها، استلام وتوصيل
  final int? totalTrips;

  /// تاريخ إنشاء حسابه
  final DateTime? joinedAt;

  const DriverStats({
    this.rating,
    this.reviewsCount,
    this.totalTrips,
    this.joinedAt,
  });

  /// flat: "driverAverageRating", "driverReviewsCount", "driverTotalTrips",
  /// "driverJoinedAt"
  /// أو جوه "driver": "averageRating", "reviewsCount",
  /// "totalTrips" / "completedTripsCount", "joinedAt" / "createdAt"
  /// "createdAt" اللي برا "driver" وقت الطلب أو الرحلة، مش تاريخ الاشتراك
  factory DriverStats.fromJson(Map<String, dynamic> json) {
    final driver = nestedDriver(json);
    num? number(String key, List<String> driverKeys) {
      final value =
          json[key] ??
          driverKeys
              .map((k) => driver[k])
              .firstWhere((v) => v != null, orElse: () => null);
      return value is num ? value : num.tryParse('${value ?? ''}');
    }

    final joined =
        json['driverJoinedAt'] ?? driver['joinedAt'] ?? driver['createdAt'];
    return DriverStats(
      rating: number('driverAverageRating', [
        'averageRating',
        'rating',
      ])?.toDouble(),
      reviewsCount: number('driverReviewsCount', ['reviewsCount'])?.toInt(),
      totalTrips: number('driverTotalTrips', [
        'totalTrips',
        'completedTripsCount',
      ])?.toInt(),
      joinedAt: DateTime.tryParse('${joined ?? ''}'),
    );
  }

  /// السيرفر مابعتش أي حاجة منهم
  bool get isEmpty =>
      rating == null &&
      reviewsCount == null &&
      totalTrips == null &&
      joinedAt == null;

  /// فيه تقييم أو عدد تقييمات، حتى لو صفر
  bool get hasRating => rating != null || reviewsCount != null;

  /// محدش قيّمه لسه، فبيظهر "جديد" بدل 0.0
  bool get isNew => (reviewsCount ?? 0) == 0 && (rating ?? 0) == 0;
}

/// بيانات الدليفري ممكن تيجي جوه "driver" بدل ما تبقى على نفس المستوى
Map<String, dynamic> nestedDriver(Map<String, dynamic> json) =>
    json['driver'] as Map<String, dynamic>? ?? const {};

/// صورة الدليفري وبيانات مركبته، من نفس المستوى أو من جوه "driver"
/// نفس القراية في عروض الدليفرية وفي الدليفري المتعيّن على الرحلة
class DriverVehicleJson {
  final String imageUrl;
  final String type;
  final String make;
  final String model;
  final int? year;

  const DriverVehicleJson._(
    this.imageUrl,
    this.type,
    this.make,
    this.model,
    this.year,
  );

  /// { "driverProfileImageUrl", "vehicleType", "vehicleMake", "vehicleModel",
  /// "vehicleYear" } أو جوه "driver" بـ "profileImageUrl" وباقي نفس الأسماء
  factory DriverVehicleJson.read(Map<String, dynamic> json) {
    final driver = nestedDriver(json);
    String text(String key, [String? driverKey]) =>
        '${json[key] ?? driver[driverKey ?? key] ?? ''}'.trim();

    final rawYear = json['vehicleYear'] ?? driver['vehicleYear'];
    final year = rawYear is num
        ? rawYear.toInt()
        : int.tryParse(text('vehicleYear'));
    return DriverVehicleJson._(
      text('driverProfileImageUrl', 'profileImageUrl'),
      text('vehicleType'),
      text('vehicleMake'),
      text('vehicleModel'),
      year == null || year <= 0 ? null : year,
    );
  }

  /// null بدل النص الفاضي
  String? get imageUrlOrNull => imageUrl.isEmpty ? null : imageUrl;
}

/// الماركة والموديل والسنة في سطر واحد زي "Kia Picanto • 2018"
/// فاضي لو مفيش حاجة منهم
String describeVehicle(String make, String model, int? year) {
  final name = [make, model].where((part) => part.isNotEmpty).join(' ');
  return [
    name,
    if (year != null) '$year',
  ].where((part) => part.isNotEmpty).join(' • ');
}
