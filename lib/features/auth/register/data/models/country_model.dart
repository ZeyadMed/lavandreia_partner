/// دولة ومدنها، شكلها مطابق للي الـ API المفروض يرجعه
/// عشان لما الربط يحصل مايتغيرش غير المصدر بس
class CountryModel {
  final String id;

  /// كود الدولة ISO حرفين، بيتستخدم في حصر البحث على الخريطة
  /// منفصل عن [id] لأن الـ API ممكن يرجع id رقمي
  final String isoCode;
  final String nameAr;
  final String nameEn;
  final List<CityModel> cities;

  const CountryModel({
    required this.id,
    required this.isoCode,
    required this.nameAr,
    required this.nameEn,
    required this.cities,
  });

  factory CountryModel.fromJson(Map<String, dynamic> json) => CountryModel(
    id: json['id'].toString(),
    isoCode: json['iso_code'] ?? '',
    nameAr: json['name_ar'] ?? '',
    nameEn: json['name_en'] ?? '',
    cities: (json['cities'] as List? ?? [])
        .map((c) => CityModel.fromJson(c))
        .toList(),
  );

  /// الاسم حسب اللغة الحالية
  String nameFor(String languageCode) =>
      languageCode == 'ar' ? nameAr : nameEn;
}

class CityModel {
  final String id;
  final String nameAr;
  final String nameEn;

  const CityModel({
    required this.id,
    required this.nameAr,
    required this.nameEn,
  });

  factory CityModel.fromJson(Map<String, dynamic> json) => CityModel(
    id: json['id'].toString(),
    nameAr: json['name_ar'] ?? '',
    nameEn: json['name_en'] ?? '',
  );

  String nameFor(String languageCode) =>
      languageCode == 'ar' ? nameAr : nameEn;
}
