/// الموديلات اللي بتشيل بيانات التسجيل وهي ماشية بين الأربع خطوات
/// كلها mutable عن قصد لأن فيه كنترولر واحد بيعدل عليها خطوة ورا خطوة
library;

import 'dart:io';

import 'package:easy_localization/easy_localization.dart';

/// مواعيد العمل ليوم واحد
/// لو isClosed بترو الساعات بتتجاهل خالص
class WorkingDay {
  /// أيام الأسبوع بترتيب التقويم العربي، السبت أول يوم
  static const List<String> weekDays = [
    'saturday',
    'sunday',
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
  ];

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

  /// من ريسبونس GET working-hours:
  /// { "id", "dayOfWeek": "Saturday", "openTime": "09:00:00", "closeTime", "isClosed" }
  factory WorkingDay.fromJson(Map<String, dynamic> json) {
    final isClosed = json['isClosed'] as bool? ?? false;
    return WorkingDay(
      key: (json['dayOfWeek'] as String? ?? '').toLowerCase(),
      isClosed: isClosed,
      openTime: isClosed ? null : DateTimeRangePart.tryParse(json['openTime']),
      closeTime: isClosed
          ? null
          : DateTimeRangePart.tryParse(json['closeTime']),
    );
  }

  /// نسخة منفصلة عشان التعديل مايتحفظش في الأصل غير لما الفاليديشن يعدي
  WorkingDay copy() => WorkingDay(
    key: key,
    isClosed: isClosed,
    openTime: openTime,
    closeTime: closeTime,
  );

  /// اليوم يبقى تمام لو مقفول، أو لو الساعتين متحددين
  bool get isValid =>
      isClosed || (openTime != null && closeTime != null);

  /// السيرفر مستني اسم اليوم بالإنجليزي بحرف كبير زي Sunday
  String get apiDayName => '${key[0].toUpperCase()}${key.substring(1)}';

  Map<String, String> toFormFields() => {
    'DayOfWeek': apiDayName,
    'IsClosed': '$isClosed',
    if (!isClosed && openTime != null) 'OpenTime': openTime!.toApiString(),
    if (!isClosed && closeTime != null) 'CloseTime': closeTime!.toApiString(),
  };

  /// شكل اليوم في body الـ PUT working-hours
  Map<String, dynamic> toJson() => {
    'dayOfWeek': apiDayName,
    'isClosed': isClosed,
    if (!isClosed && openTime != null) 'openTime': openTime!.toApiString(),
    if (!isClosed && closeTime != null) 'closeTime': closeTime!.toApiString(),
  };
}

/// وقت بسيط (ساعة ودقيقة) بدل ما نستخدم TimeOfDay
/// عشان الموديل يفضل مستقل عن الـ Flutter widgets
class DateTimeRangePart {
  final int hour;
  final int minute;

  const DateTimeRangePart({required this.hour, required this.minute});

  /// بيقرا TimeSpan جاي من السيرفر زي 09:00:00، وبيرجع null لو فاضي أو مش مفهوم
  static DateTimeRangePart? tryParse(Object? value) {
    if (value is! String) return null;
    final parts = value.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return DateTimeRangePart(hour: hour, minute: minute);
  }

  /// الصيغة اللي بتتبعت للسيرفر: TimeSpan بـ 24 ساعة زي 09:00:00
  String toApiString() =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}:00';

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
  /// صورة الغلاف بتاعة المغسلة، إجبارية
  /// بتتبعت كـ File والـ GenericDataSource بيحولها لـ MultipartFile
  File? coverImage;

  String laundryName = '';

  /// رقم هاتف المغسلة نفسها، غير رقم المسؤول
  /// كامل بكود الدولة، جاي من CustomPhoneField
  String laundryPhone = '';

  /// الرقم من غير كود الدولة، بيتخزن عشان الحقل يترجّع مليان
  /// لما اليوزر يرجع للخطوة تاني
  String laundryPhoneLocal = '';

  String ownerName = '';

  /// رقم المسؤول كامل بكود الدولة
  String ownerPhone = '';

  /// نفس الفكرة: الرقم المحلي عشان ترجيع الحقل
  String ownerPhoneLocal = '';

  /// تأكيد كلمة المرور بيتحقق منه في الشاشة بس ومبيتبعتش
  String password = '';

  // ---------- خطوة 2: الموقع ----------
  int? cityId;

  /// اسم المدينة للعرض في المراجعة بس، السيرفر بياخد الـ id
  String? cityName;

  /// إحداثيات الدبوس على الخريطة
  double? latitude;
  double? longitude;

  /// العنوان النصي اللي رجع من الخريطة، هو اللي بيتبعت كـ Address
  String? pickedAddress;

  bool get hasLocationOnMap => latitude != null && longitude != null;

  // ---------- خطوة 3: مواعيد العمل ----------
  List<WorkingDay> workingDays = [];

  /// حقول الـ multipart اللي بتتبعت وقت إنشاء الحساب
  /// الأسماء مطابقة للـ swagger، والمواعيد مفرودة بصيغة WorkingHours[0].DayOfWeek
  /// عشان الـ model binding بتاع ASP.NET يقراها كلستة، ولأن _processFormData
  /// مبيعرفش يفرد لستة فيها maps
  Map<String, dynamic> toFormData() => {
    if (coverImage != null) 'Image': coverImage,
    'Name': laundryName,
    'PhoneNumber': laundryPhone,
    'OwnerName': ownerName,
    'OwnerPhoneNumber': ownerPhone,
    'Password': password,
    'Address': pickedAddress ?? '',
    if (cityId != null) 'CityId': '$cityId',
    if (latitude != null) 'Latitude': '$latitude',
    if (longitude != null) 'Longitude': '$longitude',
    for (var i = 0; i < workingDays.length; i++)
      for (final field in workingDays[i].toFormFields().entries)
        'WorkingHours[$i].${field.key}': field.value,
  };
}
