import 'dart:io';

import 'package:lavanderia_partner/features/profile/data/models/partner_profile.dart';

/// البيانات اللي بتتعدل من صفحة تعديل المغسلة وبتتبعت في PUT api/laundry/profile
/// mutable عن قصد زي RegisterData لأن شاشة التعديل بتعدل عليها مباشرة
class LaundryProfile {
  String name;
  String ownerName;

  /// رقم المسؤول كامل بكود الدولة
  String ownerPhoneNumber;

  /// الرقم من غير الكود، بيتخزن عشان الحقل يترجّع مليان في التعديل
  String ownerPhoneLocal;

  String address;
  int? cityId;

  /// إحداثيات الدبوس على الخريطة
  double? latitude;
  double? longitude;

  /// لينك الصورة الحالية، للعرض بس في شاشة التعديل
  String imageUrl;

  /// الصورة الجديدة لو اليوزر غيّرها، بتتبعت كملف في الـ multipart
  File? image;

  LaundryProfile({
    required this.name,
    required this.ownerName,
    required this.ownerPhoneNumber,
    required this.ownerPhoneLocal,
    required this.address,
    required this.imageUrl,
    this.cityId,
    this.latitude,
    this.longitude,
    this.image,
  });

  /// من بيانات السيرفر، عشان شاشة التعديل تفتح مليانة
  /// الرقم المحلي هو الرقم من غير كود ليبيا
  factory LaundryProfile.fromPartner(PartnerProfile partner) => LaundryProfile(
    name: partner.name,
    ownerName: partner.ownerName,
    ownerPhoneNumber: partner.ownerPhoneNumber,
    ownerPhoneLocal: partner.ownerPhoneNumber.replaceFirst(
      RegExp(r'^\+218'),
      '',
    ),
    address: partner.address,
    cityId: partner.cityId,
    latitude: partner.latitude,
    longitude: partner.longitude,
    imageUrl: partner.imageUrl ?? '',
  );

  bool get hasLocationOnMap => latitude != null && longitude != null;

  /// نسخة جديدة بنفس البيانات، شاشة التعديل بتشتغل عليها
  /// عشان لو اليوزر رجع من غير حفظ الأصل مايتغيرش
  LaundryProfile copy() => LaundryProfile(
    name: name,
    ownerName: ownerName,
    ownerPhoneNumber: ownerPhoneNumber,
    ownerPhoneLocal: ownerPhoneLocal,
    address: address,
    cityId: cityId,
    latitude: latitude,
    longitude: longitude,
    imageUrl: imageUrl,
    image: image,
  );

  /// حقول الـ multipart بتاعة PUT api/laundry/profile، بنفس أسماء التسجيل
  /// الصورة بتتبعت بس لو اليوزر اختار واحدة جديدة، وإلا السيرفر بيسيب القديمة
  Map<String, dynamic> toFormData() => {
    if (image != null) 'Image': image,
    'Name': name,
    'OwnerName': ownerName,
    'OwnerPhoneNumber': ownerPhoneNumber,
    'Address': address,
    if (cityId != null) 'CityId': '$cityId',
    if (latitude != null) 'Latitude': '$latitude',
    if (longitude != null) 'Longitude': '$longitude',
  };
}
