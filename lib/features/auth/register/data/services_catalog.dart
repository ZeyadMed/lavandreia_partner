/// خدمة متاحة للاختيار في خطوة الخدمات
/// الـ label مفتاح ترجمة مش نص جاهز
class ServiceOption {
  final String id;
  final String labelKey;
  final String emoji;

  const ServiceOption({
    required this.id,
    required this.labelKey,
    required this.emoji,
  });
}

/// الخدمات اللي المغسلة تقدر تختار منها
/// ثابتة دلوقتي، ولما الـ API يجهز تتجاب منه بنفس الشكل
abstract final class ServicesCatalog {
  static const List<ServiceOption> all = [
    ServiceOption(id: 'wash_clothes', labelKey: 'service_wash_clothes', emoji: '👔'),
    ServiceOption(id: 'wash_shoes', labelKey: 'service_wash_shoes', emoji: '👟'),
    ServiceOption(id: 'wash_carpet', labelKey: 'service_wash_carpet', emoji: '🟫'),
    ServiceOption(id: 'clean_bedding', labelKey: 'service_clean_bedding', emoji: '🛏️'),
    ServiceOption(id: 'clean_curtains', labelKey: 'service_clean_curtains', emoji: '🚪'),
    ServiceOption(id: 'wash_blankets', labelKey: 'service_wash_blankets', emoji: '🛌'),
    ServiceOption(id: 'dry_clean', labelKey: 'service_dry_clean', emoji: '✨'),
    ServiceOption(id: 'ironing', labelKey: 'service_ironing', emoji: '☀️'),
    ServiceOption(id: 'clean_bags', labelKey: 'service_clean_bags', emoji: '👜'),
    ServiceOption(id: 'clean_luxury', labelKey: 'service_clean_luxury', emoji: '💎'),
    ServiceOption(id: 'steam_clean', labelKey: 'service_steam_clean', emoji: '💨'),
    ServiceOption(id: 'other', labelKey: 'service_other', emoji: '➕'),
  ];
}
