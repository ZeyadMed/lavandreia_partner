/// خدمة المغسلة بعد ما اليوزر يختارها ويحط سعرها
class SelectedService {
  /// المعرف اللي هيتبعت للسيرفر
  final String id;

  /// الاسم المعروض في الـ UI وفي المراجعة
  final String name;

  /// الإيموچي اللي بيتعرض جنب الاسم في كارت الخدمة
  final String emoji;

  /// السعر اللي اليوزر كتبه، بيفضل String عشان الحقل نفسه نصي
  /// وبيتحول لرقم وقت الإرسال بس
  String price;

  SelectedService({
    required this.id,
    required this.name,
    required this.emoji,
    this.price = '',
  });

  double? get priceValue => double.tryParse(price.trim());

  bool get hasValidPrice => (priceValue ?? 0) > 0;

  Map<String, dynamic> toJson() => {
    'service_id': id,
    'price': priceValue ?? 0,
  };
}
