/// تقييم عميل للمغسلة
class LaundryReview {
  final int id;
  final int rating;
  final String comment;
  final String customerName;
  final DateTime? createdAt;

  const LaundryReview({
    required this.id,
    required this.rating,
    required this.comment,
    required this.customerName,
    this.createdAt,
  });

  factory LaundryReview.fromJson(Map<String, dynamic> json) {
    return LaundryReview(
      id: json['id'] as int? ?? 0,
      rating: (json['rating'] as num? ?? 0).toInt(),
      comment: (json['comment'] as String? ?? '').trim(),
      customerName: json['customerName'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
    );
  }
}
