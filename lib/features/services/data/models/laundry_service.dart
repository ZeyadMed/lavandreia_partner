/// خدمة من خدمات المغسلة بعد التسجيل
/// نفس الخدمات اللي اليوزر اختارها في خطوة الخدمات، بس هنا بيقدر
/// يفعّلها/يوقفها ويعدّل سعرها
class LaundryService {
  /// المعرف اللي بيتبعت للسيرفر، نفس الـ id بتاع ServicesCatalog
  final String id;

  /// مفتاح الترجمة بتاع اسم الخدمة
  final String labelKey;

  /// الإيموچي اللي بيتعرض في الأيقونة جنب الاسم
  final String emoji;

  /// السعر، بيفضل String عشان الحقل نفسه نصي وبيتحول لرقم وقت الإرسال
  String price;

  /// الخدمة شغالة ولا موقوفة، الموقوفة مبتظهرش للعميل
  bool isActive;

  LaundryService({
    required this.id,
    required this.labelKey,
    required this.emoji,
    required this.price,
    this.isActive = true,
  });

  double? get priceValue => double.tryParse(price.trim());

  bool get hasValidPrice => (priceValue ?? 0) > 0;

  /// نسخة جديدة بنفس البيانات، بتتستخدم عشان نحتفظ بالنسخة الأصلية
  /// ونقارن بيها ونعرف إذا كان فيه تعديلات لسه متحفظتش
  LaundryService copy() => LaundryService(
    id: id,
    labelKey: labelKey,
    emoji: emoji,
    price: price,
    isActive: isActive,
  );

  /// المقارنة بالسعر والحالة بس، الباقي ثابت مبيتغيرش
  bool isSameAs(LaundryService other) =>
      id == other.id &&
      price.trim() == other.price.trim() &&
      isActive == other.isActive;

  Map<String, dynamic> toJson() => {
    'service_id': id,
    'price': priceValue ?? 0,
    'is_active': isActive,
  };
}
