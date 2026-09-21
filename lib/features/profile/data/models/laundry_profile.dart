import 'dart:io';

/// بيانات المغسلة اللي بتتعرض في صفحة حسابي وبتتعدل من صفحة التعديل
/// mutable عن قصد زي RegisterData لأن شاشة التعديل بتعدل عليها مباشرة
class LaundryProfile {
  String laundryName;
  String ownerName;

  /// رقم التواصل كامل بكود الدولة
  String phone;

  /// الرقم من غير الكود، بيتخزن عشان الحقل يترجّع مليان في التعديل
  String phoneLocal;

  String email;

  /// اسم المنطقة/الحي، نص حر
  String areaName;

  String? countryId;
  String? cityId;

  /// إحداثيات الدبوس على الخريطة
  double? latitude;
  double? longitude;

  /// العنوان النصي اللي رجع من الخريطة
  String? pickedAddress;

  /// صورة الغلاف الجديدة لو اليوزر غيّرها، بتتبعت كـ multipart
  File? coverImage;

  /// لينك صورة الغلاف الحالية الجاي من السيرفر
  String? coverImageUrl;

  /// ساعات العمل كنص جاهز للعرض، الجدول الكامل بيتعدل من مكان تاني
  String workingHours;

  /// المغسلة مستقبلة طلبات ولا لأ، نفس السويتش اللي في الرئيسية
  bool isAvailable;

  LaundryProfile({
    required this.laundryName,
    required this.ownerName,
    required this.phone,
    required this.phoneLocal,
    required this.email,
    required this.areaName,
    required this.workingHours,
    this.countryId,
    this.cityId,
    this.latitude,
    this.longitude,
    this.pickedAddress,
    this.coverImage,
    this.coverImageUrl,
    this.isAvailable = true,
  });

  bool get hasLocationOnMap => latitude != null && longitude != null;

  /// العنوان المعروض: اللي جه من الخريطة، وإلا اسم المنطقة
  String get displayAddress {
    final picked = pickedAddress?.trim() ?? '';
    return picked.isNotEmpty ? picked : areaName;
  }

  /// نسخة جديدة بنفس البيانات، شاشة التعديل بتشتغل عليها
  /// عشان لو اليوزر رجع من غير حفظ الأصل مايتغيرش
  LaundryProfile copy() => LaundryProfile(
    laundryName: laundryName,
    ownerName: ownerName,
    phone: phone,
    phoneLocal: phoneLocal,
    email: email,
    areaName: areaName,
    workingHours: workingHours,
    countryId: countryId,
    cityId: cityId,
    latitude: latitude,
    longitude: longitude,
    pickedAddress: pickedAddress,
    coverImage: coverImage,
    coverImageUrl: coverImageUrl,
    isAvailable: isAvailable,
  );

  Map<String, dynamic> toJson() => {
    'laundry_name': laundryName,
    'owner_name': ownerName,
    'phone': phone,
    if (email.trim().isNotEmpty) 'email': email.trim(),
    'country_id': countryId,
    'city_id': cityId,
    'area_name': areaName,
    'latitude': latitude,
    'longitude': longitude,
    'address': pickedAddress,
  };
}
