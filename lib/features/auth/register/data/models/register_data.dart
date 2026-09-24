/// الموديلات اللي بتشيل بيانات التسجيل وهي ماشية بين الأربع خطوات
/// كلها mutable عن قصد لأن فيه كنترولر واحد بيعدل عليها خطوة ورا خطوة
library;

import 'dart:io';

import 'package:easy_localization/easy_localization.dart';

/// مواعيد العمل ليوم واحد
/// لو isClosed بترو الساعات بتتجاهل خالص
class WorkingDay {
  /// مفتاح اليوم زي 'saturday'، نفس المفاتيح اللي في ملفات الترجمة
  final String key;

  bool isClosed;

  /// وقت الفتح، null لو اليوم مقفول أو لسه متحددش
  DateTimeRangePart? openTime;

  /// وقت القفل
  DateTimeRangePart? closeTime;

  WorkingDay({
    required this.key,
    this.isClosed = false,
    this.openTime,
    this.closeTime,
  });

  /// اليوم يبقى تمام لو مقفول، أو لو الساعتين متحددين
  bool get isValid =>
      isClosed || (openTime != null && closeTime != null);

  Map<String, dynamic> toJson() => {
    'day': key,
    'is_closed': isClosed,
    if (!isClosed) 'open_time': openTime?.toApiString(),
    if (!isClosed) 'close_time': closeTime?.toApiString(),
  };
}

/// وقت بسيط (ساعة ودقيقة) بدل ما نستخدم TimeOfDay
/// عشان الموديل يفضل مستقل عن الـ Flutter widgets
class DateTimeRangePart {
  final int hour;
  final int minute;

  const DateTimeRangePart({required this.hour, required this.minute});

  /// الصيغة اللي بتتبعت للسيرفر: 24 ساعة
  String toApiString() =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  /// الصيغة اللي بتتعرض لليوزر: 12 ساعة بـ ص/م
  /// الليبلز بتتبعت من بره عشان الموديل يفضل مستقل عن الترجمة
  String toDisplayString({String amLabel = 'ص', String pmLabel = 'م'}) {
    final period = hour < 12 ? amLabel : pmLabel;
    var displayHour = hour % 12;
    if (displayHour == 0) displayHour = 12;
    return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
  }
}

/// عرض الوقت بليبلز مترجمة، بيتستخدم في كل مكان بيعرض ساعة لليوزر
extension LocalizedTimeDisplay on DateTimeRangePart {
  String toLocalizedString() =>
      toDisplayString(amLabel: 'am'.tr(), pmLabel: 'pm'.tr());
}

/// كل بيانات التسجيل في مكان واحد
/// الكنترولر بيمسك نسخة واحدة منها وبيمررها لشاشة المراجعة في الآخر
class RegisterData {
  // ---------- خطوة 1: بيانات المغسلة ----------
  /// صورة الغلاف بتاعة المغسلة، اختيارية
  /// بتتبعت كـ multipart مش جوه الـ JSON فمش موجودة في toJson
  File? coverImage;

  String laundryName = '';
  String ownerName = '';

  /// الرقم كامل بكود الدولة، جاي من CustomPhoneField
  String ownerPhone = '';

  /// الرقم من غير كود الدولة، بيتخزن عشان الحقل يترجّع مليان
  /// لما اليوزر يرجع للخطوة تاني
  String ownerPhoneLocal = '';

  /// اختياري، ممكن يفضل فاضي
  String email = '';
  String password = '';

  // ---------- خطوة 2: الموقع ----------
  String? countryId;
  String? countryName;
  String? cityId;
  String? cityName;

  /// اسم المنطقة/الحي، نص حر
  String areaName = '';

  /// رقم هاتف المغسلة نفسها، غير رقم المسؤول
  String laundryPhone = '';

  /// نفس الفكرة: الرقم المحلي عشان ترجيع الحقل
  String laundryPhoneLocal = '';

  /// إحداثيات الدبوس على الخريطة
  double? latitude;
  double? longitude;

  /// العنوان النصي اللي رجع من الخريطة، بيتعرض في المراجعة
  String? pickedAddress;

  bool get hasLocationOnMap => latitude != null && longitude != null;

  // ---------- خطوة 3: مواعيد العمل ----------
  List<WorkingDay> workingDays = [];

  /// الشكل اللي هيتبعت للـ API وقت إنشاء الحساب
  Map<String, dynamic> toJson() => {
    'laundry_name': laundryName,
    'owner_name': ownerName,
    'owner_phone': ownerPhone,
    if (email.trim().isNotEmpty) 'email': email.trim(),
    'password': password,
    'country_id': countryId,
    'city_id': cityId,
    'area_name': areaName,
    'laundry_phone': laundryPhone,
    'latitude': latitude,
    'longitude': longitude,
    'address': pickedAddress,
    'working_hours': workingDays.map((d) => d.toJson()).toList(),
  };
}
