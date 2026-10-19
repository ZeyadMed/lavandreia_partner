/// سياسة الخصوصية، الـ content بيبقى HTML متكتب من لوحة التحكم
class PrivacyPolicy {
  final String content;

  /// null لو السيرفر مابعتش تاريخ أو بعته بشكل غلط
  final DateTime? updatedAt;

  const PrivacyPolicy({required this.content, this.updatedAt});

  factory PrivacyPolicy.fromJson(Map<String, dynamic> json) {
    return PrivacyPolicy(
      content: json['content']?.toString() ?? '',
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? ''),
    );
  }
}
