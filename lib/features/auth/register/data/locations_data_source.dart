import 'package:lavanderia_partner/features/auth/register/data/models/country_model.dart';

/// مصدر الدول والمدن
/// دلوقتي ليست ثابتة، ولما الـ API يجهز يتعمل implementation تاني
/// ويتغير السطر بتاع الإنشاء بس من غير ما الشاشات تتلمس
abstract class LocationsDataSource {
  Future<List<CountryModel>> getCountries();
}

/// النسخة الثابتة اللي شغالة دلوقتي
class StaticLocationsDataSource implements LocationsDataSource {
  const StaticLocationsDataSource();

  @override
  Future<List<CountryModel>> getCountries() async => _countries;

  static const List<CountryModel> _countries = [
    CountryModel(
      id: 'LY',
      isoCode: 'LY',
      nameAr: 'ليبيا',
      nameEn: 'Libya',
      cities: [
        CityModel(id: 'LY-TIP', nameAr: 'طرابلس', nameEn: 'Tripoli'),
        CityModel(id: 'LY-BEN', nameAr: 'بنغازي', nameEn: 'Benghazi'),
        CityModel(id: 'LY-MIS', nameAr: 'مصراتة', nameEn: 'Misrata'),
        CityModel(id: 'LY-ZAW', nameAr: 'الزاوية', nameEn: 'Zawiya'),
        CityModel(id: 'LY-BAY', nameAr: 'البيضاء', nameEn: 'Bayda'),
        CityModel(id: 'LY-KHO', nameAr: 'الخمس', nameEn: 'Khoms'),
        CityModel(id: 'LY-TOB', nameAr: 'طبرق', nameEn: 'Tobruk'),
        CityModel(id: 'LY-SAB', nameAr: 'سبها', nameEn: 'Sabha'),
        CityModel(id: 'LY-DER', nameAr: 'درنة', nameEn: 'Derna'),
        CityModel(id: 'LY-SIR', nameAr: 'سرت', nameEn: 'Sirte'),
        CityModel(id: 'LY-AJD', nameAr: 'أجدابيا', nameEn: 'Ajdabiya'),
        CityModel(id: 'LY-GHA', nameAr: 'غريان', nameEn: 'Gharyan'),
        CityModel(id: 'LY-ZLI', nameAr: 'زليتن', nameEn: 'Zliten'),
        CityModel(id: 'LY-SAB2', nameAr: 'صبراتة', nameEn: 'Sabratha'),
        CityModel(id: 'LY-TAR', nameAr: 'ترهونة', nameEn: 'Tarhuna'),
      ],
    ),
    CountryModel(
      id: 'EG',
      isoCode: 'EG',
      nameAr: 'مصر',
      nameEn: 'Egypt',
      cities: [
        CityModel(id: 'EG-CAI', nameAr: 'القاهرة', nameEn: 'Cairo'),
        CityModel(id: 'EG-GIZ', nameAr: 'الجيزة', nameEn: 'Giza'),
        CityModel(id: 'EG-ALX', nameAr: 'الإسكندرية', nameEn: 'Alexandria'),
        CityModel(id: 'EG-DAK', nameAr: 'الدقهلية', nameEn: 'Dakahlia'),
        CityModel(id: 'EG-SHR', nameAr: 'الشرقية', nameEn: 'Sharqia'),
        CityModel(id: 'EG-QAL', nameAr: 'القليوبية', nameEn: 'Qalyubia'),
        CityModel(id: 'EG-PTS', nameAr: 'بورسعيد', nameEn: 'Port Said'),
        CityModel(id: 'EG-SUZ', nameAr: 'السويس', nameEn: 'Suez'),
        CityModel(id: 'EG-ASW', nameAr: 'أسوان', nameEn: 'Aswan'),
        CityModel(id: 'EG-LUX', nameAr: 'الأقصر', nameEn: 'Luxor'),
      ],
    ),
  ];
}
