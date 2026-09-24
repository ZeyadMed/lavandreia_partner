/// مدينة من /api/auth/cities
/// السيرفر بيرجع الاسم مترجم حسب الـ Accept-Language
class CityModel {
  final int id;
  final String name;

  const CityModel({required this.id, required this.name});

  factory CityModel.fromJson(Map<String, dynamic> json) => CityModel(
    id: (json['id'] as num).toInt(),
    name: json['name']?.toString() ?? '',
  );
}
