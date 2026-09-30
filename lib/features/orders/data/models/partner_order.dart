/// موديلات الطلبات اللي بتظهر للمغسلة في الرئيسية وفي صفحة طلباتي
library;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lavanderia_partner/core/style/app_colors.dart';
import 'package:lavanderia_partner/features/trips/data/models/delivery_trip.dart';

/// حالة الطلب، نفس enum OrderStatus في الباك إند بالترتيب
/// كل حالة ليها لون وخلفية للشيب اللي بيظهر فوق يمين الكارت
enum PartnerOrderStatus {
  /// طلب جديد لسه المغسلة ماردتش عليه
  newOrder(apiName: 'New', labelKey: 'order_status_new'),

  /// المغسلة قبلت ومستنية الدليفري يجيب الهدوم من العميل
  awaitingPickup(
    apiName: 'AwaitingPickup',
    labelKey: 'order_status_awaiting_pickup',
  ),

  /// الهدوم وصلت المغسلة ولسه متعدتش
  atLaundryPendingMatch(
    apiName: 'AtLaundryPendingMatch',
    labelKey: 'order_status_pending_match',
  ),

  /// المغسلة بعتت تعديل ومستنية رد العميل
  adjustmentPendingApproval(
    apiName: 'AdjustmentPendingApproval',
    labelKey: 'order_status_adjustment_pending',
  ),

  /// المغسلة شغالة في الغسيل
  inProgress(apiName: 'InProgress', labelKey: 'order_status_in_progress'),

  /// الغسيل خلص ومستني دليفري التسليم
  ready(apiName: 'Ready', labelKey: 'order_status_ready'),

  /// الدليفري في الطريق للعميل
  outForDelivery(
    apiName: 'OutForDelivery',
    labelKey: 'order_status_out_for_delivery',
  ),

  /// العميل استلم وخلص
  delivered(apiName: 'Delivered', labelKey: 'order_status_completed'),

  /// المغسلة رفضت الطلب
  rejected(apiName: 'Rejected', labelKey: 'order_status_rejected');

  /// الاسم زي ما الباك إند بيبعته
  final String apiName;

  /// مفتاح الترجمة اللي بيتعرض في الشيب
  final String labelKey;

  const PartnerOrderStatus({required this.apiName, required this.labelKey});

  /// السيرفر ممكن يرجّع الحالة كرقم زي "1" أو كاسم زي "New"
  /// الأرقام من 1 لـ 9 بنفس ترتيب الحالات هنا، وأي حاجة تانية بنعتبرها جديد
  static PartnerOrderStatus fromApi(Object? value) {
    final number = int.tryParse('$value');
    if (number != null) {
      return number >= 1 && number <= values.length
          ? values[number - 1]
          : PartnerOrderStatus.newOrder;
    }
    final name = '$value'.toLowerCase();
    for (final status in values) {
      if (status.apiName.toLowerCase() == name) return status;
    }
    return PartnerOrderStatus.newOrder;
  }

  /// لون نص الشيب
  Color get foregroundColor => switch (this) {
    PartnerOrderStatus.newOrder => AppColors.primaryColor,
    PartnerOrderStatus.awaitingPickup => const Color(0xff6B4FD8),
    PartnerOrderStatus.atLaundryPendingMatch => const Color(0xffC2410C),
    PartnerOrderStatus.adjustmentPendingApproval => const Color(0xffA21CAF),
    PartnerOrderStatus.inProgress => const Color(0xffB26A00),
    PartnerOrderStatus.ready => const Color(0xff0E8C4F),
    PartnerOrderStatus.outForDelivery => const Color(0xff0E7490),
    PartnerOrderStatus.delivered => const Color(0xff2F8F5B),
    PartnerOrderStatus.rejected => AppColors.redColor2,
  };

