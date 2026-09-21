abstract interface class Endpoints {
  static const String baseUrl = 'https://app.professional-lawyer.com/api/';
  static const String updateLocation = '';

  // ****************************** Auth ********************************
  static const String register = 'register';
  static const String verifyOtp = 'verify-otp';
  static const String login = 'login';
  static const String forgetPassword = 'forgot/password';
  static const String resetPasssword = 'forgot/reset-password';
  static const String confirmPassword = '';
  static const String resentOtp = 'resend-otp';
  static const String forgetResendOtp = 'forgot/resend-otp';
  static const String forgetVerifyOtp = 'forgot/verify-otp';
  static const String logOut = 'logout';

  /// بناخد منها accessToken جديد لما القديم يقع بـ 401.
  /// بتستقبل { "refreshToken": "..." } وبترجع الاتنين جداد.
  static const String refreshToken = 'Auth/refresh-token';

}
