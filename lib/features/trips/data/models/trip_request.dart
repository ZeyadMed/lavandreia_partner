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

  /// زي ما السيرفر بيبعته، زي Motorcycle أو Car
  final String vehicleType;

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
    this.vehicleType = '',
    this.distanceKm,
    this.status = '',
    this.createdAt,
    this.driverAccreditedBy = const [],
  });

  /// { "id", "deliveryTripId", "driverId", "driverName", "driverPhoneNumber",
  /// "distanceKm", "status", "createdAt", "vehicleType", "driverAccreditedBy" }
  /// بيانات الدليفري ممكن تيجي جوه "driver" بدل ما تبقى في الطلب نفسه
  factory TripRequest.fromJson(Map<String, dynamic> json) {
    final driver = json['driver'] as Map<String, dynamic>? ?? const {};
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
      vehicleType: '${json['vehicleType'] ?? driver['vehicleType'] ?? ''}',
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
    vehicleType: vehicleType,
    distanceKm: distanceKm,
    status: status ?? this.status,
    createdAt: createdAt,
    driverAccreditedBy: driverAccreditedBy ?? this.driverAccreditedBy,
  );
}
