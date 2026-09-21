/// قسم في صفحة نصية زي الشروط والأحكام أو سياسة الخصوصية
/// المفاتيح بتاعة الترجمة عشان الصفحة تشتغل بالعربي والإنجليزي
class LegalSection {
  final String titleKey;
  final String bodyKey;

  const LegalSection({required this.titleKey, required this.bodyKey});
}

/// محتوى الصفحات النصية
/// ثابت دلوقتي، ولما الـ API يجهز يتجاب منه بنفس الشكل
abstract final class LegalContent {
  static const List<LegalSection> terms = [
    LegalSection(titleKey: 'terms_s1_title', bodyKey: 'terms_s1_body'),
    LegalSection(titleKey: 'terms_s2_title', bodyKey: 'terms_s2_body'),
    LegalSection(titleKey: 'terms_s3_title', bodyKey: 'terms_s3_body'),
    LegalSection(titleKey: 'terms_s4_title', bodyKey: 'terms_s4_body'),
    LegalSection(titleKey: 'terms_s5_title', bodyKey: 'terms_s5_body'),
  ];

  static const List<LegalSection> privacy = [
    LegalSection(titleKey: 'privacy_s1_title', bodyKey: 'privacy_s1_body'),
    LegalSection(titleKey: 'privacy_s2_title', bodyKey: 'privacy_s2_body'),
    LegalSection(titleKey: 'privacy_s3_title', bodyKey: 'privacy_s3_body'),
    LegalSection(titleKey: 'privacy_s4_title', bodyKey: 'privacy_s4_body'),
    LegalSection(titleKey: 'privacy_s5_title', bodyKey: 'privacy_s5_body'),
  ];

  /// الأسئلة الشائعة في صفحة الدعم
  static const List<LegalSection> faq = [
    LegalSection(titleKey: 'faq_q1', bodyKey: 'faq_a1'),
    LegalSection(titleKey: 'faq_q2', bodyKey: 'faq_a2'),
    LegalSection(titleKey: 'faq_q3', bodyKey: 'faq_a3'),
    LegalSection(titleKey: 'faq_q4', bodyKey: 'faq_a4'),
  ];
}

/// وسائل التواصل مع الدعم
/// الأرقام والإيميل ثابتين دلوقتي لحد ما ييجوا من الإعدادات
abstract final class SupportContacts {
  static const String phone = '+201000000000';
  static const String whatsapp = '+201000000000';
  static const String email = 'support@lavanderia.com';
}