  /// خلفية الشيب، نفس لون النص بس فاتح
  Color get backgroundColor => switch (this) {
    PartnerOrderStatus.newOrder => const Color(0xffE7EFFD),
    PartnerOrderStatus.awaitingPickup => const Color(0xffEEEAFB),
    PartnerOrderStatus.atLaundryPendingMatch => const Color(0xffFDEBDD),
    PartnerOrderStatus.adjustmentPendingApproval => const Color(0xffF9E8FB),
    PartnerOrderStatus.inProgress => const Color(0xffFDF3D7),
    PartnerOrderStatus.ready => const Color(0xffE3F5EA),
    PartnerOrderStatus.outForDelivery => const Color(0xffE0F2F7),
    PartnerOrderStatus.delivered => const Color(0xffE6F4EC),
    PartnerOrderStatus.rejected => const Color(0xffFCE8E8),
  };

  /// آخر مرحلة وصلها الطلب في التايم لاين
  /// المرفوض ملوش مرحلة، فبيفضل على أول واحدة
  PartnerOrderStage get stage => switch (this) {
    PartnerOrderStatus.newOrder ||
    PartnerOrderStatus.rejected => PartnerOrderStage.placed,
    PartnerOrderStatus.awaitingPickup => PartnerOrderStage.accepted,
    PartnerOrderStatus.atLaundryPendingMatch ||
    PartnerOrderStatus.adjustmentPendingApproval => PartnerOrderStage.pickedUp,
    PartnerOrderStatus.inProgress => PartnerOrderStage.cleaning,
    PartnerOrderStatus.ready => PartnerOrderStage.ready,
    PartnerOrderStatus.outForDelivery => PartnerOrderStage.outForDelivery,
    PartnerOrderStatus.delivered => PartnerOrderStage.delivered,
  };
}

/// حالة الدفع، ماشية لوحدها جنب حالة الطلب ومش بتوقف شغل المغسلة
enum PaymentStatus {
  /// الدفع لسه ماتطلبش، بيتطلب بعد المطابقة
  none(labelKey: ''),
  pending(labelKey: 'payment_status_pending'),
  successful(labelKey: 'payment_status_successful'),
  failed(labelKey: 'payment_status_failed');

  final String labelKey;

  const PaymentStatus({required this.labelKey});

  static PaymentStatus fromApi(Object? value) =>
      switch ('${value ?? ''}'.toLowerCase()) {
        'successful' || 'paid' => PaymentStatus.successful,
        'failed' => PaymentStatus.failed,
        'pending' => PaymentStatus.pending,
        _ => PaymentStatus.none,
      };
}

/// قطعة واحدة جوه الطلب
/// في كارت الطلبات بتظهر كشيب صغير، وفي التفاصيل بصورتها ونوع الخدمة
class PartnerOrderItem {
  /// الـ id بتاع القطعة جوه الطلب، هو اللي بيتبعت كـ orderItemId في التعديل
  final int id;

  /// اسم القطعة زي "قميص"
  final String name;

  final int quantity;

  /// سعر القطعة الواحدة
  final double price;

  /// سعر القطعة × الكمية
  final double lineTotal;

  /// العميل رفض التعديل على القطعة دي فهترجعله من غير ما تتغسل
  final bool isReturned;

  /// نوع الخدمة المطلوبة للقطعة دي زي "غسيل وكي"
  /// مفتاح ترجمة مش نص جاهز
  final String serviceKey;

  /// صورة القطعة، لينك من السيرفر
  /// لو فاضية بيتعرض أيقونة بدالها
  final String imageUrl;

  const PartnerOrderItem({
    this.id = 0,
    required this.name,
    required this.quantity,
    this.price = 0,
    this.lineTotal = 0,
    this.isReturned = false,
    this.serviceKey = 'service_wash_iron',
    this.imageUrl = '',
  });

  /// { "id", "serviceItemName", "price", "quantity", "lineTotal", "isReturned" }
  /// السيرفر مش بيرجّع نوع الخدمة ولا صورة، فبيفضلوا فاضيين
  factory PartnerOrderItem.fromJson(Map<String, dynamic> json) {
    final quantity = (json['quantity'] as num? ?? 0).toInt();
    final price = (json['price'] as num? ?? 0).toDouble();
    return PartnerOrderItem(
      id: (json['id'] as num? ?? 0).toInt(),
      name: json['serviceItemName'] as String? ?? '',
      quantity: quantity,
      price: price,
      lineTotal: (json['lineTotal'] as num? ?? price * quantity).toDouble(),
      isReturned: json['isReturned'] as bool? ?? false,
      serviceKey: '',
    );
  }

