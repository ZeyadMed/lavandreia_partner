abstract interface class Endpoints {
  static const String baseUrl = 'https://lavanderia.runasp.net/';
  static const String updateLocation = '';

  // ****************************** Auth ********************************
  static const String register = 'api/auth/laundry/register';

  /// المدن اللي بتتعرض في دروب داون التسجيل، بتقبل ?search اختياري
  static const String cities = 'api/auth/cities';

  /// تأكيد رقم المغسلة بعد التسجيل، بتستقبل { phoneNumber, code }
  static const String verifyPhone = 'api/auth/laundry/verify-phone';

  /// بتستقبل { phoneNumber, password, rememberMe, deviceToken }
  static const String login = 'api/auth/laundry/login';
  static const String forgetPassword = 'forgot/password';
  static const String resetPasssword = 'forgot/reset-password';
  static const String confirmPassword = '';
  static const String resentOtp = 'resend-otp';
  static const String forgetResendOtp = 'forgot/resend-otp';
  static const String forgetVerifyOtp = 'forgot/verify-otp';
  static const String logOut = '/api/auth/logout';

  /// بناخد منها accessToken جديد لما القديم يقع بـ 401.
  /// بتستقبل { "refreshToken": "..." } وبترجع الاتنين جداد.
  static const String refreshToken = '/api/auth/refresh-token';

  // ****************************** Laundry ********************************
  /// كل الخدمات اللي المغسلة تقدر تقدمها
  static const String laundryServices = 'api/laundry/services';

  /// أصناف خدمة معينة، بدّل {serviceId} بـ [serviceItems]
  static const String servicesItems = 'api/laundry/services/{serviceId}/items';

  /// أصناف المغسلة بأسعارها:
  /// GET بيجيبها، POST و PUT بيستقبلوا { items: [{ serviceItemId, price }] }
  /// و DELETE بيستقبل { serviceItemIds: [..] }
  static const String myServices = 'api/laundry/my-services';

  /// مواعيد عمل المغسلة: GET بيجيبها،
  /// و PUT بيستقبل { workingHours: [{ dayOfWeek, openTime, closeTime, isClosed }] }
  static const String workingHours = 'api/laundry/working-hours';

  static String serviceItems(int serviceId) =>
      servicesItems.replaceFirst('{serviceId}', '$serviceId');

  static const String orders = '/api/laundry/orders';
}
