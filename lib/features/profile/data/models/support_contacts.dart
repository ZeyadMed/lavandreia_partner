/// وسائل التواصل مع الدعم، بتتغير من لوحة التحكم
/// أي قيمة ممكن تيجي فاضية، والشاشة بتخفي السطر بتاعها
class SupportContacts {
  final String phoneNumber1;
  final String phoneNumber2;
  final String email;

  const SupportContacts({
    required this.phoneNumber1,
    required this.phoneNumber2,
    required this.email,
  });

  bool get isEmpty =>
      phoneNumber1.isEmpty && phoneNumber2.isEmpty && email.isEmpty;

  factory SupportContacts.fromJson(Map<String, dynamic> json) {
    return SupportContacts(
      phoneNumber1: json['phoneNumber1']?.toString().trim() ?? '',
      phoneNumber2: json['phoneNumber2']?.toString().trim() ?? '',
      email: json['email']?.toString().trim() ?? '',
    );
  }
}