  /// الشكل المعروض في الشيب: "2 قميص"
  String get display => '$quantity $name';
}

/// مراحل الطلب بالترتيب زي ما بتظهر في التايم لاين في صفحة التفاصيل
/// الترتيب هنا مهم لأن التقدم بيتحسب بالـ index
enum PartnerOrderStage {
  placed(labelKey: 'stage_placed'),
  accepted(labelKey: 'stage_accepted'),
  pickedUp(labelKey: 'stage_picked_up'),
  cleaning(labelKey: 'stage_cleaning'),
  ready(labelKey: 'stage_ready'),
  outForDelivery(labelKey: 'stage_out_for_delivery'),
  delivered(labelKey: 'stage_delivered');

  final String labelKey;

  const PartnerOrderStage({required this.labelKey});
}

/// طلب واحد زي ما بيتعرض في كارت الطلبات
class PartnerOrder {
  /// الـ id اللي في السيرفر، 0 للداتا الوهمية
  final int id;

  /// رقم الطلب من غير علامة #
  final String number;

  final String customerName;

  final List<PartnerOrderItem> items;

  /// عنوان العميل بالكامل: "مدينة نصر، القاهرة"
  final String address;

  /// وقت الطلب، بيتعرض بصيغة "اليوم، 10:45 ص"
  final DateTime createdAt;

  /// إجمالي الطلب = الأصناف + رسوم الاستلام + رسوم التسليم
  final double total;

  /// إجمالي الأصناف بس، وده اللي بينزل في محفظة المغسلة بعد المطابقة
  final double itemsTotal;

  final double pickupFee;
  final double dropoffFee;

  final PartnerOrderStatus status;

  final PaymentStatus paymentStatus;

  /// رقم تليفون العميل اللي بيظهر في كارت بيانات العميل
  final String customerPhone;

  /// اللي هيسلّم الهدوم للدليفري لو مش العميل نفسه
  final String pickupContactName;
  final String pickupContactPhone;

  /// رحلة الاستلام، بتتعمل لما المغسلة تقبل الطلب
  final DeliveryTrip? pickupTrip;

  /// رحلة التسليم، بتتعمل لما المغسلة تعلّم إن الطلب جاهز
  final DeliveryTrip? dropoffTrip;

  /// المسافة بين المغسلة والعميل بالكيلومتر
  final double distanceKm;

  /// وقت التسليم المتوقع بالساعات
  final int estimatedHours;

  const PartnerOrder({
    this.id = 0,
    required this.number,
    required this.customerName,
    required this.items,
    required this.address,
    required this.createdAt,
    required this.total,
    required this.status,
    this.itemsTotal = 0,
    this.pickupFee = 0,
    this.dropoffFee = 0,
    this.paymentStatus = PaymentStatus.none,
    this.customerPhone = '',
    this.pickupContactName = '',
    this.pickupContactPhone = '',
    this.pickupTrip,
    this.dropoffTrip,
    this.distanceKm = 0,
    this.estimatedHours = 0,
  });

