import 'package:flutter/foundation.dart';
import 'package:lavanderia_partner/features/profile/data/models/partner_profile.dart';

/// بيانات المغسلة اللي عاملة لوجين، بتتملى من آخر GET api/laundry/profile نجح
/// والهوم بيجيبه أول ما يفتح، فبتبقى موجودة طول الجلسة
/// كروت الدليفرية بتسمع عليها عشان تعرف الدليفري معتمد عندها ولا لأ
/// مش في getIt عشان resetGetItAndInit مايمسحهاش، وبتتمسح مع الـ realtime
abstract final class CurrentLaundry {
  static final ValueNotifier<PartnerProfile?> profile = ValueNotifier(null);

  /// null لحد ما البروفايل يتجاب
  static int? get id => profile.value?.id;

  static void clear() => profile.value = null;
}
