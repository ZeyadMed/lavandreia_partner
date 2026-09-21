import 'package:lavanderia_partner/features/profile/data/models/laundry_profile.dart';

/// بيانات المغسلة مؤقتاً لحد ما الـ API يجهز
/// نفس البيانات اللي في الديزاين
abstract final class ProfileMockData {
  /// نسخة واحدة بتفضل عايشة طول الجلسة عشان التعديلات ماتضيعش
  /// لما اليوزر يخرج من التاب ويرجعله
  static final LaundryProfile profile = LaundryProfile(
    laundryName: 'مغسلة المدينة',
    ownerName: 'محمد أحمد',
    phone: '+201501234567',
    phoneLocal: '501234567',
    email: 'laundry@email.com',
    areaName: 'مدينة نصر، القاهرة',
    workingHours: '8 ص — 10 م',
    countryId: 'EG',
    cityId: 'EG-CAI',
    latitude: 30.0594,
    longitude: 31.3308,
    pickedAddress: 'مدينة نصر، القاهرة',
  );
}