  /// طلب واحد من ريسبونس GET api/laundry/orders
  factory PartnerOrder.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as int? ?? 0;
    final items = (json['items'] as List? ?? [])
        .map((item) => PartnerOrderItem.fromJson(item as Map<String, dynamic>))
        .toList();
    return PartnerOrder(
      id: id,
      number: '$id',
      customerName: json['customerName'] as String? ?? '',
      customerPhone: json['customerPhoneNumber'] as String? ?? '',
      pickupContactName: json['pickupContactName'] as String? ?? '',
      pickupContactPhone: json['pickupContactPhoneNumber'] as String? ?? '',
      items: items,
      address: json['deliveryAddress'] as String? ?? '',
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      total: (json['totalPrice'] as num? ?? 0).toDouble(),
      itemsTotal:
          (json['itemsTotal'] as num? ??
                  items.fold<double>(0, (sum, item) => sum + item.lineTotal))
              .toDouble(),
      pickupFee: (json['pickupFee'] as num? ?? 0).toDouble(),
      dropoffFee: (json['dropoffFee'] as num? ?? 0).toDouble(),
      status: PartnerOrderStatus.fromApi(json['status']),
      paymentStatus: PaymentStatus.fromApi(json['paymentStatus']),
      pickupTrip: _readTrip(json, DeliveryTripType.pickup),
      dropoffTrip: _readTrip(json, DeliveryTripType.dropoff),
    );
  }

  /// شكل الرحلات في ريسبونس الطلب مش متوثق في الـ Swagger، فبنقرا الأشكال المتوقعة:
  /// لستة "deliveryTrips" كل رحلة فيها "type"، أو "pickupTrip" / "dropoffTrip"،
  /// أو "pickupTripId" / "dropoffTripId" بس
  static DeliveryTrip? _readTrip(
    Map<String, dynamic> json,
    DeliveryTripType type,
  ) {
    final key = type == DeliveryTripType.pickup ? 'pickup' : 'dropoff';

    for (final trip in json['deliveryTrips'] as List? ?? const []) {
      if (trip is Map<String, dynamic> &&
          DeliveryTripType.fromApi(trip['type']) == type) {
        return DeliveryTrip.fromJson(trip, type: type);
      }
    }

    final trip = json['${key}Trip'];
    if (trip is Map<String, dynamic>) {
      return DeliveryTrip.fromJson(trip, type: type);
    }

    final tripId = json['${key}TripId'];
    if (tripId is int) return DeliveryTrip(id: tripId, type: type);
    return null;
  }

  /// آخر مرحلة وصلها الطلب في التايم لاين
  PartnerOrderStage get stage => status.stage;

  /// بينسخ الطلب بحالة جديدة، والباقي بيفضل زي ما هو
  PartnerOrder copyWith({required PartnerOrderStatus status}) => PartnerOrder(
    id: id,
    number: number,
    customerName: customerName,
    items: items,
    address: address,
    createdAt: createdAt,
    total: total,
    status: status,
    itemsTotal: itemsTotal,
    pickupFee: pickupFee,
    dropoffFee: dropoffFee,
    paymentStatus: paymentStatus,
    customerPhone: customerPhone,
    pickupContactName: pickupContactName,
    pickupContactPhone: pickupContactPhone,
    pickupTrip: pickupTrip,
    dropoffTrip: dropoffTrip,
    distanceKm: distanceKm,
    estimatedHours: estimatedHours,
  );

  /// إجمالي عدد القطع في الطلب
  int get itemsCount => items.fold(0, (sum, item) => sum + item.quantity);

  /// "ORD-10245#" زي الديزاين
  String get displayNumber => '$number#';

  /// "2.3 كم"
  String get displayDistance => '$distanceKm ${'km'.tr()}';

  /// "4 ساعات"
  String get displayEta => 'hours_count'.plural(estimatedHours);

  /// "85 د.ل"
  String get displayTotal => formatAmount(total);

  /// "اليوم، 10:45 ص" أو "أمس، 3:20 م" أو التاريخ لو أقدم من كده
  /// [locale] بييجي من الشاشة عشان الموديل يفضل من غير BuildContext
  String displayDate(String locale) {
    final now = DateTime.now();
    final orderDay = DateTime(createdAt.year, createdAt.month, createdAt.day);
    final today = DateTime(now.year, now.month, now.day);
    final diff = today.difference(orderDay).inDays;

    final time = DateFormat('h:mm', locale).format(createdAt);
    final period = createdAt.hour < 12 ? 'am_short'.tr() : 'pm_short'.tr();
    final clock = '$time $period';

    final day = switch (diff) {
      0 => 'today'.tr(),
      1 => 'yesterday'.tr(),
      _ => DateFormat('d MMMM', locale).format(createdAt),
    };

    return '$day، $clock';
  }
}

/// "85 د.ل" — السعر من غير كسور لو رقم صحيح
String formatAmount(double amount) {
  final isWhole = amount == amount.roundToDouble();
  final text = isWhole ? amount.toInt().toString() : amount.toStringAsFixed(2);
  return '$text ${'currency'.tr()}';
}
