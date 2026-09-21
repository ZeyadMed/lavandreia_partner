/// موديلات الطلبات اللي بتظهر للمغسلة في الرئيسية وفي صفحة طلباتي
library;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lavanderia_partner/core/style/app_colors.dart';

/// حالة الطلب عند المغسلة
/// كل حالة ليها لون وخلفية للشيب اللي بيظهر فوق يمين الكارت
enum PartnerOrderStatus {
  /// طلب جديد لسه المغسلة ماردتش عليه
  newOrder(labelKey: 'order_status_new'),

  /// المغسلة قبلت الطلب وشغالة فيه
  inProgress(labelKey: 'order_status_in_progress'),

  /// الغسيل خلص ومستني التسليم
  ready(labelKey: 'order_status_ready'),

  /// الطلب اتسلم وخلص
  completed(labelKey: 'order_status_completed'),

  /// المغسلة رفضت الطلب
  rejected(labelKey: 'order_status_rejected');

  /// مفتاح الترجمة اللي بيتعرض في الشيب
  final String labelKey;

  const PartnerOrderStatus({required this.labelKey});

  /// لون نص الشيب
  Color get foregroundColor => switch (this) {
    PartnerOrderStatus.newOrder => AppColors.primaryColor,
    PartnerOrderStatus.inProgress => const Color(0xffB26A00),
    PartnerOrderStatus.ready => const Color(0xff0E8C4F),
    PartnerOrderStatus.completed => const Color(0xff2F8F5B),
    PartnerOrderStatus.rejected => AppColors.redColor2,
  };

  /// خلفية الشيب، نفس لون النص بس فاتح
  Color get backgroundColor => switch (this) {
    PartnerOrderStatus.newOrder => const Color(0xffE7EFFD),
    PartnerOrderStatus.inProgress => const Color(0xffFDF3D7),
    PartnerOrderStatus.ready => const Color(0xffE3F5EA),
    PartnerOrderStatus.completed => const Color(0xffE6F4EC),
    PartnerOrderStatus.rejected => const Color(0xffFCE8E8),
  };

  /// الطلبات اللي لسه شغالة، بتظهر في تاب "الحالية"
  bool get isActive =>
      this == PartnerOrderStatus.newOrder ||
      this == PartnerOrderStatus.inProgress ||
      this == PartnerOrderStatus.ready;
}

/// قطعة واحدة جوه الطلب
/// في كارت الطلبات بتظهر كشيب صغير، وفي التفاصيل بصورتها ونوع الخدمة
class PartnerOrderItem {
  /// اسم القطعة زي "قميص"
  final String name;

  final int quantity;

  /// نوع الخدمة المطلوبة للقطعة دي زي "غسيل وكي"
  /// مفتاح ترجمة مش نص جاهز
  final String serviceKey;

  /// صورة القطعة، لينك من السيرفر
  /// لو فاضية بيتعرض أيقونة بدالها
  final String imageUrl;

  const PartnerOrderItem({
    required this.name,
    required this.quantity,
    this.serviceKey = 'service_wash_iron',
    this.imageUrl = '',
  });

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
  delivered(labelKey: 'stage_delivered');

  final String labelKey;

  const PartnerOrderStage({required this.labelKey});

  /// المرحلة اللي بعدها، وnull لو دي آخر مرحلة
  PartnerOrderStage? get next {
    final all = PartnerOrderStage.values;
    return this == all.last ? null : all[index + 1];
  }

  /// الحالة اللي بتتحول ليها الطلب لما يوصل المرحلة دي
  PartnerOrderStatus get status => switch (this) {
    PartnerOrderStage.placed => PartnerOrderStatus.newOrder,
    PartnerOrderStage.accepted ||
    PartnerOrderStage.pickedUp ||
    PartnerOrderStage.cleaning => PartnerOrderStatus.inProgress,
    PartnerOrderStage.ready => PartnerOrderStatus.ready,
    PartnerOrderStage.delivered => PartnerOrderStatus.completed,
  };
}

/// طلب واحد زي ما بيتعرض في كارت الطلبات
class PartnerOrder {
  /// رقم الطلب من غير علامة #
  final String number;

  final String customerName;

  final List<PartnerOrderItem> items;

  /// عنوان العميل بالكامل: "مدينة نصر، القاهرة"
  final String address;

  /// وقت الطلب، بيتعرض بصيغة "اليوم، 10:45 ص"
  final DateTime createdAt;

  /// إجمالي الطلب بالريال
  final double total;

  final PartnerOrderStatus status;

  /// رقم تليفون العميل اللي بيظهر في كارت بيانات العميل
  final String customerPhone;

  /// المسافة بين المغسلة والعميل بالكيلومتر
  final double distanceKm;

  /// وقت التسليم المتوقع بالساعات
  final int estimatedHours;

  /// آخر مرحلة وصلها الطلب في التايم لاين
  final PartnerOrderStage stage;

  const PartnerOrder({
    required this.number,
    required this.customerName,
    required this.items,
    required this.address,
    required this.createdAt,
    required this.total,
    required this.status,
    this.customerPhone = '',
    this.distanceKm = 0,
    this.estimatedHours = 0,
    this.stage = PartnerOrderStage.placed,
  });

  /// بينسخ الطلب بمرحلة جديدة والحالة بتتحدث معاها تلقائياً
  PartnerOrder copyWithStage(PartnerOrderStage newStage) => PartnerOrder(
    number: number,
    customerName: customerName,
    items: items,
    address: address,
    createdAt: createdAt,
    total: total,
    status: newStage.status,
    customerPhone: customerPhone,
    distanceKm: distanceKm,
    estimatedHours: estimatedHours,
    stage: newStage,
  );

  /// إجمالي عدد القطع في الطلب
  int get itemsCount =>
      items.fold(0, (sum, item) => sum + item.quantity);

  /// "ORD-10245#" زي الديزاين
  String get displayNumber => '$number#';

  /// "2.3 كم"
  String get displayDistance => '$distanceKm ${'km'.tr()}';

  /// "4 ساعات"
  String get displayEta => 'hours_count'.plural(estimatedHours);

  /// "85 ر.س" — السعر من غير كسور لو رقم صحيح
  String get displayTotal {
    final isWhole = total == total.roundToDouble();
    final amount = isWhole ? total.toInt().toString() : total.toStringAsFixed(2);
    return '$amount ${'currency_sar'.tr()}';
  }

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
