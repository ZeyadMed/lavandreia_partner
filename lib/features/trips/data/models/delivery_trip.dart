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

/// مين المفروض يدخل كود التأكيد دلوقتي، نفس awaitingConfirmationBy في الباك إند
/// رحلة التسليم ليها كودين: الأول للمغسلة وهي بتسلّم الدليفري، والتاني للعميل
enum TripConfirmationParty {
  laundry(apiName: 'Laundry'),
  customer(apiName: 'Customer');

  final String apiName;

  const TripConfirmationParty({required this.apiName});

  static TripConfirmationParty? fromApi(Object? value) {
    final name = '${value ?? ''}'.toLowerCase();
    for (final party in values) {
      if (party.apiName.toLowerCase() == name) return party;
    }
    return null;
  }
}

class DeliveryTrip {
  final int id;
  final DeliveryTripType type;

  /// الطلب اللي الرحلة دي تبعه، 0 لو السيرفر مابعتهوش
  final int orderId;

  /// أجرة الدليفري على الرحلة
  final double fee;

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

  /// الرحلة مستنية حد يدخل الكود، و [awaitingConfirmationBy] بيقول مين
  final bool isAwaitingConfirmation;
  final TripConfirmationParty? awaitingConfirmationBy;

  /// اللي استلم أكّد بالكود: المغسلة في الاستلام والعميل في التسليم
  final bool isConfirmed;

  /// في التسليم بس: المغسلة سلّمت الهدوم للدليفري
  final bool isHandedOver;

  /// الرحلة خلصت ومبقاش عليها أي أكشن
  final bool isClosed;

  const DeliveryTrip({
    required this.id,
    required this.type,
    this.orderId = 0,
    this.fee = 0,
    this.driverId,
    this.driverName = '',
    this.driverPhone = '',
    this.photoUrls = const [],
    this.failureReason = '',
    this.failureNote = '',
    this.pendingRequestsCount = 0,
    this.isAwaitingConfirmation = false,
    this.awaitingConfirmationBy,
    this.isConfirmed = false,
    this.isHandedOver = false,
    this.isClosed = false,
  });

  /// الدليفري بيتعيّن على الرحلة بس لما المغسلة توافق على طلبه
  bool get hasDriver => driverId != null || driverName.isNotEmpty;

  /// الدليفري وصل المغسلة ومستنيها تدخل الكود اللي معاه
  /// قبل كده الدليفري لسه في الطريق، فمفيش زرار تأكيد
  bool get needsLaundryConfirmation =>
      awaitingConfirmationBy == TripConfirmationParty.laundry;

  /// { "id", "orderId", "type", "driverId", "driverName", "driverPhoneNumber",
  /// "fee", "isAwaitingConfirmation", "awaitingConfirmationBy", "isConfirmed",
  /// "isHandedOver", "isClosed", "photoUrls", "failureReason", "failureNote",
  /// "pendingRequestsCount", .. }
  factory DeliveryTrip.fromJson(
    Map<String, dynamic> json, {
    required DeliveryTripType type,
  }) {
    return DeliveryTrip(
      id: (json['id'] as num? ?? 0).toInt(),
      type: DeliveryTripType.fromApi(json['type']) ?? type,
      orderId: (json['orderId'] as num? ?? 0).toInt(),
      fee: (json['fee'] as num? ?? 0).toDouble(),
      driverId: json['driverId'] as int?,
      driverName: json['driverName'] as String? ?? '',
      driverPhone: json['driverPhoneNumber'] as String? ?? '',
      photoUrls: [
        for (final url in json['photoUrls'] as List? ?? const []) '$url',
      ],
      failureReason: json['failureReason'] as String? ?? '',
      failureNote: json['failureNote'] as String? ?? '',
      pendingRequestsCount: (json['pendingRequestsCount'] as num? ?? 0).toInt(),
      isAwaitingConfirmation: json['isAwaitingConfirmation'] as bool? ?? false,
      awaitingConfirmationBy: TripConfirmationParty.fromApi(
        json['awaitingConfirmationBy'],
      ),
      isConfirmed: json['isConfirmed'] as bool? ?? false,
      isHandedOver: json['isHandedOver'] as bool? ?? false,
      isClosed: json['isClosed'] as bool? ?? false,
    );
  }

  /// بيستخدمه الـ realtime عشان يحدّث عدد الطلبات من غير ما يجيب الطلب تاني
  DeliveryTrip copyWith({int? pendingRequestsCount}) => DeliveryTrip(
    id: id,
    type: type,
    orderId: orderId,
    fee: fee,
    driverId: driverId,
    driverName: driverName,
    driverPhone: driverPhone,
    photoUrls: photoUrls,
    failureReason: failureReason,
    failureNote: failureNote,
    pendingRequestsCount: pendingRequestsCount ?? this.pendingRequestsCount,
    isAwaitingConfirmation: isAwaitingConfirmation,
    awaitingConfirmationBy: awaitingConfirmationBy,
    isConfirmed: isConfirmed,
    isHandedOver: isHandedOver,
    isClosed: isClosed,
  );
}
