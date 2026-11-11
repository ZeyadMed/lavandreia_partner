import 'package:lavanderia_partner/features/accredited_drivers/data/models/accrediting_laundry.dart';
import 'package:lavanderia_partner/features/trips/data/models/vehicle_kind.dart';

/// طلب دليفري واحد على رحلة، المغسلة بتختار واحد منهم والباقي بيترفض
class TripRequest {
  final int id;

  /// الرحلة اللي الدليفري طلبها، 0 لو السيرفر مابعتهاش
  final int deliveryTripId;
  final int? driverId;
  final String driverName;
  final String driverPhone;

  /// صورة الدليفري الشخصية، null لو مارفعش صورة
  final String? driverImageUrl;

  /// زي ما السيرفر بيبعته، زي Motorcycle أو Car
  final String vehicleType;

  /// ماركة المركبة زي Kia، وموديلها زي Picanto، فاضيين لو مش معروفين
  final String vehicleMake;
  final String vehicleModel;

  /// سنة الصنع، null لو مش معروفة
  final int? vehicleYear;

  /// بعد الدليفري عن المغسلة بالكيلومتر لو معروف
  final double? distanceKm;

  /// Pending أو Approved أو Rejected أو Cancelled
  final String status;

  final DateTime? createdAt;

  /// المغاسل اللي معتمدة الدليفري، فاضية لو محدش معتمده
  final List<AccreditingLaundry> driverAccreditedBy;

  const TripRequest({
    required this.id,
    required this.driverName,
    this.deliveryTripId = 0,
    this.driverId,
    this.driverPhone = '',
    this.driverImageUrl,
    this.vehicleType = '',
    this.vehicleMake = '',
    this.vehicleModel = '',
    this.vehicleYear,
    this.distanceKm,
    this.status = '',
    this.createdAt,
    this.driverAccreditedBy = const [],
  });

  /// { "id", "deliveryTripId", "driverId", "driverName", "driverPhoneNumber",
  /// "driverProfileImageUrl", "vehicleType", "vehicleMake", "vehicleModel",
  /// "vehicleYear", "distanceKm", "status", "createdAt", "driverAccreditedBy" }
  /// بيانات الدليفري ممكن تيجي جوه "driver" بدل ما تبقى في الطلب نفسه
  factory TripRequest.fromJson(Map<String, dynamic> json) {
    final driver = json['driver'] as Map<String, dynamic>? ?? const {};
    String text(String key, [String? driverKey]) =>
        '${json[key] ?? driver[driverKey ?? key] ?? ''}'.trim();

    final imageUrl = text('driverProfileImageUrl', 'profileImageUrl');
    final rawYear = json['vehicleYear'] ?? driver['vehicleYear'];
    final year = rawYear is num
        ? rawYear.toInt()
        : int.tryParse(text('vehicleYear'));
    return TripRequest(
      id: (json['id'] as num? ?? 0).toInt(),
      deliveryTripId: (json['deliveryTripId'] as num? ?? 0).toInt(),
      driverId: ((json['driverId'] ?? driver['id']) as num?)?.toInt(),
      driverName:
          (json['driverName'] ?? driver['fullName'] ?? driver['name'])
              as String? ??
          '',
      driverPhone:
          (json['driverPhoneNumber'] ?? driver['phoneNumber']) as String? ?? '',
      driverImageUrl: imageUrl.isEmpty ? null : imageUrl,
      vehicleType: text('vehicleType'),
      vehicleMake: text('vehicleMake'),
      vehicleModel: text('vehicleModel'),
      vehicleYear: year == null || year <= 0 ? null : year,
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
      status: '${json['status'] ?? ''}',
      createdAt: DateTime.tryParse('${json['createdAt'] ?? ''}'),
      driverAccreditedBy: AccreditingLaundry.listFromJson(
        json['driverAccreditedBy'],
      ),
    );
  }

  bool get isPending => status.toLowerCase() == 'pending';

  bool get isApproved => status.toLowerCase() == 'approved';

  bool get isRejected => status.toLowerCase() == 'rejected';

  bool get isCancelled => status.toLowerCase() == 'cancelled';

  /// لسه مستني المغسلة ترد، والحالة الفاضية كمان لو الحدث جه من غيرها
  bool get isOpen => !isApproved && !isRejected && !isCancelled;

  VehicleKind get vehicleKind => VehicleKind.fromApi(vehicleType);

  /// الماركة والموديل والسنة في سطر واحد زي "Kia Picanto • 2018"
  /// فاضي لو السيرفر مابعتش حاجة منهم
  String get vehicleDescription {
    final name = [
      vehicleMake,
      vehicleModel,
    ].where((part) => part.isNotEmpty).join(' ');
    return [
      name,
      if (vehicleYear != null) '$vehicleYear',
    ].where((part) => part.isNotEmpty).join(' • ');
  }

  /// الوقت المتوقع لوصوله المغسلة بالدقايق من المسافة وسرعة مركبته
  /// + دقيقتين لحد ما يتحرك، و null لو المسافة مش معروفة
  int? get etaMinutes {
    final distance = distanceKm;
    if (distance == null || distance < 0) return null;
    final minutes = (distance / vehicleKind.speedKmh * 60).ceil() + 2;
    return minutes < 1 ? 1 : minutes;
  }

  /// الأقرب الأول، واللي مسافته مش معروفة في الآخر بترتيب طلبه
  static int compareByArrival(TripRequest a, TripRequest b) {
    final etaA = a.etaMinutes;
    final etaB = b.etaMinutes;
    if (etaA != null && etaB != null && etaA != etaB) {
      return etaA.compareTo(etaB);
    }
    if (etaA == null && etaB != null) return 1;
    if (etaA != null && etaB == null) return -1;
    final createdA = a.createdAt;
    final createdB = b.createdAt;
    if (createdA == null || createdB == null) return a.id.compareTo(b.id);
    return createdA.compareTo(createdB);
  }

  /// الأقرب في الوصول لما يبقى فيه أكتر من عرض، و null لو عرض واحد أو مفيش
  static TripRequest? closestOf(List<TripRequest> requests) {
    if (requests.length < 2) return null;
    return requests.reduce(
      (closest, request) =>
          compareByArrival(request, closest) < 0 ? request : closest,
    );
  }

  /// المعتمدين لدى [laundryId] الأول وبعدهم بترتيب [compareByArrival]
  /// من غير [laundryId] بيبقى زي [compareByArrival] بالظبط
  static Comparator<TripRequest> compareForLaundry(int? laundryId) => (a, b) {
    final aAccredited = a.driverAccreditedBy.isAccreditedBy(laundryId);
    final bAccredited = b.driverAccreditedBy.isAccreditedBy(laundryId);
    if (aAccredited != bAccredited) return aAccredited ? -1 : 1;
    return compareByArrival(a, b);
  };

  TripRequest copyWith({
    String? status,
    List<AccreditingLaundry>? driverAccreditedBy,
  }) => TripRequest(
    id: id,
    deliveryTripId: deliveryTripId,
    driverId: driverId,
    driverName: driverName,
    driverPhone: driverPhone,
    driverImageUrl: driverImageUrl,
    vehicleType: vehicleType,
    vehicleMake: vehicleMake,
    vehicleModel: vehicleModel,
    vehicleYear: vehicleYear,
    distanceKm: distanceKm,
    status: status ?? this.status,
    createdAt: createdAt,
    driverAccreditedBy: driverAccreditedBy ?? this.driverAccreditedBy,
  );
}
