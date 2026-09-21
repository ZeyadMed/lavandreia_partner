import 'package:lavanderia_partner/features/auth/register/data/services_catalog.dart';
import 'package:lavanderia_partner/features/services/data/models/laundry_service.dart';

/// خدمات المغسلة مؤقتاً لحد ما الـ API يجهز
/// المفروض تيجي من السيرفر بنفس اللي اليوزر اختاره وقت التسجيل
abstract final class ServicesMockData {
  /// الأسعار زي اللي في الديزاين، والخدمات اللي مش هنا اليوزر ميكونش
  /// اختارها فبتفضل متاحة للإضافة من زرار "إضافة خدمة"
  static const Map<String, String> _prices = {
    'wash_clothes': '15',
    'wash_shoes': '25',
    'wash_carpet': '80',
    'clean_curtains': '60',
    'dry_clean': '35',
    'ironing': '10',
    'steam_clean': '20',
    'wash_blankets': '70',
  };

  /// الخدمات الموقوفة في الديزاين
  static const Set<String> _inactive = {'wash_carpet', 'steam_clean'};

  /// الترتيب زي ما هو في الماب فوق، مش ترتيب الكتالوج
  static List<LaundryService> get all => _prices.entries.map((entry) {
    final option = ServicesCatalog.all.firstWhere(
      (service) => service.id == entry.key,
    );
    return LaundryService(
      id: option.id,
      labelKey: option.labelKey,
      emoji: option.emoji,
      price: entry.value,
      isActive: !_inactive.contains(option.id),
    );
  }).toList();
}
